class Note {
  final int? id;
  final String title;
  final String content;
  final String? createdAt;

  const Note({this.id, required this.title, this.content = '', this.createdAt});

  Map<String, dynamic> toMap() => {'title': title, 'content': content};

  factory Note.fromMap(Map<String, dynamic> map) => Note(
    id: map['id'] as int?,
    title: map['title'] as String,
    content: (map['content'] as String?) ?? '',
    createdAt: map['created_at'] as String?,
  );
}
