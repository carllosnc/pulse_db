import 'package:flutter/material.dart';

import '../notes_model.dart';

Future<Note?> showAddNoteDialog(BuildContext context) {
  final titleCtrl = TextEditingController();
  final contentCtrl = TextEditingController();

  return showDialog<Note>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('New Note'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: contentCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Content (optional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (titleCtrl.text.trim().isEmpty) return;
            Navigator.pop(
              ctx,
              Note(
                title: titleCtrl.text.trim(),
                content: contentCtrl.text.trim(),
              ),
            );
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );
}
