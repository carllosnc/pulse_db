import 'package:pulse_db/pulse_db.dart';

import 'notes_model.dart';

final notesTable = TableDef('notes', [
  integer('id').primaryKey().autoIncrement(),
  text('title').required(),
  text('content').defaultTo("''"),
  text('created_at').defaultTo("(datetime('now'))"),
]);

Repository<Note> notesRepo(PulseDb db) =>
    Repository<Note>(db, table: notesTable, fromRow: Note.fromMap, toRow: (n) => n.toMap());
