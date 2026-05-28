// ignore_for_file: use_super_parameters

import 'package:pulse_db/pulse_db.dart';

import 'todo_model.dart';

final todoTable = Table('todos', [
  integer('id').primaryKey().autoIncrement(),
  text('title').required(),
  text('note').defaultTo("''"),
  integer('priority').defaultTo('0'),
  integer('done').defaultTo('0'),
  text('created_at').defaultTo("(datetime('now'))"),
]);

class TodoRepository extends Repository<Todo> {
TodoRepository(PulseDb db) : super(
    db,
    table: todoTable,
    fromRow: Todo.fromMap,
    toRow: (t) => t.toMap(),
  );

  Stream<List<Todo>> watchActive() => watchWhere('done = 0');
  Stream<List<Todo>> watchDone() => watchWhere('done = 1');
  void toggle(int id, bool done) =>
      update({'done': done ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  void remove(int id) => delete(id);
}
