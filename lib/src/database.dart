import 'dart:async';

import 'package:sqlite3/sqlite3.dart';

import 'change_notifier.dart';
import 'migration.dart';
import 'table_tracker.dart' as tracker;

class PulseDb {
  Database? _db;
  late ChangeNotifier _notifier;
  bool _isOpen = false;
  bool _inTransaction = false;
  final Set<String> _pendingTables = {};

  void open(String path, {List<Migration> migrations = const []}) {
    _db = sqlite3.open(path);
    _notifier = ChangeNotifier();
    _isOpen = true;
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
      throw StateError('Database is not open');
    }
  }

  Stream<Set<String>> get changes => _notifier.changes;

  List<Map<String, dynamic>> query(
    String sql, [
    List<Object?> params = const [],
  ]) {
    _ensureOpen();
    final rows = _db!.select(sql, params);
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  int execute(String sql, [List<Object?> params = const []]) {
    _ensureOpen();
    final tables = tracker.extractTables(sql);
    _db!.execute(sql, params);
    final affected = _db!.updatedRows;
    if (_inTransaction) {
      _pendingTables.addAll(tables);
    } else {
      _notifier.notify(tables);
    }
    return affected;
  }

  int insert(String table, Map<String, dynamic> data) {
    final columns = data.keys.join(', ');
    final placeholders = data.keys.map((_) => '?').join(', ');
    final values = data.values.toList();
    execute('INSERT INTO "$table" ($columns) VALUES ($placeholders)', values);
    return _db!.lastInsertRowId;
  }

  int update(
    String table,
    Map<String, dynamic> data,
    String where, [
    List<Object?> whereArgs = const [],
  ]) {
    final setClause = data.keys.map((k) => '$k = ?').join(', ');
    final values = [...data.values, ...whereArgs];
    return execute(
      'UPDATE "$table" SET $setClause WHERE $where',
      values,
    );
  }

  int delete(
    String table,
    String where, [
    List<Object?> whereArgs = const [],
  ]) {
    return execute(
      'DELETE FROM "$table" WHERE $where',
      whereArgs,
    );
  }

  void transaction(void Function() fn) {
    _ensureOpen();
    if (_inTransaction) {
      throw StateError('Nested transactions are not supported');
    }
    _inTransaction = true;
    _pendingTables.clear();
    _db!.execute('BEGIN');
    try {
      fn();
      _db!.execute('COMMIT');
    } catch (e) {
      _db!.execute('ROLLBACK');
      _pendingTables.clear();
      _inTransaction = false;
      rethrow;
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

  Stream<List<Map<String, dynamic>>> watchQuery(
    String sql, [
    List<Object?> params = const [],
  ]) {
    _ensureOpen();
    return _watchQuery(sql, params);
  }

  Stream<List<Map<String, dynamic>>> _watchQuery(
    String sql,
    List<Object?> params,
  ) {
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
        sub = _notifier.changes
            .where((changed) => changed.any((t) => tables.contains(t)))
            .listen((_) => emit());
      },
      onCancel: () => sub?.cancel(),
    );

    return controller.stream;
  }

  void _runMigrations(List<Migration> migrations) {
    _db!.execute('''CREATE TABLE IF NOT EXISTS _meta_migrations (
      version INTEGER PRIMARY KEY,
      applied_at TEXT NOT NULL DEFAULT (datetime('now'))
    )''');

    final applied = _db!
        .select('SELECT version FROM _meta_migrations')
        .map((r) => r.columnAt(0) as int)
        .toSet();

    for (final m in migrations) {
      if (!applied.contains(m.version)) {
        _db!.execute(m.up);
        _db!.execute(
          'INSERT INTO _meta_migrations (version) VALUES (?)',
          [m.version],
        );
      }
    }
  }
}
