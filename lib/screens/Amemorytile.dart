
// import 'dart:async';

import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controllers/settings_controller.dart';
import 'leaderboard_screen.dart';
// import '__settings_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  final Random _random = Random();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isGameOver = false;
  bool _isAppActive = true;
  bool _showInstructions = true;
  List<int> _sequence = [];
  int _currentStep = 0;
  int _gridSize = 3;
  int _score = 0;
  int _record = 0;
  int? _blinkingIndex;
  bool _isPlayerTurn = false;
  Timer? _timer;
  int _secondsRemaining = 20;
  late ConfettiController _confettiController;

  final List<Color> _gridColors = [
    Colors.cyan,
    Colors.purpleAccent,
    Colors.amber,
    Colors.lightGreen,
    Colors.deepOrangeAccent,
    Colors.lightBlueAccent,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _loadRecord();
    _showTutorial();
  }

  Future<void> _showTutorial() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted && _showInstructions) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildInstructionsDialog(),
      );
    }
  }

  Widget _buildInstructionsDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF2D2D3D) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? Colors.blueAccent : Colors.blue,
          width: 2
        )
      ),
      title: Text(
        'How to Play',
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInstructionStep(
              "1. Watch the sequence",
              "The game will flash colored boxes in a pattern",
              isDark
            ),
            const SizedBox(height: 10),
            _buildInstructionStep(
              "2. Repeat the sequence",
              "Tap the boxes in the same order you saw them",
              isDark
            ),
            const SizedBox(height: 10),
            _buildInstructionStep(
              "3. Advance to next level",
              "Each correct sequence increases your score",
              isDark
            ),
            const SizedBox(height: 10),
            _buildInstructionStep(
              "4. Beat your high score!",
              "Try to remember longer sequences as you progress",
              isDark
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() => _showInstructions = false);
            Navigator.pop(context);
            _startNewGame();
          },
          child: Text(
            'Got it!',
            style: TextStyle(
              color: isDark ? Colors.blueAccent : Colors.blue,
              fontSize: 16
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionStep(String title, String description, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.blueAccent : Colors.blue,
            fontWeight: FontWeight.bold,
            fontSize: 16
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black87,
            fontSize: 14
          ),
        ),
      ],
    );
  }

  void _startNewGame() {
    _sequence.clear();
    _addNextToSequence();
    _playSequence();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _isAppActive = false;
      _audioPlayer.stop();
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      _isAppActive = true;
      if (!_isGameOver && _isPlayerTurn) {
        _startCountdown();
      }
    }
  }

  Future<void> _loadRecord() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    
    final recordKey = user != null ? 'highestScore_${user.uid}' : 'highestScore_guest';
    
    setState(() {
      _record = prefs.getInt(recordKey) ?? 0;
    });
  }

  Future<void> _saveRecord(int newRecord) async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    
    final recordKey = user != null ? 'highestScore_${user.uid}' : 'highestScore_guest';
    
    await prefs.setInt(recordKey, newRecord);
  }

  Future<void> _saveScoreToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = _firestore.collection('users').doc(user.uid);
    final doc = await userDoc.get();
    
    final currentHighScore = doc.exists 
        ? ((doc.data()?['gameStats'] as Map<String, dynamic>?)?['memoryTile']?['highScore'] as int? ?? 0)
        : 0;

    if (_score > currentHighScore) {
      await userDoc.set({
        'username': user.displayName ?? 'Player',
        'profileImageUrl': user.photoURL ?? '',
        'lastUpdated': FieldValue.serverTimestamp(),
        'gameStats': {
          'memoryTile': {
            'highScore': _score,
            'lastPlayed': FieldValue.serverTimestamp(),
          }
        }
      }, SetOptions(merge: true));
    }
  }

  Future<void> resetGame() async {
    setState(() {
      _sequence.clear();
      _score = 0;
      _secondsRemaining = _getInitialTimeForDifficulty();
      _blinkingIndex = null;
      _isPlayerTurn = false;
      _isGameOver = false;
    });
    _startNewGame();
  }

  int _getInitialTimeForDifficulty() {
    const difficulty = "medium";
    switch (difficulty) {
      case "easy":
        return 15;
      case "hard":
        return 30;
      default:
        return 20;
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsRemaining--;
        if (_secondsRemaining <= 0) {
          timer.cancel();
          _onTimeUp();
        }
      });
    });
  }

  Future<void> _playSound(String name) async {
    if (!_isAppActive) return;
    final settings = Provider.of<SettingsController>(context, listen: false);
    if (!settings.soundEffects) return;
    
    try {
      await _audioPlayer.setVolume(settings.volumeLevel);
      await _audioPlayer.play(AssetSource('sounds/$name'));
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  Future<void> _playSequence() async {
    setState(() {
      _isPlayerTurn = false;
      _blinkingIndex = null;
      _currentStep = 0;
    });

    _timer?.cancel();

    await Future.delayed(const Duration(milliseconds: 500));

    for (int i in _sequence) {
      setState(() => _blinkingIndex = i);
      await _playSound('beep.mp3');
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() => _blinkingIndex = null);
      await Future.delayed(const Duration(milliseconds: 300));
    }

    setState(() => _isPlayerTurn = true);
    _startCountdown();
  }

  void _onBoxTap(int index) async {
    if (!_isPlayerTurn || _isGameOver) return;

    setState(() => _blinkingIndex = index);
    await Future.delayed(const Duration(milliseconds: 200));
    setState(() => _blinkingIndex = null);

    if (index == _sequence[_currentStep]) {
      await _playSound('beep.mp3');
      _currentStep++;
      if (_currentStep == _sequence.length) {
        _score++;
        final isNewRecord = _score > _record;
        if (isNewRecord) {
          await _saveRecord(_score);
        }
        _secondsRemaining += 5;
        _addNextToSequence();
        await _playSound('success.mp3');
        _playSequence();
      }
    } else {
      _timer?.cancel();
      final isNewRecord = _score > _record;
      _showGameOverDialog("Wrong box tapped.", isNewRecord);
    }
  }

  void _onTimeUp() {
    if (_isGameOver) return;
    _timer?.cancel();
    final isNewRecord = _score > _record;
    _showGameOverDialog("Time's up!", isNewRecord);
  }

  void _addNextToSequence() {
    _sequence.add(_random.nextInt(_gridSize * _gridSize));
  }

  void _showGameOverDialog(String message, bool isNewRecord) async {
    if (_isGameOver) return;
    _isGameOver = true;

    if (isNewRecord) {
      setState(() {
        _record = _score;
      });
      await _saveRecord(_score);
      await _playSound('congrats.mp3');
      _confettiController.play();
      await _saveScoreToFirestore();
    } else {
      await _playSound('fail.mp3');
    }
    
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Material(
            color: Colors.transparent,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isNewRecord)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: RadialGradient(
                          colors: [Colors.amber.withOpacity(0.2), Colors.transparent],
                          radius: 0.5,
                        ),
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple[900]?.withOpacity(0.98),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isNewRecord
                          ? Colors.amberAccent.shade200.withOpacity(0.5)
                          : Colors.deepPurpleAccent.shade400.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 32,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isNewRecord)
                        TweenAnimationBuilder(
                          duration: const Duration(milliseconds: 600),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (_, double value, __) {
                            return Transform.scale(
                              scale: Curves.easeOutBack.transform(value),
                              child: Icon(
                                Icons.star_rounded,
                                size: 56,
                                color: Colors.amberAccent.shade200,
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 16),
                      isNewRecord
                          ? ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [Colors.amberAccent.shade200, Colors.orangeAccent],
                              ).createShader(bounds),
                              child: const Text(
                                'NEW RECORD!',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                  height: 1.2,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'GAME OVER',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                      const SizedBox(height: 12),
                      TweenAnimationBuilder(
                        duration: const Duration(milliseconds: 400),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (_, double value, __) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, (1 - value) * 8),
                              child: Text(
                                isNewRecord
                                    ? 'Score: $_score'
                                    : '$message\nScore: $_score',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: [
                                isNewRecord
                                    ? Colors.amber.shade600
                                    : Colors.deepPurpleAccent.shade400,
                                isNewRecord
                                    ? Colors.orange.shade600
                                    : Colors.indigoAccent.shade400,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              _isGameOver = false;
                              Navigator.of(context).pop();
                              resetGame();
                            },
                            child: const Text(
                              'PLAY AGAIN',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isNewRecord)
                  ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                    emissionFrequency: 0.05,
                    numberOfParticles: 20,
                    maxBlastForce: 20,
                    minBlastForce: 8,
                    gravity: 0.2,
                    colors: const [
                      Colors.amberAccent,
                      Colors.deepPurpleAccent,
                      Colors.cyanAccent,
                      Colors.pinkAccent,
                    ],
                  ),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (_, anim, __, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
    );
  }

  Color _colorForIndex(int index) => _gridColors[index % _gridColors.length];

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _audioPlayer.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final settings = Provider.of<SettingsController>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode
            ? const Color.fromARGB(255, 86, 63, 153)
            : const Color.fromARGB(255, 187, 180, 239),
        iconTheme: const IconThemeData(
          color: Color.fromARGB(255, 0, 0, 0),
        ),
        title: const Text(
          'MEMORY',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Color.fromARGB(255, 0, 0, 0),
            shadows: [
              Shadow(
                blurRadius: 4,
                offset: Offset(1, 1),
                color: Colors.black45,
              ),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.leaderboard,
              color: Color.fromARGB(255, 0, 0, 0)),
            tooltip: 'Leaderboard',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: Color.fromARGB(255, 0, 0, 0)),
            tooltip: 'Restart Game',
            onPressed: resetGame,
          ),
          // IconButton(
          //   icon: const Icon(
          //     Icons.settings,
          //     color: Color.fromARGB(255, 0, 0, 0)),
          //   tooltip: 'Settings',
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (context) => const SettingsScreen()),
          //     );
          //   },
          // ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDarkMode
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Color(0xFFF0F0F0)],
                ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusCard('⏳ Time', '$_secondsRemaining s', isDarkMode),
                  _buildStatusCard('⭐ Score', '$_score', isDarkMode),
                  _buildStatusCard('🏆 Record', '$_record', isDarkMode),
                ],
              ),
            ),
            if (settings.soundEffects)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.volume_up, 
                      size: 16,
                      color: isDarkMode ? Colors.white70 : Colors.black54),
                    const SizedBox(width: 4),
                    Text(
                      'Volume: ${(settings.volumeLevel * 100).round()}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.white70 : Colors.black54),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  itemCount: _gridSize * _gridSize,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _gridSize,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemBuilder: (context, index) => GestureDetector(
                    onTap: () => _onBoxTap(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? null
                            : (_blinkingIndex == index
                                ? _colorForIndex(index)
                                : _colorForIndex(index).withOpacity(0.8)),
                        gradient: isDarkMode
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _colorForIndex(index).withOpacity(
                                    _blinkingIndex == index ? 0.9 : 0.4,
                                  ),
                                  _colorForIndex(index).withOpacity(
                                    _blinkingIndex == index ? 0.7 : 0.2,
                                  ),
                                ],
                              )
                            : null,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: _blinkingIndex == index
                            ? [
                                BoxShadow(
                                  color: _colorForIndex(index).withOpacity(0.9),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(2, 2),
                                ),
                              ],
                      ),
                      child: _blinkingIndex == index
                          ? const Center(
                              child: Icon(
                                Icons.star,
                                color: Colors.white,
                                size: 30,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String label, String value, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isDarkMode ? Colors.white.withOpacity(0.2) : Colors.white,
        ),
        boxShadow: isDarkMode
            ? null
            : [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  offset: const Offset(2, 2),
                ),
              ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDarkMode ? Colors.white.withOpacity(0.8) : Colors.black87,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}


