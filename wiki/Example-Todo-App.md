# Example: Todo App

**Directory:** `example/`

A complete Flutter todo-list app demonstrating all pulse\_db features. Context-separated architecture with 4 files.

## File map

```
example/
├── lib/
│   ├── main.dart                        — App entry point
│   └── todo/
│       ├── todo_model.dart              — Data model
│       ├── todo_database.dart           — Schema + repository
│       ├── todo_page.dart               — UI with PulseDbMixin
│       └── widgets/
│           ├── add_todo_dialog.dart     — Add dialog
│           └── todo_tile.dart           — List item tile
└── test/
    └── widget_test.dart                 — Widget tests
```

## `todo_model.dart` — Data model

A plain Dart class with `fromMap`/`toMap` for DB serialization:

```dart
class Todo {
  final int? id;
  final String title;
  final String note;
  final int priority;
  final bool done;
  final String? createdAt;

  Map<String, dynamic> toMap() => {
    'title': title,
    'note': note,
    'priority': priority,
    'done': done ? 1 : 0,          // bool → int for SQLite
  };

  factory Todo.fromMap(Map<String, dynamic> map) => Todo(
    id: map['id'] as int?,
    title: map['title'] as String,
    done: (map['done'] as int?) == 1,  // int → bool
    // ...
  );
}
```

Key detail: booleans are stored as 0/1 integers (SQLite has no native bool type).

## `todo_database.dart` — Schema + Repository

Two things are exported:

### The schema

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

### The typed repository

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

## `todo_page.dart` — UI

Uses `PulseDbMixin` with zero boilerplate:

```dart
class _TodoPageState extends State<TodoPage> with PulseDbMixin {
  late final _repo = TodoRepository(db);
  late final _todos = observe(_repo);
  var _filter = 'all';

  @override
  void initState() {
    super.initState();
    initDb(databaseName: 'todos.db', migrations: [
      Migration(version: 1, up: todoTable.createSql),
    ]);
  }
```

The `observe(_repo)` call wires up a `ValueNotifier` that:
1. Subscribes to `_repo.watch()` (a reactive stream that emits all todos on every change)
2. Calls `setState` automatically when todos change

The `_filtered` getter applies the current filter (all/active/done).

The `build()` method checks `dbReady` first to show a loading indicator, then accesses `_todos.value` for the data.

## `widgets/add_todo_dialog.dart`

Shows a dialog with title and note fields. Returns a new `Todo` or `null` if cancelled.

```dart
Future<Todo?> showAddTodoDialog(BuildContext context) async {
  // ... shows AlertDialog with TextFields
  // Returns Todo(title: ..., note: ...) or null
}
```

## `widgets/todo_tile.dart`

A `ListTile` with checkbox (toggle) and delete button.

```dart
TodoTile({
  required Todo todo,
  required void Function(bool) onToggle,
  required VoidCallback onDelete,
})
```

## Data flow in the app

```
User taps FAB
  → showAddTodoDialog()
  → _repo.insert(todo)
  → PulseDb.insert() → SQLite EXEC → TableNotifier fires
  → _todos.watch() emits new list
  → ValueNotifier.value = new list
  → setState() → build() re-renders

User checks a todo
  → _repo.toggle(id, done)
  → Same flow → UI updates

User adds todo → appears in list
  → watch stream emits all rows (not just changes)
  → UI shows "X pending" count based on full list
```
