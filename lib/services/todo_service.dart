
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/todo_task_model.dart';
import 'firebase_service.dart';

class TodoService {
  static String? get _storageKey {
    final userId = FirebaseService.currentUserId;

    if (userId == null) return null;

    return 'studysync_todos_$userId';
  }

  // Load tasks for the logged-in user.
  static Future<List<TodoTask>> loadTodos() async {
    final key = _storageKey;

    if (key == null) return [];

    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString(key);

    if (savedData == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(savedData);

      return decoded.map((item) {
        return TodoTask.fromJson(
          Map<String, dynamic>.from(item),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Save tasks for the logged-in user.
  static Future<void> saveTodos(List<TodoTask> todos) async {
    final key = _storageKey;

    if (key == null) return;

    final prefs = await SharedPreferences.getInstance();

    final encoded = jsonEncode(
      todos.map((todo) => todo.toJson()).toList(),
    );

    await prefs.setString(key, encoded);
  }
}
