import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/gradient_widgets.dart';

class TopicsView extends StatelessWidget {
  final Function(String) onTopicSelected;

  const TopicsView({super.key, required this.onTopicSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Text(
            'PLACEMENT TOPICS',
            style: TextStyle(
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.95,
            children: [
              _buildTopicCard('Data Structures', '15 questions', '🌳', score: '✓ 87%', color: Colors.green),
              _buildTopicCard('Algorithms', '12 questions', '⚡', color: AppColors.accentPurple),
              _buildTopicCard('OS Concepts', '10 questions', '💻', score: '✓ 73%', color: Colors.green),
              _buildTopicCard('DBMS', '10 questions', '🗄️', color: AppColors.accentPurple),
              _buildTopicCard('Networks', '8 questions', '🌐', color: AppColors.accentPurple),
              _buildTopicCard('Aptitude', '20 questions', '🤖', color: AppColors.accentPurple),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopicCard(String title, String subtitle, String icon, {String? score, required Color color}) {
    bool isCompleted = score != null;
    return GestureDetector(
      onTap: () => onTopicSelected(title),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(icon, style: const TextStyle(fontSize: 28)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green.withOpacity(0.1) : AppColors.accentPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    score ?? 'Attempt',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
