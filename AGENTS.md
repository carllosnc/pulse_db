# Agent Rules & Best Practices for PulseDb

This file contains guidelines and best practices for AI agents and developers working on the `pulse_db` project.

## Project Overview
`pulse_db` is a lightweight SQLite wrapper for Flutter and Dart with reactive queries and a type-safe schema builder. It uses the `sqlite3` package under the hood.

## 1. Code Style & Conventions
- **Strict Typing:** Always use strong types. Avoid using `dynamic` unless absolutely necessary (e.g., when dealing with raw JSON or untyped map maps).
- **Dart Formatter:** Ensure all code adheres to the standard Dart formatting (`dart format`).
- **Documentation:** All public APIs (classes, methods, parameters, return types) **must** have descriptive `dartdoc` (`///`) comments. This is a critical requirement for publishing.
- **Null Safety:** Strictly adhere to Dart's sound null safety.

## 2. Architecture & Design Principles
- **Dart vs Flutter Core:** Keep the core database logic pure Dart. Dependencies on Flutter (like `path_provider` or `flutter/foundation.dart`) should be isolated to specific integration files (e.g., `client.dart`). Do not leak Flutter dependencies into pure Dart data logic.
- **Exception Handling:** Always throw exceptions from the `PulseDbException` hierarchy (`PulseDbConstraintException`, `PulseDbSchemaException`, etc.) defined in `lib/src/exceptions.dart`. Never throw raw `StateError` or `SqliteException` for database operations.
- **Reactive Streams:** When adding new query methods, ensure they integrate properly with the `TableNotifier` and `watch`/`watchQuery` ecosystem to emit fresh results on table mutations.
- **Schema Evolution:** Encourage the use of `TableDef` for schemas. Understand that `PulseDb` has an auto-sync schema feature; new columns are added automatically without manual migration scripts. Data migrations use the `Migration` class.

## 3. Testing Requirements
- **Always Test:** Every new feature, bug fix, or edge case must be accompanied by a comprehensive test in the `test/` directory.
- **Test Command:** Run tests using `flutter test` (since the project currently integrates with Flutter).
- **In-Memory Testing:** Use in-memory SQLite databases (`path: ':memory:'`) in tests whenever possible to keep the test suite fast and avoid disk I/O side effects.

## 4. Workflow Guidelines
- **Analyze Code:** Always run `dart analyze` to ensure no warnings or linting errors exist before completing a task.
- **Backlog Tracking:** Check `BACKLOG.md` to see where your task fits within the project's roadmap. Mark tasks as completed using `[x]` in the backlog list when done.
- **Changelog:** Always document new features, bug fixes, and breaking changes in `CHANGELOG.md` before finalizing a task or release.
- **Commit Size:** Keep changes scoped to the specific request. Do not refactor unrelated files or perform "drive-by" cleanups unless explicitly requested by the user.

## 5. Release Guidelines
- **Commit Granularity:** Commit changes using one file per commit when preparing release-specific adjustments (unless the changes are tightly coupled).
- **Bump Version:** Always bump the version in `pubspec.yaml` prior to a release.
- **Tagging:** Add a new git tag corresponding to the new version (e.g., `v0.0.2`) when releasing.

By following these rules, agents will maintain the project's high standards of quality, reliability, and architectural cleanliness.
