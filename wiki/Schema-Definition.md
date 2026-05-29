# Schema Definition

**File:** `lib/src/schema.dart`

Provides a type-safe way to define database schemas using Dart code instead of raw SQL strings.

## Column types

```dart
enum ColumnType { integer, text, real, blob }
```

Four helper functions create columns of each type:

```dart
integer('id')   // Col(name: 'id', type: ColumnType.integer)
text('name')    // Col(name: 'name', type: ColumnType.text)
real('price')   // Col(name: 'price', type: ColumnType.real)
blob('photo')   // Col(name: 'photo', type: ColumnType.blob)
```

## The `Col` class

```dart
class Col {
  final String name;
  final ColumnType type;
  final bool isPrimaryKey;
  final bool isAutoIncrement;
  final bool isRequired;        // → NOT NULL
  final String? defaultValue;   // → DEFAULT <raw SQL value>
}
```

### `definition` getter

Produces a column definition SQL string. Examples:

| Col | Output |
|-----|--------|
| `integer('id').primaryKey().autoIncrement()` | `id INTEGER PRIMARY KEY AUTOINCREMENT` |
| `text('name').required()` | `name TEXT NOT NULL` |
| `text('note').defaultTo("''")` | `note TEXT DEFAULT ''` |
| `text('ts').defaultTo("(datetime('now'))")` | `ts TEXT DEFAULT (datetime('now'))` |

### Chainable modifiers

The `ColMod` extension adds modifier methods that return **new** `Col` instances (immutable):

| Method | Effect |
|--------|--------|
| `.primaryKey()` | Sets `isPrimaryKey = true` |
| `.autoIncrement()` | Sets `isAutoIncrement = true` |
| `.required()` | Sets `isRequired = true` → adds `NOT NULL` |
| `.defaultTo(value)` | Sets `defaultValue` → adds `DEFAULT <value>` |

Modifiers can be chained in any order:

```dart
integer('id').primaryKey().autoIncrement()
text('email').required()
integer('count').defaultTo('0')
```

### Important: `defaultTo` takes raw SQL

The `defaultTo` parameter is inserted verbatim after `DEFAULT`. This means:

| What you write | SQL produced | Use case |
|---|---|---|
| `defaultTo('0')` | `DEFAULT 0` | Numeric literal |
| `defaultTo("''")` | `DEFAULT ''` | Empty string literal |
| `defaultTo("'active'")` | `DEFAULT 'active'` | String literal |
| `defaultTo("(datetime('now'))")` | `DEFAULT (datetime('now'))` | Expression (needs parentheses!) |

SQLite requires parentheses around expression defaults. For a function call like `datetime('now')`, write `defaultTo("(datetime('now'))")`.

## The `TableDef` class

```dart
class TableDef {
  final String name;
  final List<Col> columns;
}

const TableDef(this.name, this.columns);
```

### `createSql` getter

Generates the full `CREATE TABLE` statement:

```dart
final todoTable = TableDef('todos', [
  integer('id').primaryKey().autoIncrement(),
  text('title').required(),
  text('note').defaultTo("''"),
  integer('priority').defaultTo('0'),
  integer('done').defaultTo('0'),
  text('created_at').defaultTo("(datetime('now'))"),
]);

print(todoTable.createSql);
// CREATE TABLE "todos" (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL,
//   note TEXT DEFAULT '', priority INTEGER DEFAULT 0, done INTEGER DEFAULT 0,
//   created_at TEXT DEFAULT (datetime('now')))
```

### `pkName` getter

Returns the name of the primary key column (the first column with `isPrimaryKey: true`). Falls back to `'id'` if no primary key is defined.

Used by `Repository.delete()` to build `WHERE <pk> = ?`.

## Auto schema sync

Pass `TableDef` objects to `PulseDb.open()` or `PulseDbMixin.initDb()` via the `tables:` parameter:

```dart
db.open(path: 'app.db', tables: [todoTable]);
```

- **First run** — creates all tables.
- **Schema changes** — when columns are added to a `TableDef`, the library detects the drift via `PRAGMA table_info` and runs `ALTER TABLE ADD COLUMN` automatically.
- **Tracking** — column hashes are stored in `_meta_schema` so unchanged tables are skipped.

This replaces manual `CREATE TABLE` migrations for schema evolution. Data migrations (rename columns, transform data) still use the `migrations:` parameter.
