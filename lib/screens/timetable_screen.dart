import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../theme/app_colors.dart';
import '../widgets/gradient_widgets.dart';

class TimetableScreen extends StatefulWidget {
  final List<Task> tasks;
  final Function(List<Task>) onTasksChanged;

  const TimetableScreen({super.key, required this.tasks, required this.onTasksChanged});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> with TickerProviderStateMixin {
  int _selectedDayIndex = DateTime.now().weekday - 1; 
  late List<AnimationController> _cardControllers;

  @override
  void initState() {
    super.initState();
    _initCardControllers();
    _startCardAnimations();
  }

  @override
  void didUpdateWidget(covariant TimetableScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tasks != oldWidget.tasks) {
      _startCardAnimations();
    }
  }

  void _initCardControllers() {
    _cardControllers = List.generate(
      30, // max tasks
      (index) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 300 + (index * 50)),
      ),
    );
  }

  void _startCardAnimations() {
    for (var controller in _cardControllers) {
      controller.reset();
      controller.forward();
    }
  }

  @override
  void dispose() {
    for (var controller in _cardControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Calculate dynamic progress for the week based on tasks
  List<double> get _dynamicGraphValues {
    if (widget.tasks.isEmpty) return [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1];
    
    // In a real app we would map tasks to days of the week, but since our mock engine
    // just generates for "today", we will mock the consistency graph.
    int completed = widget.tasks.where((t) => t.isCompleted).length;
    double progress = widget.tasks.isNotEmpty ? completed / widget.tasks.length : 0.1;
    
    List<double> values = [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1];
    values[_selectedDayIndex] = progress < 0.1 ? 0.1 : progress; // current day real progress
    
    // mock other days to look nice
    for(int i=0; i<7; i++) {
       if (i != _selectedDayIndex) values[i] = (i % 2 == 0) ? 0.6 : 0.3;
    }
    return values;
  }

  @override
  Widget build(BuildContext context) {
    int completedTasks = widget.tasks.where((t) => t.isCompleted).length;
    int totalTasks = widget.tasks.length;
    double dailyProgress = totalTasks == 0 ? 0.0 : completedTasks / totalTasks;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Week of May 16 – 22', // Mocked date
                style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              const GradientText(
                'Timetable',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              Text(
                'CONSISTENCY GRAPH',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              _buildBarChart(),
              const SizedBox(height: 24),
              _buildDaySelector(),
              const SizedBox(height: 40),
              
              if (widget.tasks.isEmpty)
                 _buildEmptyState()
              else ...[
                _buildDailyProgress(completedTasks, totalTasks, dailyProgress),
                const SizedBox(height: 24),
                Text(
                  'TODAY • ${widget.tasks.length} SESSIONS',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSessionList(),
              ],
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.event_busy_rounded, size: 80, color: AppColors.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text(
            'No schedule for today',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Go to the Setup tab to build your perfect plan.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyProgress(int completed, int total, double progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daily Progress',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                '$completed / $total completed',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.white.withOpacity(0.05),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9B5DE5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final values = _dynamicGraphValues;

    return Container(
      height: 160,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.02)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          bool isSelected = index == _selectedDayIndex;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: values[index]),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Container(
                    width: 32,
                    height: 80 * value,
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFFF15BB5), Color(0xFF9B5DE5)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            )
                          : null,
                      color: isSelected ? null : Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFFF15BB5).withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : null,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Text(
                days[index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? const Color(0xFFF15BB5) : AppColors.textSecondary,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildDaySelector() {
    final days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final dates = ['16', '17', '18', '19', '20', '21', '22'];

    return SizedBox(
      height: 85,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, index) {
          bool isSelected = _selectedDayIndex == index;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedDayIndex = index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 12),
              width: 65,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFFF15BB5), Color(0xFF9B5DE5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFFF15BB5).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    days[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dates[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSessionList() {
    final now = DateTime.now();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.tasks.length,
      itemBuilder: (context, index) {
        final task = widget.tasks[index];
        final controller = index < _cardControllers.length 
            ? _cardControllers[index] 
            : _cardControllers.last;
        
        final duration = task.endTime.difference(task.startTime);
        final durationText = '${duration.inMinutes} min session';

        IconData iconData;
        Color iconBgColor;
        switch (task.colorIndex % 4) {
          case 0:
            iconData = Icons.menu_book_rounded;
            iconBgColor = const Color(0xFF202244); 
            break;
          case 1:
            iconData = Icons.park_rounded;
            iconBgColor = const Color(0xFF1F3528); 
            break;
          case 2:
            iconData = Icons.bolt_rounded;
            iconBgColor = const Color(0xFF381F26); 
            break;
          case 3:
            iconData = Icons.grid_view_rounded;
            iconBgColor = const Color(0xFF291E36); 
            break;
          default:
            iconData = Icons.book;
            iconBgColor = const Color(0xFF202244);
        }

        Color iconColor;
        switch(task.colorIndex % 4) {
           case 0: iconColor = Colors.blue[300]!; break;
           case 1: iconColor = Colors.green[400]!; break;
           case 2: iconColor = Colors.orange[400]!; break;
           case 3: iconColor = Colors.pink[300]!; break;
           default: iconColor = Colors.white;
        }

        bool isNow = now.isAfter(task.startTime) && now.isBefore(task.endTime);

        String statusText;
        Color statusColor;
        Color statusBgColor;
        
        if (task.isCompleted) {
          statusText = 'Done ✓';
          statusColor = AppColors.textSecondary;
          statusBgColor = Colors.transparent;
        } else if (isNow) { 
          statusText = 'Now';
          statusColor = const Color(0xFF9B5DE5);
          statusBgColor = const Color(0xFF9B5DE5).withOpacity(0.15);
        } else if (now.isAfter(task.endTime)) {
          statusText = 'Missed';
          statusColor = Colors.redAccent;
          statusBgColor = Colors.redAccent.withOpacity(0.15);
        } else {
          statusText = 'Up Next';
          statusColor = const Color(0xFFF15BB5);
          statusBgColor = const Color(0xFFF15BB5).withOpacity(0.15);
        }

        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.2, 0), end: Offset.zero).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeOut),
          ),
          child: FadeTransition(
            opacity: controller,
            child: GestureDetector(
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
                    );
                  }
                  return t;
                }).toList();
                widget.onTasksChanged(updatedTasks);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isNow ? const Color(0xFF9B5DE5).withOpacity(0.5) : Colors.white.withOpacity(0.05),
                    width: isNow ? 2 : 1,
                  ),
                  boxShadow: isNow ? [
                    BoxShadow(color: const Color(0xFF9B5DE5).withOpacity(0.2), blurRadius: 10, spreadRadius: 2)
                  ] : null,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 65,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('h:mm a').format(task.startTime),
                            style: TextStyle(
                              color: isNow ? Colors.white : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: isNow ? FontWeight.bold : FontWeight.w600,
                            ),
                          ),
                          Container(
                            height: 16,
                            width: 2,
                            color: const Color(0xFF9B5DE5).withOpacity(0.5),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                          ),
                          Text(
                            DateFormat('h:mm a').format(task.endTime),
                            style: TextStyle(
                              color: isNow ? Colors.white : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: isNow ? FontWeight.bold : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: task.isCompleted ? AppColors.surface : iconBgColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(iconData, color: task.isCompleted ? AppColors.textSecondary : iconColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: TextStyle(
                              color: task.isCompleted ? AppColors.textSecondary : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            durationText,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: statusBgColor == Colors.transparent
                            ? Border.all(color: AppColors.textSecondary.withOpacity(0.3))
                            : Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
