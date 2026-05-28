# Lifecycle Mixin

**File:** `lib/src/client.dart`

`PulseDbMixin` eliminates all the boilerplate of setting up a database in a `StatefulWidget`:

- No `getApplicationDocumentsDirectory()` call
- No manual `StreamSubscription` management
- No `mounted` checks
- No separate `List<T>` state variable
- No `_init()` async method

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

`true` after `initDb()` has completed. Use in `build()` to show a loading indicator until the database is ready.

### `Future<void> initDb({String? path, String databaseName, List<Migration>? migrations})`

Opens the database. Two ways to specify the path:

```dart
// Automatic: resolves against getApplicationDocumentsDirectory()
initDb(databaseName: 'todos.db', migrations: [...]);

// Explicit: absolute path (skips path_provider)
initDb(path: '/custom/path/db.sqlite', migrations: [...]);
```

If neither `path` nor `databaseName` is given, defaults to `'default.db'` in the app documents directory.

After opening, sets `_dbReady = true` and calls `setState(() {})` to trigger a rebuild (if still mounted).

### `ValueNotifier<List<R>> observe<R>(Repository<R> repo)`

The key to zero-boilerplate reactivity:

```dart
late final _todos = observe(TodoRepository(db));
```

What `observe` does:
1. Creates a `ValueNotifier<List<R>>` initialized with `[]`.
2. Subscribes to `repo.watch()` — when watch emits new data, it sets `notifier.value = items`.
3. Adds a listener to the notifier that calls `setState(() {})` on every change — so the widget rebuilds automatically.
4. Stores the `StreamSubscription` in `_subs` for cleanup in `dispose()`.

Use the notifier in `build()`:

```dart
@override
Widget build(BuildContext context) {
  if (!dbReady) return const Center(child: CircularProgressIndicator());
  final todos = _todos.value;
  return ListView.builder(
    itemCount: todos.length,
    itemBuilder: (_, i) => Text(todos[i].title),
  );
}
```

> **Important:** Access `_todos.value` only after checking `dbReady`. The `late final` fields are lazily initialized — they're set when first accessed, which must happen after `initDb()` completes.

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

The full `todo_page.dart` at 89 lines:

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
      return Scaffold(
        appBar: AppBar(title: const Text('Todo List')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final todos = _todos.value;
    // ... render the list
  }
}
```

That's it. No `_init()`, no `getApplicationDocumentsDirectory`, no manual subscription, no `mounted` check, no `_todos` list variable.
