enum TodoPriority { high, medium, low }

class TodoTask {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final TodoPriority priority;
  final bool isCompleted;

  TodoTask({
    required this.id,
    required this.title,
    this.description = '',
    required this.dueDate,
    this.priority = TodoPriority.medium,
    this.isCompleted = false,
  });

  TodoTask copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    TodoPriority? priority,
    bool? isCompleted,
  }) {
    return TodoTask(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'dueDate': dueDate.toIso8601String(),
    'priority': priority.name,
    'isCompleted': isCompleted,
  };

  factory TodoTask.fromJson(Map<String, dynamic> json) {
    return TodoTask(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      dueDate: DateTime.parse(json['dueDate']),
      priority: TodoPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => TodoPriority.medium,
      ),
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}