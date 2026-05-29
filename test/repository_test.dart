import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_db/pulse_db.dart';

class _Item {
  final int? id;
  final String name;
  final double? price;

  const _Item({this.id, required this.name, this.price});

  Map<String, dynamic> toMap() => {
    'name': name,
    if (price != null) 'price': price,
  };

  static _Item fromMap(Map<String, dynamic> map) => _Item(
    id: map['id'] as int?,
    name: map['name'] as String,
    price: map['price'] as double?,
  );
}

final _itemsTable = TableDef('items', [
  integer('id').primaryKey().autoIncrement(),
  text('name').required(),
  real('price'),
]);

class _ItemRepository extends Repository<_Item> {
  _ItemRepository(super.db) : super(
    table: _itemsTable,
    fromRow: _Item.fromMap,
    toRow: (i) => i.toMap(),
  );
}

void main() {
  late PulseDb db;
  late _ItemRepository repo;
  late String dbPath;

  setUp(() {
    dbPath = '${Directory.systemTemp.path}/repo_test_${DateTime.now().millisecondsSinceEpoch}.db';
    db = PulseDb();
    db.open(path: dbPath);
    db.execute(_itemsTable.createSql);
    repo = _ItemRepository(db);
  });

  tearDown(() {
    db.close();
    final f = File(dbPath);
    if (f.existsSync()) f.deleteSync();
  });

  group('insert', () {
    test('insert returns row id', () {
      final id = repo.insert(const _Item(name: 'Alice'));
      expect(id, greaterThan(0));
    });

    test('insert persists data', () {
      repo.insert(const _Item(name: 'Bob'));
      final rows = db.query('SELECT * FROM items');
      expect(rows.length, 1);
      expect(rows[0]['name'], 'Bob');
    });
  });

  group('get', () {
    test('get returns item by id', () {
      final id = repo.insert(const _Item(name: 'Alice'));
      final item = repo.get(id);
      expect(item, isNotNull);
      expect(item!.name, 'Alice');
    });

    test('get returns null for non-existent id', () {
      final item = repo.get(999);
      expect(item, isNull);
    });
  });

  group('update', () {
    test('update modifies existing row', () {
      final id = repo.insert(const _Item(name: 'Alice'));
      repo.update({'name': 'Bob'}, where: 'id = ?', whereArgs: [id]);
      final item = repo.get(id);
      expect(item!.name, 'Bob');
    });

    test('update returns affected rows', () {
      final id = repo.insert(const _Item(name: 'Alice'));
      final affected = repo.update({'name': 'Bob'}, where: 'id = ?', whereArgs: [id]);
      expect(affected, 1);
    });

    test('update with non-existent id affects 0 rows', () {
      final affected = repo.update({'name': 'X'}, where: 'id = ?', whereArgs: [999]);
      expect(affected, 0);
    });
  });

  group('delete', () {
    test('delete removes row by id', () {
      final id = repo.insert(const _Item(name: 'Alice'));
      repo.delete(id);
      final item = repo.get(id);
      expect(item, isNull);
    });

    test('delete returns affected rows', () {
      final id = repo.insert(const _Item(name: 'Alice'));
      final affected = repo.delete(id);
      expect(affected, 1);
    });

    test('delete with non-existent id affects 0 rows', () {
      final affected = repo.delete(999);
      expect(affected, 0);
    });
  });

  group('deleteWhere', () {
    test('deleteWhere removes matching rows', () {
      repo.insert(const _Item(name: 'Alice'));
      repo.insert(const _Item(name: 'Bob'));
      repo.deleteWhere('name = ?', ['Alice']);
      final all = db.query('SELECT * FROM items');
      expect(all.length, 1);
      expect(all[0]['name'], 'Bob');
    });

    test('deleteWhere returns affected rows', () {
      repo.insert(const _Item(name: 'Alice'));
      final affected = repo.deleteWhere('name = ?', ['Alice']);
      expect(affected, 1);
    });
  });

  group('watch', () {
    test('watch emits initial data', () async {
      repo.insert(const _Item(name: 'Initial'));
      final emitted = <List<_Item>>[];

      final sub = repo.watch().listen(emitted.add);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await sub.cancel();
      expect(emitted.length, 1);
      expect(emitted[0].length, 1);
      expect(emitted[0][0].name, 'Initial');
    });

    test('watch emits on insert', () async {
      final emitted = <List<_Item>>[];

      final sub = repo.watch().listen(emitted.add);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      repo.insert(const _Item(name: 'Added'));
      await Future<void>.delayed(const Duration(milliseconds: 100));

      await sub.cancel();
      expect(emitted.length, 2);
      expect(emitted[1].length, 1);
      expect(emitted[1][0].name, 'Added');
    });

    test('watch emits on update', () async {
      repo.insert(const _Item(name: 'A'));
      final emitted = <List<_Item>>[];

      final sub = repo.watch().listen(emitted.add);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      repo.update({'name': 'B'}, where: 'id = ?', whereArgs: [1]);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      await sub.cancel();
      expect(emitted.last.length, 1);
      expect(emitted.last[0].name, 'B');
    });

    test('watch emits on delete', () async {
      repo.insert(const _Item(name: 'A'));
      final emitted = <List<_Item>>[];

      final sub = repo.watch().listen(emitted.add);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      repo.delete(1);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      await sub.cancel();
      expect(emitted.last.length, 0);
    });
  });

  group('watchWhere', () {
    test('watchWhere filters rows', () async {
      repo.insert(const _Item(name: 'Alice'));
      repo.insert(const _Item(name: 'Bob'));
      final emitted = <List<_Item>>[];

      final sub = repo.watchWhere('name = ?', ['Alice']).listen(emitted.add);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      repo.insert(const _Item(name: 'Charlie'));
      await Future<void>.delayed(const Duration(milliseconds: 100));

      await sub.cancel();
      expect(emitted.first.length, 1);
      expect(emitted.first[0].name, 'Alice');
    });
  });
}
