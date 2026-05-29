import 'package:flutter/material.dart';

import 'counter/counter_page.dart';
import 'notes/notes_page.dart';
import 'todo/todo_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('PulseDb Examples')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Select an example', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          _Card(
            icon: Icons.checklist,
            title: 'Todo List',
            subtitle: 'Typed model — Repository<Todo> with priority, filtering, checkboxes',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TodoPage())),
          ),
          const SizedBox(height: 8),
          _Card(
            icon: Icons.note,
            title: 'Notes',
            subtitle: 'Typed model — Repository<Note> with inline editing, create/delete',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesPage())),
          ),
          const SizedBox(height: 8),
          _Card(
            icon: Icons.exposure,
            title: 'Counters',
            subtitle: 'MapRepository — no model class, direct map CRUD via db.repository()',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CounterPage())),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _Card({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
