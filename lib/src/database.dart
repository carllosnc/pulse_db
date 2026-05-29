import 'dart:async';

import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import 'exceptions.dart';
import 'table_notifier.dart';
import 'migration.dart';
import 'table_tracker.dart' as tracker;
import 'schema.dart';

class PulseDb {
  Database? _db;
  late TableNotifier _notifier;
  bool _isOpen = false;
  bool _inTransaction = false;
  final Set<String> _pendingTables = {};

  static Future<PulseDb> openAsync({String? path, String databaseName = 'default.db', List<Migration> migrations = const [], List<TableDef> tables = const []}) async {
    final db = PulseDb();
    db.open(path: path ?? '${(await getApplicationDocumentsDirectory()).path}/$databaseName', migrations: migrations, tables: tables);
    return db;
  }

  void open({required String path, List<Migration> migrations = const [], List<TableDef> tables = const []}) {
    _db = sqlite3.open(path);
    _notifier = TableNotifier();
    _isOpen = true;
    if (tables.isNotEmpty) {
      _syncTables(tables);
    }
    if (migrations.isNotEmpty) {
      _runMigrations(migrations);
    }
  }

  void close() {
    _notifier.dispose();
    _db?.close();
    _db = null;
    _isOpen = false;
  }

  bool get isOpen => _isOpen;

  void _ensureOpen() {
    if (!_isOpen || _db == null) {
      throw PulseDbClosedException('Database is not open');
    }
  }

  T _wrapExceptions<T>(T Function() block) {
    try {
      return block();
    } on SqliteException catch (e) {
      if (e.resultCode == 19) {
        throw PulseDbConstraintException(e.message, e);
      } else if (e.message.contains('no such table') || e.message.contains('no such column') || e.message.contains('has no column named')) {
        throw PulseDbSchemaException(e.message, e);
      }
      throw PulseDbException(e.message, e);
    } catch (e) {
      if (e is PulseDbException) rethrow;
      throw PulseDbException(e.toString(), e);
    }
  }

  Stream<Set<String>> get changes => _notifier.changes;

  List<Map<String, dynamic>> query(String sql, [List<Object?> params = const []]) {
    _ensureOpen();
    return _wrapExceptions(() {
      final rows = _db!.select(sql, params);
      return rows.map((r) => Map<String, dynamic>.from(r)).toList();
    });
  }

  int execute(String sql, [List<Object?> params = const []]) {
    _ensureOpen();
    return _wrapExceptions(() {
      final tables = tracker.extractTables(sql);
      _db!.execute(sql, params);
      final affected = _db!.updatedRows;
      if (_inTransaction) {
        _pendingTables.addAll(tables);
      } else {
        _notifier.notify(tables);
      }
      return affected;
    });
  }

  int insert(String table, Map<String, dynamic> data) {
    final columns = data.keys.join(', ');
    final placeholders = data.keys.map((_) => '?').join(', ');
    final values = data.values.toList();
    execute('INSERT INTO "$table" ($columns) VALUES ($placeholders)', values);
    return _db!.lastInsertRowId;
  }

  int update(String table, Map<String, dynamic> data, String where, [List<Object?> whereArgs = const []]) {
    final setClause = data.keys.map((k) => '$k = ?').join(', ');
    final values = [...data.values, ...whereArgs];
    return execute('UPDATE "$table" SET $setClause WHERE $where', values);
  }

  int delete(String table, String where, [List<Object?> whereArgs = const []]) {
    return execute('DELETE FROM "$table" WHERE $where', whereArgs);
  }

  void transaction(void Function() fn) {
    _ensureOpen();
    if (_inTransaction) {
      throw PulseDbTransactionException('Nested transactions are not supported');
    }
    _inTransaction = true;
    _pendingTables.clear();
    _wrapExceptions(() => _db!.execute('BEGIN'));
    try {
      fn();
      _wrapExceptions(() => _db!.execute('COMMIT'));
    } catch (e) {
      _wrapExceptions(() => _db!.execute('ROLLBACK'));
      _pendingTables.clear();
      _inTransaction = false;
      if (e is PulseDbException) rethrow;
      throw PulseDbTransactionException('Transaction failed: $e', e);
    }
    _inTransaction = false;
    if (_pendingTables.isNotEmpty) {
      _notifier.notify(Set.of(_pendingTables));
      _pendingTables.clear();
    }
  }

  Stream<List<Map<String, dynamic>>> watch(String table) {
    _ensureOpen();
    return _watchQuery('SELECT * FROM "$table"', []);
  }

  Stream<List<Map<String, dynamic>>> watchQuery(String sql, [List<Object?> params = const []]) {
    _ensureOpen();
    return _watchQuery(sql, params);
  }

  Stream<List<Map<String, dynamic>>> _watchQuery(String sql, List<Object?> params) {
    final tables = tracker.extractTables(sql);
    late final StreamController<List<Map<String, dynamic>>> controller;
    StreamSubscription<Set<String>>? sub;
    var started = false;

    void emit() {
      if (!_isOpen) return;
      try {
        controller.add(query(sql, params));
      } catch (e) {
        controller.addError(e);
      }
    }

    controller = StreamController<List<Map<String, dynamic>>>.broadcast(
      onListen: () {
        if (started) return;
        started = true;
        emit();
        sub = _notifier.changes.where((changed) => changed.any((t) => tables.contains(t))).listen((_) => emit());
      },
      onCancel: () => sub?.cancel(),
    );

    return controller.stream;
  }

  void _syncTables(List<TableDef> tables) {
    _db!.execute('''CREATE TABLE IF NOT EXISTS _meta_schema (
      table_name TEXT PRIMARY KEY,
      columns_hash TEXT NOT NULL,
      updated_at TEXT NOT NULL DEFAULT (datetime('now'))
    )''');

    for (final table in tables) {
      _syncTable(table);
    }
  }

  void _syncTable(TableDef table) {
    final hash = _schemaHash(table);
    final rows = query('SELECT columns_hash FROM _meta_schema WHERE table_name = ?', [table.name]);

    if (rows.isEmpty) {
      _db!.execute(table.createSql.replaceFirst('CREATE TABLE', 'CREATE TABLE IF NOT EXISTS'));
    } else if (rows.first['columns_hash'] != hash) {
      _addMissingColumns(table);
    } else {
      return;
    }

    _db!.execute('INSERT OR REPLACE INTO _meta_schema (table_name, columns_hash) VALUES (?, ?)', [table.name, hash]);
  }

  void _addMissingColumns(TableDef table) {
    final existing = query('PRAGMA table_info("${table.name}")');
    final existingNames = existing.map((r) => r['name'] as String).toSet();
    for (final col in table.columns) {
      if (!existingNames.contains(col.name)) {
        _db!.execute('ALTER TABLE "${table.name}" ADD COLUMN ${col.definition}');
      }
    }
  }

  static String _schemaHash(TableDef table) => table.columns.map((c) => c.definition).join('||');

  void _runMigrations(List<Migration> migrations) {
    _db!.execute('''CREATE TABLE IF NOT EXISTS _meta_migrations (
      version INTEGER PRIMARY KEY,
      applied_at TEXT NOT NULL DEFAULT (datetime('now'))
    )''');

    final applied = _db!.select('SELECT version FROM _meta_migrations').map((r) => r.columnAt(0) as int).toSet();

    for (final m in migrations) {
      if (!applied.contains(m.version)) {
        _db!.execute(m.up);
        _db!.execute('INSERT INTO _meta_migrations (version) VALUES (?)', [m.version]);
      }
    }
  }
}
