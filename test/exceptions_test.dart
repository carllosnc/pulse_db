import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_db/pulse_db.dart';

void main() {
  late PulseDb db;

  setUp(() {
    db = PulseDb();
    db.open(path: ':memory:');
    db.execute('CREATE TABLE test (id INTEGER PRIMARY KEY, val TEXT UNIQUE)');
  });

  tearDown(() {
    if (db.isOpen) {
      db.close();
    }
  });

  test('PulseDbConstraintException is thrown on UNIQUE constraint violation', () {
    db.insert('test', {'id': 1, 'val': 'a'});
    expect(
      () => db.insert('test', {'id': 2, 'val': 'a'}),
      throwsA(isA<PulseDbConstraintException>()),
    );
  });

  test('PulseDbSchemaException is thrown when querying a non-existent table', () {
    expect(
      () => db.query('SELECT * FROM non_existent'),
      throwsA(isA<PulseDbSchemaException>()),
    );
  });

  test('PulseDbSchemaException is thrown when inserting into non-existent column', () {
    expect(
      () => db.insert('test', {'id': 3, 'val': 'c', 'missing_col': 1}),
      throwsA(isA<PulseDbSchemaException>()),
    );
  });

  test('PulseDbTransactionException is thrown on nested transactions', () {
    expect(
      () {
        db.transaction(() {
          db.transaction(() {});
        });
      },
      throwsA(isA<PulseDbTransactionException>()),
    );
  });

  test('PulseDbTransactionException is thrown when commit fails', () {
    expect(
      () {
        db.transaction(() {
          throw Exception('custom error');
        });
      },
      throwsA(isA<PulseDbTransactionException>()),
    );
  });

  test('transaction rethrows PulseDbException without wrapping', () {
    expect(
      () {
        db.transaction(() {
          db.insert('test', {'id': 1, 'val': 'a'});
          db.insert('test', {'id': 2, 'val': 'a'}); // Constraint exception
        });
      },
      throwsA(isA<PulseDbConstraintException>()),
    );
  });

  test('PulseDbClosedException is thrown when accessing closed db', () {
    db.close();
    expect(
      () => db.query('SELECT * FROM test'),
      throwsA(isA<PulseDbClosedException>()),
    );
    expect(
      () => db.execute('SELECT * FROM test'),
      throwsA(isA<PulseDbClosedException>()),
    );
  });
}
