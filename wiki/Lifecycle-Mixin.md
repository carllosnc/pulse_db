# Lifecycle Mixin

**File:** `lib/src/client.dart`

`PulseDbMixin` eliminates all the boilerplate of setting up a database in a `StatefulWidget`:

- No `getApplicationDocumentsDirectory()` call
- No manual `StreamSubscription` management
- No `mounted` checks
- No separate `List<T>` state variable
- No `_init()` async method
- No `dbReady` checks

## Adding the mixin

```dart
class _TodoPageState extends State<TodoPage> with PulseDbMixin {
  // ...
}
```

## Properties and methods

### `PulseDb get db`

The underlying `PulseDb` instance. Created lazily by `initDb()`. Read-only.

### `bool get dbReady`

`true` after `initDb()` has completed. Prefer `ObservableList.isLoading` instead — the mixin defers watch subscriptions to the next frame, so `isLoading` stays `true` until data arrives.

### `Future<void> initDb({String? path, String databaseName, List<Migration>? migrations, List<TableDef>? tables})`

Opens the database. Two ways to specify the path:

```dart
// Automatic: resolves against getApplicationDocumentsDirectory()
initDb(databaseName: 'todos.db', tables: [todoTable]);

// Explicit: absolute path (skips path_provider)
initDb(path: '/custom/path/db.sqlite', tables: [todoTable]);
```

If neither `path` nor `databaseName` is given, defaults to `'default.db'` in the app documents directory.

The `tables:` parameter auto-creates tables and adds new columns on schema changes — no manual migrations needed for table evolution. For data migrations, use `migrations:` alongside `tables:`.

After opening, defers `_dbReady`, flushing pending subscriptions, and `setState` to a post-frame callback — ensuring the loading state always renders for at least one frame.

### `ObservableList<R> autoObserve<R>(Repository<R> Function(PulseDb db) factory)`

Creates an `ObservableList` but defers repository creation until the database is ready:

```dart
late final _todos = autoObserve((db) => Repository<Todo>(db, table: todoTable, fromRow: Todo.fromMap, toRow: (t) => t.toMap()));
```

If `initDb()` or `use()` hasn't completed yet, the factory is queued and automatically connected once the database is available.

### `ObservableList<R> observe<R>(Repository<R> repo)`

The key to zero-boilerplate reactivity:

```dart
late final _todos = observe(Repository<Todo>(db, table: todoTable, fromRow: Todo.fromMap, toRow: (t) => t.toMap()));
```

What `observe` does:
1. Creates an `ObservableList<R>` initialized with `[]` and `isLoading = true`.
2. If the DB is ready, subscribes to `repo.watch()` immediately. If not, queues the subscription — it fires automatically after `initDb()` completes.
3. When watch emits new data, sets `list.value = items`, which marks `isLoading = false` and calls `setState(() {})`.
4. Stores the `StreamSubscription` in `_subs` for cleanup in `dispose()`.

The `ObservableList` provides:

| Property | Returns | Behaviour |
|----------|---------|-----------|
| `.value` | `List<R>` | Current data (empty `[]` until first emission) |
| `.isLoading` | `bool` | `true` until first data arrives |
| `.isEmpty` | `bool` | `true` only when loaded AND list is empty (safe — `false` while loading) |
| `.repo` | `Repository<R>?` | The underlying repository, or `null` before DB ready |

Use in `build()` with no `dbReady` check:

```dart
@override
Widget build(BuildContext context) {
  if (_todos.isLoading) return const Center(child: CircularProgressIndicator());
  if (_todos.isEmpty) return const Text('No items');
  final todos = _todos.value;
  return ListView.builder(
    itemCount: todos.length,
    itemBuilder: (_, i) => Text(todos[i].title),
  );
}
```

For writes, use the embedded repo:

```dart
_todos.repo!.insert(todo);
_todos.repo!.update({'done': 1}, where: 'id = ?', whereArgs: [id]);
_todos.repo!.delete(id);
```

### Automatic dispose

```dart
@override
void dispose() {
  for (final s in _subs) s.cancel();  // cancel all watch subscriptions
  _db.close();                         // close the database
  super.dispose();
}
```

No manual cleanup needed in your widget.

## Complete example

The full `todo_page.dart` at ~88 lines, with no `_repo` field and no `dbReady`:

```dart
class _TodoPageState extends State<TodoPage> with PulseDbMixin {
  late final _todos = observe(todoRepo(db));

  @override
  void initState() {
    super.initState();
    initDb(databaseName: 'todos.db', tables: [todoTable]);
  }

  @override
  Widget build(BuildContext context) {
    if (_todos.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Todo List')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_todos.isEmpty) return const Center(child: Text('No todos'));
    // ... render the list
  }
}
```

No `_init()`, no `getApplicationDocumentsDirectory`, no manual subscription, no `mounted` check, no `_todos` list variable, no `_repo` field, no `dbReady` check.
