# PULSE DB

[![CI](https://github.com/carllosnc/pulse_db/actions/workflows/ci.yml/badge.svg)](https://github.com/carllosnc/pulse_db/actions/workflows/ci.yml)
[![Flutter](https://img.shields.io/badge/Flutter-%5E3.12.0-blue?logo=flutter)](https://flutter.dev)
[![Status](https://img.shields.io/badge/status-alpha-yellow)](BACKLOG.md)

Lightweight SQLite wrapper for Flutter with reactive queries and a type-safe schema builder.

See [BACKLOG.md](BACKLOG.md) for full details on planned features and development roadmap.

## Backlog
- [x] 1. Typed error handling
- [ ] 2. Async query offloading
- [ ] 3. Watch pagination & streaming
- [ ] 4. Bulk operations
- [ ] 5. Migration improvements
- [ ] 6. dartdoc on all public APIs
- [ ] 7. ObservableList tests
- [ ] 8. Stress & large-dataset tests
- [ ] 9. Error recovery in mixin
- [ ] 10. Concurrent access guard
- [ ] 11. Split Flutter vs Dart core
- [ ] 12. pub.dev release checklist

## Features

- **Reactive streams** — `watch(table)` and `watchQuery(sql)` emit fresh results on every insert/update/delete
- **Type-safe schema** — `TableDef`, `Col`, and helpers like `integer()`, `text()`, `real()`, `blob()` with chainable modifiers (`primaryKey()`, `required()`, `defaultTo()`, `autoIncrement()`)
- **Typed repository** — `Repository<T>` base class with `insert`, `get`, `update`, `delete`, `deleteWhere`, `watch`, `watchWhere`; plus `MapRepository` for map-based usage with no model class
- **Lifecycle mixin** — `PulseDbMixin` with `initDb`, `observe()`, `autoObserve()`, and auto-dispose. `ObservableList` provides `.isLoading`, `.isEmpty`, `.repo` — no `dbReady` checks needed
- **Auto schema sync** — pass `tables:` to `open()` — auto-creates tables and adds new columns on schema changes. No manual migrations for table changes
- **Migrations** — versioned `Migration` list for data migrations; `Migration.table()` shorthand from `TableDef` schemas
- **No native setup** — backed by `sqlite3` v3 which bundles the native library via Dart hooks

## Getting started

Add the dependency:

```yaml
dependencies:
  pulse_db: ^0.0.1
```

No platform-specific configuration needed — `sqlite3` v3 handles native library bundling automatically.

## Usage

### Schema definition

```dart
final todoTable = TableDef('todos', [
  integer('id').primaryKey().autoIncrement(),
  text('title').required(),
  text('note').defaultTo("''"),
  integer('priority').defaultTo('0'),
  integer('done').defaultTo('0'),
  text('created_at').defaultTo("(datetime('now'))"),
]);
```

### Typed repository

No subclass needed — create `Repository<T>` directly:

```dart
final repo = Repository<Todo>(db, table: todoTable,
  fromRow: Todo.fromMap,
  toRow: (t) => t.toMap(),
);

repo.watch();              // Stream<List<Todo>>
repo.insert(todo);         // returns row id
repo.get(1);               // Todo?
repo.update({'done': 1}, where: 'id = ?', whereArgs: [1]);
repo.delete(1);
```

Or use `MapRepository` to skip the model class entirely:

```dart
final repo = MapRepository(db, todoTable);
repo.insert({'title': 'Learn', 'done': 0});
repo.watch();  // Stream<List<Map<String, dynamic>>>
```

#### With domain methods (optional)

Extend `Repository<T>` only when you need custom queries or domain logic:

```dart
class TodoRepository extends Repository<Todo> {
  TodoRepository(PulseDb db) : super(db, table: todoTable,
    fromRow: Todo.fromMap, toRow: (t) => t.toMap());

  Stream<List<Todo>> watchActive() => watchWhere('done = 0');
  void toggle(int id, bool done) =>
      update({'done': done ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  void remove(int id) => delete(id);
}
```

### Using PulseDbMixin in a StatefulWidget

```dart
class _TodoPageState extends State<TodoPage> with PulseDbMixin {
  late final _todos = observe(Repository<Todo>(
    db, table: todoTable,
    fromRow: Todo.fromMap,
    toRow: (t) => t.toMap(),
  ));

  @override
  void initState() {
    super.initState();
    initDb(databaseName: 'todos.db', tables: [todoTable]);
  }

  @override
  Widget build(BuildContext context) {
    if (_todos.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_todos.isEmpty) return const Text('No items');
    final todos = _todos.value;
    // ... render list
  }
}
```

`observe()` returns an `ObservableList<R>` — a `ValueNotifier` subclass with `.isLoading`, `.isEmpty`, and `.repo` for insert/update/delete. It defers the watch subscription until the DB is ready, so `isLoading` stays `true` until the first data arrives.

For cases where the repository depends on `PulseDb` (which isn't ready yet at field init), use `autoObserve()` which defers creation:

```dart
late final _todos = autoObserve((db) => Repository<Todo>(db,
    table: todoTable, fromRow: Todo.fromMap, toRow: (t) => t.toMap()));
```

### Map-based repository (no model class)

Skip the model class entirely with `MapRepository` — works directly with `Map<String, dynamic>`:

```dart
final repo = db.repository(todoTable);
// or: MapRepository(db, todoTable)

repo.insert({'title': 'Learn pulse_db', 'done': 0});
repo.watch().listen(print); // Stream<List<Map<String, dynamic>>>
repo.get(1);  // Map<String, dynamic>?
repo.delete(1);
```

### Auto schema sync

Pass `tables:` to `open()` — tables are auto-created, and new columns are added automatically when the `TableDef` changes:

```dart
final db = PulseDb();
db.open(path: 'app.db', tables: [todoTable]);
// First run: CREATE TABLE
// After adding a column to todoTable: ALTER TABLE ADD COLUMN
```

No manual `Migration` tracking needed for schema evolution. Old migrations are still supported for data transformations.

### Async opening

For convenience, `PulseDb.openAsync()` handles path resolution automatically:

```dart
final db = await PulseDb.openAsync(
  databaseName: 'app.db',
  tables: [todoTable],
);
```

### Low-level API

```dart
final db = PulseDb();
db.open('path/to/db.db');

final id = db.insert('users', {'name': 'Alice'});
db.update('users', {'name': 'Bob'}, 'id = ?', [id]);
final rows = db.query('SELECT * FROM users');
db.delete('users', 'id = ?', [id]);

db.transaction(() {
  db.insert('users', {'name': 'Charlie'});
});

final stream = db.watch('users'); // reactive
db.close();
```

## Additional information

- See the `/example` directory for a complete todo-list app
- File issues at [github.com/carllosnc/pulse_db](https://github.com/carllosnc/pulse_db)
- Pull requests welcome

---
Carlos Costa @ 2026