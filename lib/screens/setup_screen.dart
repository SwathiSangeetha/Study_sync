import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../models/subject_model.dart';
import '../theme/app_colors.dart';
import '../widgets/gradient_widgets.dart';
import '../utils/timetable_engine.dart';

class SetupScreen extends StatefulWidget {
  final List<Task> tasks;
  final Function(List<Task>) onTasksChanged;
  final VoidCallback onGenerateComplete;

  const SetupScreen({
    super.key, 
    required this.tasks, 
    required this.onTasksChanged,
    required this.onGenerateComplete,
  });

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  double _dailyHours = 6.0;
  String _prepGoal = 'Exams';
  int _freeTimeMinutes = 15;

  TimeOfDay _wakeUpTime = const TimeOfDay(hour: 6, minute: 30);
  TimeOfDay _bedTime = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _lunchTime = const TimeOfDay(hour: 13, minute: 0);
  TimeOfDay _dinnerTime = const TimeOfDay(hour: 19, minute: 30);

  final TextEditingController _subjectController = TextEditingController();

  final List<Subject> _subjects = [
    Subject(id: '1', name: 'DS', durationMinutes: 60, emoji: '🌳', isActive: true),
    Subject(id: '2', name: 'Algorithms', durationMinutes: 60, emoji: '⚡', isActive: true),
    Subject(id: '3', name: 'OS', durationMinutes: 60, emoji: '📘', isActive: true),
    Subject(id: '4', name: 'DBMS', durationMinutes: 60, emoji: '🗄️', isActive: true),
    Subject(id: '5', name: 'MAD', durationMinutes: 60, emoji: '📱', isActive: true),
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
  }

  void _generateTimetable() {
    final newTasks = TimetableEngine.generate(
      dailyHours: _dailyHours,
      subjects: _subjects,
      wakeUpTime: _wakeUpTime,
      lunchTime: _lunchTime,
      dinnerTime: _dinnerTime,
      restMins: _freeTimeMinutes,
    );
    widget.onTasksChanged(newTasks);
    widget.onGenerateComplete();
  }