// import 'dart:math';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:confetti/confetti.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../controllers/settings_controller.dart';
// import 'leaderboard_screen.dart';

// class GameScreen extends StatefulWidget {
//   const GameScreen({super.key});

//   @override
//   State<GameScreen> createState() => _GameScreenState();
// }

// class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
//   final Random _random = Random();
//   final AudioPlayer _audioPlayer = AudioPlayer();
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   bool _isGameOver = false;
//   bool _isAppActive = true;
//   bool _showInstructions = true;
//   List<int> _sequence = [];
//   int _currentStep = 0;
//   int _gridSize = 3;
//   int _score = 0;
//   int _record = 0;
//   int? _blinkingIndex;
//   bool _isPlayerTurn = false;
//   Timer? _timer;
//   int _secondsRemaining = 20;
//   late ConfettiController _confettiController;

//   final List<Color> _gridColors = [
//     Colors.cyan,
//     Colors.purpleAccent,
//     Colors.amber,
//     Colors.lightGreen,
//     Colors.deepOrangeAccent,
//     Colors.lightBlueAccent,
//   ];

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _confettiController = ConfettiController(duration: const Duration(seconds: 3));
//     _loadRecord();
//     _showTutorial();
//   }

//   Future<void> _showTutorial() async {
//     await Future.delayed(const Duration(milliseconds: 500));
//     if (mounted && _showInstructions) {
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => _buildInstructionsDialog(),
//       );
//     }
//   }

//   Widget _buildInstructionsDialog() {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
    
