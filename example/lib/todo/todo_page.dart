import 'package:flutter/material.dart';
import 'package:pulse_db/pulse_db.dart';

import 'todo_database.dart';
import 'todo_model.dart';
import 'widgets/add_todo_dialog.dart';
import 'widgets/todo_tile.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> with PulseDbMixin {
  late final _todos = observe(todoRepo(db));
  var _filter = 'all';

  @override
  void initState() {
    super.initState();
    initDb(databaseName: 'todos.db', tables: [todoTable]);
  }

  @override
  Widget build(BuildContext context) {
    if (_todos.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Todo List'), actions: [_filterMenu()]),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final todos = _todos.value;
    final activeCount = todos.where((t) => !t.done).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Todo List'), actions: [_filterMenu()]),
      body: todos.isEmpty
          ? const Center(child: Text('No todos yet'))
          : Column(
              children: [
                if (activeCount > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(children: [const Icon(Icons.info_outline, size: 16), const SizedBox(width: 6), Text('$activeCount pending')]),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final todo = _filtered[i];
                      return TodoTile(
                        todo: todo,
                        onToggle: (done) => _todos.repo!.update({'done': done ? 1 : 0}, where: 'id = ?', whereArgs: [todo.id!]),
                        onDelete: () => _todos.repo!.delete(todo.id!),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final todo = await showAddTodoDialog(context);
          if (todo != null) _todos.repo!.insert(todo);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  List<Todo> get _filtered {
    final todos = _todos.value;
    if (_filter == 'active') return todos.where((t) => !t.done).toList();
    if (_filter == 'done') return todos.where((t) => t.done).toList();
    return todos;
  }

  PopupMenuButton<String> _filterMenu() => PopupMenuButton<String>(
    icon: const Icon(Icons.filter_list),
    onSelected: (v) => setState(() => _filter = v),
    itemBuilder: (_) => [
      CheckedPopupMenuItem(value: 'all', checked: _filter == 'all', child: const Text('All')),
      CheckedPopupMenuItem(value: 'active', checked: _filter == 'active', child: const Text('Active')),
      CheckedPopupMenuItem(value: 'done', checked: _filter == 'done', child: const Text('Done')),
    ],
  );
}
