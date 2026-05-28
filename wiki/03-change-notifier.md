# ChangeNotifier (internal)

**File:** `lib/src/change_notifier.dart`

This is *not* Flutter's `ChangeNotifier`. It's a small internal class that provides debounced reactive notifications about which tables changed.

## Purpose

When `PulseDb.execute()` modifies data, it notifies the `ChangeNotifier` with the set of table names that were touched. The `ChangeNotifier` debounces these notifications and forwards them as a stream that `watch()` subscribers listen to.

## How it works

```
INSERT INTO users ... ──┐
                        ├──→ _pending = {users, posts}
UPDATE posts ... ───────┘          │
                             50 ms │ debounce
                                   ▼
                            _flush()
                              │
                              ▼
                    controller.add({users, posts})
```

### Fields

| Field | Type | Purpose |
|-------|------|---------|
| `_pending` | `Set<String>` | Accumulates table names between flushes |
| `_timer` | `Timer?` | Debounce timer |
| `_controller` | `StreamController<Set<String>>` | Broadcast controller |
| `_debounceDelay` | `Duration` | Default 50 ms |

### Methods

**`notify(Set<String> tables)`**
Adds table names to `_pending`, cancels any pending timer, and starts a new 50 ms timer. If multiple writes happen within 50 ms, they coalesce into one flush.

**`flush()`**
Immediately cancels the timer and flushes. Used when the database is closing.

**`_flush()`**
If `_pending` is non-empty, adds a copy to the stream controller and clears `_pending`.

**`dispose()`**
Cancels the timer and closes the stream controller. Called from `PulseDb.close()`.

## Why debounce?

Without debouncing, a batch of 10 inserts would fire 10 notifications, each triggering 10 re-queries. With debouncing, they coalesce into 1 notification → 1 re-query.

The 50 ms delay is short enough to feel instant to the user but long enough to batch typical burst writes.
