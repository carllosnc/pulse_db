# Table Tracker (internal)

**File:** `lib/src/table_tracker.dart`

Extracts table names from SQL statements using regex. This is how `PulseDb` knows which tables to notify when data changes, and which tables a `watchQuery` depends on.

## Regex patterns

### `_tablePattern`

```dart
r'''(?:FROM|JOIN|INTO|UPDATE|TABLE)\s+["'`]?(\w+)["'`]?'''
```

Matches keywords that introduce table names:
- `FROM users` → `users`
- `JOIN posts ON ...` → `posts`
- `INTO users ...` → `users`
- `UPDATE users SET ...` → `users`
- `TABLE users (...)` → `users`

Handles optional quoting with `"`, `'`, or backtick.

### `_deleteFromPattern`

```dart
r'''DELETE\s+FROM\s+["'`]?(\w+)["'`]?'''
```

A separate pattern because `DELETE FROM` is two tokens that the first regex doesn't handle as `FROM` (it matches `FROM` after DELETE).

## How `extractTables` works

```dart
Set<String> extractTables(String sql)
```

1. Runs `_tablePattern` over the SQL and collects group 1 (the table name).
2. Runs `_deleteFromPattern` and collects group 1.
3. Lowercases all names for case-insensitive comparison.
4. Returns the set.

## Where it's used

| Location | Purpose |
|----------|---------|
| `PulseDb.execute()` | After a write, extract which tables changed so `ChangeNotifier` can notify listeners |
| `PulseDb._watchQuery()` | On stream creation, extract which tables to listen to |

## Limitations

- Only handles simple SQL. Complex CTEs or subqueries with aliases may miss tables.
- Doesn't distinguish between tables and aliases (e.g., `FROM users u` returns `users` and `u`, but `u` won't match anything since it's not a real table — this is harmless).
- Assumes table names are plain identifiers (no schema prefixes like `main.t`).
