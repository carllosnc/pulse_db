import 'package:flutter/material.dart';

import '../todo_model.dart';

Future<Todo?> showAddTodoDialog(BuildContext context) {
  final titleCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  var priority = 0;

  return showDialog<Todo>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: const Text('New Todo'),
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
              controller: noteCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Priority: '),
                const SizedBox(width: 8),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Low')),
                    ButtonSegment(value: 1, label: Text('Med')),
                    ButtonSegment(value: 2, label: Text('High')),
                  ],
                  selected: {priority},
                  onSelectionChanged: (v) =>
                      setDialogState(() => priority = v.first),
                ),
              ],
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
                Todo(
                  title: titleCtrl.text.trim(),
                  note: noteCtrl.text.trim(),
                  priority: priority,
                ),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    ),
  );
}
