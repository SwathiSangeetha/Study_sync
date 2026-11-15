
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart' as firebase;

import 'firebase_options.dart';
import 'models/task_model.dart';
import 'screens/home_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/timetable_screen.dart';
import 'screens/mock_test/self_intro_view.dart';
import 'screens/auth_screen.dart';
import 'services/firebase_service.dart';
import 'theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await firebase.Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);

  // Initialize existing app services
  await FirebaseService.initialize();

  runApp(const StudySyncApp());
}

class StudySyncApp extends StatelessWidget {
  const StudySyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudySync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.accentPurple,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accentPurple,
          brightness: Brightness.dark,
          secondary: AppColors.accentPink,
        ),
        textTheme: GoogleFonts.outfitTextTheme(
          ThemeData.dark().textTheme.apply(
                bodyColor: Colors.white,
                displayColor: Colors.white,
              ),
        ),
        useMaterial3: true,
      ),
      home: StreamBuilder<String?>(
        stream: FirebaseService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  color: AppColors.accentPurple,
                ),
              ),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            return const MainScaffold();
          }

          return const AuthScreen();
        },
      ),
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  List<Task> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);

    final tasks = await FirebaseService.loadTimetable();

    if (!mounted) return;

    setState(() {
      _tasks = tasks;
      _isLoading = false;
    });
  }

  Future<void> _saveTasks() async {
    await FirebaseService.saveTimetable(_tasks);
  }

  void _onTasksChanged(List<Task> newTasks) {
    setState(() {
      _tasks = newTasks;
    });

    _saveTasks();
  }

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _currentIndex,
          children: [
            HomeScreen(
              tasks: _tasks,
              onTasksChanged: _onTasksChanged,
            ),
            SetupScreen(
              tasks: _tasks,
              onTasksChanged: _onTasksChanged,
              onGenerateComplete: () => _navigateToTab(2),
            ),
            TimetableScreen(
              tasks: _tasks,
              onTasksChanged: _onTasksChanged,
            ),
            const SelfIntroView(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomNavItem(Icons.home_rounded, 'Home', 0),
          _buildBottomNavItem(Icons.settings_rounded, 'Setup', 1),
          _buildBottomNavItem(Icons.calendar_month_rounded, 'Plan', 2),
          _buildBottomNavItem(
            Icons.record_voice_over_rounded,
            'Self Intro',
            3,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(
    IconData icon,
    String label,
    int index,
  ) {
    bool isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive
                  ? AppColors.accentPurple
                  : AppColors.textSecondary.withOpacity(0.5),
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? Colors.white
                    : AppColors.textSecondary.withOpacity(0.5),
                fontSize: 10,
                fontWeight:
                    isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isActive)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.accentPink,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
