import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/gradient_widgets.dart';

class QuizView extends StatefulWidget {
  final String topic;
  final VoidCallback onBack;

  const QuizView({super.key, required this.topic, required this.onBack});

  @override
  State<QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<QuizView> with TickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  int _score = 0;
  int? _selectedOption;
  bool _showResult = false;
  late AnimationController _timerController;
  
  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // Results & AI suggestions
  bool _showResultsPage = false;
  bool _isAiLoading = false;
  String _aiRecommendation = '';
  final bool _hasAiError = false;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(minutes: 5), // Will start after loading
    )..addStatusListener((status) {
        if (status == AnimationStatus.dismissed) {
          _finishQuiz();
        }
      });
    _generateQuestions();
  }

  Future<void> _generateQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      const apiKey = String.fromEnvironment('GEMINI_API_KEY');
      if (apiKey.isEmpty) {
        throw StateError('GEMINI_API_KEY is not configured.');
      }
      final model = GenerativeModel(model: 'gemini-3.8-flash', apiKey: apiKey);
      
      final prompt = '''
      Generate exactly 15 multiple-choice questions for a placement exam on the topic: "${widget.topic}".
      Return ONLY a strict JSON array containing objects. Do not include markdown formatting like ```json or any other text.
      Each object must have exactly these keys:
      - "question": (string) the question text
      - "options": (array of 4 strings) the four possible answers
      - "answer": (integer 0 to 3) the index of the correct option in the options array
      ''';

      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      
      // Clean up markdown block if the model ignores the strict instruction
      String cleanedJson = text.trim();
      if (cleanedJson.startsWith('```json')) {
        cleanedJson = cleanedJson.substring(7);
      } else if (cleanedJson.startsWith('```')) {
        cleanedJson = cleanedJson.substring(3);
      }
      if (cleanedJson.endsWith('```')) {
        cleanedJson = cleanedJson.substring(0, cleanedJson.length - 3);
      }
      
      final List<dynamic> jsonList = jsonDecode(cleanedJson.trim());
      
      if (mounted) {
        setState(() {
          _questions = jsonList.map((item) => {
            'question': item['question'] as String,
            'options': List<String>.from(item['options']),
            'answer': item['answer'] as int,
          }).toList();
          _isLoading = false;
        });
        _timerController.reverse(from: 1.0); // Start timer once loaded
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to generate questions. Please try again.\nError: ${e.toString()}';
        });
      }
    }
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedOption = null;
        _showResult = false;
      });
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() {
    _timerController.stop();
    setState(() {
      _showResultsPage = true;
    });
    _fetchAiSuggestions();
  }

  Future<void> _fetchAiSuggestions() async {
    final correctCount = _score ~/ 10;
    final percentage = (correctCount / 15.0) * 100;

    setState(() {
      _isAiLoading = true;
    });

    try {
      const apiKey = String.fromEnvironment('GEMINI_API_KEY');
      if (apiKey.isEmpty) {
        throw StateError('GEMINI_API_KEY is not configured.');
      }

      final model = GenerativeModel(model: 'gemini-3.8-flash', apiKey: apiKey);

      final prompt = '''
You are a supportive placement-exam coach. Give short feedback for this quiz.

Topic: "${widget.topic}"
Correct answers: $correctCount out of 15
Percentage: ${percentage.toStringAsFixed(1)}%

Rules:
- If the student performed well (70% or above), congratulate them warmly, mention what this result demonstrates, and do not invent improvement areas. Give at most one optional next-step practice tip.
- If the score is below 70%, begin with one encouraging sentence and then give ONLY the three most important, specific areas to improve.
- Never give more than three improvement points.
- Keep the complete response concise and easy to scan.
- Avoid long paragraphs, repetitive advice, harsh language, and generic criticism.
- Do not claim the student has mastered a topic unless the score supports it.
''';

      final response = await model.generateContent([Content.text(prompt)]);

      if (mounted) {
        setState(() {
          _aiRecommendation = response.text?.trim().isNotEmpty == true
              ? response.text!.trim()
              : (percentage >= 70
                  ? 'Super work! You performed well. Keep practising to maintain your progress!'
                  : 'Good effort! Review the questions you missed and practise the topic again.');
          _isAiLoading = false;
        });

        await FirebaseService.saveQuizScore(
          topic: widget.topic,
          correctCount: correctCount,
          totalQuestions: 15,
          scorePercentage: percentage,
          suggestions: _aiRecommendation,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiRecommendation = percentage >= 70
              ? 'Great work! You performed well in this mock test. Keep practising to maintain your progress. Personalized AI feedback could not be loaded.'
              : 'Good effort for completing the mock test. Review the questions you missed and practise the topic again. Personalized AI feedback could not be loaded.';
          _isAiLoading = false;
        });

        // Save the result even when Gemini is unavailable.
        await FirebaseService.saveQuizScore(
          topic: widget.topic,
          correctCount: correctCount,
          totalQuestions: 15,
          scorePercentage: percentage,
          suggestions: _aiRecommendation,
        );
      }
    }
  }

  Widget _buildResultsScreen() {
    final correctCount = _score ~/ 10;
    final incorrectCount = 15 - correctCount;
    final percentage = (correctCount / 15.0) * 100;
    final isPassed = percentage >= 60.0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                  onPressed: widget.onBack,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const GradientText(
                        'Exam Results',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        widget.topic,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Performance Circle
            Center(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  border: Border.all(
                    color: isPassed ? Colors.greenAccent.withOpacity(0.3) : AppColors.accentPink.withOpacity(0.3),
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isPassed ? Colors.greenAccent : AppColors.accentPink).withOpacity(0.15),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isPassed ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded,
                      color: isPassed ? Colors.greenAccent : AppColors.accentPink,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: GoogleFonts.outfit(
                        fontSize: 44,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      isPassed ? 'TEST PASSED' : 'NEED MORE STUDY',
                      style: GoogleFonts.outfit(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: isPassed ? Colors.greenAccent : AppColors.accentPink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Scoreboard Grid
            Row(
              children: [
                Expanded(
                  child: GlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 24),
                        const SizedBox(height: 8),
                        Text(
                          '$correctCount / 15',
                          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const Text('CORRECT', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 24),
                        const SizedBox(height: 8),
                        Text(
                          '$incorrectCount / 15',
                          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const Text('INCORRECT', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Score display
            GlassContainer(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Score Earned', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(
                    '$_score / 150 Points',
                    style: GoogleFonts.outfit(
                      color: AppColors.accentPurple,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // AI Recommendations Header
            Row(
              children: [
                const Icon(Icons.psychology_rounded, color: AppColors.accentPink, size: 24),
                const SizedBox(width: 10),
                Text(
                  'AI TUTOR SUGGESTIONS',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: AppColors.accentPink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // AI Recommendations Box
            _isAiLoading
                ? GlassContainer(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const CircularProgressIndicator(color: AppColors.accentPink),
                        const SizedBox(height: 16),
                        Text(
                          'AI Tutor is evaluating your answers and generating personalized suggestions...',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : GlassContainer(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      _aiRecommendation,
                      style: GoogleFonts.outfit(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14.5,
                        height: 1.5,
                      ),
                    ),
                  ),
            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _currentQuestionIndex = 0;
                          _score = 0;
                          _selectedOption = null;
                          _showResult = false;
                          _showResultsPage = false;
                          _aiRecommendation = '';
                        });
                        _generateQuestions();
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('RETAKE EXAM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: AppColors.primaryGradient,
                    ),
                    child: ElevatedButton(
                      onPressed: widget.onBack,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('BACK TO TOPICS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showResultsPage) {
      return _buildResultsScreen();
    }

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.accentPurple),
            const SizedBox(height: 24),
            Text(
              'AI is generating 15 questions for\n${widget.topic}...',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _generateQuestions,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentPurple),
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Center(
        child: Text('No questions available', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    
    final question = _questions[_currentQuestionIndex];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 40),
            _buildTimerSection(),
            const SizedBox(height: 40),
            _buildStatsRow(),
            const SizedBox(height: 40),
            _buildQuestionCard(question),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
              onPressed: widget.onBack,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GradientText(
                  'Mock Test',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
                ),
                Text(
                  'Topic: ${widget.topic}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.info_outline_rounded, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildTimerSection() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 180,
            height: 180,
            child: AnimatedBuilder(
              animation: _timerController,
              builder: (context, child) {
                return CustomPaint(
                  painter: TimerPainter(
                    progress: _timerController.value,
                    color: AppColors.accentPurple,
                  ),
                );
              },
            ),
          ),
          Column(
            children: [
              AnimatedBuilder(
                animation: _timerController,
                builder: (context, child) {
                  int totalSeconds = (_timerController.value * 300).toInt();
                  int minutes = totalSeconds ~/ 60;
                  int seconds = totalSeconds % 60;
                  return Text(
                    '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
              const Text('TIME LEFT', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, letterSpacing: 1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildCountingStat('SCORE', _score, AppColors.accentPurple)),
        const SizedBox(width: 16),
        Expanded(child: _buildCountingStat('QUESTION', _currentQuestionIndex + 1, AppColors.accentPink)),
      ],
    );
  }

  Widget _buildCountingStat(String label, int value, Color color) {
    return GlassContainer(
      child: Column(
        children: [
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: value),
            duration: const Duration(milliseconds: 600),
            builder: (context, val, child) {
              return Text(
                '$val',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              );
            },
          ),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Column(
        key: ValueKey(_currentQuestionIndex),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question['question'],
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.5),
          ),
          const SizedBox(height: 24),
          ...List.generate(question['options'].length, (index) {
            bool isSelected = _selectedOption == index;
            bool isCorrect = index == question['answer'];
            Color bgColor = AppColors.surface;
            if (_showResult) {
              if (isCorrect) {
                bgColor = Colors.green.withOpacity(0.2);
              } else if (isSelected) bgColor = Colors.red.withOpacity(0.2);
            } else if (isSelected) {
              bgColor = AppColors.accentPurple.withOpacity(0.2);
            }

            return GestureDetector(
              onTap: _showResult ? null : () {
                setState(() {
                  _selectedOption = index;
                  _showResult = true;
                  if (index == question['answer']) _score += 10;
                });
                Future.delayed(const Duration(seconds: 1), _nextQuestion);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _showResult && isCorrect 
                        ? Colors.green 
                        : (_showResult && isSelected ? Colors.red : Colors.white.withOpacity(0.05)),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      String.fromCharCode(65 + index),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        question['options'][index],
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    if (_showResult && isCorrect)
                      const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                    if (_showResult && isSelected && !isCorrect)
                      const Icon(Icons.cancel_rounded, color: Colors.red, size: 20),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class TimerPainter extends CustomPainter {
  final double progress;
  final Color color;

  TimerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, paint);

    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708, // Start at top
      6.28319 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant TimerPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
