import 'package:pulse_db/pulse_db.dart';

final counterTable = TableDef('counters', [
  integer('id').primaryKey().autoIncrement(),
  text('label').required(),
  integer('value').defaultTo('0'),
]);
