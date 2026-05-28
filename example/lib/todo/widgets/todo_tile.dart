import 'package:flutter/material.dart';

import '../todo_model.dart';
import 'priority_chip.dart';

class TodoTile extends StatelessWidget {
  final Todo todo;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const TodoTile({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: todo.done,
        onChanged: (v) => onToggle(v ?? false),
      ),
      title: Text(
        todo.title,
        style: todo.done
            ? const TextStyle(
                decoration: TextDecoration.lineThrough,
                color: Colors.grey,
              )
            : null,
      ),
      subtitle: todo.note.isNotEmpty
          ? Text(todo.note, maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PriorityChip(todo.priority),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
