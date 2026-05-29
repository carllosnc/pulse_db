# Repository Pattern

**File:** `lib/src/repository.dart`

`Repository<T>` provides typed CRUD and reactive streams for a single table. It bridges the raw `Map<String, dynamic>` world of `PulseDb` and your domain models.

## Constructor

```dart
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
}
```

| Parameter | Purpose |
|-----------|---------|
| `_db` | The `PulseDb` instance (private) |
| `table` | The `TableDef` schema — used for table name and primary key name |
| `fromRow` | Convert a DB row map to your model |
| `toRow` | Convert your model to a DB row map |

## Methods

### `insert(T value) → int`

Calls `_db.insert(table.name, toRow(value))`. Returns the new row ID.

### `get(dynamic id) → T?`

```dart
T? get(dynamic id) {
  final rows = _db.query(
    'SELECT * FROM "${table.name}" WHERE ${table.pkName} = ?', [id],
  );
  return rows.isEmpty ? null : fromRow(rows.first);
}
```

Looks up a single row by primary key.

### `update(Map values, {required String where, List whereArgs}) → int`

Calls `_db.update(table.name, values, where, whereArgs)`. Returns affected rows.

### `delete(dynamic id) → int`

```dart
int delete(dynamic id) =>
  _db.delete(table.name, '${table.pkName} = ?', [id]);
```

Deletes by primary key. Returns affected rows.

### `deleteWhere(String where, [List whereArgs]) → int`

Calls `_db.delete(table.name, where, whereArgs)`. Returns affected rows.

### `watch() → Stream<List<T>>`

```dart
Stream<List<T>> watch() =>
  _db.watch(table.name).map((rows) => rows.map(fromRow).toList());
```

Reactive stream that emits the full table contents on every change.

### `watchWhere(String where, [List args]) → Stream<List<T>>`

```dart
Stream<List<T>> watchWhere(String where, [List<Object?> args = const []]) =>
  _db.watchQuery('SELECT * FROM "${table.name}" WHERE $where', args)
      .map((rows) => rows.map(fromRow).toList());
```

Filtered reactive stream, e.g. `watchWhere('done = 0')`.

## Example subclass

```dart
class TodoRepository extends Repository<Todo> {
  TodoRepository(PulseDb db) : super(
    db,
    table: todoTable,
    fromRow: Todo.fromMap,
    toRow: (t) => t.toMap(),
  );

  Stream<List<Todo>> watchActive() => watchWhere('done = 0');
  Stream<List<Todo>> watchDone() => watchWhere('done = 1');
  void toggle(int id, bool done) =>
      update({'done': done ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  void remove(int id) => delete(id);
}
```

## Important: no `super` params

You might wonder why `Repository` doesn't use Dart 3 super parameters to auto-forward `fromRow`/`toRow`:

```dart
// ❌ This won't compile for factory constructors
class TodoRepository extends Repository<Todo> {
  TodoRepository(super.db) : super(  // super.params can't be used for positional
```

The `Repository` constructor takes `this._db` as a positional parameter and named `fromRow`/`toRow`. Subclasses must pass them explicitly because factory constructors aren't `const` and `super` params with initializers don't apply here.

---

## MapRepository — no model class

For quick scripts or when you don't want to define a model class, use `MapRepository` which works directly with `Map<String, dynamic>`:

```dart
final repo = MapRepository(db, todoTable);
// or via extension: db.repository(todoTable)

final id = repo.insert({'title': 'Learn', 'done': 0});
final row = repo.get(id);     // Map<String, dynamic>?
final all = repo.watch();     // Stream<List<Map<String, dynamic>>>
repo.delete(id);
```

`MapRepository` extends `Repository<Map<String, dynamic>>` with passthrough `fromRow`/`toRow` that return the map as-is. All CRUD and reactive methods work the same way.
