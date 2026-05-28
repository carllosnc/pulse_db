# pulse\_db wiki

Step-by-step documentation of the codebase.

## Index

| Page | Covers |
|------|--------|
| [Architecture Overview](Architecture-Overview.md) | High-level design, dependency graph, data flow |
| [PulseDb Core](PulseDb-Core.md) | `PulseDb` class: open, close, insert, update, delete, query, transaction |
| [ChangeNotifier (internal)](ChangeNotifier.md) | Debounced reactive notification engine |
| [Table Tracker (internal)](Table-Tracker.md) | SQL parsing to extract table names |
| [Migration System](Migration-System.md) | How versioned migrations are applied |
| [Schema Definition](Schema-Definition.md) | `Table`, `Col`, column types, chainable modifiers |
| [Repository Pattern](Repository-Pattern.md) | `Repository<T>` with typed CRUD and reactive streams |
| [Lifecycle Mixin](Lifecycle-Mixin.md) | `PulseDbMixin`: `initDb`, `observe`, `dbReady`, auto-dispose |
| [Example: Todo App](Example-Todo-App.md) | Walkthrough of `example/` from model to UI |
| [Testing Guide](Testing-Guide.md) | How tests are structured, edge cases covered |
