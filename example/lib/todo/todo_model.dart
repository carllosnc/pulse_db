class Todo {
  final int? id;
  final String title;
  final String note;
  final int priority;
  final bool done;
  final String? createdAt;

  const Todo({
    this.id,
    required this.title,
    this.note = '',
    this.priority = 0,
    this.done = false,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'note': note,
    'priority': priority,
    'done': done ? 1 : 0,
  };

  factory Todo.fromMap(Map<String, dynamic> map) => Todo(
    id: map['id'] as int?,
    title: map['title'] as String,
    note: (map['note'] as String?) ?? '',
    priority: (map['priority'] as int?) ?? 0,
    done: (map['done'] as int?) == 1,
    createdAt: map['created_at'] as String?,
  );

  Todo copyWith({
    int? id,
    String? title,
    String? note,
    int? priority,
    bool? done,
    String? createdAt,
  }) => Todo(
    id: id ?? this.id,
    title: title ?? this.title,
    note: note ?? this.note,
    priority: priority ?? this.priority,
    done: done ?? this.done,
    createdAt: createdAt ?? this.createdAt,
  );
}
