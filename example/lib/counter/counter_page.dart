import 'package:flutter/material.dart';
import 'package:pulse_db/pulse_db.dart';

import 'counter_database.dart';

class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> with PulseDbMixin {
  late final _counters = autoObserve(
    (db) => db.repository(counterTable),
  );

  @override
  void initState() {
    super.initState();
    initDb(databaseName: 'counters.db', tables: [counterTable]);
  }

  @override
  Widget build(BuildContext context) {
    if (_counters.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Counters')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final items = _counters.value;
    return Scaffold(
      appBar: AppBar(title: const Text('Counters')),
      body: items.isEmpty
          ? const Center(child: Text('No counters yet'))
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                final id = item['id'] as int;
                final label = item['label'] as String;
                final value = item['value'] as int;
                return ListTile(
                  title: Text(label),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () => db.update(counterTable.name, {'value': value - 1}, 'id = ?', [id]),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text('$value', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => db.update(counterTable.name, {'value': value + 1}, 'id = ?', [id]),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final nameCtrl = TextEditingController();
          final label = await showDialog<String>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('New Counter'),
              content: TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Label',
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    Navigator.pop(ctx, nameCtrl.text.trim());
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          );
          if (label != null) {
            db.insert(counterTable.name, {'label': label, 'value': 0});
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
