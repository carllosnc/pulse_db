// ignore_for_file: use_super_parameters

import 'package:pulse_db/pulse_db.dart';

final todoTable = TableDef('todos', [
  integer('id').primaryKey().autoIncrement(),
  text('title').required(),
  text('note').defaultTo("''"),
  integer('priority').defaultTo('0'),
  integer('done').defaultTo('0'),
  text('created_at').defaultTo("(datetime('now'))"),
]);
