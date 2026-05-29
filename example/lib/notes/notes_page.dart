import 'package:flutter/material.dart';
import 'package:pulse_db/pulse_db.dart';

import 'notes_database.dart';
import 'notes_model.dart';
import 'widgets/add_note_dialog.dart';
import 'widgets/note_tile.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> with PulseDbMixin {
  late final _notes = observe(notesRepo(db));
  var _editingNoteId = -1;
  final _editCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    initDb(databaseName: 'notes.db', tables: [notesTable]);
  }

  @override
  void dispose() {
    _editCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_notes.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notes')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final notes = _notes.value;
    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: notes.isEmpty
          ? const Center(child: Text('No notes yet'))
          : ListView.builder(
              itemCount: notes.length,
              itemBuilder: (_, i) {
                final note = notes[i];
                if (note.id == _editingNoteId) {
                  return _editTile(note);
                }
                return NoteTile(
                  title: note.title,
                  content: note.content,
                  createdAt: note.createdAt,
                  onTap: () => setState(() {
                    _editingNoteId = note.id!;
                    _editCtrl.text = note.content;
                  }),
                  onDelete: () => _notes.repo!.delete(note.id!),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final note = await showAddNoteDialog(context);
          if (note != null) _notes.repo!.insert(note);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _editTile(Note note) {
    return ListTile(
      title: Text(note.title),
      subtitle: TextField(
        controller: _editCtrl,
        autofocus: true,
        maxLines: null,
        decoration: const InputDecoration(border: OutlineInputBorder()),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              _notes.repo!.update({'content': _editCtrl.text}, where: 'id = ?', whereArgs: [note.id]);
              setState(() => _editingNoteId = -1);
            },
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => setState(() => _editingNoteId = -1),
          ),
        ],
      ),
    );
  }
}
