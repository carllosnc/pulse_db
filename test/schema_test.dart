import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_db/pulse_db.dart';

void main() {
  group('Col', () {
    test('integer() creates Col with integer type', () {
      final col = integer('id');
      expect(col.name, 'id');
      expect(col.type, ColumnType.integer);
      expect(col.isPrimaryKey, false);
      expect(col.isAutoIncrement, false);
      expect(col.isRequired, false);
      expect(col.defaultValue, isNull);
    });

    test('text() creates Col with text type', () {
      final col = text('name');
      expect(col.name, 'name');
      expect(col.type, ColumnType.text);
    });

    test('real() creates Col with real type', () {
      final col = real('price');
      expect(col.name, 'price');
      expect(col.type, ColumnType.real);
    });

    test('blob() creates Col with blob type', () {
      final col = blob('data');
      expect(col.name, 'data');
      expect(col.type, ColumnType.blob);
    });

    group('chainable modifiers', () {
      test('primaryKey() sets isPrimaryKey', () {
        final col = integer('id').primaryKey();
        expect(col.isPrimaryKey, true);
        expect(col.isAutoIncrement, false);
      });

      test('autoIncrement() sets isAutoIncrement', () {
        final col = integer('id').autoIncrement();
        expect(col.isAutoIncrement, true);
      });

      test('required() sets isRequired', () {
        final col = text('name').required();
        expect(col.isRequired, true);
      });

      test('defaultTo() sets defaultValue', () {
        final col = text('status').defaultTo("'active'");
        expect(col.defaultValue, "'active'");
      });

      test('multiple chained modifiers', () {
        final col = integer('id').primaryKey().autoIncrement();
        expect(col.isPrimaryKey, true);
        expect(col.isAutoIncrement, true);
        expect(col.type, ColumnType.integer);
      });
    });

    group('definition SQL', () {
      test('simple integer column', () {
        expect(integer('id').definition, 'id INTEGER');
      });

      test('integer primary key', () {
        expect(integer('id').primaryKey().definition, 'id INTEGER PRIMARY KEY');
      });

      test('integer primary key autoincrement', () {
        expect(
          integer('id').primaryKey().autoIncrement().definition,
          'id INTEGER PRIMARY KEY AUTOINCREMENT',
        );
      });

      test('text required', () {
        expect(text('name').required().definition, 'name TEXT NOT NULL');
      });

    test('text with default', () {
      expect(
        text('status').defaultTo("'active'").definition,
        "status TEXT DEFAULT 'active'",
      );
    });

    test('text with empty string default', () {
      expect(
        text('note').defaultTo("''").definition,
        "note TEXT DEFAULT ''",
      );
    });

      test('full column: integer primary key autoincrement', () {
        final col = integer('id').primaryKey().autoIncrement();
        expect(col.definition, 'id INTEGER PRIMARY KEY AUTOINCREMENT');
      });

      test('full column: text required with default', () {
        final col = text('role').required().defaultTo("'user'");
        expect(col.definition, "role TEXT NOT NULL DEFAULT 'user'");
      });
    });
  });

  group('Table', () {
    test('createSql generates CREATE TABLE', () {
      final t = Table('users', [
        integer('id').primaryKey().autoIncrement(),
        text('name').required(),
        text('email'),
      ]);

      expect(
        t.createSql,
        'CREATE TABLE "users" (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, email TEXT)',
      );
    });

    test('pkName returns primary key column', () {
      final t = Table('users', [
        integer('id').primaryKey(),
        text('name'),
      ]);
      expect(t.pkName, 'id');
    });

    test('pkName defaults to "id" when no primary key', () {
      final t = Table('items', [
        text('name'),
      ]);
      expect(t.pkName, 'id');
    });

    test('multiple columns with various modifiers', () {
      final t = Table('todos', [
        integer('id').primaryKey().autoIncrement(),
        text('title').required(),
        text('note').defaultTo("''"),
        integer('priority').defaultTo('0'),
        integer('done').defaultTo('0'),
        text('created_at').defaultTo("datetime('now')"),
      ]);

      expect(
        t.createSql,
        'CREATE TABLE "todos" ('
        'id INTEGER PRIMARY KEY AUTOINCREMENT, '
        'title TEXT NOT NULL, '
        'note TEXT DEFAULT \'\', '
        'priority INTEGER DEFAULT 0, '
        'done INTEGER DEFAULT 0, '
        'created_at TEXT DEFAULT datetime(\'now\')'
        ')',
      );
    });

    test('real column type', () {
      final t = Table('products', [
        text('name'),
        real('price'),
      ]);
      expect(t.createSql, contains('price REAL'));
    });

    test('blob column type', () {
      final t = Table('files', [
        text('name'),
        blob('data'),
      ]);
      expect(t.createSql, contains('data BLOB'));
    });
  });
}
