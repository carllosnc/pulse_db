# PULSE DB

Lightweight SQLite wrapper for Flutter with reactive queries and a type-safe schema builder.

## Features

- **Reactive streams** — `watch(table)` and `watchQuery(sql)` emit fresh results on every insert/update/delete
- **Type-safe schema** — `Table`, `Col`, and helpers like `integer()`, `text()`, `real()`, `blob()` with chainable modifiers (`primaryKey()`, `required()`, `defaultTo()`, `autoIncrement()`)
- **Typed repository** — `Repository<T>` base class with `insert`, `get`, `update`, `delete`, `deleteWhere`, `watch`, `watchWhere`
- **Lifecycle mixin** — `PulseDbMixin` with `initDb`, `observe()`, and auto-dispose. No manual subscriptions or `mounted` checks
- **Migrations** — versioned `Migration` list applied automatically
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
final todoTable = Table('todos', [
  integer('id').primaryKey().autoIncrement(),
  text('title').required(),
  text('note').defaultTo("''"),
  integer('priority').defaultTo('0'),
  integer('done').defaultTo('0'),
  text('created_at').defaultTo("(datetime('now'))"),
]);
```

### Typed repository

```dart
class Todo {
  final int? id;
  final String title;
  final String note;
  final int priority;
  final bool done;
  final String? createdAt;

  const Todo({this.id, required this.title, this.note = '', this.priority = 0, this.done = false, this.createdAt});

  Map<String, dynamic> toMap() => {
    'title': title,
    'note': note,
    'priority': priority,
    'done': done ? 1 : 0,
  };

  static Todo fromMap(Map<String, dynamic> map) => Todo(
    id: map['id'] as int?,
    title: map['title'] as String,
    note: map['note'] as String? ?? '',
    priority: map['priority'] as int? ?? 0,
    done: (map['done'] as int?) == 1,
    createdAt: map['created_at'] as String?,
  );
}

class TodoRepository extends Repository<Todo> {
  TodoRepository(PulseDb db) : super(
    db,
    table: todoTable,
    fromRow: Todo.fromMap,
    toRow: (t) => t.toMap(),
  );

  Stream<List<Todo>> watchActive() => watchWhere('done = 0');
  void toggle(int id, bool done) =>
      update({'done': done ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  void remove(int id) => delete(id);
}
```

### Using PulseDbMixin in a StatefulWidget

```dart
class _TodoPageState extends State<TodoPage> with PulseDbMixin {
  late final _repo = TodoRepository(db);
  late final _todos = observe(_repo);
  var _filter = 'all';

  @override
  void initState() {
    super.initState();
    initDb(
      databaseName: 'todos.db',
      migrations: [Migration(version: 1, up: todoTable.createSql)],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!dbReady) {
      return const Center(child: CircularProgressIndicator());
    }
    final todos = _todos.value;
    // ... render list
  }
}
```

`observe()` auto-subscribes to the repository's watch stream and triggers `setState` on every change — no manual `StreamSubscription`, no `mounted` checks. The `databaseName` parameter resolves the path against `getApplicationDocumentsDirectory()` automatically (uses `path_provider` internally).

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
- File issues at [github.com/anomalyco/pulse_db](https://github.com/anomalyco/pulse_db)
- Pull requests welcome

---
Carlos Costa @ 2026