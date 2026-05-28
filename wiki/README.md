# pulse\_db wiki

Step-by-step documentation of the codebase.

## Index

| Page | Covers |
|------|--------|
| [01 — Architecture Overview](01-architecture-overview.md) | High-level design, dependency graph, data flow |
| [02 — PulseDb Core](02-pulse-db-core.md) | `PulseDb` class: open, close, insert, update, delete, query, transaction |
| [03 — ChangeNotifier (internal)](03-change-notifier.md) | Debounced reactive notification engine |
| [04 — Table Tracker (internal)](04-table-tracker.md) | SQL parsing to extract table names |
| [05 — Migration System](05-migration-system.md) | How versioned migrations are applied |
| [06 — Schema Definition](06-schema-definition.md) | `Table`, `Col`, column types, chainable modifiers |
| [07 — Repository Pattern](07-repository-pattern.md) | `Repository<T>` with typed CRUD and reactive streams |
| [08 — Lifecycle Mixin](08-lifecycle-mixin.md) | `PulseDbMixin`: `initDb`, `observe`, `dbReady`, auto-dispose |
| [09 — Example: Todo App](09-example-todo-app.md) | Walkthrough of `example/` from model to UI |
| [10 — Testing Guide](10-testing-guide.md) | How tests are structured, edge cases covered |
