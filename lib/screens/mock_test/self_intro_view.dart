import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../theme/app_colors.dart';
import '../../widgets/gradient_widgets.dart';

class SelfIntroView extends StatefulWidget {
  const SelfIntroView({super.key});

  @override
  State<SelfIntroView> createState() => _SelfIntroViewState();
}

class _SelfIntroViewState extends State<SelfIntroView> with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _timer;
  late AnimationController _pulseController;
  
  bool _showAnalysis = false;
  bool _isAnalyzing = false;
  
  // Real AI and Speech variables
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechEnabled = false;
  String _speechStatusText = 'Initializing speech engine...';
  String _recognizedText = '';
  String _aiFeedback = '';
  String? _speechError;
  
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _initSpeech();
  }

  void _initSpeech() async {
    try {
      _speechEnabled = await _speech.initialize(
        onError: (val) {
          print('Speech Error: ${val.errorMsg}');
          setState(() {
            _isRecording = false;
            _timer?.cancel();
            _speechError = val.errorMsg;
          });
        },
        onStatus: (val) {
          print('Speech Status: $val');
          if (_speechError == null) {
            setState(() {
              if (val == 'listening') {
                _speechStatusText = 'Listening... Speak clearly!';
              } else if (val == 'notListening') {
                _speechStatusText = 'Stopped listening.';
              }
            });
          }
        },
      );
      setState(() {
        if (_speechEnabled) {
          _speechStatusText = 'Speech engine ready. Tap the mic to record!';
        } else {
          _speechStatusText = 'Speech recognition not supported on this browser. You can type below!';
        }
      });
    } catch (e) {
      setState(() {
        _speechEnabled = false;
        _speechStatusText = 'Speech engine initialization failed. You can type below!';
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _speech.stop();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _analyzeWithGemini() async {
    final text = _textController.text;
    
    if (text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please record or type your introduction first!')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _showAnalysis = false;
      _aiFeedback = '';
    });

    // Hardcoded API key for direct access
    const apiKey = 'AIzaSyDQrvm-rcoej5KjDBRivKuZuELgp_C-Roc';
    
    try {
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
      final prompt = 'You are an expert HR interviewer. Analyze this short self-introduction and provide 2-3 quick, constructive tips on clarity, content, and pacing. Keep it very concise (bullet points). Here is the introduction: "$text"';
      
      final response = await model.generateContent([Content.text(prompt)]);
      
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _showAnalysis = true;
          _aiFeedback = response.text ?? 'No feedback generated.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _showAnalysis = true;
          _aiFeedback = 'Error connecting to AI. Please check your internet connection or try again later.';
        });
      }
    }
  }

  void _toggleRecording() async {
    if (_isRecording) {
      // Stop recording
      _timer?.cancel();
      await _speech.stop();
      
      setState(() {
        _isRecording = false;
        _speechStatusText = 'Recording stopped. Review or edit your introduction below.';
      });
    } else {
      // Check if speech recognition is available
      if (!_speechEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speech recognition is not available. Please type your intro manually!'),
            backgroundColor: AppColors.accentPink,
          ),
        );
        return;
      }
      
      // Start recording
      setState(() {
        _isRecording = true;
        _recordSeconds = 0;
        _recognizedText = '';
        _speechError = null;
        _textController.clear();
        _speechStatusText = 'Listening... Speak clearly!';
      });
      
      try {
        await _speech.listen(
          onResult: (result) {
            setState(() {
              _recognizedText = result.recognizedWords;
              _textController.text = _recognizedText;
            });
          },
          listenFor: const Duration(minutes: 5), // Maximum intro length
          pauseFor: const Duration(seconds: 30), // Generous 30s pause duration to prevent auto-stopping
          listenMode: stt.ListenMode.dictation, // Continuous dictation optimization for long speech
        );
        
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordSeconds++;
          });
        });
      } catch (e) {
        setState(() {
          _isRecording = false;
          _speechStatusText = 'Failed to start listening: ${e.toString()}';
        });
        _timer?.cancel();
      }
    }
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI-Powered',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const GradientText(
              'Self Introduction',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Record your voice or type your intro manually to receive real-time actionable feedback.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 24),
            _buildRecordingCard(),
            const SizedBox(height: 20),
            _buildTranscriptBox(),
            const SizedBox(height: 24),
            if (_showAnalysis) _buildAnalysisResults() else _buildWhatToInclude(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingCard() {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RECORDING',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppColors.accentPink,
                ),
              ),
              Text(
                _formatTime(_recordSeconds),
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Fake audio visualizer, pulses faster when recording
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(15, (index) {
              return AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  double height = 4 + 
                      ((index % 3 == 0) ? 8 : ((index % 2 == 0) ? 12 : 4)) * 
                      (_isRecording ? _pulseController.value : 0.1);
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 4,
                    height: height,
                    decoration: BoxDecoration(
                      color: _isRecording 
                          ? Colors.redAccent.withOpacity(0.8) 
                          : AppColors.accentPink.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                },
              );
            }),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _toggleRecording,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: _isRecording 
                      ? [Colors.redAccent, Colors.red] 
                      : [AppColors.accentPurple, AppColors.accentPink],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isRecording ? Colors.red : AppColors.accentPink).withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 3,
                  )
                ],
              ),
              child: Icon(
                _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _speechStatusText,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          if (_speechError != null) _buildErrorBanner(),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    String title = 'Speech Recognition Issue';
    String description = 'An unexpected error occurred. Please type your introduction below!';
    IconData icon = Icons.warning_amber_rounded;
    Color color = Colors.orangeAccent;

    if (_speechError == 'network') {
      title = 'Browser Speech Service Network Error';
      description = 'Your browser failed to connect to its speech processing servers. This is very common in Microsoft Edge.\n\n👉 RECOMMENDATION: Run the app in Google Chrome, check your network/VPN, or simply type/edit your self-introduction directly into the transcript box below!';
      icon = Icons.cloud_off_rounded;
      color = Colors.redAccent;
    } else if (_speechError == 'notAllowed' || _speechError == 'permissionBlocked') {
      title = 'Microphone Permission Blocked';
      description = 'Microphone access is disabled in your browser settings.\n\n👉 TO FIX: Click the lock icon in the address bar, enable the microphone, refresh the page, or simply type your introduction manually below!';
      icon = Icons.mic_off_rounded;
      color = Colors.orangeAccent;
    } else if (_speechError == 'no-speech' || _speechError == 'noMatch') {
      title = 'No Speech Detected';
      description = 'The microphone started but did not hear any speech. Please speak louder, adjust your system microphone volume, or type your introduction below!';
      icon = Icons.hearing_disabled_rounded;
      color = Colors.yellowAccent;
    } else {
      title = 'Speech Engine Error: $_speechError';
      description = 'The browser speech engine failed. Please try again or type/edit your introduction manually below!';
    }

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: GoogleFonts.outfit(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptBox() {
    int wordCount = _textController.text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'YOUR TRANSCRIPT / SELF-INTRODUCTION',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppColors.accentPurple,
                ),
              ),
              if (_textController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_rounded, color: AppColors.textSecondary, size: 18),
                  onPressed: () {
                    setState(() {
                      _textController.clear();
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _textController,
            maxLines: null, // Auto-expand horizontally and vertically
            minLines: 4, // Generous initial height
            keyboardType: TextInputType.multiline,
            onChanged: (text) {
              setState(() {}); // Update word count
            },
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
            decoration: const InputDecoration(
              hintText: 'Your spoken words will appear here in real-time...\n\nFeel free to edit them or type your introduction directly if your microphone is not working!',
              hintStyle: TextStyle(color: Colors.white30, fontSize: 14),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
            ),
          ),
          const Divider(color: Colors.white10, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Words: $wordCount / 150',
                style: TextStyle(
                  color: wordCount > 150 ? Colors.redAccent : AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isAnalyzing || _textController.text.trim().isEmpty
                    ? null
                    : _analyzeWithGemini,
                icon: _isAnalyzing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome_rounded, size: 14),
                label: Text(
                  _isAnalyzing ? 'Analyzing...' : 'Analyze with AI',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentPurple,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white10,
                  disabledForegroundColor: Colors.white24,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWhatToInclude() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'WHAT TO INCLUDE',
          style: TextStyle(
            color: AppColors.textSecondary,
            letterSpacing: 1.2,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoCard(Icons.person, 'Name & college', 'Start with who you are and where you\'re from'),
        const SizedBox(height: 12),
        _buildInfoCard(Icons.work, 'Skills & projects', 'Mention your strongest tech stack and key projects'),
        const SizedBox(height: 12),
        _buildInfoCard(Icons.track_changes, 'Goal', 'Why you want this role and what value you bring'),
      ],
    );
  }

  Widget _buildAnalysisResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AI FEEDBACK',
          style: TextStyle(
            color: AppColors.accentPink,
            letterSpacing: 1.2,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
        GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accentPurple.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome, color: AppColors.accentPink, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _aiFeedback, 
                      style: const TextStyle(fontWeight: FontWeight.w500, height: 1.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String subtitle) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accentPurple, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
