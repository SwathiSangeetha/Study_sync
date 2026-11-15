
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_service.dart';

class MotivationQuote {
  final String text;
  final String author;
  final String? meaning;

  const MotivationQuote({
    required this.text,
    required this.author,
    this.meaning,
  });
}

class MotivationService {
  static const List<MotivationQuote> quotes = [
    MotivationQuote(
      text: 'கற்க கசடறக் கற்பவை கற்றபின் நிற்க அதற்குத் தக.',
      author: 'Thiruvalluvar - Thirukkural 391',
      meaning: 'Learn thoroughly what is worth learning, then live according to what you have learned.',
    ),
    MotivationQuote(
      text: 'கேடில் விழுச்செல்வம் கல்வி ஒருவற்கு மாடல்ல மற்றை யவை.',
      author: 'Thiruvalluvar - Thirukkural 400',
      meaning: 'Education is an imperishable wealth; other forms of wealth cannot compare.',
    ),
    MotivationQuote(
      text: 'You have to dream before your dreams can come true.',
      author: 'A. P. J. Abdul Kalam',
    ),
    MotivationQuote(
      text: 'Dream, dream, dream. Dreams transform into thoughts and thoughts result in action.',
      author: 'A. P. J. Abdul Kalam',
    ),
    MotivationQuote(
      text: 'Life is like riding a bicycle. To keep your balance, you must keep moving.',
      author: 'Albert Einstein',
    ),
    MotivationQuote(
      text: 'The important thing is not to stop questioning.',
      author: 'Albert Einstein',
    ),
    MotivationQuote(
      text: 'Small steps every day create meaningful progress.',
      author: 'StudySync',
    ),
    MotivationQuote(
      text: 'You do not need to be perfect. You need to keep going.',
      author: 'StudySync',
    ),
  ];

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  static Future<MotivationQuote> getDailyQuote() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = FirebaseService.currentUserId ?? 'guest';

    final dateKey = 'motivation_date_$userId';
    final indexKey = 'motivation_index_$userId';
    final usedKey = 'motivation_used_$userId';

    final today = _todayKey();
    final savedDate = prefs.getString(dateKey);
    final savedIndex = prefs.getInt(indexKey);

    if (savedDate == today &&
        savedIndex != null &&
        savedIndex >= 0 &&
        savedIndex < quotes.length) {
      return quotes[savedIndex];
    }

    List<String> used = prefs.getStringList(usedKey) ?? [];

    List<int> available = List.generate(quotes.length, (i) => i)
        .where((i) => !used.contains(i.toString()))
        .toList();

    if (available.isEmpty) {
      used = [];
      available = List.generate(quotes.length, (i) => i);
    }

    final selectedIndex = available[Random().nextInt(available.length)];

    used.add(selectedIndex.toString());

    await prefs.setStringList(usedKey, used);
    await prefs.setString(dateKey, today);
    await prefs.setInt(indexKey, selectedIndex);

    return quotes[selectedIndex];
  }

  static String getPerformanceMessage({
    required int completed,
    required int total,
  }) {
    if (total == 0) {
      return 'Your study journey starts here. Take one small step today!';
    }

    final percentage = completed / total * 100;

    if (completed == total) {
      return 'Amazing work! You completed every planned task. Celebrate your effort!';
    }

    if (percentage >= 70) {
      return 'Wonderful effort! You completed most of your tasks. Keep going!';
    }

    if (percentage >= 40) {
      return 'You made good progress today. Every completed task counts!';
    }

    if (completed > 0) {
      return 'You have already made a start. Take your next small step!';
    }

    return 'A fresh opportunity is waiting. Start with one manageable task!';
  }
}