//     return AlertDialog(
//       backgroundColor: isDark ? const Color(0xFF2D2D3D) : Colors.white,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(20),
//         side: BorderSide(
//           color: isDark ? Colors.blueAccent : Colors.blue,
//           width: 2
//         )
//       ),
//       title: Text(
//         'How to Play',
//         style: TextStyle(
//           color: isDark ? Colors.white : Colors.black,
//           fontWeight: FontWeight.bold
//         ),
//       ),
//       content: SingleChildScrollView(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildInstructionStep(
//               "1. Watch the sequence",
//               "The game will flash colored boxes in a pattern",
//               isDark
//             ),
//             const SizedBox(height: 10),
//             _buildInstructionStep(
//               "2. Repeat the sequence",
//               "Tap the boxes in the same order you saw them",
//               isDark
//             ),
//             const SizedBox(height: 10),
//             _buildInstructionStep(
//               "3. Advance to next level",
//               "Each correct sequence increases your score",
//               isDark
//             ),
//             const SizedBox(height: 10),
//             _buildInstructionStep(
//               "4. Beat your high score!",
//               "Try to remember longer sequences as you progress",
//               isDark
//             ),
//           ],
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () {
//             setState(() => _showInstructions = false);
//             Navigator.pop(context);
//             _startNewGame();
//           },
//           child: Text(
//             'Got it!',
//             style: TextStyle(
//               color: isDark ? Colors.blueAccent : Colors.blue,
//               fontSize: 16
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildInstructionStep(String title, String description, bool isDark) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           title,
//           style: TextStyle(
//             color: isDark ? Colors.blueAccent : Colors.blue,
//             fontWeight: FontWeight.bold,
//             fontSize: 16
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           description,
//           style: TextStyle(
//             color: isDark ? Colors.white70 : Colors.black87,
//             fontSize: 14
//           ),
//         ),
//       ],
//     );
//   }

//   void _startNewGame() {
//     _sequence.clear();
//     _addNextToSequence();
//     _playSequence();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
//       _isAppActive = false;
//       _audioPlayer.stop();
//       _timer?.cancel();
//     } else if (state == AppLifecycleState.resumed) {
//       _isAppActive = true;
//       if (!_isGameOver && _isPlayerTurn) {
//         _startCountdown();
//       }
//     }
//   }

//   Future<void> _loadRecord() async {
//     final prefs = await SharedPreferences.getInstance();
//     final user = FirebaseAuth.instance.currentUser;
    
//     final recordKey = user != null ? 'highestScore_${user.uid}' : 'highestScore_guest';
    
//     setState(() {
//       _record = prefs.getInt(recordKey) ?? 0;
//     });
//   }

//   Future<void> _saveRecord(int newRecord) async {
//     final prefs = await SharedPreferences.getInstance();
//     final user = FirebaseAuth.instance.currentUser;
    
//     final recordKey = user != null ? 'highestScore_${user.uid}' : 'highestScore_guest';
    
//     await prefs.setInt(recordKey, newRecord);
//   }

//   Future<void> _saveScoreToFirestore() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     final userDoc = _firestore.collection('users').doc(user.uid);
//     final doc = await userDoc.get();
    
//     final currentHighScore = doc.exists 
//         ? ((doc.data()?['gameStats'] as Map<String, dynamic>?)?['memoryTile']?['highScore'] as int? ?? 0)
//         : 0;

//     if (_score > currentHighScore) {
//       await userDoc.set({
//         'username': user.displayName ?? 'Player',
//         'profileImageUrl': user.photoURL ?? '',
//         'lastUpdated': FieldValue.serverTimestamp(),
//         'gameStats': {
//           'memoryTile': {
//             'highScore': _score,
//             'lastPlayed': FieldValue.serverTimestamp(),
//           }
//         }
//       }, SetOptions(merge: true));
//     }
//   }

//   Future<void> resetGame() async {
//     setState(() {
//       _sequence.clear();
//       _score = 0;
//       _secondsRemaining = _getInitialTimeForDifficulty();
//       _blinkingIndex = null;
//       _isPlayerTurn = false;
//       _isGameOver = false;
//     });
//     _startNewGame();
//   }

//   int _getInitialTimeForDifficulty() {
//     const difficulty = "medium";
//     switch (difficulty) {
//       case "easy":
//         return 15;
//       case "hard":
//         return 30;
//       default:
//         return 20;
//     }
//   }

//   void _startCountdown() {
//     _timer?.cancel();
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       setState(() {
//         _secondsRemaining--;
//         if (_secondsRemaining <= 0) {
//           timer.cancel();
//           _onTimeUp();
//         }
//       });
//     });
//   }

//   Future<void> _playSound(String name) async {
//     if (!_isAppActive) return;
//     final settings = Provider.of<SettingsController>(context, listen: false);
//     if (!settings.soundEffects) return;
//     try {
//       await _audioPlayer.play(AssetSource('sounds/$name'));
//     } catch (_) {}
//   }

//   Future<void> _playSequence() async {
//     setState(() {
//       _isPlayerTurn = false;
//       _blinkingIndex = null;
//       _currentStep = 0;
//     });

//     _timer?.cancel();

//     await Future.delayed(const Duration(milliseconds: 500));

//     for (int i in _sequence) {
//       setState(() => _blinkingIndex = i);
//       await _playSound('beep.mp3');
//       await Future.delayed(const Duration(milliseconds: 600));
//       setState(() => _blinkingIndex = null);
//       await Future.delayed(const Duration(milliseconds: 300));
//     }

//     setState(() => _isPlayerTurn = true);
//     _startCountdown();
//   }

//   void _onBoxTap(int index) async {
//     if (!_isPlayerTurn || _isGameOver) return;

//     setState(() => _blinkingIndex = index);
//     await Future.delayed(const Duration(milliseconds: 200));
//     setState(() => _blinkingIndex = null);

//     if (index == _sequence[_currentStep]) {
//       await _playSound('beep.mp3');
//       _currentStep++;
//       if (_currentStep == _sequence.length) {
//         _score++;
//         final isNewRecord = _score > _record;
//         if (isNewRecord) {
//           await _saveRecord(_score);
//         }
//         _secondsRemaining += 5;
//         _addNextToSequence();
//         await _playSound('success.mp3');
//         _playSequence();
//       }
//     } else {
//       _timer?.cancel();
//       final isNewRecord = _score > _record;
//       _showGameOverDialog("Wrong box tapped.", isNewRecord);
//     }
//   }

//   void _onTimeUp() {
//     if (_isGameOver) return;
//     _timer?.cancel();
//     final isNewRecord = _score > _record;
//     _showGameOverDialog("Time's up!", isNewRecord);
//   }

//   void _addNextToSequence() {
//     _sequence.add(_random.nextInt(_gridSize * _gridSize));
//   }

//   void _showGameOverDialog(String message, bool isNewRecord) async {
//     if (_isGameOver) return;
//     _isGameOver = true;

//     if (isNewRecord) {
//       setState(() {
//         _record = _score;
//       });
//       await _saveRecord(_score);
//       await _playSound('congrats.mp3');
//       _confettiController.play();
//       await _saveScoreToFirestore();
//     } else {
//       await _playSound('fail.mp3');
//     }
    
//     showGeneralDialog(
//       context: context,
//       barrierDismissible: false,
//       barrierColor: Colors.black.withOpacity(0.85),
//       transitionDuration: const Duration(milliseconds: 300),
//       pageBuilder: (_, __, ___) {
//         return Dialog(
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//           child: Material(
//             color: Colors.transparent,
//             child: Stack(
//               alignment: Alignment.center,
//               children: [
//                 if (isNewRecord)
//                   Positioned.fill(
//                     child: Container(
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(24),
//                         gradient: RadialGradient(
//                           colors: [Colors.amber.withOpacity(0.2), Colors.transparent],
//                           radius: 0.5,
//                         ),
//                       ),
//                     ),
//                   ),
//                 Container(
//                   padding: const EdgeInsets.all(24),
//                   decoration: BoxDecoration(
//                     color: Colors.deepPurple[900]?.withOpacity(0.98),
//                     borderRadius: BorderRadius.circular(24),
//                     border: Border.all(
//                       color: isNewRecord
//                           ? Colors.amberAccent.shade200.withOpacity(0.5)
//                           : Colors.deepPurpleAccent.shade400.withOpacity(0.3),
//                       width: 1.5,
//                     ),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.4),
//                         blurRadius: 32,
//                         offset: const Offset(0, 16),
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       if (isNewRecord)
//                         TweenAnimationBuilder(
//                           duration: const Duration(milliseconds: 600),
//                           tween: Tween(begin: 0.0, end: 1.0),
//                           builder: (_, double value, __) {
//                             return Transform.scale(
//                               scale: Curves.easeOutBack.transform(value),
//                               child: Icon(
//                                 Icons.star_rounded,
//                                 size: 56,
//                                 color: Colors.amberAccent.shade200,
//                               ),
//                             );
//                           },
//                         ),
//                       const SizedBox(height: 16),
//                       isNewRecord
//                           ? ShaderMask(
//                               shaderCallback: (bounds) => LinearGradient(
//                                 colors: [Colors.amberAccent.shade200, Colors.orangeAccent],
//                               ).createShader(bounds),
//                               child: const Text(
//                                 'NEW RECORD!',
//                                 style: TextStyle(
//                                   fontSize: 32,
//                                   fontWeight: FontWeight.w900,
//                                   letterSpacing: 1.2,
//                                   height: 1.2,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                             )
//                           : const Text(
//                               'GAME OVER',
//                               style: TextStyle(
//                                 fontSize: 32,
//                                 fontWeight: FontWeight.w900,
//                                 color: Colors.white,
//                                 letterSpacing: 1.2,
//                               ),
//                             ),
//                       const SizedBox(height: 12),
//                       TweenAnimationBuilder(
//                         duration: const Duration(milliseconds: 400),
//                         tween: Tween(begin: 0.0, end: 1.0),
//                         builder: (_, double value, __) {
//                           return Opacity(
//                             opacity: value,
//                             child: Transform.translate(
//                               offset: Offset(0, (1 - value) * 8),
//                               child: Text(
//                                 isNewRecord
//                                     ? 'Score: $_score'
//                                     : '$message\nScore: $_score',
//                                 style: TextStyle(
//                                   color: Colors.white.withOpacity(0.9),
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                       const SizedBox(height: 24),
//                       MouseRegion(
//                         cursor: SystemMouseCursors.click,
//                         child: AnimatedContainer(
//                           duration: const Duration(milliseconds: 150),
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(12),
//                             gradient: LinearGradient(
//                               colors: [
//                                 isNewRecord
//                                     ? Colors.amber.shade600
//                                     : Colors.deepPurpleAccent.shade400,
//                                 isNewRecord
//                                     ? Colors.orange.shade600
//                                     : Colors.indigoAccent.shade400,
//                               ],
//                             ),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.3),
//                                 blurRadius: 12,
//                                 offset: const Offset(0, 6),
//                               ),
//                             ],
//                           ),
//                           child: ElevatedButton(
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.transparent,
//                               shadowColor: Colors.transparent,
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 32,
//                                 vertical: 16,
//                               ),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               elevation: 0,
//                             ),
//                             onPressed: () {
//                               _isGameOver = false;
//                               Navigator.of(context).pop();
//                               resetGame();
//                             },
//                             child: const Text(
//                               'PLAY AGAIN',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                                 letterSpacing: 1.1,
//                                 color: Colors.white,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 if (isNewRecord)
//                   ConfettiWidget(
//                     confettiController: _confettiController,
//                     blastDirectionality: BlastDirectionality.explosive,
//                     shouldLoop: false,
//                     emissionFrequency: 0.05,
//                     numberOfParticles: 20,
//                     maxBlastForce: 20,
//                     minBlastForce: 8,
//                     gravity: 0.2,
//                     colors: const [
//                       Colors.amberAccent,
//                       Colors.deepPurpleAccent,
//                       Colors.cyanAccent,
//                       Colors.pinkAccent,
//                     ],
//                   ),
//               ],
//             ),
//           ),
//         );
//       },
//       transitionBuilder: (_, anim, __, child) {
//         return ScaleTransition(
//           scale: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
//           child: FadeTransition(opacity: anim, child: child),
//         );
//       },
//     );
//   }

//   Color _colorForIndex(int index) => _gridColors[index % _gridColors.length];

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _timer?.cancel();
//     _audioPlayer.dispose();
//     _confettiController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDarkMode = Theme.of(context).brightness == Brightness.dark;

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: isDarkMode
//             ? const Color.fromARGB(255, 86, 63, 153)
//             : const Color.fromARGB(255, 187, 180, 239),
//         iconTheme: const IconThemeData(
//           color: Color.fromARGB(255, 0, 0, 0),
//         ),
//         title: const Text(
//           'MEMORY',
//           style: TextStyle(
//             fontSize: 19,
//             fontWeight: FontWeight.bold,
//             letterSpacing: 1.5,
//             color: Color.fromARGB(255, 0, 0, 0),
//             shadows: [
//               Shadow(
//                 blurRadius: 4,
//                 offset: Offset(1, 1),
//                 color: Colors.black45,
//               ),
//             ],
//           ),
//         ),
//         centerTitle: true,
//         actions: [
//           IconButton(
//             icon: const Icon(
//               Icons.leaderboard,
//               color: Color.fromARGB(255, 0, 0, 0),
//             ),
//             tooltip: 'Leaderboard',
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
//               );
//             },
//           ),
//           IconButton(
//             icon: const Icon(
//               Icons.refresh,
//               color: Color.fromARGB(255, 0, 0, 0),
//             ),
//             tooltip: 'Restart Game',
//             onPressed: resetGame,
//           ),
//         ],
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: isDarkMode
//               ? const LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
//                 )
//               : const LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   colors: [Colors.white, Color(0xFFF0F0F0)],
//                 ),
//         ),
//         child: Column(
//           children: [
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   _buildStatusCard('⏳ Time', '$_secondsRemaining s', isDarkMode),
//                   _buildStatusCard('⭐ Score', '$_score', isDarkMode),
//                   _buildStatusCard('🏆 Record', '$_record', isDarkMode),
//                 ],
//               ),
//             ),
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: GridView.builder(
//                   itemCount: _gridSize * _gridSize,
//                   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: _gridSize,
//                     crossAxisSpacing: 15,
//                     mainAxisSpacing: 15,
//                   ),
//                   itemBuilder: (context, index) => GestureDetector(
//                     onTap: () => _onBoxTap(index),
//                     child: AnimatedContainer(
//                       duration: const Duration(milliseconds: 300),
//                       curve: Curves.easeInOut,
//                       decoration: BoxDecoration(
//                         color: isDarkMode
//                             ? null
//                             : (_blinkingIndex == index
//                                 ? _colorForIndex(index)
//                                 : _colorForIndex(index).withOpacity(0.8)),
//                         gradient: isDarkMode
//                             ? LinearGradient(
//                                 begin: Alignment.topLeft,
//                                 end: Alignment.bottomRight,
//                                 colors: [
//                                   _colorForIndex(index).withOpacity(
//                                     _blinkingIndex == index ? 0.9 : 0.4,
//                                   ),
//                                   _colorForIndex(index).withOpacity(
//                                     _blinkingIndex == index ? 0.7 : 0.2,
//                                   ),
//                                 ],
//                               )
//                             : null,
//                         borderRadius: BorderRadius.circular(15),
//                         boxShadow: _blinkingIndex == index
//                             ? [
//                                 BoxShadow(
//                                   color: _colorForIndex(index).withOpacity(0.9),
//                                   blurRadius: 20,
//                                   spreadRadius: 2,
//                                 ),
//                               ]
//                             : [
//                                 BoxShadow(
//                                   color: Colors.black.withOpacity(0.2),
//                                   blurRadius: 4,
//                                   offset: const Offset(2, 2),
//                                 ),
//                               ],
//                       ),
//                       child: _blinkingIndex == index
//                           ? const Center(
//                               child: Icon(
//                                 Icons.star,
//                                 color: Colors.white,
//                                 size: 30,
//                               ),
//                             )
//                           : null,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatusCard(String label, String value, bool isDarkMode) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//       decoration: BoxDecoration(
//         color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white,
//         borderRadius: BorderRadius.circular(15),
//         border: Border.all(
//           color: isDarkMode ? Colors.white.withOpacity(0.2) : Colors.white,
//         ),
//         boxShadow: isDarkMode
//             ? null
//             : [
//                 BoxShadow(
//                   color: Colors.grey.withOpacity(0.3),
//                   offset: const Offset(2, 2),
//                 ),
//               ],
//       ),
//       child: Column(
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               color: isDarkMode ? Colors.white.withOpacity(0.8) : Colors.black87,
//               fontSize: 14,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             value,
//             style: TextStyle(
//               color: isDarkMode ? Colors.white : Colors.black,
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }




// import 'dart:async';
// import 'dart:math';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:confetti/confetti.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../controllers/settings_controller.dart';
// import 'leaderboard_screen.dart';

// class GameScreen extends StatefulWidget {
//   const GameScreen({super.key});

//   @override
//   State<GameScreen> createState() => _GameScreenState();
// }

// class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
//   final Random random = Random();
//   final AudioPlayer audioPlayer = AudioPlayer();
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   bool _isGameOver = false;
//   bool _isAppActive = true;
//   bool _showInstructions = true;
//   List<int> sequence = [];
//   int currentStep = 0;
//   int gridSize = 3;
//   int score = 0;
//   int record = 0;
//   int? blinkingIndex;
//   bool isPlayerTurn = false;
//   Timer? timer;
//   int secondsRemaining = 20;
//   late ConfettiController _confettiController;

//   final List<Color> gridColors = [
//     Colors.cyan,
//     Colors.purpleAccent,
//     Colors.amber,
//     Colors.lightGreen,
//     Colors.deepOrangeAccent,
//     Colors.lightBlueAccent,
//   ];

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _confettiController = ConfettiController(duration: const Duration(seconds: 3));
//     loadRecord();
//     _showTutorial();
//   }

//   Future<void> _showTutorial() async {
//     await Future.delayed(const Duration(milliseconds: 500));
//     if (mounted && _showInstructions) {
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => _buildInstructionsDialog(),
//       );
//     }
//   }

//   Widget _buildInstructionsDialog() {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
    
//     return AlertDialog(
//       backgroundColor: isDark ? const Color(0xFF2D2D3D) : Colors.white,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(20),
//         side: BorderSide(
//           color: isDark ? Colors.blueAccent : Colors.blue,
//           width: 2
//         )
//       ),
//       title: Text(
//         'How to Play',
//         style: TextStyle(
//           color: isDark ? Colors.white : Colors.black,
//           fontWeight: FontWeight.bold
//         ),
//       ),
//       content: SingleChildScrollView(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildInstructionStep(
//               "1. Watch the sequence",
//               "The game will flash colored boxes in a pattern",
//               isDark
//             ),
//             const SizedBox(height: 10),
//             _buildInstructionStep(
//               "2. Repeat the sequence",
//               "Tap the boxes in the same order you saw them",
//               isDark
//             ),
//             const SizedBox(height: 10),
//             _buildInstructionStep(
//               "3. Advance to next level",
//               "Each correct sequence increases your score",
//               isDark
//             ),
//             const SizedBox(height: 10),
//             _buildInstructionStep(
//               "4. Beat your high score!",
//               "Try to remember longer sequences as you progress",
//               isDark
//             ),
//           ],
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () {
//             setState(() => _showInstructions = false);
//             Navigator.pop(context);
//             startNewGame();
//           },
//           child: Text(
//             'Got it!',
//             style: TextStyle(
//               color: isDark ? Colors.blueAccent : Colors.blue,
//               fontSize: 16
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildInstructionStep(String title, String description, bool isDark) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           title,
//           style: TextStyle(
//             color: isDark ? Colors.blueAccent : Colors.blue,
//             fontWeight: FontWeight.bold,
//             fontSize: 16
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           description,
//           style: TextStyle(
//             color: isDark ? Colors.white70 : Colors.black87,
//             fontSize: 14
//           ),
//         ),
//       ],
//     );
//   }

//   void startNewGame() {
//     sequence.clear();
//     addNextToSequence();
//     playSequence();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
//       _isAppActive = false;
//       audioPlayer.stop();
//       timer?.cancel();
//     } else if (state == AppLifecycleState.resumed) {
//       _isAppActive = true;
//       if (!_isGameOver && isPlayerTurn) {
//         startCountdown();
//       }
//     }
//   }

//   Future<void> loadRecord() async {
//     final prefs = await SharedPreferences.getInstance();
//     final user = FirebaseAuth.instance.currentUser;
    
//     final recordKey = user != null ? 'highestScore_${user.uid}' : 'highestScore_guest';
    
//     setState(() {
//       record = prefs.getInt(recordKey) ?? 0;
//     });
//   }

//   Future<void> saveRecord(int newRecord) async {
//     final prefs = await SharedPreferences.getInstance();
//     final user = FirebaseAuth.instance.currentUser;
    
//     final recordKey = user != null ? 'highestScore_${user.uid}' : 'highestScore_guest';
    
//     await prefs.setInt(recordKey, newRecord);
//   }

//   Future<void> saveScoreToFirestore() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     final userDoc = _firestore.collection('users').doc(user.uid);
//     final doc = await userDoc.get();
    
//     final currentHighScore = doc.exists 
//         ? ((doc.data()?['gameStats'] as Map<String, dynamic>?)?['memoryTile']?['highScore'] as int? ?? 0)
//         : 0;

//     if (score > currentHighScore) {
//       await userDoc.set({
//         'username': user.displayName ?? 'Player',
//         'profileImageUrl': user.photoURL ?? '',
//         'lastUpdated': FieldValue.serverTimestamp(),
//         'gameStats': {
//           'memoryTile': {
//             'highScore': score,
//             'lastPlayed': FieldValue.serverTimestamp(),
//           }
//         }
//       }, SetOptions(merge: true));
//     }
//   }

//   Future<void> resetGame() async {
//     setState(() {
//       sequence.clear();
//       score = 0;
//       secondsRemaining = getInitialTimeForDifficulty();
//       blinkingIndex = null;
//       isPlayerTurn = false;
//       _isGameOver = false;
//     });
//     startNewGame();
//   }

//   int getInitialTimeForDifficulty() {
//     String difficulty = "medium";
//     switch (difficulty) {
//       case "easy":
//         return 15;
//       case "hard":
//         return 30;
//       default:
//         return 20;
//     }
//   }

//   void startCountdown() {
//     timer?.cancel();
//     timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       setState(() {
//         secondsRemaining--;
//         if (secondsRemaining <= 0) {
//           timer.cancel();
//           onTimeUp();
//         }
//       });
//     });
//   }

//   Future<void> playSound(String name) async {
//     if (!_isAppActive) return;
//     final settings = Provider.of<SettingsController>(context, listen: false);
//     if (!settings.soundEffects) return;
//     try {
//       await audioPlayer.play(AssetSource('sounds/$name'));
//     } catch (_) {}
//   }

//   Future<void> playSequence() async {
//     setState(() {
//       isPlayerTurn = false;
//       blinkingIndex = null;
//       currentStep = 0;
//     });

//     timer?.cancel();

//     await Future.delayed(const Duration(milliseconds: 500));

//     for (int i in sequence) {
//       setState(() => blinkingIndex = i);
//       await playSound('beep.mp3');
//       await Future.delayed(const Duration(milliseconds: 600));
//       setState(() => blinkingIndex = null);
//       await Future.delayed(const Duration(milliseconds: 300));
//     }

//     setState(() => isPlayerTurn = true);
//     startCountdown();
//   }

//   void onBoxTap(int index) async {
//     if (!isPlayerTurn || _isGameOver) return;

//     setState(() => blinkingIndex = index);
//     await Future.delayed(const Duration(milliseconds: 200));
//     setState(() => blinkingIndex = null);

//     if (index == sequence[currentStep]) {
//       await playSound('beep.mp3');
//       currentStep++;
//       if (currentStep == sequence.length) {
//         score++;
//         bool isNewRecord = score > record;
//         if (isNewRecord) {
//           await saveRecord(score);
//         }
//         secondsRemaining += 5;
//         addNextToSequence();
//         await playSound('success.mp3');
//         playSequence();
//       }
//     } else {
//       timer?.cancel();
//       bool isNewRecord = score > record;
//       showGameOverDialog("Wrong box tapped.", isNewRecord);
//     }
//   }

//   void onTimeUp() {
//     if (_isGameOver) return;
//     timer?.cancel();
//     bool isNewRecord = score > record;
//     showGameOverDialog("Time's up!", isNewRecord);
//   }

//   void addNextToSequence() {
//     sequence.add(random.nextInt(gridSize * gridSize));
//   }

//   void showGameOverDialog(String message, bool isNewRecord) async {
//     if (_isGameOver) return;
//     _isGameOver = true;

//     if (isNewRecord) {
//       setState(() {
//         record = score;
//       });
//       await saveRecord(score);
//       await playSound('congrats.mp3');
//       _confettiController.play();
//       await saveScoreToFirestore();
//     } else {
//       await playSound('fail.mp3');
//     }
    
//     showGeneralDialog(
//       context: context,
//       barrierDismissible: false,
//       barrierColor: Colors.black.withOpacity(0.85),
//       transitionDuration: const Duration(milliseconds: 300),
//       pageBuilder: (_, __, ___) {
//         return Dialog(
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//           child: Material(
//             color: Colors.transparent,
//             child: Stack(
//               alignment: Alignment.center,
//               children: [
//                 if (isNewRecord)
//                   Positioned.fill(
//                     child: Container(
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(24),
//                         gradient: RadialGradient(
//                           colors: [Colors.amber.withOpacity(0.2), Colors.transparent],
//                           radius: 0.5,
//                         ),
//                       ),
//                     ),
//                   ),
//                 Container(
//                   padding: const EdgeInsets.all(24),
//                   decoration: BoxDecoration(
//                     color: Colors.deepPurple[900]?.withOpacity(0.98),
//                     borderRadius: BorderRadius.circular(24),
//                     border: Border.all(
//                       color: isNewRecord
//                           ? Colors.amberAccent.shade200.withOpacity(0.5)
//                           : Colors.deepPurpleAccent.shade400.withOpacity(0.3),
//                       width: 1.5,
//                     ),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.4),
//                         blurRadius: 32,
//                         offset: const Offset(0, 16),
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       if (isNewRecord)
//                         TweenAnimationBuilder(
//                           duration: const Duration(milliseconds: 600),
//                           tween: Tween(begin: 0.0, end: 1.0),
//                           builder: (_, double value, __) {
//                             return Transform.scale(
//                               scale: Curves.easeOutBack.transform(value),
//                               child: Icon(
//                                 Icons.star_rounded,
//                                 size: 56,
//                                 color: Colors.amberAccent.shade200,
//                               ),
//                             );
//                           },
//                         ),
//                       const SizedBox(height: 16),
//                       isNewRecord
//                           ? ShaderMask(
//                               shaderCallback: (bounds) => LinearGradient(
//                                 colors: [Colors.amberAccent.shade200, Colors.orangeAccent],
//                               ).createShader(bounds),
//                               child: const Text(
//                                 'NEW RECORD!',
//                                 style: TextStyle(
//                                   fontSize: 32,
//                                   fontWeight: FontWeight.w900,
//                                   letterSpacing: 1.2,
//                                   height: 1.2,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                             )
//                           : const Text(
//                               'GAME OVER',
//                               style: TextStyle(
//                                 fontSize: 32,
//                                 fontWeight: FontWeight.w900,
//                                 color: Colors.white,
//                                 letterSpacing: 1.2,
//                               ),
//                             ),
//                       const SizedBox(height: 12),
//                       TweenAnimationBuilder(
//                         duration: const Duration(milliseconds: 400),
//                         tween: Tween(begin: 0.0, end: 1.0),
//                         builder: (_, double value, __) {
//                           return Opacity(
//                             opacity: value,
//                             child: Transform.translate(
//                               offset: Offset(0, (1 - value) * 8),
//                               child: Text(
//                                 isNewRecord
//                                     ? 'Score: $score'
//                                     : '$message\nScore: $score',
//                                 style: TextStyle(
//                                   color: Colors.white.withOpacity(0.9),
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                       const SizedBox(height: 24),
//                       MouseRegion(
//                         cursor: SystemMouseCursors.click,
//                         child: AnimatedContainer(
//                           duration: const Duration(milliseconds: 150),
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(12),
//                             gradient: LinearGradient(
//                               colors: [
//                                 isNewRecord
//                                     ? Colors.amber.shade600
//                                     : Colors.deepPurpleAccent.shade400,
//                                 isNewRecord
//                                     ? Colors.orange.shade600
//                                     : Colors.indigoAccent.shade400,
//                               ],
//                             ),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.3),
//                                 blurRadius: 12,
//                                 offset: const Offset(0, 6),
//                               ),
//                             ],
//                           ),
//                           child: ElevatedButton(
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.transparent,
//                               shadowColor: Colors.transparent,
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 32,
//                                 vertical: 16,
//                               ),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               elevation: 0,
//                             ),
//                             onPressed: () {
//                               _isGameOver = false;
//                               Navigator.of(context).pop();
//                               resetGame();
//                             },
//                             child: const Text(
//                               'PLAY AGAIN',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                                 letterSpacing: 1.1,
//                                 color: Colors.white,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 if (isNewRecord)
//                   ConfettiWidget(
//                     confettiController: _confettiController,
//                     blastDirectionality: BlastDirectionality.explosive,
//                     shouldLoop: false,
//                     emissionFrequency: 0.05,
//                     numberOfParticles: 20,
//                     maxBlastForce: 20,
//                     minBlastForce: 8,
//                     gravity: 0.2,
//                     colors: const [
//                       Colors.amberAccent,
//                       Colors.deepPurpleAccent,
//                       Colors.cyanAccent,
//                       Colors.pinkAccent,
//                     ],
//                   ),
//               ],
//             ),
//           ),
//         );
//       },
//       transitionBuilder: (_, anim, __, child) {
//         return ScaleTransition(
//           scale: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
//           child: FadeTransition(opacity: anim, child: child),
//         );
//       },
//     );
//   }

//   Color colorForIndex(int index) => gridColors[index % gridColors.length];

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     timer?.cancel();
//     audioPlayer.dispose();
//     _confettiController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDarkMode = Theme.of(context).brightness == Brightness.dark;

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: isDarkMode
//             ? const Color.fromARGB(255, 86, 63, 153)
//             : const Color.fromARGB(255, 187, 180, 239),
//         iconTheme: const IconThemeData(
//           color: Color.fromARGB(255, 0, 0, 0),
//         ),
//         title: const Text(
//           'MEMORY',
//           style: TextStyle(
//             fontSize: 19,
//             fontWeight: FontWeight.bold,
//             letterSpacing: 1.5,
//             color: Color.fromARGB(255, 0, 0, 0),
//             shadows: [
//               Shadow(
//                 blurRadius: 4,
//                 offset: Offset(1, 1),
//                 color: Colors.black45,
//               ),
//             ],
//           ),
//         ),
//         centerTitle: true,
//         actions: [
//           IconButton(
//             icon: const Icon(
//               Icons.leaderboard,
//               color: Color.fromARGB(255, 0, 0, 0),
//             ),
//             tooltip: 'Leaderboard',
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
//               );
//             },
//           ),
//           IconButton(
//             icon: const Icon(
//               Icons.refresh,
//               color: Color.fromARGB(255, 0, 0, 0),
//             ),
//             tooltip: 'Restart Game',
//             onPressed: resetGame,
//           ),
//         ],
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: isDarkMode
//               ? const LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
//                 )
//               : const LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   colors: [Colors.white, Color(0xFFF0F0F0)],
//                 ),
//         ),
//         child: Column(
//           children: [
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   _buildStatusCard('⏳ Time', '$secondsRemaining s', isDarkMode),
//                   _buildStatusCard('⭐ Score', '$score', isDarkMode),
//                   _buildStatusCard('🏆 Record', '$record', isDarkMode),
//                 ],
//               ),
//             ),
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: GridView.builder(
//                   itemCount: gridSize * gridSize,
//                   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: gridSize,
//                     crossAxisSpacing: 15,
//                     mainAxisSpacing: 15,
//                   ),
//                   itemBuilder: (context, index) => GestureDetector(
//                     onTap: () => onBoxTap(index),
//                     child: AnimatedContainer(
//                       duration: const Duration(milliseconds: 300),
//                       curve: Curves.easeInOut,
//                       decoration: BoxDecoration(
//                         color: isDarkMode
//                             ? null
//                             : (blinkingIndex == index
//                                 ? colorForIndex(index)
//                                 : colorForIndex(index).withOpacity(0.8)),
//                         gradient: isDarkMode
//                             ? LinearGradient(
//                                 begin: Alignment.topLeft,
//                                 end: Alignment.bottomRight,
//                                 colors: [
//                                   colorForIndex(index).withOpacity(
//                                     blinkingIndex == index ? 0.9 : 0.4,
//                                   ),
//                                   colorForIndex(index).withOpacity(
//                                     blinkingIndex == index ? 0.7 : 0.2,
//                                   ),
//                                 ],
//                               )
//                             : null,
//                         borderRadius: BorderRadius.circular(15),
//                         boxShadow: blinkingIndex == index
//                             ? [
//                                 BoxShadow(
//                                   color: colorForIndex(index).withOpacity(0.9),
//                                   blurRadius: 20,
//                                   spreadRadius: 2,
//                                 ),
//                               ]
//                             : [
//                                 BoxShadow(
//                                   color: Colors.black.withOpacity(0.2),
//                                   blurRadius: 4,
//                                   offset: const Offset(2, 2),
//                                 ),
//                               ],
//                       ),
//                       child: blinkingIndex == index
//                           ? const Center(
//                               child: Icon(
//                                 Icons.star,
//                                 color: Colors.white,
//                                 size: 30,
//                               ),
//                             )
//                           : null,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatusCard(String label, String value, bool isDarkMode) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//       decoration: BoxDecoration(
//         color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white,
//         borderRadius: BorderRadius.circular(15),
//         border: Border.all(
//           color: isDarkMode ? Colors.white.withOpacity(0.2) : Colors.white,
//         ),
//         boxShadow: isDarkMode
//             ? null
//             : [
//                 BoxShadow(
//                   color: Colors.grey.withOpacity(0.3),
//                   offset: const Offset(2, 2),
//                 ),
//               ],
//       ),
//       child: Column(
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               color: isDarkMode ? Colors.white.withOpacity(0.8) : Colors.black87,
//               fontSize: 14,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             value,
//             style: TextStyle(
//               color: isDarkMode ? Colors.white : Colors.black,
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }








// import 'dart:async';
// import 'dart:math';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:confetti/confetti.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../controllers/settings_controller.dart';
// import 'leaderboard_screen.dart';

// class GameScreen extends StatefulWidget {
//   const GameScreen({super.key});

//   @override
//   State<GameScreen> createState() => _GameScreenState();
// }

// class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
//   final Random random = Random();
//   final AudioPlayer audioPlayer = AudioPlayer();
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   bool _isGameOver = false;
//   bool _isAppActive = true;
//   bool _showInstructions = true;
//   List<int> sequence = [];
//   int currentStep = 0;
//   int gridSize = 3;
//   int score = 0;
//   int record = 0;
//   int? blinkingIndex;
//   bool isPlayerTurn = false;
//   Timer? timer;
//   int secondsRemaining = 20;
//   late ConfettiController _confettiController;

//   final List<Color> gridColors = [
//     Colors.cyan,
//     Colors.purpleAccent,
//     Colors.amber,
//     Colors.lightGreen,
//     Colors.deepOrangeAccent,
//     Colors.lightBlueAccent,
//   ];

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _confettiController = ConfettiController(duration: const Duration(seconds: 3));
//     loadRecord();
//     _showTutorial();
//   }

//   Future<void> _showTutorial() async {
//     await Future.delayed(const Duration(milliseconds: 500));
//     if (mounted && _showInstructions) {
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => _buildInstructionsDialog(),
//       );
//     }
//   }

//   Widget _buildInstructionsDialog() {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
    
//     return AlertDialog(
//       backgroundColor: isDark ? const Color(0xFF2D2D3D) : Colors.white,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(20),
//         side: BorderSide(
//           color: isDark ? Colors.blueAccent : Colors.blue,
//           width: 2
//         )
//       ),
//       title: Text(
//         'How to Play',
//         style: TextStyle(
//           color: isDark ? Colors.white : Colors.black,
//           fontWeight: FontWeight.bold
//         ),
//       ),
//       content: SingleChildScrollView(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildInstructionStep(
//               "1. Watch the sequence",
//               "The game will flash colored boxes in a pattern",
//               isDark
//             ),
//             const SizedBox(height: 10),
//             _buildInstructionStep(
//               "2. Repeat the sequence",
//               "Tap the boxes in the same order you saw them",
//               isDark
//             ),
//             const SizedBox(height: 10),
//             _buildInstructionStep(
//               "3. Advance to next level",
//               "Each correct sequence increases your score",
//               isDark
//             ),
//             const SizedBox(height: 10),
//             _buildInstructionStep(
//               "4. Beat your high score!",
//               "Try to remember longer sequences as you progress",
//               isDark
//             ),
//           ],
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () {
//             setState(() => _showInstructions = false);
//             Navigator.pop(context);
//             startNewGame();
//           },
//           child: Text(
//             'Got it!',
//             style: TextStyle(
//               color: isDark ? Colors.blueAccent : Colors.blue,
//               fontSize: 16
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildInstructionStep(String title, String description, bool isDark) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           title,
//           style: TextStyle(
//             color: isDark ? Colors.blueAccent : Colors.blue,
//             fontWeight: FontWeight.bold,
//             fontSize: 16
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           description,
//           style: TextStyle(
//             color: isDark ? Colors.white70 : Colors.black87,
//             fontSize: 14
//           ),
//         ),
//       ],
//     );
//   }

//   void startNewGame() {
//     sequence.clear();
//     addNextToSequence();
//     playSequence();
//   }
  

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
//       _isAppActive = false;
//       audioPlayer.stop();
//       timer?.cancel();
//     } else if (state == AppLifecycleState.resumed) {
//       _isAppActive = true;
//       if (!_isGameOver && isPlayerTurn) {
//         startCountdown();
//       }
//     }
//   }
// Future<void> loadRecord() async {
//   final prefs = await SharedPreferences.getInstance();
//   final user = FirebaseAuth.instance.currentUser;
  
//   // Use a user-specific key for shared preferences
//   final recordKey = user != null ? 'highestScore_${user.uid}' : 'highestScore_guest';
  
//   setState(() {
//     record = prefs.getInt(recordKey) ?? 0;
//   });
// }

// Future<void> saveRecord(int newRecord) async {
//   final prefs = await SharedPreferences.getInstance();
//   final user = FirebaseAuth.instance.currentUser;
  
//   // Use a user-specific key
//   final recordKey = user != null ? 'highestScore_${user.uid}' : 'highestScore_guest';
  
//   await prefs.setInt(recordKey, newRecord);
// }


// Future<void> saveScoreToFirestore() async {
//   final user = FirebaseAuth.instance.currentUser;
//   if (user == null) return;

//   final userDoc = _firestore.collection('users').doc(user.uid);
//   final doc = await userDoc.get();
  
//   // Get current high score from gameStats.memoryTile if it exists
//   final currentHighScore = doc.exists 
//       ? ((doc.data()?['gameStats'] as Map<String, dynamic>?)?['memoryTile']?['highScore'] as int? ?? 0)
//       : 0;

//   // Only update if this is a new high score for the user
//   if (score > currentHighScore) {
//     await userDoc.set({
//       'username': user.displayName ?? 'Player',
//       'profileImageUrl': user.photoURL ?? '',
//       'lastUpdated': FieldValue.serverTimestamp(),
//       'gameStats': {
//         'memoryTile': {
//           'highScore': score,
//           'lastPlayed': FieldValue.serverTimestamp(),
//         }
//       }
//     }, SetOptions(merge: true));
//   }
// }






//   Future<void> resetGame() async {
//     setState(() {
//       sequence.clear();
//       score = 0;
//       secondsRemaining = getInitialTimeForDifficulty();
//       blinkingIndex = null;
//       isPlayerTurn = false;
//       _isGameOver = false;
//     });
//     startNewGame();
//   }

//   int getInitialTimeForDifficulty() {
//     String difficulty = "medium";
//     switch (difficulty) {
//       case "easy":
//         return 15;
//       case "hard":
//         return 30;
//       default:
//         return 20;
//     }
//   }

//   void startCountdown() {
//     timer?.cancel();
//     timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       setState(() {
//         secondsRemaining--;
//         if (secondsRemaining <= 0) {
//           timer.cancel();
//           onTimeUp();
//         }
//       });
//     });
//   }

//   Future<void> playSound(String name) async {
//     if (!_isAppActive) return;
//     final settings = Provider.of<SettingsController>(context, listen: false);
//     if (!settings.soundEffects) return;
//     try {
//       await audioPlayer.play(AssetSource('sounds/$name'));
//     } catch (_) {}
//   }

//   Future<void> playSequence() async {
//     setState(() {
//       isPlayerTurn = false;
//       blinkingIndex = null;
//       currentStep = 0;
//     });

//     timer?.cancel();

//     await Future.delayed(const Duration(milliseconds: 500));

//     for (int i in sequence) {
//       setState(() => blinkingIndex = i);
//       await playSound('beep.mp3');
//       await Future.delayed(const Duration(milliseconds: 600));
//       setState(() => blinkingIndex = null);
//       await Future.delayed(const Duration(milliseconds: 300));
//     }

//     setState(() => isPlayerTurn = true);
//     startCountdown();
//   }

//   void onBoxTap(int index) async {
//     if (!isPlayerTurn || _isGameOver) return;

//     setState(() => blinkingIndex = index);
//     await Future.delayed(const Duration(milliseconds: 200));
//     setState(() => blinkingIndex = null);

//     if (index == sequence[currentStep]) {
//       await playSound('beep.mp3');
//       currentStep++;
//       if (currentStep == sequence.length) {
//         score++;
//         bool isNewRecord = score > record;
//         if (isNewRecord) {
//           await saveRecord(score);
//         }
//         secondsRemaining += 5;
//         addNextToSequence();
//         await playSound('success.mp3');
//         playSequence();
//       }
//     } else {
//       timer?.cancel();
//       bool isNewRecord = score > record;
//       showGameOverDialog("Wrong box tapped.", isNewRecord);
//     }
//   }

//   void onTimeUp() {
//     if (_isGameOver) return;
//     timer?.cancel();
//     bool isNewRecord = score > record;
//     showGameOverDialog("Time's up!", isNewRecord);
//   }

//   void addNextToSequence() {
//     sequence.add(random.nextInt(gridSize * gridSize));
//   }



// void showGameOverDialog(String message, bool isNewRecord) async {
//   if (_isGameOver) return;
//   _isGameOver = true;

//   if (isNewRecord) {
//     setState(() {
//       record = score; // Update local record
//     });
//     await saveRecord(score); // Save to local storage
//     await playSound('congrats.mp3');
//     _confettiController.play();
//     await saveScoreToFirestore(); // Optional: Save to leaderboard
//   } else {
//     await playSound('fail.mp3');
//   }
  
//     showGeneralDialog(
//       context: context,
//       barrierDismissible: false,
//       barrierColor: Colors.black.withOpacity(0.85),
//       transitionDuration: const Duration(milliseconds: 300),
//       pageBuilder: (_, __, ___) {
//         return Dialog(
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//           child: Material(
//             color: Colors.transparent,
//             child: Stack(
//               alignment: Alignment.center,
//               children: [
//                 if (isNewRecord)
//                   Positioned.fill(
//                     child: Container(
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(24),
//                         gradient: RadialGradient(
//                           colors: [Colors.amber.withOpacity(0.2), Colors.transparent],
//                           radius: 0.5,
//                         ),
//                       ),
//                     ),
//                   ),
//                 Container(
//                   padding: const EdgeInsets.all(24),
//                   decoration: BoxDecoration(
//                     color: Colors.deepPurple[900]?.withOpacity(0.98),
//                     borderRadius: BorderRadius.circular(24),
//                     border: Border.all(
//                       color: isNewRecord
//                           ? Colors.amberAccent.shade200.withOpacity(0.5)
//                           : Colors.deepPurpleAccent.shade400.withOpacity(0.3),
//                       width: 1.5,
//                     ),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.4),
//                         blurRadius: 32,
//                         offset: const Offset(0, 16),
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       if (isNewRecord)
//                         TweenAnimationBuilder(
//                           duration: const Duration(milliseconds: 600),
//                           tween: Tween(begin: 0.0, end: 1.0),
//                           builder: (_, double value, __) {
//                             return Transform.scale(
//                               scale: Curves.easeOutBack.transform(value),
//                               child: Icon(
//                                 Icons.star_rounded,
//                                 size: 56,
//                                 color: Colors.amberAccent.shade200,
//                               ),
//                             );
//                           },
//                         ),
//                       const SizedBox(height: 16),
//                       isNewRecord
//                           ? ShaderMask(
//                               shaderCallback: (bounds) => LinearGradient(
//                                 colors: [Colors.amberAccent.shade200, Colors.orangeAccent],
//                               ).createShader(bounds),
//                               child: const Text(
//                                 'NEW RECORD!',
//                                 style: TextStyle(
//                                   fontSize: 32,
//                                   fontWeight: FontWeight.w900,
//                                   letterSpacing: 1.2,
//                                   height: 1.2,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                             )
//                           : const Text(
//                               'GAME OVER',
//                               style: TextStyle(
//                                 fontSize: 32,
//                                 fontWeight: FontWeight.w900,
//                                 color: Colors.white,
//                                 letterSpacing: 1.2,
//                               ),
//                             ),
//                       const SizedBox(height: 12),
//                       TweenAnimationBuilder(
//                         duration: const Duration(milliseconds: 400),
//                         tween: Tween(begin: 0.0, end: 1.0),
//                         builder: (_, double value, __) {
//                           return Opacity(
//                             opacity: value,
//                             child: Transform.translate(
//                               offset: Offset(0, (1 - value) * 8),
//                               child: Text(
//                                 isNewRecord
//                                     ? 'Score: $score'
//                                     : '$message\nScore: $score',
//                                 style: TextStyle(
//                                   color: Colors.white.withOpacity(0.9),
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                       const SizedBox(height: 24),
//                       MouseRegion(
//                         cursor: SystemMouseCursors.click,
//                         child: AnimatedContainer(
//                           duration: const Duration(milliseconds: 150),
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(12),
//                             gradient: LinearGradient(
//                               colors: [
//                                 isNewRecord
//                                     ? Colors.amber.shade600
//                                     : Colors.deepPurpleAccent.shade400,
//                                 isNewRecord
//                                     ? Colors.orange.shade600
//                                     : Colors.indigoAccent.shade400,
//                               ],
//                             ),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.3),
//                                 blurRadius: 12,
//                                 offset: const Offset(0, 6),
//                               ),
//                             ],
//                           ),
//                           child: ElevatedButton(
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.transparent,
//                               shadowColor: Colors.transparent,
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 32,
//                                 vertical: 16,
//                               ),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               elevation: 0,
//                             ),
//                             onPressed: () {
//                               _isGameOver = false;
//                               Navigator.of(context).pop();
//                               resetGame();
//                             },
//                             child: const Text(
//                               'PLAY AGAIN',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                                 letterSpacing: 1.1,
//                                 color: Colors.white,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 if (isNewRecord)
//                   ConfettiWidget(
//                     confettiController: _confettiController,
//                     blastDirectionality: BlastDirectionality.explosive,
//                     shouldLoop: false,
//                     emissionFrequency: 0.05,
//                     numberOfParticles: 20,
//                     maxBlastForce: 20,
//                     minBlastForce: 8,
//                     gravity: 0.2,
//                     colors: const [
//                       Colors.amberAccent,
//                       Colors.deepPurpleAccent,
//                       Colors.cyanAccent,
//                       Colors.pinkAccent,
//                     ],
//                   ),
//               ],
//             ),
//           ),
//         );
//       },
//       transitionBuilder: (_, anim, __, child) {
//         return ScaleTransition(
//           scale: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
//           child: FadeTransition(opacity: anim, child: child),
//         );
//       },
//     );
//   }

//   Color colorForIndex(int index) => gridColors[index % gridColors.length];

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     timer?.cancel();
//     audioPlayer.dispose();
//     _confettiController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDarkMode = Theme.of(context).brightness == Brightness.dark;

//     return Scaffold(
//    appBar: AppBar(
//   backgroundColor: isDarkMode
//       ?  Color.fromARGB(255, 86, 63, 153) // Dark theme app bar color
//       : Color.fromARGB(255, 187, 180, 239), // Light theme app bar color
//   iconTheme: const IconThemeData(
//     color: Color.fromARGB(255, 0, 0, 0), // Back arrow color
//   ),
//   title: const Text(
//     'MEMORY',
//     style: TextStyle(
//       fontSize: 19,
//       fontWeight: FontWeight.bold,
//       letterSpacing: 1.5,
//       color: Color.fromARGB(255, 0, 0, 0), // White text for both themes
//       shadows: [
//         Shadow(
//           blurRadius: 4,
//           offset: Offset(1, 1),
//           color: Colors.black45,
//         ),
//       ],
//     ),
//   ),
//   centerTitle: true,
//   actions: [
//     IconButton(
//       icon: const Icon(
//         Icons.leaderboard,
//         color: Color.fromARGB(255, 0, 0, 0),
//       ),
//       tooltip: 'Leaderboard',
//       onPressed: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
//         );
//       },
//     ),
//     IconButton(
//       icon: const Icon(
//         Icons.refresh,
//         color: Color.fromARGB(255, 0, 0, 0),
//       ),
//       tooltip: 'Restart Game',
//       onPressed: resetGame,
//     ),
//   ],
// ),


//       body: Container(
//         decoration: BoxDecoration(
//           gradient: isDarkMode
//               ? const LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
//                 )
//               : const LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   colors: [Colors.white, Color(0xFFF0F0F0)],
//                 ),
//         ),
//         child: Column(
//           children: [
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   _buildStatusCard('⏳ Time', '$secondsRemaining s', isDarkMode),
//                   _buildStatusCard('⭐ Score', '$score', isDarkMode),
//                   _buildStatusCard('🏆 Record', '$record', isDarkMode),
                  
//                 ],
//               ),
//             ),
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: GridView.builder(
//                   itemCount: gridSize * gridSize,
//                   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: gridSize,
//                     crossAxisSpacing: 15,
//                     mainAxisSpacing: 15,
//                   ),
//                   itemBuilder: (context, index) => GestureDetector(
//                     onTap: () => onBoxTap(index),
//                     child: AnimatedContainer(
//                       duration: const Duration(milliseconds: 300),
//                       curve: Curves.easeInOut,
//                       decoration: BoxDecoration(
//                         color: isDarkMode
//                             ? null
//                             : (blinkingIndex == index
//                                 ? colorForIndex(index)
//                                 : colorForIndex(index).withOpacity(0.8)),
//                         gradient: isDarkMode
//                             ? LinearGradient(
//                                 begin: Alignment.topLeft,
//                                 end: Alignment.bottomRight,
//                                 colors: [
//                                   colorForIndex(index).withOpacity(
//                                     blinkingIndex == index ? 0.9 : 0.4,
//                                   ),
//                                   colorForIndex(index).withOpacity(
//                                     blinkingIndex == index ? 0.7 : 0.2,
//                                   ),
//                                 ],
//                               )
//                             : null,
//                         borderRadius: BorderRadius.circular(15),
//                         boxShadow: blinkingIndex == index
//                             ? [
//                                 BoxShadow(
//                                   color: colorForIndex(index).withOpacity(0.9),
//                                   blurRadius: 20,
//                                   spreadRadius: 2,
//                                 ),
//                               ]
//                             : [
//                                 BoxShadow(
//                                   color: Colors.black.withOpacity(0.2),
//                                   blurRadius: 4,
//                                   offset: const Offset(2, 2),
//                                 ),
//                               ],
//                       ),
//                       child: blinkingIndex == index
//                           ? const Center(
//                               child: Icon(
//                                 Icons.star,
//                                 color: Colors.white,
//                                 size: 30,
//                               ),
//                             )
//                           : null,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatusCard(String label, String value, bool isDarkMode) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//       decoration: BoxDecoration(
//         color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white,
//         borderRadius: BorderRadius.circular(15),
//         border: Border.all(
//           color: isDarkMode ? Colors.white.withOpacity(0.2) : Colors.white,
//         ),
//         boxShadow: isDarkMode
//             ? null
//             : [
//                 BoxShadow(
//                   color: Colors.grey.withOpacity(0.3),
//                   offset: const Offset(2, 2),
//                 ),
//               ],
//       ),
//       child: Column(
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               color: isDarkMode ? Colors.white.withOpacity(0.8) : Colors.black87,
//               fontSize: 14,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             value,
//             style: TextStyle(
//               color: isDarkMode ? Colors.white : Colors.black,
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }



////////////////////////////////////////////////////////////////////////////////

// import 'dart:async';
// import 'dart:math';

// import 'package:audioplayers/audioplayers.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:confetti/confetti.dart';

// import '../controllers/settings_controller.dart';

// class GameScreen extends StatefulWidget {
//   const GameScreen({super.key});

//   @override
//   State<GameScreen> createState() => _GameScreenState();
// }

// class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
//   final Random random = Random();
//   final AudioPlayer audioPlayer = AudioPlayer();

//   bool _isGameOver = false;
//   bool _isAppActive = true; // Track if app is in foreground

//   List<int> sequence = [];
//   int currentStep = 0;
//   int gridSize = 3;
//   int score = 0;
//   int record = 0;
//   int? blinkingIndex;
//   bool isPlayerTurn = false;
//   Timer? timer;
//   int secondsRemaining = 20;

//   final List<Color> gridColors = [
//     Colors.cyan,
//     Colors.purpleAccent,
//     Colors.amber,
//     Colors.lightGreen,
//     Colors.deepOrangeAccent,
//     Colors.lightBlueAccent,
//   ];

//   Future<void> resetGame() async {
//     setState(() {
//       sequence.clear();
//       score = 0;
//       secondsRemaining = getInitialTimeForDifficulty();
//       blinkingIndex = null;
//       isPlayerTurn = false;
//       _isGameOver = false;
//     });
//     startNewGame();
//   }

//   // Future<void> resetHighScore() async {
//   //   final prefs = await SharedPreferences.getInstance();
//   //   await prefs.remove('highScore');
//   //   setState(() {
//   //     record = 0;
//   //   });
//   //   ScaffoldMessenger.of(
//   //     context,
//   //   ).showSnackBar(const SnackBar(content: Text('High score reset!')));
//   // }

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _confettiController = ConfettiController(
//       duration: const Duration(seconds: 3),
//     );
//     loadRecord();
//     startNewGame();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.paused ||
//         state == AppLifecycleState.inactive) {
//       _isAppActive = false;
//       audioPlayer.stop();
//       timer?.cancel();
//     } else if (state == AppLifecycleState.resumed) {
//       _isAppActive = true;
//       // Resume timer if game is not over and it's player's turn
//       if (!_isGameOver && isPlayerTurn) {
//         startCountdown();
//       }
//     }
//   }

//   void loadRecord() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       record = prefs.getInt('highestScore') ?? 0;
//     });
//   }

//   late ConfettiController _confettiController;

//   Future<void> saveRecord(int newRecord) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setInt('highestScore', newRecord);
//   }

//   void startNewGame() {
//     sequence = [];
//     score = 0;
//     secondsRemaining = getInitialTimeForDifficulty();
//     addNextToSequence();
//     playSequence();
//   }

//   int getInitialTimeForDifficulty() {
//     // You can later set this via settings
//     String difficulty =
//         "medium"; // You can pull this from your settings controller
//     switch (difficulty) {
//       case "easy":
//         return 15; // Less time for easy
//       case "hard":
//         return 30; // More time for hard
//       default:
//         return 20; // Medium
//     }
//   }

//   void startCountdown() {
//     timer?.cancel();
//     timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       setState(() {
//         secondsRemaining--;
//         if (secondsRemaining <= 0) {
//           timer.cancel();
//           onTimeUp();
//         }
//       });
//     });
//   }

//   Future<void> playSound(String name) async {
//     if (!_isAppActive) return; // Prevent sound if app is not active
//     final settings = Provider.of<SettingsController>(context, listen: false);
//     if (!settings.soundEffects) return;
//     try {
//       await audioPlayer.play(AssetSource('sounds/$name'));
//     } catch (_) {}
//   }

//   Future<void> playSequence() async {
//     setState(() {
//       isPlayerTurn = false;
//       blinkingIndex = null;
//       currentStep = 0;
//     });

//     timer?.cancel(); // stop timer during sequence playback

//     await Future.delayed(const Duration(milliseconds: 500));

//     for (int i in sequence) {
//       setState(() => blinkingIndex = i);
//       await playSound('beep.mp3');
//       await Future.delayed(const Duration(milliseconds: 600));
//       setState(() => blinkingIndex = null);
//       await Future.delayed(const Duration(milliseconds: 300));
//     }

//     setState(() => isPlayerTurn = true);
//     startCountdown(); // resume timer when it's player's turn
//   }

//   void onBoxTap(int index) async {
//     if (!isPlayerTurn || _isGameOver) return;

//     setState(() => blinkingIndex = index);
//     await Future.delayed(const Duration(milliseconds: 200));
//     setState(() => blinkingIndex = null);

//     if (index == sequence[currentStep]) {
//       await playSound('beep.mp3');
//       currentStep++;
//       if (currentStep == sequence.length) {
//         score++;
//         bool isNewRecord = score > record;
//         if (isNewRecord) {
//           await saveRecord(score);
//         }
//         secondsRemaining += 5;
//         addNextToSequence();
//         await playSound('success.mp3');
//         playSequence();
//       }
//     } else {
//       timer?.cancel();
//       bool isNewRecord = score > record;
//       showGameOverDialog("Wrong box tapped.", isNewRecord);
//     }
//   }

//   void onTimeUp() {
//     if (_isGameOver) return;
//     timer?.cancel();
//     bool isNewRecord = score > record;
//     showGameOverDialog("Time's up!", isNewRecord);
//   }

//   void addNextToSequence() {
//     sequence.add(random.nextInt(gridSize * gridSize));
//   }

//   void showGameOverDialog(String message, bool isNewRecord) async {
//     if (_isGameOver) return; // Prevent multiple dialogs
//     _isGameOver = true; // Set flag immediately

//     if (isNewRecord) {
//       record = score;
//       await playSound('congrats.mp3');
//       _confettiController.play(); // 🎊
//     } else {
//       await playSound('fail.mp3');
//     }

//     showGeneralDialog(
//       context: context,
//       barrierDismissible: false,
//       barrierColor: Colors.black.withOpacity(0.85),
//       transitionDuration: const Duration(
//         milliseconds: 300,
//       ), // Faster transition
//       pageBuilder: (_, __, ___) {
//         return Dialog(
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//           insetAnimationDuration: const Duration(milliseconds: 200),
//           child: Material(
//             color: Colors.transparent,
//             child: Stack(
//               alignment: Alignment.center,
//               children: [
//                 // Modern background effect
//                 if (isNewRecord)
//                   Positioned.fill(
//                     child: Container(
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(24),
//                         gradient: RadialGradient(
//                           colors: [
//                             Colors.amber.withOpacity(0.2),
//                             Colors.transparent,
//                           ],
//                           radius: 0.5,
//                         ),
//                       ),
//                     ),
//                   ),

//                 // Main dialog card with modern neumorphic effect
//                 Container(
//                   padding: const EdgeInsets.all(24),
//                   decoration: BoxDecoration(
//                     color: Colors.deepPurple[900]?.withOpacity(0.98),
//                     borderRadius: BorderRadius.circular(24),
//                     border: Border.all(
//                       color:
//                           isNewRecord
//                               ? Colors.amberAccent.shade200.withOpacity(0.5)
//                               : Colors.deepPurpleAccent.shade400.withOpacity(
//                                 0.3,
//                               ),
//                       width: 1.5,
//                     ),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.4),
//                         blurRadius: 32,
//                         offset: const Offset(0, 16),
//                       ),
//                       BoxShadow(
//                         color: Colors.white.withOpacity(0.05),
//                         blurRadius: 8,
//                         offset: const Offset(-4, -4),
//                         spreadRadius: -4,
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       // Modern animated icon
//                       if (isNewRecord)
//                         TweenAnimationBuilder(
//                           duration: const Duration(
//                             milliseconds: 600,
//                           ), // Faster animation
//                           tween: Tween(begin: 0.0, end: 1.0),
//                           builder: (_, double value, __) {
//                             return Transform.scale(
//                               scale: Curves.easeOutBack.transform(value),
//                               child: Icon(
//                                 Icons.star_rounded,
//                                 size: 56,
//                                 color: Colors.amberAccent.shade200,
//                               ),
//                             );
//                           },
//                         ),

//                       const SizedBox(height: 16),
//                       // Modern text with gradient for new records
//                       isNewRecord
//                           ? ShaderMask(
//                             shaderCallback:
//                                 (bounds) => LinearGradient(
//                                   colors: [
//                                     Colors.amberAccent.shade200,
//                                     Colors.orangeAccent,
//                                   ],
//                                 ).createShader(bounds),
//                             child: Text(
//                               'NEW RECORD!',
//                               textAlign: TextAlign.center,
//                               style: TextStyle(
//                                 fontSize: 32,
//                                 fontWeight: FontWeight.w900,
//                                 letterSpacing: 1.2,
//                                 height: 1.2,
//                                 color: Colors.white,
//                               ),
//                             ),
//                           )
//                           : Text(
//                             'GAME OVER',
//                             textAlign: TextAlign.center,
//                             style: TextStyle(
//                               fontSize: 32,
//                               fontWeight: FontWeight.w900,
//                               color: Colors.white,
//                               letterSpacing: 1.2,
//                             ),
//                           ),

//                       const SizedBox(height: 12),
//                       TweenAnimationBuilder(
//                         duration: const Duration(
//                           milliseconds: 400,
//                         ), // Faster animation
//                         tween: Tween(begin: 0.0, end: 1.0),
//                         builder: (_, double value, __) {
//                           return Opacity(
//                             opacity: value,
//                             child: Transform.translate(
//                               offset: Offset(0, (1 - value) * 8),
//                               child: Text(
//                                 isNewRecord
//                                     ? 'Score: $score'
//                                     : '$message\nScore: $score',
//                                 textAlign: TextAlign.center,
//                                 style: TextStyle(
//                                   color: Colors.white.withOpacity(0.9),
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                       const SizedBox(height: 24),
//                       // Modern button with quick hover effect
//                       MouseRegion(
//                         cursor: SystemMouseCursors.click,
//                         child: AnimatedContainer(
//                           duration: const Duration(
//                             milliseconds: 150,
//                           ), // Faster animation
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(12),
//                             gradient: LinearGradient(
//                               colors: [
//                                 isNewRecord
//                                     ? Colors.amber.shade600
//                                     : Colors.deepPurpleAccent.shade400,
//                                 isNewRecord
//                                     ? Colors.orange.shade600
//                                     : Colors.indigoAccent.shade400,
//                               ],
//                             ),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.3),
//                                 blurRadius: 12,
//                                 offset: const Offset(0, 6),
//                               ),
//                             ],
//                           ),
//                           child: ElevatedButton(
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.transparent,
//                               shadowColor: Colors.transparent,
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 32,
//                                 vertical: 16,
//                               ),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               elevation: 0,
//                             ),
//                             onPressed: () {
//                               _isGameOver = false;
//                               Navigator.of(context).pop();
//                               resetGame();
//                             },
//                             child: const Text(
//                               'PLAY AGAIN',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                                 letterSpacing: 1.1,
//                                 color: Colors.white,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 // Confetti (modern colors)
//                 if (isNewRecord)
//                   ConfettiWidget(
//                     confettiController: _confettiController,
//                     blastDirectionality: BlastDirectionality.explosive,
//                     shouldLoop: false,
//                     emissionFrequency: 0.05,
//                     numberOfParticles: 20, // Slightly less for cleaner look
//                     maxBlastForce: 20,
//                     minBlastForce: 8,
//                     gravity: 0.2,
//                     colors: const [
//                       Colors.amberAccent,
//                       Colors.deepPurpleAccent,
//                       Colors.cyanAccent,
//                       Colors.pinkAccent,
//                     ], // Modern color palette
//                   ),
//               ],
//             ),
//           ),
//         );
//       },
//       transitionBuilder: (_, anim, __, child) {
//         return ScaleTransition(
//           scale: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
//           child: FadeTransition(opacity: anim, child: child),
//         );
//       },
//     );
//   }

//   // ignore: unused_element
//   Widget _buildDialogButton(
//     String text,
//     IconData icon,
//     Color color,
//     VoidCallback onPressed,
//   ) {
//     return ElevatedButton.icon(
//       icon: Icon(icon, size: 20),
//       label: Text(text),
//       onPressed: onPressed,
//       style: ElevatedButton.styleFrom(
//         backgroundColor: color.withOpacity(0.9),
//         foregroundColor: Colors.white,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//       ),
//     );
//   }

//   Color colorForIndex(int index) => gridColors[index % gridColors.length];

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     timer?.cancel();
//     audioPlayer.dispose();
//     _confettiController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDarkMode = Theme.of(context).brightness == Brightness.dark;

//     return Scaffold(
//       appBar: AppBar(
//         title: ShaderMask(
//           shaderCallback:
//               (bounds) => LinearGradient(
//                 colors:
//                     Theme.of(context).brightness == Brightness.dark
//                         ? [Colors.blueAccent, Colors.purpleAccent]
//                         : [Colors.deepPurple, Colors.indigo],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ).createShader(bounds),
//           child: const Text(
//             'MEMORY CHALLENGE',
//             style: TextStyle(
//               fontSize: 19,
//               fontWeight: FontWeight.bold,
//               letterSpacing: 1.5,
//               shadows: [
//                 Shadow(
//                   blurRadius: 4,
//                   offset: Offset(1, 1),
//                   color: Colors.black45,
//                 ),
//               ],
//             ),
//           ),
//         ),
//         centerTitle: true,
//         actions: [
//           IconButton(
//             icon: Icon(
//               Icons.refresh,
//               color:
//                   Theme.of(context).brightness == Brightness.dark
//                       ? Colors.white
//                       : Colors.deepPurple,
//             ),
//             // tooltip: 'Reset Record',
//             // onPressed: resetHighScore,
//             tooltip: 'Restart Game',
//             onPressed: resetGame,
//           ),
//         ],
//         flexibleSpace: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors:
//                   Theme.of(context).brightness == Brightness.dark
//                       ? [Colors.deepPurple.shade900, Colors.indigo.shade900]
//                       : [Colors.deepPurple.shade100, Colors.indigo.shade100],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//         ),
//         elevation: 4,
//         shadowColor: Colors.black.withOpacity(0.3),
//         shape: const RoundedRectangleBorder(
//           borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
//         ),
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient:
//               isDarkMode
//                   ? const LinearGradient(
//                     begin: Alignment.topCenter,
//                     end: Alignment.bottomCenter,
//                     colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
//                   )
//                   : const LinearGradient(
//                     begin: Alignment.topCenter,
//                     end: Alignment.bottomCenter,
//                     colors: [Colors.white, Color(0xFFF0F0F0)],
//                   ),
//         ),
//         child: Column(
//           children: [
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   _buildStatusCard('⏳ Time', '$secondsRemaining s', isDarkMode),
//                   _buildStatusCard('⭐ Score', '$score', isDarkMode),
//                   _buildStatusCard('🏆 Record', '$record', isDarkMode),
//                 ],
//               ),
//             ),
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: GridView.builder(
//                   itemCount: gridSize * gridSize,
//                   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: gridSize,
//                     crossAxisSpacing: 15,
//                     mainAxisSpacing: 15,
//                   ),
//                   itemBuilder:
//                       (context, index) => GestureDetector(
//                         onTap: () => onBoxTap(index),
//                         child: AnimatedContainer(
//                           duration: const Duration(milliseconds: 300),
//                           curve: Curves.easeInOut,
//                           decoration: BoxDecoration(
//                             color:
//                                 isDarkMode
//                                     ? null
//                                     : (blinkingIndex == index
//                                         ? colorForIndex(index)
//                                         : colorForIndex(
//                                           index,
//                                         ).withOpacity(0.8)),
//                             gradient:
//                                 isDarkMode
//                                     ? LinearGradient(
//                                       begin: Alignment.topLeft,
//                                       end: Alignment.bottomRight,
//                                       colors: [
//                                         colorForIndex(index).withOpacity(
//                                           blinkingIndex == index ? 0.9 : 0.4,
//                                         ),
//                                         colorForIndex(index).withOpacity(
//                                           blinkingIndex == index ? 0.7 : 0.2,
//                                         ),
//                                       ],
//                                     )
//                                     : null,
//                             borderRadius: BorderRadius.circular(15),
//                             boxShadow:
//                                 blinkingIndex == index
//                                     ? [
//                                       BoxShadow(
//                                         color: colorForIndex(
//                                           index,
//                                         ).withOpacity(0.9),
//                                         blurRadius: 20,
//                                         spreadRadius: 2,
//                                       ),
//                                     ]
//                                     : [
//                                       BoxShadow(
//                                         color: Colors.black.withOpacity(0.2),
//                                         blurRadius: 4,
//                                         offset: const Offset(2, 2),
//                                       ),
//                                     ],
//                           ),
//                           child:
//                               blinkingIndex == index
//                                   ? const Center(
//                                     child: Icon(
//                                       Icons.star,
//                                       color: Colors.white,
//                                       size: 30,
//                                     ),
//                                   )
//                                   : null,
//                         ),
//                       ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatusCard(String label, String value, bool isDarkMode) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//       decoration: BoxDecoration(
//         color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white,
//         borderRadius: BorderRadius.circular(15),
//         border: Border.all(
//           color: isDarkMode ? Colors.white.withOpacity(0.2) : Colors.white,
//         ),
//         boxShadow:
//             isDarkMode
//                 ? null
//                 : [
//                   BoxShadow(
//                     color: Colors.grey.withOpacity(0.3),
//                     offset: const Offset(2, 2),
//                   ),
//                 ],
//       ),
//       child: Column(
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               color:
//                   isDarkMode ? Colors.white.withOpacity(0.8) : Colors.black87,
//               fontSize: 14,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             value,
//             style: TextStyle(
//               color: isDarkMode ? Colors.white : Colors.black,
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
