import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'mock_test/topics_view.dart';
import 'mock_test/quiz_view.dart';
import 'mock_test/self_intro_view.dart';

class MockTestScreen extends StatefulWidget {
  const MockTestScreen({super.key});

  @override
  State<MockTestScreen> createState() => _MockTestScreenState();
}

class _MockTestScreenState extends State<MockTestScreen> {
  int _selectedTabIndex = 0; // 0 for All Topics, 1 for Self Intro
  String? _selectedTopic;

  @override
  Widget build(BuildContext context) {
    if (_selectedTopic != null) {
      return QuizView(
        topic: _selectedTopic!,
        onBack: () {
          setState(() {
            _selectedTopic = null;
          });
        },
      );
    }

    return Column(
      children: [
        _buildHeader(),
        _buildTabBar(),
        Expanded(
          child: _selectedTabIndex == 0
              ? TopicsView(
                  onTopicSelected: (topic) {
                    setState(() {
                      _selectedTopic = topic;
                    });
                  },
                )
              : const SelfIntroView(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 48, left: 24, right: 24, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // const Text(
          //   '9:41',
          //   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          // ),
          // const Icon(Icons.more_horiz, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Row(
        children: [
          _buildTabButton(0, 'All Topics'),
          const SizedBox(width: 12),
          _buildTabButton(1, 'Self Intro'),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String title) {
    bool isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [AppColors.accentPurple, AppColors.accentPink])
              : null,
          color: isSelected ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
