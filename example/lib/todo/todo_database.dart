// ignore_for_file: use_super_parameters

import 'package:pulse_db/pulse_db.dart';

import 'todo_model.dart';

final todoTable = TableDef('todos', [
  integer('id').primaryKey().autoIncrement(),
  text('title').required(),
  text('note').defaultTo("''"),
  integer('priority').defaultTo('0'),
  integer('done').defaultTo('0'),
  text('created_at').defaultTo("(datetime('now'))"),
]);

Repository<Todo> todoRepo(PulseDb db) =>
    Repository<Todo>(db, table: todoTable, fromRow: Todo.fromMap, toRow: (t) => t.toMap());
