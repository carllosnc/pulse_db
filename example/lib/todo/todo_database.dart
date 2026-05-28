import 'package:path_provider/path_provider.dart';
import 'package:pulse_db/pulse_db.dart';

import 'todo_model.dart';

class TodoDatabase {
  final _db = PulseDb();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    final dir = await getApplicationDocumentsDirectory();
    _db.open('${dir.path}/todos.db', migrations: [
      Migration(
        version: 1,
        up: '''CREATE TABLE todos (
          id INTEGER PRIMARY KEY,
          title TEXT NOT NULL,
          note TEXT DEFAULT '',
          priority INTEGER DEFAULT 0,
          done INTEGER DEFAULT 0,
          created_at TEXT DEFAULT (datetime('now'))
        )''',
      ),
    ]);
    _initialized = true;
  }

  Stream<List<Todo>> watchAll() {
    return _db.watch('todos').map(
      (rows) => rows.map(Todo.fromMap).toList(),
    );
  }

  void add(Todo todo) {
    _db.insert('todos', todo.toMap());
  }

  void toggle(int id, bool done) {
    _db.update('todos', {'done': done ? 1 : 0}, 'id = ?', [id]);
  }

  void delete(int id) {
    _db.delete('todos', 'id = ?', [id]);
  }

  void close() {
    _db.close();
  }
}
