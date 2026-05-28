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

## The `Table` class

```dart
class Table {
  final String name;
  final List<Col> columns;
}
```

### `createSql` getter

Generates the full `CREATE TABLE` statement:

```dart
final todoTable = Table('todos', [
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
