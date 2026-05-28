# PulseDb Core

**File:** `lib/src/database.dart`

`PulseDb` is the central class — a thin wrapper around the `sqlite3` Dart package. It owns a single `Database` connection and exposes CRUD, transactions, and reactive streams.

## Opening and closing

```dart
final db = PulseDb();
db.open('path/to/db.db', migrations: [
  Migration(version: 1, up: 'CREATE TABLE ...'),
]);
// ... use it ...
db.close();
```

- `open()` creates the SQLite connection and runs pending migrations synchronously.
- `close()` disposes the change notifier, closes the database, and sets `isOpen = false`.
- Every public method calls `_ensureOpen()` which throws `StateError` if the database isn't open.

## Insert

```dart
int insert(String table, Map<String, dynamic> data)
```

Builds `INSERT INTO "table" (k1, k2) VALUES (?, ?)` from the map keys/values. Returns `lastInsertRowId`.

## Update

```dart
int update(String table, Map<String, dynamic> data, String where, [List<Object?> whereArgs])
```

Builds `UPDATE "table" SET k1 = ?, k2 = ? WHERE <where>`. Returns the number of affected rows (`_db!.updatedRows`).

## Delete

```dart
int delete(String table, String where, [List<Object?> whereArgs])
```

Builds `DELETE FROM "table" WHERE <where>`. Returns affected rows.

## Query

```dart
List<Map<String, dynamic>> query(String sql, [List<Object?> params])
```

Runs `SELECT` via `_db!.select(sql, params)` and converts each row to `Map<String, dynamic>`.

## Transaction

```dart
void transaction(void Function() fn)
```

1. Throws `StateError` if already inside a transaction (no nesting).
2. Sets `_inTransaction = true`, calls `BEGIN`.
3. Runs `fn()`. If it succeeds → `COMMIT`. If it throws → `ROLLBACK` and rethrow.
4. After commit, collects all table names that were touched during the transaction, and notifies `ChangeNotifier` once with the union.

This batching means a transaction that inserts into 3 tables fires a single reactive notification for all 3 tables.

## Watch

```dart
Stream<List<Map<String, dynamic>>> watch(String table)
Stream<List<Map<String, dynamic>>> watchQuery(String sql, [List<Object?> params])
```

Returns a broadcast stream. On first listener:
1. **Emits current data** immediately by running the query.
2. **Subscribes to `ChangeNotifier.changes`** — whenever any tracked table changes, it re-runs the query and emits the new result.

`watchQuery` works for joins and arbitrary SQL. The table names are extracted from the SQL by `table_tracker.dart`.

## Internal method: `_watchQuery`

```dart
Stream<List<Map<String, dynamic>>> _watchQuery(String sql, List<Object?> params)
```

- Extracts table names from `sql` via `extractTables()`.
- Creates a `StreamController.broadcast`.
- `onListen`: emits current data, then listens to `_notifier.changes` filtered to those table names.
- `onCancel`: cancels the subscription.
- The `emit()` closure guards `_isOpen` to avoid emitting after close.

## Internal method: `execute`

```dart
int execute(String sql, [List<Object?> params])
```

The single write entry point used by `insert`, `update`, and `delete`:
1. Extracts table names from `sql`.
2. Runs `_db!.execute(sql, params)`.
3. Reads `_db!.updatedRows`.
4. If inside a transaction → buffers table names in `_pendingTables`.
5. If not in a transaction → immediately notifies `ChangeNotifier`.

This separation ensures that transaction notifications are batched at commit time.
