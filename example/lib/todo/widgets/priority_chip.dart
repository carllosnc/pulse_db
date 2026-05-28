import 'package:flutter/material.dart';

class PriorityChip extends StatelessWidget {
  final int priority;

  const PriorityChip(this.priority, {super.key});

  @override
  Widget build(BuildContext context) {
    final map = {
      0: ('Low', Colors.green),
      1: ('Med', Colors.orange),
      2: ('High', Colors.red),
    };
    final (label, color) = map[priority] ?? map[0]!;
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color)),
    );
  }
}
