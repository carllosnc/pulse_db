# Testing Guide

**Directories:** `test/` (package) and `example/test/` (example)

## Test files

| File | Tests | Count |
|------|-------|-------|
| `test/schema_test.dart` | `Col` creation, modifiers, `definition` SQL, `TableDef.createSql`, `pkName` | 23 |
| `test/repository_test.dart` | `Repository` CRUD, `watch`, `watchWhere` | 16 |
| `test/pulse_db_test.dart` | `PulseDb` core + edge cases | 20 |
| `example/test/widget_test.dart` | Widget integration | 2 |
| **Total** | | **61** |

## `schema_test.dart`

Tests every `Col` factory, every modifier, `definition` output, `TableDef.createSql`, and `pkName`.

### Key patterns

**Testing `definition` output:**

```dart
test('integer primary key autoincrement', () {
  final col = integer('id').primaryKey().autoIncrement();
  expect(col.definition, 'id INTEGER PRIMARY KEY AUTOINCREMENT');
});
```

**Testing chainable modifiers:**

```dart
test('multiple chained modifiers', () {
  final col = text('email').required().defaultTo("'x@y.com'");
  expect(col.definition, "name TEXT NOT NULL DEFAULT 'x@y.com'");
});
```

**Testing `pkName` fallback:**

```dart
test('defaults to "id" when no primary key', () {
  final t = TableDef('t', [text('name')]);
  expect(t.pkName, 'id');
});
```

## `repository_test.dart`

Uses an `_Item` model with `id`, `name`, and optional `price`. The `_Item.toMap()` conditionally includes `price` only when non-null — this tests that repositories correctly handle partial data.

### Key patterns

**Testing watch emits initial data:**

```dart
test('watch emits initial data', () async {
  repo.insert(_Item(name: 'A'));
  final emitted = <List<_Item>>[];
  repo.watch().listen(emitted.add);
  await Future<void>.delayed(const Duration(milliseconds: 10));
  expect(emitted.length, 1);
  expect(emitted[0].length, 1);
});
```

Watch streams are async — the initial emission happens in a microtask after subscription, hence the `delayed`.

**Testing watch emits on changes:**

```dart
test('watch emits on insert', () async {
  final emitted = <List<_Item>>[];
  repo.watch().listen(emitted.add);
  await Future<void>.delayed(const Duration(milliseconds: 10));

  repo.insert(_Item(name: 'A'));
  await Future<void>.delayed(const Duration(milliseconds: 100));

  expect(emitted.length, 2);
});
```

The first emission is the initial empty result. The second is triggered by the insert.

## `pulse_db_test.dart`

Tests the core `PulseDb` class directly. Each test creates a fresh `.db` file in `Directory.systemTemp`, runs tests, then closes and deletes it.

### Edge cases covered

| Test | What it verifies |
|------|------------------|
| `insert returns correct row id` | `lastInsertRowId` is accurate |
| `update returns affected row count` | `updatedRows` for matched rows |
| `update with no match returns 0` | Returns 0 when `WHERE` matches nothing |
| `delete returns affected row count` | `updatedRows` for matched rows |
| `delete with no match returns 0` | Returns 0 when `WHERE` matches nothing |
| `nested transaction throws StateError` | `transaction()` inside `transaction()` |
| `operations throw after close` | `query/execute/insert/update/delete` after `close()` |
| `watch on empty table emits empty list` | Initial emission is `[]` |
| `multiple watch subscribers` | Two listeners both receive all updates |
| `watchQuery with params` | Parameterized reactive queries work |

### Testing watch after close

```dart
test('watch on empty table emits empty list', () async {
  final emitted = <List<Map<String, dynamic>>>[];
  final sub = db.watch('test').listen(emitted.add);
  await Future<void>.delayed(const Duration(milliseconds: 10));
  await sub.cancel();
  expect(emitted.length, 1);
  expect(emitted[0], isEmpty);
});
```

## `example/test/widget_test.dart`

Widget integration tests using `WidgetTester`. Since `PulseDbMixin.initDb` uses `path_provider` internally, the test must mock the method channel:

```dart
setUp(() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (MethodCall methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return Directory.systemTemp.path;
      }
      return null;
    },
  );
});
```

### Tests

1. **Todo app renders** — Verifies the app builds without errors.
2. **loading then empty state** — Pump the widget, verify `CircularProgressIndicator` shows initially, then after pump delays verify "No todos yet" appears.

## Running tests

```bash
# Package tests
cd pulse_db
flutter test

# Example widget tests
cd example
flutter test

# All tests with verbose output
flutter test --reporter expanded
```
