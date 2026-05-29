# Example: Todo App

**Directory:** `example/`

A complete Flutter todo-list app demonstrating pulse\_db features alongside Notes (typed model) and Counters (`MapRepository`).

## File map

```
example/
├── lib/
│   ├── main.dart                        — App entry point
│   ├── home_page.dart                   — Example list with navigation
│   ├── todo/
│   │   ├── todo_model.dart              — Data model
│   │   ├── todo_database.dart           — Schema + repo factory
│   │   ├── todo_page.dart               — UI with PulseDbMixin
│   │   └── widgets/
│   ├── notes/                           — Same structure as todo/
│   └── counter/                         — MapRepository, no model class
└── test/
    └── widget_test.dart                 — Tests for home + all 3 examples
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

## `todo_database.dart` — Schema + repo factory

### The schema

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

### The repo factory (not a subclass)

```dart
Repository<Todo> todoRepo(PulseDb db) =>
    Repository<Todo>(db, table: todoTable, fromRow: Todo.fromMap, toRow: (t) => t.toMap());
```

No `TodoRepository` subclass required — a top-level function is enough.

## `todo_page.dart` — UI

Uses `PulseDbMixin` with a single field (no separate `_repo`):

```dart
class _TodoPageState extends State<TodoPage> with PulseDbMixin {
  late final _todos = observe(todoRepo(db));
  var _filter = 'all';

  @override
  void initState() {
    super.initState();
    initDb(databaseName: 'todos.db', tables: [todoTable]);
  }
```

`observe()` returns an `ObservableList<Todo>`:
- `.isLoading` — `true` until data arrives (replaces `dbReady`)
- `.isEmpty` — `true` only when loaded and empty
- `.repo` — the `Repository<Todo>` for write operations

```dart
@override
Widget build(BuildContext context) {
  if (_todos.isLoading) return const CircularProgressIndicator();
  if (_todos.isEmpty) return const Text('No todos yet');
  // ... render list
}
```

Writes go through the embedded repo:

```dart
_todos.repo!.insert(todo);
_todos.repo!.update({'done': 1}, where: 'id = ?', whereArgs: [id]);
_todos.repo!.delete(id);
```

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
  → _todos.repo!.insert(todo)
  → PulseDb.insert() → SQLite EXEC → TableNotifier fires
  → ObservableList.value = new list
  → setState() → build() re-renders

User checks a todo
  → _todos.repo!.update(...)
  → Same flow → UI updates
```
