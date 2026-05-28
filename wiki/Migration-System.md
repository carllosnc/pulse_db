# Migration System

**File:** `lib/src/migration.dart` + `PulseDb._runMigrations()`

## Migration model

```dart
class Migration {
  final int version;
  final String up;        // SQL to apply
  final String? down;     // SQL to roll back (not used yet)
}
```

Versions are integers applied in ascending order. The `down` field is reserved for future rollback support; currently only forward migrations are executed.

## How migrations are applied

When `PulseDb.open(path, migrations: [...])` is called with a non-empty list, `_runMigrations(migrations)` runs immediately (synchronously).

### The `_meta_migrations` table

```sql
CREATE TABLE IF NOT EXISTS _meta_migrations (
  version INTEGER PRIMARY KEY,
  applied_at TEXT NOT NULL DEFAULT (datetime('now'))
)
```

This table tracks which migrations have already run. It's created on first use.

### The algorithm

```dart
void _runMigrations(List<Migration> migrations) {
  // 1. Ensure tracking table exists
  _db!.execute('''CREATE TABLE IF NOT EXISTS _meta_migrations (...)''');

  // 2. Read already-applied versions
  final applied = _db!
      .select('SELECT version FROM _meta_migrations')
      .map((r) => r.columnAt(0) as int)
      .toSet();

  // 3. Apply each migration that hasn't been applied
  for (final m in migrations) {
    if (!applied.contains(m.version)) {
      _db!.execute(m.up);                     // run the SQL
      _db!.execute(                           // record the version
        'INSERT INTO _meta_migrations (version) VALUES (?)',
        [m.version],
      );
    }
  }
}
```

Migrations are idempotent — running `open()` multiple times is safe. Already-applied versions are skipped.

## Example

```dart
db.open('app.db', migrations: [
  Migration(version: 1, up: 'CREATE TABLE users (id INTEGER PRIMARY KEY, email TEXT)'),
  Migration(version: 2, up: 'ALTER TABLE users ADD COLUMN name TEXT'),
]);
```

- First run: migrations 1 and 2 both execute.
- Second run: `_meta_migrations` already has versions 1 and 2, so nothing executes.

## Important notes

- Migrations run **synchronously** inside `open()`. They block the constructor call.
- There is **no rollback on failure** — if a migration SQL throws, the database is left in an inconsistent state and `open()` throws.
- The `TableNotifier` is created **before** migrations run, but migrations don't fire change notifications because `execute()` calls `_notifier.notify()` only when `_isOpen` is true (it is) and migrations don't go through user-facing `watch()`.
