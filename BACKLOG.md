# v1.0 Backlog

**Current version:** `0.0.1` | **Target:** `1.0.0`

---

## 1. Typed error handling
**Priority:** Critical | **Area:** Core | **Effort:** Medium

Wrap raw `SqliteException` and `StateError` into a typed exception hierarchy:

```
PulseDbException (base)
├── PulseDbClosedException       (db used after close)
├── PulseDbConstraintException   (UNIQUE, FK violations)
├── PulseDbSchemaException       (table/column not found)
└── PulseDbTransactionException  (nested tx, rollback, failed commit)
```

All public methods (`insert`, `update`, `delete`, `query`, `watch`, `transaction`) must only throw these typed exceptions so callers can catch specific failures.

**Files:** `lib/src/exceptions.dart` (new), `lib/src/database.dart` (modify)

---

## 2. Async query offloading
**Priority:** High | **Area:** Performance | **Effort:** Large

All `PulseDb` queries currently run synchronously on the main isolate. For large datasets this blocks the UI thread, especially during `watch()` emissions (every insert triggers a full `SELECT *`).

Provide an `Isolate`-based offloading mechanism:

```dart
// Read-only queries on a separate isolate
final result = await db.compute((db) => db.query('SELECT * FROM large_table'));
```

Or make the primary API async by default, with `querySync()` for known-hot paths.

**Files:** `lib/src/database.dart` (modify)

---

## 3. Watch pagination & streaming
**Priority:** High | **Area:** API | **Effort:** Medium

`watch()` currently does `SELECT * FROM table` on every change with no limit/offset. A single insert re-queries the entire table.

Add:
- `watchCursor(table, {int? limit, int? offset})` — paginated reactive stream
- Document the `watchQuery` pattern for arbitrary filtered/paginated queries
- Consider incremental diff: emit only the changed row instead of full table

**Files:** `lib/src/database.dart` (modify)

---

## 4. Bulk operations
**Priority:** Medium | **Area:** API | **Effort:** Small

Add to `PulseDb` and `Repository<T>`:

- `insertAll(List<Map>)` / `insertAll(List<T>)` — single INSERT with multiple rows, wrapped in a transaction
- `updateAll(...)` — batch update by list of IDs
- `upsert(table, data, conflictColumn)` — `INSERT OR REPLACE` / `INSERT ... ON CONFLICT DO UPDATE`

**Files:** `lib/src/database.dart`, `lib/src/repository.dart` (modify)

---

## 5. Migration improvements
**Priority:** Medium | **Area:** API | **Effort:** Medium

- **Down migrations** — optional `Migration.down` for rollback
- **`Migration.table()` collision handling** — currently generates `CREATE TABLE` but doesn't integrate with `_syncTables` when the table already exists
- **`migrateTo(version)`** — migrate up/down to a specific version
- **Dry-run** — `db.previewMigrations()` — list pending migrations without applying

**Files:** `lib/src/migration.dart`, `lib/src/database.dart` (modify)

---

## 6. dartdoc on all public APIs
**Priority:** High | **Area:** Documentation | **Effort:** Large

Every public class, method, parameter, and return type needs a dartdoc comment. Currently zero public APIs are documented. This blocks `pub publish` without warnings.

**Files:** `lib/src/*.dart` (all)

---

## 7. ObservableList tests
**Priority:** High | **Area:** Testing | **Effort:** Small

`ObservableList` was added with zero dedicated tests. Needed:

- `isLoading` starts `true`, flips to `false` on first value set
- `isEmpty` returns `false` while loading, correct value after loaded
- `.repo` accessor returns the correct repository
- Extends `ValueNotifier` — listeners fire when value changes

**Files:** `test/observable_list_test.dart` (new)

---

## 8. Stress & large-dataset tests
**Priority:** Medium | **Area:** Testing | **Effort:** Medium

- **10k rows** — bulk insert, verify `watch()` emission time under threshold
- **Concurrent subscribers** — 50 listeners on same table, all receive updates
- **Rapid writes** — 1000 tight-loop inserts, no dropped emissions
- **Transaction stress** — nested chains, large batch rollback

**Files:** `test/stress_test.dart` (new)

---

## 9. Error recovery in mixin
**Priority:** Medium | **Area:** Lifecycle | **Effort:** Small

The mixin's `initDb()` and `use()` have no error handling — a failed DB open crashes the widget. Add:

- Optional `onError` callback to `initDb`
- `initError` state property for pages to check in `build()`

```dart
await initDb(databaseName: 'todos.db', tables: [todoTable]);
if (initError != null) return Text('Error: $initError');
```

**Files:** `lib/src/client.dart` (modify)

---

## 10. Concurrent access guard
**Priority:** Low | **Area:** Core | **Effort:** Small

SQLite doesn't support concurrent writes from multiple processes on the same file. Use an advisory lock file (`.db.lock`) to detect and reject double-opening cleanly.

**Files:** `lib/src/database.dart` (modify)

---

## 11. Split Flutter vs Dart core
**Priority:** Low | **Area:** Packaging | **Effort:** Medium

`PulseDb` currently imports `path_provider` (Flutter-only), making it unusable from pure Dart projects. Move `path_provider` out of the core — only `PulseDbMixin` and `PulseDb.openAsync()` should depend on it. `PulseDb.open()` should be pure Dart.

**Files:** `lib/src/database.dart`, `lib/src/client.dart` (modify), `pubspec.yaml` (restructure deps)

---

## 12. pub.dev release checklist
**Priority:** Medium | **Area:** Publishing | **Effort:** Small

- [x] Clean `dart analyze` (passing)
- [ ] Add `homepage` URL to `pubspec.yaml`
- [ ] Add `repository` URL to `pubspec.yaml`
- [ ] `dart doc` — no warnings
- [ ] `dart pub publish --dry-run` — passes
- [ ] Add `CHANGELOG.md`
- [ ] Add `LICENSE` file
- [ ] Bump version to `1.0.0`

**Files:** `pubspec.yaml`, `CHANGELOG.md` (new), `LICENSE` (new)

---

## Quick reference

| # | Item | Priority | Effort | Quick win? |
|---|------|----------|--------|------------|
| 1 | Typed error handling | Critical | Medium | |
| 2 | Async query offloading | High | Large | |
| 3 | Watch pagination / streaming | High | Medium | |
| 4 | Bulk operations | Medium | Small | ✓ |
| 5 | Migration improvements | Medium | Medium | |
| 6 | dartdoc on all public APIs | High | Large | |
| 7 | ObservableList tests | High | Small | ✓ |
| 8 | Stress & large-dataset tests | Medium | Medium | |
| 9 | Error recovery in mixin | Medium | Small | ✓ |
| 10 | Concurrent access guard | Low | Small | ✓ |
| 11 | Split Flutter vs Dart core | Low | Medium | |
| 12 | pub.dev release checklist | Medium | Small | ✓ |