  Future<void> _selectTime(BuildContext context, TimeOfDay initialTime, Function(TimeOfDay) onSelected) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFF15BB5),
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E2C),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        onSelected(picked);
      });
    }
  }

  void _addSubject() {
    if (_subjectController.text.trim().isNotEmpty) {
      setState(() {
        _subjects.add(Subject(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _subjectController.text.trim(),
          durationMinutes: 60,
          emoji: '📚', // Default emoji
          isActive: true,
        ));
        _subjectController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildBuildYourPlanHeader(),
              const SizedBox(height: 32),
              
              _buildSectionTitle('SUBJECTS'),
              const SizedBox(height: 16),
              _buildSubjectsSection(),
              const SizedBox(height: 32),
              
              _buildSectionTitle('DAILY SCHEDULE'),
              const SizedBox(height: 16),
              _buildDailySchedule(),
              const SizedBox(height: 32),
              
              _buildSectionTitle('DAILY STUDY HOURS'),
              const SizedBox(height: 16),
              _buildDailyStudyHours(),
              const SizedBox(height: 32),
              
              _buildSectionTitle('PREP GOAL'),
              const SizedBox(height: 16),
              _buildPrepGoalSection(),
              const SizedBox(height: 32),
              
              _buildSmartNotifications(),
              const SizedBox(height: 32),
              
              _buildActionButtons(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildBuildYourPlanHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Build Your Plan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF9B5DE5).withOpacity(0.5)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.auto_awesome, color: Color(0xFFF15BB5), size: 14),
                  SizedBox(width: 4),
                  Text(
                    'AI-powered',
                    style: TextStyle(
                      color: Color(0xFF9B5DE5),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'AI analyses your schedule and creates the perfect timetable',
          style: TextStyle(
            color: AppColors.textSecondary.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 12,
          children: _subjects.map((subject) {
            bool isSelected = subject.isActive;
            return GestureDetector(
              onTap: () {
                setState(() {
                  subject = subject.copyWith(isActive: !subject.isActive);
                  int idx = _subjects.indexWhere((s) => s.id == subject.id);
                  _subjects[idx] = subject;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF9B5DE5).withOpacity(0.5) : Colors.white.withOpacity(0.05),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(subject.emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      subject.name,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Center(
                  child: TextField(
                    controller: _subjectController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Add subject...',
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addSubject(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _addSubject,
              child: Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF15BB5), Color(0xFF9B5DE5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF15BB5).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDailySchedule() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildScheduleItem('🌅', 'Wake up', _wakeUpTime, (t) => _wakeUpTime = t),
              ),
              Expanded(
                child: _buildScheduleItem('😴', 'Bedtime', _bedTime, (t) => _bedTime = t),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildScheduleItem('🍽️', 'Lunch', _lunchTime, (t) => _lunchTime = t),
              ),
              Expanded(
                child: _buildScheduleItem('🌙', 'Dinner', _dinnerTime, (t) => _dinnerTime = t),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white12),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('☕', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Text(
                    'Free Time (Breaks)',
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (_freeTimeMinutes > 5) setState(() => _freeTimeMinutes -= 5);
                    },
                    child: const Icon(Icons.remove_circle_outline, color: AppColors.accentPink),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$_freeTimeMinutes min',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      if (_freeTimeMinutes < 60) setState(() => _freeTimeMinutes += 5);
                    },
                    child: const Icon(Icons.add_circle_outline, color: AppColors.accentPurple),
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildScheduleItem(String emoji, String title, TimeOfDay time, Function(TimeOfDay) onUpdate) {
    final dt = DateTime(2022, 1, 1, time.hour, time.minute);
    final timeStr = DateFormat('hh:mm a').format(dt); 

    return GestureDetector(
      onTap: () => _selectTime(context, time, onUpdate),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                timeStr.substring(0, 5),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                timeStr.substring(6),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              const Icon(Icons.access_time_rounded, color: AppColors.textSecondary, size: 16),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyStudyHours() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF9B5DE5),
                inactiveTrackColor: Colors.white.withOpacity(0.1),
                thumbColor: const Color(0xFF9B5DE5),
                trackHeight: 6,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              ),
              child: Slider(
                value: _dailyHours,
                min: 1,
                max: 12,
                onChanged: (val) {
                  setState(() {
                    _dailyHours = val;
                  });
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          GradientText(
            '${_dailyHours.toInt()}h',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            gradient: const LinearGradient(
              colors: [Color(0xFFF15BB5), Color(0xFF9B5DE5)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrepGoalSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildPrepCard('🏢', 'Placement', 'Tech interviews', _prepGoal == 'Placement')),
            const SizedBox(width: 16),
            Expanded(child: _buildPrepCard('📝', 'Exams', 'University', _prepGoal == 'Exams')),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildPrepCard('🎯', 'Both', 'Mixed prep', _prepGoal == 'Both')),
            const SizedBox(width: 16),
            Expanded(child: _buildPrepCard('🚀', 'GATE / GRE', 'Competitive', _prepGoal == 'GATE / GRE')),
          ],
        ),
      ],
    );
  }

  Widget _buildPrepCard(String emoji, String title, String subtitle, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _prepGoal = title;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF9B5DE5).withOpacity(0.5) : Colors.white.withOpacity(0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartNotifications() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_rounded, color: Colors.amber, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Smart notifications on',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  '5-min warning + start alert + daily streak reminder.',
                  style: TextStyle(color: AppColors.textSecondary.withOpacity(0.8), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF9B5DE5), Color(0xFFF15BB5)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF15BB5).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _generateTimetable,
              borderRadius: BorderRadius.circular(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Generate AI Timetable',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _dailyHours = 6.0;
                  _prepGoal = 'Exams';
                  _freeTimeMinutes = 15;
                  for (var i = 0; i < _subjects.length; i++) {
                     _subjects[i] = _subjects[i].copyWith(isActive: true);
                  }
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.refresh_rounded, color: AppColors.textSecondary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Reset Defaults',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
