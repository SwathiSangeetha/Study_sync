import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../services/firebase_service.dart';
import '../theme/app_colors.dart';
import '../widgets/gradient_widgets.dart';
import '../services/motivation_service.dart';
import 'todo_screen.dart';

class HomeScreen extends StatefulWidget {
  final List<Task> tasks;
  final Function(List<Task>) onTasksChanged;

  const HomeScreen({super.key, required this.tasks, required this.onTasksChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin 
{
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Future<MotivationQuote> _quoteFuture;

  @override
  void initState() {
    super.initState();
    _quoteFuture = MotivationService.getDailyQuote();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Task? _getActiveTask() {
    final now = DateTime.now();
    try {
      return widget.tasks.firstWhere(
        (task) => now.isAfter(task.startTime) && now.isBefore(task.endTime),
      );
    } catch (_) {
      return null;
    }
  }

  double _getCompletionProgress() {
    if (widget.tasks.isEmpty) return 0.0;
    final completedCount = widget.tasks.where((t) => t.isCompleted).length;
    return completedCount / widget.tasks.length;
  }

  @override
  Widget build(BuildContext context) {
    final activeTask = _getActiveTask();
    final progress = _getCompletionProgress();
    final completedCount = widget.tasks.where((t) => t.isCompleted).length;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
             const SizedBox(height: 20),
            _buildMotivationCard(
             completed: completedCount,
             total: widget.tasks.length,
             ),
            const SizedBox(height: 24),
            _buildStreakPill(),
            const SizedBox(height: 40),
            _buildStatsGrid(completedCount),
            const SizedBox(height: 32),
            _buildAnimatedProgress(progress),
            const SizedBox(height: 40),
            _buildSectionTitle('SESSIONS NOW'),
            const SizedBox(height: 16),
            _buildHorizontalSlots(activeTask),
            const SizedBox(height: 40),
            _buildAIInsight(),
            const SizedBox(height: 40),
            _buildSectionTitle('NEXT UP'),
            const SizedBox(height: 16),
            _buildSessionsList(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

Widget _buildHeader() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WELCOME BACK,',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            GradientText(
              (FirebaseService.currentUserName ?? 'STUDENT')
                  .toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
          ],
        ),
      ),

      // To-Do shortcut
      Container(
        decoration: BoxDecoration(
          color: AppColors.accentPurple.withOpacity(0.12),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.accentPurple.withOpacity(0.3),
          ),
        ),
        child: IconButton(
          tooltip: 'My To-Do List',
          icon: const Icon(
            Icons.checklist_rounded,
            color: AppColors.accentPurple,
            size: 24,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TodoScreen(),
              ),
            );
          },
        ),
      ),

      const SizedBox(width: 8),

      // Logout button
      Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.03),
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
          ),
        ),
        child: IconButton(
          icon: const Icon(
            Icons.logout_rounded,
            color: AppColors.accentPink,
            size: 20,
          ),
          onPressed: () async {
            await FirebaseService.signOut();
          },
        ),
      ),
    ],
  );
}


  Widget _buildStreakPill() {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(30),
          boxShadow: AppColors.glowShadow(AppColors.accentPurple),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              '7 DAY STREAK',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(int completed) {
    return Row(
      children: [
        Expanded(child: _buildStatCard('SESSIONS', '$completed', Icons.check_circle_outline)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('REMAINING', '${widget.tasks.length - completed}', Icons.timer_outlined)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accentPurple, size: 24),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedProgress(double progress) {
    return GlassContainer(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Daily Goal', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${(progress * 100).toInt()}%', style: const TextStyle(color: AppColors.accentPink, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 10,
                  backgroundColor: Colors.white.withOpacity(0.05),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentPurple),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: AppColors.textSecondary.withOpacity(0.5),
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildHorizontalSlots(Task? activeTask) {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.tasks.length,
        itemBuilder: (context, index) {
          final task = widget.tasks[index];
          final isNow = task == activeTask;
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isNow ? AppColors.accentPurple : AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: isNow ? AppColors.glowShadow(AppColors.accentPurple) : null,
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isNow)
                  const Text('NOW', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                Text(
                  task.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('h:mm a').format(task.startTime),
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAIInsight() {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(32),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentPink.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.psychology_outlined, color: AppColors.accentPink),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI INSIGHT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(
                  'Your focus peak is usually around 10:00 AM. Try doing hard subjects then!',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsList() {
    final remainingTasks = widget.tasks.where((t) => !t.isCompleted).toList();
    if (remainingTasks.isEmpty) return const Center(child: Text('All done for today! 🎉'));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: remainingTasks.length,
      itemBuilder: (context, index) {
        final task = remainingTasks[index];
        return GestureDetector(
          onTap: () {
            final updatedTasks = widget.tasks.map((t) {
              if (t.id == task.id) {
                return Task(
                     id: t.id,
                     title: t.title,
                     startTime: t.startTime,
                     endTime: t.endTime,
                     colorIndex: t.colorIndex,
                     isCompleted: !t.isCompleted,
                     completedAt: !t.isCompleted ? DateTime.now() : null,
                  );
              }
              return t;
            }).toList();
            widget.onTasksChanged(updatedTasks);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.03)),
            ),
            child: Row(
              children: [
                const Icon(Icons.book_rounded, color: AppColors.accentPurple),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                        '${DateFormat('h:mm a').format(task.startTime)} - ${DateFormat('h:mm a').format(task.endTime)}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(
                  task.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: task.isCompleted ? AppColors.accentPink : AppColors.textSecondary.withOpacity(0.3),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

Widget _buildMotivationCard({
  required int completed,
  required int total,
}) {
  return FutureBuilder<MotivationQuote>(
    future: _quoteFuture,
    builder: (context, snapshot) {
      final quote = snapshot.data;

      return GlassContainer(
        padding: const EdgeInsets.all(22),
        borderRadius: BorderRadius.circular(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.accentPurple,
                ),
                const SizedBox(width: 8),
                const Text(
                  'DAILY INSPIRATION',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1.3,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            if (quote == null)
              const Center(
                child: CircularProgressIndicator(),
              )
            else ...[
              Text(
                '“${quote.text}”',
                style: GoogleFonts.outfit(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                '— ${quote.author}',
                style: const TextStyle(
                  color: AppColors.accentPink,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),

              if (quote.meaning != null) ...[
                const SizedBox(height: 10),
                Text(
                  quote.meaning!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ],

            const SizedBox(height: 20),

            Container(
              height: 1,
              color: Colors.white.withOpacity(0.08),
            ),

            const SizedBox(height: 16),

            const Text(
              'YOUR PERSONAL MOTIVATION',
              style: TextStyle(
                color: AppColors.accentPurple,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              MotivationService.getPerformanceMessage(
                completed: completed,
                total: total,
              ),
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    },
  );
}

}
