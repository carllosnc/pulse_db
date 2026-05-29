import '../pulse_db.dart';

class Repository<T> {
  final PulseDb _db;
  final TableDef table;
  final T Function(Map<String, dynamic>) fromRow;
  final Map<String, dynamic> Function(T) toRow;

  Repository(
    this._db, {
    required this.table,
    required this.fromRow,
    required this.toRow,
  });

  Stream<List<T>> watch() =>
    _db.watch(table.name).map((rows) => rows.map(fromRow).toList());

  Stream<List<T>> watchWhere(String where, [List<Object?> args = const []]) =>
    _db.watchQuery('SELECT * FROM "${table.name}" WHERE $where', args)
        .map((rows) => rows.map(fromRow).toList());

  int insert(T value) => _db.insert(table.name, toRow(value));

  int update(
    Map<String, dynamic> values, {
    required String where,
    List<Object?> whereArgs = const [],
  }  ) => _db.update(table.name, values, where, whereArgs);

  int delete(dynamic id) =>
    _db.delete(table.name, '${table.pkName} = ?', [id]);

  int deleteWhere(String where, [List<Object?> whereArgs = const []]) =>
    _db.delete(table.name, where, whereArgs);

  T? get(dynamic id) {
    final rows = _db.query(
      'SELECT * FROM "${table.name}" WHERE ${table.pkName} = ?', [id],
    );
    return rows.isEmpty ? null : fromRow(rows.first);
  }
}

class MapRepository extends Repository<Map<String, dynamic>> {
  // ignore: use_super_parameters
  MapRepository(PulseDb db, TableDef table) : super(
    db,
    table: table,
    fromRow: (m) => m,
    toRow: (m) => m,
  );
}

extension PulseDbRepo on PulseDb {
  MapRepository repository(TableDef table) => MapRepository(this, table);
}
