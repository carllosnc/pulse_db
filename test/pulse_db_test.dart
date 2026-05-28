import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_db/pulse_db.dart';

void main() {
  group('PulseDb', () {
    late PulseDb db;
    late String dbPath;

    setUp(() {
      dbPath = '${Directory.systemTemp.path}/pulse_db_test_${DateTime.now().millisecondsSinceEpoch}.db';
      db = PulseDb();
      db.open(dbPath);
      db.execute('CREATE TABLE IF NOT EXISTS test (id INTEGER PRIMARY KEY, name TEXT)');
    });

    tearDown(() {
      db.close();
      final f = File(dbPath);
      if (f.existsSync()) f.deleteSync();
    });

    test('insert and query', () {
      db.insert('test', {'name': 'Alice'});
      db.insert('test', {'name': 'Bob'});
      final rows = db.query('SELECT * FROM test ORDER BY id');
      expect(rows.length, 2);
      expect(rows[0]['name'], 'Alice');
      expect(rows[1]['name'], 'Bob');
    });

    test('update', () {
      db.insert('test', {'name': 'Alice'});
      db.update('test', {'name': 'Bob'}, 'id = ?', [1]);
      final rows = db.query('SELECT * FROM test WHERE id = 1');
      expect(rows[0]['name'], 'Bob');
    });

    test('delete', () {
      db.insert('test', {'name': 'Alice'});
      db.insert('test', {'name': 'Bob'});
      db.delete('test', 'id = ?', [1]);
      final rows = db.query('SELECT * FROM test');
      expect(rows.length, 1);
      expect(rows[0]['name'], 'Bob');
    });

    test('transaction commits changes', () {
      db.transaction(() {
        db.insert('test', {'name': 'Charlie'});
        db.insert('test', {'name': 'Diana'});
      });
      final rows = db.query('SELECT * FROM test ORDER BY id');
      expect(rows.length, 2);
    });

    test('transaction rolls back on error', () {
      expect(
        () => db.transaction(() {
          db.insert('test', {'name': 'Eve'});
          throw Exception('boom');
        }),
        throwsA(isA<Exception>()),
      );
      final rows = db.query('SELECT * FROM test');
      expect(rows.length, 0);
    });

    test('watch emits initial data and on change', () async {
      db.insert('test', {'name': 'Initial'});
      final stream = db.watch('test');
      final emitted = <List<Map<String, dynamic>>>[];

      final sub = stream.listen(emitted.add);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      db.insert('test', {'name': 'Added'});
      await Future<void>.delayed(const Duration(milliseconds: 100));

      await sub.cancel();
      expect(emitted.length, 2);
      expect(emitted[0].length, 1);
      expect(emitted[1].length, 2);
    });

    test('watchQuery emits on relevant table changes', () async {
      db.execute('CREATE TABLE IF NOT EXISTS related (id INTEGER PRIMARY KEY, val TEXT)');
      db.insert('test', {'name': 'A'});
      db.insert('related', {'val': 'X'});

      final stream = db.watchQuery('SELECT t.name, r.val FROM test t JOIN related r ON 1=1');
      final emitted = <List<Map<String, dynamic>>>[];

      final sub = stream.listen(emitted.add);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      db.insert('test', {'name': 'B'});
      await Future<void>.delayed(const Duration(milliseconds: 100));

      await sub.cancel();
      expect(emitted.length, 2);
      expect(emitted[1].length, 2);
    });

    test('migration applies pending migrations', () {
      db.close();
      File(dbPath).deleteSync();

      final db2 = PulseDb();
      db2.open(
        dbPath,
        migrations: [
          Migration(version: 1, up: 'CREATE TABLE users (id INTEGER PRIMARY KEY, email TEXT)'),
          Migration(version: 2, up: 'ALTER TABLE users ADD COLUMN name TEXT'),
        ],
      );

      db2.insert('users', {'email': 'a@b.com', 'name': 'Alice'});
      final row = db2.query('SELECT * FROM users').first;
      expect(row['email'], 'a@b.com');
      expect(row['name'], 'Alice');

      db2.close();
      File(dbPath).deleteSync();
    });

    test('closing and reopening is safe', () {
      db.insert('test', {'name': 'X'});
      db.close();
      expect(db.isOpen, false);
    });
  });
}

// Mock sqlite3 for testing web platforms
void Function()? testOnPlatform;
