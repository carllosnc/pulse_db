import 'dart:async';

import 'package:flutter/material.dart';

import 'todo_database.dart';
import 'todo_model.dart';
import 'widgets/add_todo_dialog.dart';
import 'widgets/todo_tile.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final _db = TodoDatabase();
  List<Todo> _todos = [];
  String _filter = 'all';
  StreamSubscription? _sub;
  var _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _db.init();
    if (!mounted) return;
    _sub = _db.watchAll().listen((todos) {
      if (!mounted) return;
      setState(() => _todos = todos);
    });
    setState(() => _ready = true);
  }

  List<Todo> get _filtered {
    if (_filter == 'active') {
      return _todos.where((t) => !t.done).toList();
    } else if (_filter == 'done') {
      return _todos.where((t) => t.done).toList();
    }
    return _todos;
  }

  @override
  void dispose() {
    _sub?.cancel();
    _db.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _todos.where((t) => !t.done).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo List'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (v) => setState(() => _filter = v),
            itemBuilder: (_) => [
              CheckedPopupMenuItem(value: 'all', checked: _filter == 'all', child: const Text('All')),
              CheckedPopupMenuItem(value: 'active', checked: _filter == 'active', child: const Text('Active')),
              CheckedPopupMenuItem(value: 'done', checked: _filter == 'done', child: const Text('Done')),
            ],
          ),
        ],
      ),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : _todos.isEmpty
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
                      return TodoTile(todo: todo, onToggle: (done) => _db.toggle(todo.id!, done), onDelete: () => _db.delete(todo.id!));
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _ready
            ? () async {
                final todo = await showAddTodoDialog(context);
                if (todo != null) _db.add(todo);
              }
            : null,
        child: const Icon(Icons.add),
      ),
    );
  }
}
