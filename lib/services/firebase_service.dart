
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task_model.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Current Firebase user details
  static String? get currentUserId => _auth.currentUser?.uid;

  static String? get currentUserEmail => _auth.currentUser?.email;

  static String? get currentUserName {
    final user = _auth.currentUser;

    if (user == null) return null;

    return user.displayName ??
        user.email?.split('@').first ??
        'Student';
  }

  // Firebase authentication state
  static Stream<String?> get authStateChanges {
    return _auth.authStateChanges().map(
          (user) => user?.uid,
        );
  }

  // Firebase is initialized in main.dart before this method is called.
  static Future<void> initialize() async {
    // Firebase Auth automatically restores the previous login session.
  }

  // Register a new user using Firebase Authentication.
  static Future<String?> signUp(
    String email,
    String password,
    String name,
  ) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      final cleanName = name.trim();

      if (cleanEmail.isEmpty ||
          password.isEmpty ||
          cleanName.isEmpty) {
        return 'Please fill in all fields.';
      }

      final credential =
          await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      await credential.user?.updateDisplayName(cleanName);
      await credential.user?.reload();
      debugPrint('========== FIREBASE DEBUG ==========');
debugPrint('PROJECT ID: ${_auth.app.options.projectId}');
debugPrint('APP ID: ${_auth.app.options.appId}');
debugPrint('USER EMAIL: ${_auth.currentUser?.email}');
debugPrint('USER UID: ${_auth.currentUser?.uid}');
debugPrint('====================================');

      // Transfer existing local data if this email was used before.
      await _migrateOldLocalData(cleanEmail);

      return null;
    } on FirebaseAuthException catch (e) {
      return _getAuthErrorMessage(e);
    } catch (e) {
      return 'Registration failed. Please try again.';
    }
  }

  // Sign in an existing Firebase user.
  static Future<String?> signIn(
    String email,
    String password,
  ) async {
    try {
      final cleanEmail = email.trim().toLowerCase();

      if (cleanEmail.isEmpty || password.isEmpty) {
        return 'Please fill in all fields.';
      }

      await _auth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      // Transfer existing local data if it belongs to this email.
      await _migrateOldLocalData(cleanEmail);

      return null;
    } on FirebaseAuthException catch (e) {
      return _getAuthErrorMessage(e);
    } catch (e) {
      return 'Login failed. Please try again.';
    }
  }

  // Convert Firebase errors into readable messages.
  static String _getAuthErrorMessage(
    FirebaseAuthException e,
  ) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account already exists with this email. Please sign in.';

      case 'invalid-email':
        return 'Please enter a valid email address.';

      case 'weak-password':
        return 'Password must contain at least 6 characters.';

      case 'user-not-found':
        return 'No account found with this email. Please sign up.';

      case 'wrong-password':
        return 'Incorrect password. Please try again.';

      case 'invalid-credential':
        return 'Invalid email or password. Please check your details.';

      case 'user-disabled':
        return 'This account has been disabled.';

      case 'operation-not-allowed':
        return 'Email/Password sign-in is not enabled in Firebase.';

      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  // Migrate old SharedPreferences data from the mock user ID to Firebase UID.
  static Future<void> _migrateOldLocalData(
    String email,
  ) async {
    final user = _auth.currentUser;

    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();

    // This matches the ID format used by the previous mock service.
    final oldUserId = email.replaceAll('.', '_');
    final newUserId = user.uid;

    final oldKeys = [
      'firebase_mock_timetable_$oldUserId',
      'daily_performance_$oldUserId',
      'firebase_mock_quiz_$oldUserId',
    ];

    final newKeys = [
      'firebase_mock_timetable_$newUserId',
      'daily_performance_$newUserId',
      'firebase_mock_quiz_$newUserId',
    ];

    for (int i = 0; i < oldKeys.length; i++) {
      final oldData = prefs.getString(oldKeys[i]);

      final newData = prefs.getString(newKeys[i]);

      if (oldData != null && newData == null) {
        await prefs.setString(newKeys[i], oldData);
      }
    }
  }

  // Sign out the current Firebase user.
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // Save timetable and update daily performance history.
  static Future<void> saveTimetable(
    List<Task> tasks,
  ) async {
    final userId = currentUserId;

    if (userId == null) return;

    final prefs = await SharedPreferences.getInstance();

    final timetableKey =
        'firebase_mock_timetable_$userId';

    final historyKey =
        'daily_performance_$userId';

    if (tasks.isNotEmpty) {
      final date = tasks.first.startTime;

      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final historyJson =
          prefs.getString(historyKey) ?? '{}';

      final Map<String, dynamic> history =
          Map<String, dynamic>.from(
        json.decode(historyJson),
      );

      final completed =
          tasks.where((task) => task.isCompleted).length;

      final total = tasks.length;

      history[dateKey] = {
        'date': dateKey,
        'totalTasks': total,
        'completedTasks': completed,
        'incompleteTasks': total - completed,
        'percentage': (completed / total) * 100,
      };

      await prefs.setString(
        historyKey,
        json.encode(history),
      );
    }

    final encoded = json.encode(
      tasks.map((task) => task.toJson()).toList(),
    );

    await prefs.setString(timetableKey, encoded);
  }

  // Get daily performance history.
  static Future<List<Map<String, dynamic>>>
      getDailyPerformanceHistory() async {
    final userId = currentUserId;

    if (userId == null) return [];

    final prefs = await SharedPreferences.getInstance();

    final historyKey =
        'daily_performance_$userId';

    final historyJson = prefs.getString(historyKey);

    if (historyJson == null) return [];

    final Map<String, dynamic> history =
        Map<String, dynamic>.from(
      json.decode(historyJson),
    );

    return history.values
        .map((item) => Map<String, dynamic>.from(item))
        .toList()
      ..sort(
        (a, b) => a['date'].compareTo(b['date']),
      );
  }

  // Load saved timetable.
  static Future<List<Task>> loadTimetable() async {
    final userId = currentUserId;

    if (userId == null) return [];

    final prefs = await SharedPreferences.getInstance();

    final tasksJson = prefs.getString(
      'firebase_mock_timetable_$userId',
    );

    if (tasksJson == null) return [];

    final List<dynamic> decoded = json.decode(tasksJson);

    return decoded
        .map((item) => Task.fromJson(item))
        .toList();
  }

  // Save quiz score.
  static Future<void> saveQuizScore({
    required String topic,
    required int correctCount,
    required int totalQuestions,
    required double scorePercentage,
    required String suggestions,
  }) async {
    final userId = currentUserId;

    if (userId == null) return;

    final prefs = await SharedPreferences.getInstance();

    final key = 'firebase_mock_quiz_$userId';

    final historyJson = prefs.getString(key) ?? '[]';

    final List<dynamic> history = json.decode(historyJson);

    history.add({
      'topic': topic,
      'correctCount': correctCount,
      'totalQuestions': totalQuestions,
      'scorePercentage': scorePercentage,
      'suggestions': suggestions,
      'timestamp': DateTime.now().toIso8601String(),
    });

    await prefs.setString(
      key,
      json.encode(history),
    );
  }

  // Get quiz history.
  static Future<List<Map<String, dynamic>>>
      getQuizHistory() async {
    final userId = currentUserId;

    if (userId == null) return [];

    final prefs = await SharedPreferences.getInstance();

    final key = 'firebase_mock_quiz_$userId';

    final historyJson = prefs.getString(key);

    if (historyJson == null) return [];

    final List<dynamic> decoded = json.decode(historyJson);

    return List<Map<String, dynamic>>.from(decoded);
  }
}
