# Changelog

## 0.0.1 (unreleased)

### Core

- **PulseDb** — thin wrapper around `sqlite3` with typed CRUD (`insert`, `update`, `delete`, `query`, `transaction`)
- **Reactive streams** — `watch(table)` and `watchQuery(sql)` emit fresh results on every insert/update/delete via a debounced `TableNotifier`
- **Auto schema sync** — pass `tables:` to `open()`: tables are auto-created on first run, new columns are added via `ALTER TABLE ADD COLUMN` when `TableDef` changes. Schema state tracked in `_meta_schema` table
- **Migrations** — versioned `Migration` list with `Migration.table()` factory shorthand that generates `CREATE TABLE` SQL from a `TableDef`
- **Convenience factory** — `PulseDb.openAsync()` resolves path via `getApplicationDocumentsDirectory()` automatically

### Schema builder

- **TableDef** — declarative table schema with typed column builders
- **Col** — chainable modifiers: `primaryKey()`, `required()`, `autoIncrement()`, `defaultTo()`
- **Column type helpers** — `integer()`, `text()`, `real()`, `blob()`
- **`TableDef.createSql`** — generates `CREATE TABLE` SQL from the definition
- **`TableDef.pkName`** — returns the primary key column name (defaults to `'id'`)

### Repository

- **Repository<T>** — typed CRUD base class with `insert`, `get`, `update`, `delete`, `deleteWhere`, `watch`, `watchWhere`
- **MapRepository** — zero-boilerplate map-based repository, no model class required
- **`PulseDb.repository()` extension** — shorthand for `MapRepository(db, table)`

### Lifecycle mixin

- **PulseDbMixin** — database lifecycle management in `StatefulWidget`
- **`initDb()`** — async DB open with auto path resolution, `tables:` param for schema sync
- **`observe(Repository<R>)`** — returns `ObservableList<R>` with reactive data binding and automatic `setState`
- **`autoObserve(Repository<R> Function(PulseDb) factory)`** — defers repo creation until DB is ready
- **`use(PulseDb db)`** — attach an externally-owned database instance
- **Automatic cleanup** — cancels subscriptions and closes the database in `dispose()`

### ObservableList

- **`ObservableList<R>`** — `ValueNotifier<List<R>>` subclass with:
  - `.isLoading` — `true` until first data arrives
  - `.isEmpty` — `true` only when loaded and list is empty
  - `.repo` — access to the underlying `Repository<R>` for writes

### Example app

- **Home page** — gallery of examples with navigation
- **Todo** — typed model (`Repository<Todo>`) with priority, filtering, checkboxes
- **Notes** — typed model (`Repository<Note>`) with inline editing
- **Counters** — `MapRepository` via `autoObserve`, no model class

### Documentation

- **README.md** — setup guide, feature overview, code samples
- **Wiki** — 10-page wiki: Architecture Overview, PulseDb Core, Schema Definition, Repository Pattern, Migration System, Lifecycle Mixin, TableNotifier, Table Tracker, Example Todo App, Testing Guide
- **Architecture SVG diagrams** — TableNotifier and overview charts
- **CI badge** — GitHub Actions workflow

### Testing

- **59 core tests** — schema builder (23), repository CRUD + watch (16), database edge cases (20)
- **4 widget tests** — home page rendering, loading/empty states for all 3 examples
- **Edge cases covered** — row ID accuracy, nested transaction rejection, operations after close, empty watch emissions, multiple subscribers
