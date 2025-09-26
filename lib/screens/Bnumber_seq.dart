// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:confetti/confetti.dart';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:provider/provider.dart';
// import '../controllers/settings_controller.dart';

// class NumberSequenceMemoryGame extends StatefulWidget {
//   const NumberSequenceMemoryGame({super.key});

//   @override
//   _NumberSequenceMemoryGameState createState() => _NumberSequenceMemoryGameState();
// }

// class _NumberSequenceMemoryGameState extends State<NumberSequenceMemoryGame> with SingleTickerProviderStateMixin {
//   final TextEditingController _inputController = TextEditingController();
//   final FocusNode _inputFocusNode = FocusNode();

//   late ConfettiController _confettiController;
//   late AnimationController _scaleController;
//   late AudioPlayer _audioPlayer;

//   final List<int> _sequence = [];
//   String _playerInput = '';
//   int _level = 1;
//   int _score = 0;
//   int _highScore = 0;
//   int _initialHighScore = 0; // Track the high score at session start

//   String _message = 'Press START to begin';
//   Color _messageColor = Colors.blueGrey; // Use a visible color for both themes

//   bool _isPlaying = false;
//   bool _isDisplaying = false;
//   bool _showTutorial = false;

//   @override
//   void initState() {
//     super.initState();
//     _confettiController = ConfettiController(duration: const Duration(seconds: 3));
//     _scaleController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 400),
//       lowerBound: 0.8,
//       upperBound: 1.0,
//     )..repeat(reverse: true);
//     _audioPlayer = AudioPlayer();
//     _loadHighScore();
//   }

//   @override
//   void dispose() {
//     _inputController.dispose();
//     _inputFocusNode.dispose();
//     _confettiController.dispose();
//     _scaleController.dispose();
//     super.dispose();
//   }

//   Future<void> _loadHighScore() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       _highScore = prefs.getInt('highScore') ?? 0;
//       _initialHighScore = _highScore; // Save initial high score for session
//     });
//   }

//   Future<void> _saveHighScore() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setInt('highScore', _highScore);
//   }

//   Future<void> _playSound(String asset) async {
//     await _audioPlayer.play(AssetSource(asset));
//   }

//   void _startGame() {
//     setState(() {
//       _sequence.clear();
//       _playerInput = '';
//       _level = 1;
//       _score = 0;
//       _message = 'Watch the sequence!';
//       _messageColor = Colors.blueAccent;
//       _isPlaying = true;
//       _showTutorial = false;
//     });
//     _addNumberToSequence();
//   }

//   void _restartGame() {
//     setState(() {
//       _sequence.clear();
//       _playerInput = '';
//       _level = 1;
//       _score = 0;
//       _message = 'Game reset. Press START to begin';
//       _messageColor = Theme.of(context).brightness == Brightness.dark
//           ? Colors.white
//           : Colors.blueGrey.shade800;
//       _isPlaying = false;
//       _showTutorial = false;
//     });
//   }

//   void _addNumberToSequence() {
//     setState(() {
//       _isDisplaying = true;
//       _playerInput = '';
//       _sequence.add(1 + (DateTime.now().millisecondsSinceEpoch % 9)); // random 1-9
//       _displaySequence();
//     });
//   }

//   Future<void> _displaySequence() async {
//     for (int number in _sequence) {
//       setState(() {
//         _playerInput = number.toString();
//       });
//       _playSound('sounds/beep.mp3'); // Play beep sound for each number
//       await Future.delayed(const Duration(seconds: 1));
//       setState(() {
//         _playerInput = '';
//       });
//       await Future.delayed(const Duration(milliseconds: 500));
//     }
//     setState(() {
//       _message = 'Your turn. Enter the full sequence.';
//       _messageColor = Colors.orange;
//       _isDisplaying = false;
//     });
//     // Always request focus and show keyboard for direct typing
//     Future.delayed(const Duration(milliseconds: 100), () {
//       if (mounted) {
//         FocusScope.of(context).requestFocus(_inputFocusNode);
//         SystemChannels.textInput.invokeMethod('TextInput.show');
//       }
//     });
//   }

//   void _checkInput(String input) {
//     setState(() {
//       _playerInput = input;
//     });
//   }

//   Future<void> _submitInput() async {
//     if (_isDisplaying || !_isPlaying) return;
//     // Disable input immediately to prevent double submit
//     setState(() {
//       _isDisplaying = true;
//     });

//     if (_playerInput == _sequence.join()) {
//       _score += _level * 10;
//       _level++;
//       // Show "Great!" or "Awesome!" before next turn
//       setState(() {
//         _message = (_level % 2 == 0) ? 'Awesome!' : 'Great!';
//         _messageColor = Colors.green;
//       });
//       _playSound('sounds/success.mp3');
//       if (_score > _initialHighScore && _highScore == _initialHighScore) {
//         _highScore = _score;
//         _saveHighScore();
//         _confettiController.play();
//       } else if (_score > _highScore) {
//         _highScore = _score;
//         _saveHighScore();
//       }
//       _inputController.clear();
//       await Future.delayed(const Duration(seconds: 1));
//       setState(() {
//         _message = 'Correct! Next level...';
//         _messageColor = Colors.green;
//       });
//       await Future.delayed(const Duration(milliseconds: 600));
//       _addNumberToSequence();
//     } else {
//       setState(() {
//         _message = 'Wrong! Game over.';
//         _messageColor = Colors.red;
//         _isPlaying = false;
//         _isDisplaying = false;
//       });
//       _playSound('sounds/fail.mp3');
//       _inputController.clear();
//       _inputFocusNode.unfocus();
//     }
//   }

//   Color _getMessageBackgroundColor(Color messageColor) {
//     if (messageColor == Colors.green) {
//       return const Color(0xFF81C784);
//     } else if (messageColor == Colors.red) {
//       return const Color(0xFFE57373);
//     } else if (messageColor == Colors.orange) {
//       return const Color(0xFFFFB74D);
//     } else if (messageColor == Colors.blueAccent) {
//       return const Color(0xFF64B5F6);
//     } else if (messageColor == Colors.white) {
//       return const Color(0xFFE0E0E0);
//     }
//     return Colors.grey.withOpacity(0.3);
//   }

//   Widget _buildStatCard(String label, int value, Color cardColor, Color labelColor, Color valueColor) {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//       decoration: BoxDecoration(
//         color: cardColor,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         children: [
//           Text(label, style: TextStyle(color: labelColor)),
//           const SizedBox(height: 6),
//           Text(value.toString(), style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 18)),
//         ],
//       ),
//     );
//   }

//   Widget _buildTutorialOverlay() {
//     final isDark = Provider.of<SettingsController>(context, listen: false).isDarkMode;
//     return Container(
//       color: Colors.black54,
//       child: Center(
//         child: Container(
//           margin: const EdgeInsets.all(24),
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: isDark ? const Color(0xFF222B3A) : Colors.white.withOpacity(0.95),
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 'How to Play',
//                 style: TextStyle(
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold,
//                   color: isDark ? Colors.white : Colors.black,
//                 ),
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 '1. Press START to begin.\n'
//                 '2. Watch the number sequence carefully.\n'
//                 '3. Enter the full sequence in the input box.\n'
//                 '4. Press SUBMIT to check.\n'
//                 '5. If correct, level up and repeat.\n'
//                 '6. If wrong, game over.\n\n'
//                 'Good luck!',
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: isDark ? Colors.white70 : Colors.black87,
//                 ),
//               ),
//               const SizedBox(height: 16),
//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF26A69A),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                   padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                 ),
//                 onPressed: () {
//                   setState(() {
//                     _showTutorial = false;
//                   });
//                 },
//                 child: const Text('Got it!', style: TextStyle(fontSize: 18)),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Provider.of<SettingsController>(context).isDarkMode;
//     final backgroundGradient = isDark
//         ? const LinearGradient(
//             colors: [Color(0xFF0D1B2A), Color(0xFF071B2B)],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           )
//         : const LinearGradient(
//             colors: [Color(0xFFFFF8E1), Color(0xFFE1F5FE)],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           );
//     final appBarColor = isDark ? const Color(0xFF102B44) : Colors.blue.shade100;
//     final appBarTextColor = isDark ? Colors.white : Colors.black87;
//     final cardColor = isDark ? const Color(0xFF334756) : Colors.white;
//     final statTextColor = isDark ? Colors.white70 : Colors.black54;
//     final statValueColor = isDark ? Colors.white : Colors.black87;
//     final messageBg = _getMessageBackgroundColor(_messageColor).withOpacity(0.3);
//     final inputFillColor = isDark ? const Color(0xFF1E2E43) : Colors.blue.shade50;
//     final inputHintColor = isDark ? Colors.grey[400] : Colors.blueGrey[300];
//     final restartBtnColor = isDark ? const Color(0xFF334756) : Colors.blue.shade200;
//     final submitBtnColor = _isPlaying
//         ? (isDark ? const Color(0xFF00B8D4) : Colors.green)
//         : (isDark ? const Color(0xFF26A69A) : Colors.blueAccent);
//     final submitTextColor = Colors.white;
//     final restartTextColor = isDark ? Colors.white70 : Colors.black87;

//     // Set message color for initial state based on theme
//     final initialMessageColor = isDark ? Colors.white : Colors.blueGrey.shade800;
//     // If the message is the initial one, override the color
//     final displayMessageColor =
//         _message == 'Press START to begin' ? initialMessageColor : _messageColor;

//     return Container(
//       decoration: BoxDecoration(gradient: backgroundGradient),
//       child: Scaffold(
//         backgroundColor: Colors.transparent,
//         appBar: AppBar(
//           title: Text('Number Sequence', style: TextStyle(color: appBarTextColor)),
//           backgroundColor: appBarColor,
//           elevation: 0,
//           leading: IconButton(
//             icon: Icon(Icons.arrow_back, color: appBarTextColor),
//             onPressed: () => Navigator.of(context).pop(),
//           ),
//           actions: [
//             IconButton(
//               icon: Icon(Icons.help_outline, color: appBarTextColor),
//               onPressed: () {
//                 setState(() {
//                   _showTutorial = true;
//                 });
//               },
//             ),
//           ],
//         ),
//         body: Stack(
//           children: [
//             SingleChildScrollView(
//               padding: const EdgeInsets.all(16),
//               reverse: true,
//               child: Column(
//                 children: [
//                   const SizedBox(height: 20),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       _buildStatCard('Level', _level, cardColor, statTextColor, statValueColor),
//                       _buildStatCard('Score', _score, cardColor, statTextColor, statValueColor),
//                       _buildStatCard('High Score', _highScore, cardColor, statTextColor, statValueColor),
//                     ],
//                   ),
//                   const SizedBox(height: 20),
//                   AnimatedContainer(
//                     duration: const Duration(milliseconds: 500),
//                     padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
//                     decoration: BoxDecoration(
//                       color: messageBg,
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: AnimatedDefaultTextStyle(
//                       duration: const Duration(milliseconds: 300),
//                       style: TextStyle(
//                         color: displayMessageColor,
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       child: Text(_message),
//                     ),
//                   ),
//                   const SizedBox(height: 30),
//                   GestureDetector(
//                     onTap: !_isPlaying
//                         ? () {
//                             _startGame();
//                           }
//                         : null,
//                     child: ScaleTransition(
//                       scale: _scaleController,
//                       child: Container(
//                         width: 150,
//                         height: 150,
//                         decoration: BoxDecoration(
//                           gradient: isDark
//                               ? const LinearGradient(
//                                   colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
//                                   begin: Alignment.topLeft,
//                                   end: Alignment.bottomRight,
//                                 )
//                               : const LinearGradient(
//                                   colors: [Color(0xFFB3E5FC), Color(0xFFFFF9C4)],
//                                   begin: Alignment.topLeft,
//                                   end: Alignment.bottomRight,
//                                 ),
//                           shape: BoxShape.circle,
//                           boxShadow: const [
//                             BoxShadow(
//                               color: Colors.black45,
//                               blurRadius: 15,
//                               offset: Offset(0, 6),
//                             ),
//                           ],
//                         ),
//                         child: Center(
//                           child: AnimatedSwitcher(
//                             duration: const Duration(milliseconds: 300),
//                             child: FittedBox(
//                               fit: BoxFit.scaleDown,
//                               child: Text(
//                                 _playerInput.isEmpty && !_isDisplaying
//                                     ? _isPlaying ? '?' : 'GO'
//                                     : _playerInput,
//                                 key: ValueKey<String>(_playerInput),
//                                 style: TextStyle(
//                                   fontSize: 60,
//                                   fontWeight: FontWeight.bold,
//                                   color: isDark ? Colors.white : Colors.black,
//                                   shadows: [
//                                     Shadow(
//                                       color: isDark ? Colors.black54 : Colors.grey.shade200,
//                                       offset: const Offset(1, 1),
//                                       blurRadius: 2,
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 30),
//                   TextField(
//                     controller: _inputController,
//                     focusNode: _inputFocusNode,
//                     autofocus: true,
//                     onChanged: _checkInput,
//                     onSubmitted: (_) => _submitInput(),
//                     enabled: _isPlaying && !_isDisplaying,
//                     keyboardType: TextInputType.number,
//                     inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontSize: 24,
//                       color: isDark ? Colors.white : Colors.black,
//                       fontWeight: FontWeight.bold,
//                       shadows: [
//                         Shadow(
//                           color: isDark ? Colors.black87 : Colors.grey.shade200,
//                           offset: const Offset(0, 1),
//                           blurRadius: 2,
//                         )
//                       ],
//                     ),
//                     decoration: InputDecoration(
//                       filled: true,
//                       fillColor: inputFillColor,
//                       hintText: 'Enter full sequence',
//                       hintStyle: TextStyle(color: inputHintColor),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide.none,
//                       ),
//                       contentPadding: const EdgeInsets.symmetric(vertical: 20),
//                     ),
//                     autofillHints: const [], // Disable autofill suggestions
//                     enableSuggestions: false, // Disable suggestions
//                     autocorrect: false, // Disable autocorrect
//                   ),
//                   const SizedBox(height: 30),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: ElevatedButton(
//                           onPressed: _restartGame,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: restartBtnColor,
//                             padding: const EdgeInsets.symmetric(vertical: 16),
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                           ),
//                           child: Text(
//                             'RESTART',
//                             style: TextStyle(fontWeight: FontWeight.bold, color: restartTextColor),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: ElevatedButton(
//                           onPressed: (_isPlaying && !_isDisplaying) ? _submitInput : null,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: submitBtnColor,
//                             padding: const EdgeInsets.symmetric(vertical: 16),
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                           ),
//                           child: Text(
//                             _isPlaying ? 'SUBMIT' : 'START',
//                             style: TextStyle(fontWeight: FontWeight.bold, color: submitTextColor),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 30),
//                 ],
//               ),
//             ),
//             Align(
//               alignment: Alignment.topCenter,
//               child: ConfettiWidget(
//                 confettiController: _confettiController,
//                 blastDirectionality: BlastDirectionality.explosive,
//                 shouldLoop: false,
//                 colors: const [
//                   Color(0xFF00B8D4),
//                   Color(0xFF26A69A),
//                   Color(0xFFFF6F61),
//                   Color(0xFFFFC107),
//                   Color(0xFF8E24AA),
//                 ],
//               ),
//             ),
//             if (_showTutorial) _buildTutorialOverlay(),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/settings_controller.dart';
import 'leaderboard_screen2.dart';
// import 'settings_screen.dart';

class NumberSequenceMemoryGame extends StatefulWidget {
  const NumberSequenceMemoryGame({super.key});

  @override
  _NumberSequenceMemoryGameState createState() => _NumberSequenceMemoryGameState();
}

class _NumberSequenceMemoryGameState extends State<NumberSequenceMemoryGame> 
    with SingleTickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late ConfettiController _confettiController;
  late AnimationController _scaleController;
  late AudioPlayer _audioPlayer;

  final List<int> _sequence = [];
  String _playerInput = '';
  int _level = 1;
  int _score = 0;
  int _personalRecord = 0;
  int _initialPersonalRecord = 0;
  String _message = 'Press START to begin';
  Color _messageColor = Colors.blueGrey;
  bool _isPlaying = false;
  bool _isDisplaying = false;
  bool _showTutorial = false;
  bool _isGameOver = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      lowerBound: 0.8,
      upperBound: 1.0,
    )..repeat(reverse: true);
    _audioPlayer = AudioPlayer();
    _loadPersonalRecord();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocusNode.dispose();
    _confettiController.dispose();
    _scaleController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadPersonalRecord() async {
    final prefs = await SharedPreferences.getInstance();
    final user = _auth.currentUser;
    final recordKey = user != null ? 'personalRecord_${user.uid}' : 'personalRecord_guest';
    
    setState(() {
      _personalRecord = prefs.getInt(recordKey) ?? 0;
      _initialPersonalRecord = _personalRecord;
    });
  }

  Future<void> _savePersonalRecord() async {
    final prefs = await SharedPreferences.getInstance();
    final user = _auth.currentUser;
    final recordKey = user != null ? 'personalRecord_${user.uid}' : 'personalRecord_guest';
    
    await prefs.setInt(recordKey, _personalRecord);
    
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'username': user.displayName ?? 'Player',
        'profileImageUrl': user.photoURL ?? '',
        'lastUpdated': FieldValue.serverTimestamp(),
        'gameStats': {
          'numberSequence': {
            'personalRecord': _personalRecord,
            'highestLevel': _level,
            'lastPlayed': FieldValue.serverTimestamp(),
          }
        }
      }, SetOptions(merge: true));
    }
  }

  Future<void> _playSound(String asset) async {
    final settings = Provider.of<SettingsController>(context, listen: false);
    if (!settings.soundEffects) return;
    
    try {
      await _audioPlayer.setVolume(settings.volumeLevel);
      await _audioPlayer.play(AssetSource('sounds/$asset'));
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  void _startGame() {
    setState(() {
      _sequence.clear();
      _playerInput = '';
      _level = 1;
      _score = 0;
      _message = 'Watch the sequence!';
      _messageColor = Colors.blueAccent;
      _isPlaying = true;
      _isGameOver = false;
      _showTutorial = false;
    });
    _addNumberToSequence();
  }

  void _restartGame() {
    setState(() {
      _sequence.clear();
      _playerInput = '';
      _level = 1;
      _score = 0;
      _message = 'Game reset. Press START to begin';
      _messageColor = Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : Colors.blueGrey.shade800;
      _isPlaying = false;
      _isGameOver = false;
      _showTutorial = false;
    });
  }

  void _addNumberToSequence() {
    setState(() {
      _isDisplaying = true;
      _playerInput = '';
      _sequence.add(1 + (DateTime.now().millisecondsSinceEpoch % 9));
      _displaySequence();
    });
  }

  Future<void> _displaySequence() async {
    for (int number in _sequence) {
      setState(() {
        _playerInput = number.toString();
      });
      await _playSound('beep.mp3');
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _playerInput = '';
      });
      await Future.delayed(const Duration(milliseconds: 500));
    }
    setState(() {
      _message = 'Your turn. Enter the full sequence.';
      _messageColor = Colors.orange;
      _isDisplaying = false;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        FocusScope.of(context).requestFocus(_inputFocusNode);
        SystemChannels.textInput.invokeMethod('TextInput.show');
      }
    });
  }

  void _checkInput(String input) {
    setState(() {
      _playerInput = input;
    });
  }

  Future<void> _submitInput() async {
    if (_isDisplaying || !_isPlaying || _isGameOver) return;
    
    setState(() {
      _isDisplaying = true;
    });

    if (_playerInput == _sequence.join()) {
      _score += _level * 10;
      _level++;
      
      setState(() {
        _message = (_level % 2 == 0) ? 'Awesome!' : 'Great!';
        _messageColor = Colors.green;
      });
      
      await _playSound('success.mp3');
      
      bool isNewRecord = _score > _initialPersonalRecord && _personalRecord == _initialPersonalRecord;
      if (isNewRecord) {
        _personalRecord = _score;
        await _savePersonalRecord();
        _confettiController.play();
      } else if (_score > _personalRecord) {
        _personalRecord = _score;
        await _savePersonalRecord();
      }
      
      _inputController.clear();
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _message = 'Correct! Next level...';
        _messageColor = Colors.green;
      });
      await Future.delayed(const Duration(milliseconds: 600));
      _addNumberToSequence();
    } else {
      _gameOver();
    }
  }

  void _gameOver() async {
    setState(() {
      _message = 'Wrong! Game over.';
      _messageColor = Colors.red;
      _isPlaying = false;
      _isDisplaying = false;
      _isGameOver = true;
    });
    
    await _playSound('fail.mp3');
    _inputController.clear();
    _inputFocusNode.unfocus();
    
    bool isNewRecord = _score > _initialPersonalRecord;
    if (isNewRecord) {
      await _showGameOverDialog(true);
    } else {
      await _showGameOverDialog(false);
    }
  }

  Future<void> _showGameOverDialog(bool isNewRecord) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
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
            isNewRecord ? 'NEW RECORD!' : 'GAME OVER',
            style: TextStyle(
              color: isNewRecord ? Colors.amber : (isDark ? Colors.white : Colors.black),
              fontWeight: FontWeight.bold
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your score: $_score',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontSize: 18
                ),
              ),
              if (isNewRecord)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    'Previous record: $_initialPersonalRecord',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 16
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _restartGame();
              },
              child: Text(
                'RESTART',
                style: TextStyle(
                  color: isDark ? Colors.blueAccent : Colors.blue,
                  fontSize: 16
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getMessageBackgroundColor(Color messageColor) {
    if (messageColor == Colors.green) {
      return const Color(0xFF81C784);
    } else if (messageColor == Colors.red) {
      return const Color(0xFFE57373);
    } else if (messageColor == Colors.orange) {
      return const Color(0xFFFFB74D);
    } else if (messageColor == Colors.blueAccent) {
      return const Color(0xFF64B5F6);
    } else if (messageColor == Colors.white) {
      return const Color(0xFFE0E0E0);
    }
    return Colors.grey.withOpacity(0.3);
  }

  Widget _buildStatCard(String label, int value, Color cardColor, Color labelColor, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: labelColor)),
          const SizedBox(height: 6),
          Text(value.toString(), style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildTutorialOverlay() {
    final isDark = Provider.of<SettingsController>(context, listen: false).isDarkMode;
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF222B3A) : Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How to Play',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '1. Press START to begin.\n'
                '2. Watch the number sequence carefully.\n'
                '3. Enter the full sequence in the input box.\n'
                '4. Press SUBMIT to check.\n'
                '5. If correct, level up and repeat.\n'
                '6. If wrong, game over.\n\n'
                'Good luck!',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF26A69A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () {
                  setState(() {
                    _showTutorial = false;
                  });
                },
                child: const Text('Got it!', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsController>(context);
    final isDark = settings.isDarkMode;
    final backgroundGradient = isDark
        ? const LinearGradient(
            colors: [Color(0xFF0D1B2A), Color(0xFF071B2B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : const LinearGradient(
            colors: [Color(0xFFFFF8E1), Color(0xFFE1F5FE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );
    final appBarColor = isDark ? const Color(0xFF102B44) : Colors.blue.shade100;
    final appBarTextColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? const Color(0xFF334756) : Colors.white;
    final statTextColor = isDark ? Colors.white70 : Colors.black54;
    final statValueColor = isDark ? Colors.white : Colors.black87;
    final messageBg = _getMessageBackgroundColor(_messageColor).withOpacity(0.3);
    final inputFillColor = isDark ? const Color(0xFF1E2E43) : Colors.blue.shade50;
    final inputHintColor = isDark ? Colors.grey[400] : Colors.blueGrey[300];
    final restartBtnColor = isDark ? const Color(0xFF334756) : Colors.blue.shade200;
    final submitBtnColor = _isPlaying
        ? (isDark ? const Color(0xFF00B8D4) : Colors.green)
        : (isDark ? const Color(0xFF26A69A) : Colors.blueAccent);
    final submitTextColor = Colors.white;
    final restartTextColor = isDark ? Colors.white70 : Colors.black87;
    final displayMessageColor =
        _message == 'Press START to begin' ? (isDark ? Colors.white : Colors.blueGrey.shade800) : _messageColor;

    return Container(
      decoration: BoxDecoration(gradient: backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('N.Sequence', style: TextStyle(color: appBarTextColor)),
          centerTitle: true,
          backgroundColor: appBarColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: appBarTextColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.leaderboard, color: appBarTextColor),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LeaderboardScreen2()),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.help_outline, color: appBarTextColor),
              onPressed: () {
                setState(() {
                  _showTutorial = true;
                });
              },
            ),
            // IconButton(
            //   icon: Icon(Icons.settings, color: appBarTextColor),
            //   onPressed: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(builder: (context) => const SettingsScreen()),
            //     );
            //   },
            // ),
          ],
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              reverse: true,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatCard('Level', _level, cardColor, statTextColor, statValueColor),
                      _buildStatCard('Score', _score, cardColor, statTextColor, statValueColor),
                      _buildStatCard('Record', _personalRecord, cardColor, statTextColor, statValueColor),
                    ],
                  ),
                  if (settings.soundEffects)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(Icons.volume_up, 
                            size: 14,
                            color: isDark ? Colors.white70 : Colors.black54),
                          const SizedBox(width: 4),
                          Text(
                            'Volume: ${(settings.volumeLevel * 100).round()}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    decoration: BoxDecoration(
                      color: messageBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: TextStyle(
                        color: displayMessageColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      child: Text(_message),
                    ),
                  ),
                  const SizedBox(height: 30),
                  GestureDetector(
                    onTap: !_isPlaying
                        ? () {
                            _startGame();
                          }
                        : null,
                    child: ScaleTransition(
                      scale: _scaleController,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          gradient: isDark
                              ? const LinearGradient(
                                  colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : const LinearGradient(
                                  colors: [Color(0xFFB3E5FC), Color(0xFFFFF9C4)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black45,
                              blurRadius: 15,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _playerInput.isEmpty && !_isDisplaying
                                    ? _isPlaying ? '?' : 'GO'
                                    : _playerInput,
                                key: ValueKey<String>(_playerInput),
                                style: TextStyle(
                                  fontSize: 60,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black,
                                  shadows: [
                                    Shadow(
                                      color: isDark ? Colors.black54 : Colors.grey.shade200,
                                      offset: const Offset(1, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: _inputController,
                    focusNode: _inputFocusNode,
                    autofocus: true,
                    onChanged: _checkInput,
                    onSubmitted: (_) => _submitInput(),
                    enabled: _isPlaying && !_isDisplaying,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: isDark ? Colors.black87 : Colors.grey.shade200,
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                        )
                      ],
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: inputFillColor,
                      hintText: 'Enter full sequence',
                      hintStyle: TextStyle(color: inputHintColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                    autofillHints: const [],
                    enableSuggestions: false,
                    autocorrect: false,
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _restartGame,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: restartBtnColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            'RESTART',
                            style: TextStyle(fontWeight: FontWeight.bold, color: restartTextColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (_isPlaying && !_isDisplaying) ? _submitInput : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: submitBtnColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            _isPlaying ? 'SUBMIT' : 'START',
                            style: TextStyle(fontWeight: FontWeight.bold, color: submitTextColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  Color(0xFF00B8D4),
                  Color(0xFF26A69A),
                  Color(0xFFFF6F61),
                  Color(0xFFFFC107),
                  Color(0xFF8E24AA),
                ],
              ),
            ),
            if (_showTutorial) _buildTutorialOverlay(),
          ],
        ),
      ),
    );
  }
}


// import 'dart:async';////////////////////////////////////////////////////
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:confetti/confetti.dart';
// import '/screens/leaderboard_screen2.dart';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:provider/provider.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../controllers/settings_controller.dart';

// class NumberSequenceMemoryGame extends StatefulWidget {
//   const NumberSequenceMemoryGame({super.key});

//   @override
//   _NumberSequenceMemoryGameState createState() => _NumberSequenceMemoryGameState();
// }

// class _NumberSequenceMemoryGameState extends State<NumberSequenceMemoryGame> with SingleTickerProviderStateMixin {
//   final TextEditingController _inputController = TextEditingController();
//   final FocusNode _inputFocusNode = FocusNode();
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   late ConfettiController _confettiController;
//   late AnimationController _scaleController;
//   late AudioPlayer _audioPlayer;

//   final List<int> _sequence = [];
//   String _playerInput = '';
//   int _level = 1;
//   int _score = 0;
//   int _personalRecord = 0;
//   int _initialPersonalRecord = 0;
//   String _message = 'Press START to begin';
//   Color _messageColor = Colors.blueGrey;
//   bool _isPlaying = false;
//   bool _isDisplaying = false;
//   bool _showTutorial = false;
//   bool _isGameOver = false;

//   @override
//   void initState() {
//     super.initState();
//     _confettiController = ConfettiController(duration: const Duration(seconds: 3));
//     _scaleController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 400),
//       lowerBound: 0.8,
//       upperBound: 1.0,
//     )..repeat(reverse: true);
//     _audioPlayer = AudioPlayer();
//     _loadPersonalRecord();
//   }

//   @override
//   void dispose() {
//     _inputController.dispose();
//     _inputFocusNode.dispose();
//     _confettiController.dispose();
//     _scaleController.dispose();
//     super.dispose();
//   }

//   Future<void> _loadPersonalRecord() async {
//     final prefs = await SharedPreferences.getInstance();
//     final user = _auth.currentUser;
//     final recordKey = user != null ? 'personalRecord_${user.uid}' : 'personalRecord_guest';
    
//     setState(() {
//       _personalRecord = prefs.getInt(recordKey) ?? 0;
//       _initialPersonalRecord = _personalRecord;
//     });
//   }

//   Future<void> _savePersonalRecord() async {
//     final prefs = await SharedPreferences.getInstance();
//     final user = _auth.currentUser;
//     final recordKey = user != null ? 'personalRecord_${user.uid}' : 'personalRecord_guest';
    
//     await prefs.setInt(recordKey, _personalRecord);
    
//     if (user != null) {
//       await _firestore.collection('users').doc(user.uid).set({
//         'username': user.displayName ?? 'Player',
//         'profileImageUrl': user.photoURL ?? '',
//         'lastUpdated': FieldValue.serverTimestamp(),
//         'gameStats': {
//           'numberSequence': {
//             'personalRecord': _personalRecord,
//             'highestLevel': _level,
//             'lastPlayed': FieldValue.serverTimestamp(),
//           }
//         }
//       }, SetOptions(merge: true));
//     }
//   }

//   Future<void> _playSound(String asset) async {
//     await _audioPlayer.play(AssetSource(asset));
//   }

//   void _startGame() {
//     setState(() {
//       _sequence.clear();
//       _playerInput = '';
//       _level = 1;
//       _score = 0;
//       _message = 'Watch the sequence!';
//       _messageColor = Colors.blueAccent;
//       _isPlaying = true;
//       _isGameOver = false;
//       _showTutorial = false;
//     });
//     _addNumberToSequence();
//   }

//   void _restartGame() {
//     setState(() {
//       _sequence.clear();
//       _playerInput = '';
//       _level = 1;
//       _score = 0;
//       _message = 'Game reset. Press START to begin';
//       _messageColor = Theme.of(context).brightness == Brightness.dark
//           ? Colors.white
//           : Colors.blueGrey.shade800;
//       _isPlaying = false;
//       _isGameOver = false;
//       _showTutorial = false;
//     });
//   }

//   void _addNumberToSequence() {
//     setState(() {
//       _isDisplaying = true;
//       _playerInput = '';
//       _sequence.add(1 + (DateTime.now().millisecondsSinceEpoch % 9));
//       _displaySequence();
//     });
//   }

//   Future<void> _displaySequence() async {
//     for (int number in _sequence) {
//       setState(() {
//         _playerInput = number.toString();
//       });
//       _playSound('sounds/beep.mp3');
//       await Future.delayed(const Duration(seconds: 1));
//       setState(() {
//         _playerInput = '';
//       });
//       await Future.delayed(const Duration(milliseconds: 500));
//     }
//     setState(() {
//       _message = 'Your turn. Enter the full sequence.';
//       _messageColor = Colors.orange;
//       _isDisplaying = false;
//     });
//     Future.delayed(const Duration(milliseconds: 100), () {
//       if (mounted) {
//         FocusScope.of(context).requestFocus(_inputFocusNode);
//         SystemChannels.textInput.invokeMethod('TextInput.show');
//       }
//     });
//   }

//   void _checkInput(String input) {
//     setState(() {
//       _playerInput = input;
//     });
//   }

//   Future<void> _submitInput() async {
//     if (_isDisplaying || !_isPlaying || _isGameOver) return;
    
//     setState(() {
//       _isDisplaying = true;
//     });

//     if (_playerInput == _sequence.join()) {
//       _score += _level * 10;
//       _level++;
      
//       setState(() {
//         _message = (_level % 2 == 0) ? 'Awesome!' : 'Great!';
//         _messageColor = Colors.green;
//       });
      
//       _playSound('sounds/success.mp3');
      
//       bool isNewRecord = _score > _initialPersonalRecord && _personalRecord == _initialPersonalRecord;
//       if (isNewRecord) {
//         _personalRecord = _score;
//         await _savePersonalRecord();
//         _confettiController.play();
//       } else if (_score > _personalRecord) {
//         _personalRecord = _score;
//         await _savePersonalRecord();
//       }
      
//       _inputController.clear();
//       await Future.delayed(const Duration(seconds: 1));
//       setState(() {
//         _message = 'Correct! Next level...';
//         _messageColor = Colors.green;
//       });
//       await Future.delayed(const Duration(milliseconds: 600));
//       _addNumberToSequence();
//     } else {
//       _gameOver();
//     }
//   }

//   void _gameOver() async {
//     setState(() {
//       _message = 'Wrong! Game over.';
//       _messageColor = Colors.red;
//       _isPlaying = false;
//       _isDisplaying = false;
//       _isGameOver = true;
//     });
    
//     _playSound('sounds/fail.mp3');
//     _inputController.clear();
//     _inputFocusNode.unfocus();
    
//     bool isNewRecord = _score > _initialPersonalRecord;
//     if (isNewRecord) {
//       await _showGameOverDialog(true);
//     } else {
//       await _showGameOverDialog(false);
//     }
//   }

//   Future<void> _showGameOverDialog(bool isNewRecord) async {
//     await showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) {
//         final isDark = Theme.of(context).brightness == Brightness.dark;
        
//         return AlertDialog(
//           backgroundColor: isDark ? const Color(0xFF2D2D3D) : Colors.white,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//             side: BorderSide(
//               color: isDark ? Colors.blueAccent : Colors.blue,
//               width: 2
//             )
//           ),
//           title: Text(
//             isNewRecord ? 'NEW RECORD!' : 'GAME OVER',
//             style: TextStyle(
//               color: isNewRecord ? Colors.amber : (isDark ? Colors.white : Colors.black),
//               fontWeight: FontWeight.bold
//             ),
//           ),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 'Your score: $_score',
//                 style: TextStyle(
//                   color: isDark ? Colors.white70 : Colors.black87,
//                   fontSize: 18
//                 ),
//               ),
//               if (isNewRecord)
//                 Padding(
//                   padding: const EdgeInsets.only(top: 10),
//                   child: Text(
//                     'Previous record: $_initialPersonalRecord',
//                     style: TextStyle(
//                       color: isDark ? Colors.white60 : Colors.black54,
//                       fontSize: 16
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 _restartGame();
//               },
//               child: Text(
//                 'RESTART',
//                 style: TextStyle(
//                   color: isDark ? Colors.blueAccent : Colors.blue,
//                   fontSize: 16
//                 ),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Color _getMessageBackgroundColor(Color messageColor) {
//     if (messageColor == Colors.green) {
//       return const Color(0xFF81C784);
//     } else if (messageColor == Colors.red) {
//       return const Color(0xFFE57373);
//     } else if (messageColor == Colors.orange) {
//       return const Color(0xFFFFB74D);
//     } else if (messageColor == Colors.blueAccent) {
//       return const Color(0xFF64B5F6);
//     } else if (messageColor == Colors.white) {
//       return const Color(0xFFE0E0E0);
//     }
//     return Colors.grey.withOpacity(0.3);
//   }

//   Widget _buildStatCard(String label, int value, Color cardColor, Color labelColor, Color valueColor) {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//       decoration: BoxDecoration(
//         color: cardColor,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         children: [
//           Text(label, style: TextStyle(color: labelColor)),
//           const SizedBox(height: 6),
//           Text(value.toString(), style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 18)),
//         ],
//       ),
//     );
//   }

//   Widget _buildTutorialOverlay() {
//     final isDark = Provider.of<SettingsController>(context, listen: false).isDarkMode;
//     return Container(
//       color: Colors.black54,
//       child: Center(
//         child: Container(
//           margin: const EdgeInsets.all(24),
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: isDark ? const Color(0xFF222B3A) : Colors.white.withOpacity(0.95),
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 'How to Play',
//                 style: TextStyle(
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold,
//                   color: isDark ? Colors.white : Colors.black,
//                 ),
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 '1. Press START to begin.\n'
//                 '2. Watch the number sequence carefully.\n'
//                 '3. Enter the full sequence in the input box.\n'
//                 '4. Press SUBMIT to check.\n'
//                 '5. If correct, level up and repeat.\n'
//                 '6. If wrong, game over.\n\n'
//                 'Good luck!',
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: isDark ? Colors.white70 : Colors.black87,
//                 ),
//               ),
//               const SizedBox(height: 16),
//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF26A69A),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                   padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                 ),
//                 onPressed: () {
//                   setState(() {
//                     _showTutorial = false;
//                   });
//                 },
//                 child: const Text('Got it!', style: TextStyle(fontSize: 18)),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Provider.of<SettingsController>(context).isDarkMode;
//     final backgroundGradient = isDark
//         ? const LinearGradient(
//             colors: [Color(0xFF0D1B2A), Color(0xFF071B2B)],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           )
//         : const LinearGradient(
//             colors: [Color(0xFFFFF8E1), Color(0xFFE1F5FE)],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           );
//     final appBarColor = isDark ? const Color(0xFF102B44) : Colors.blue.shade100;
//     final appBarTextColor = isDark ? Colors.white : Colors.black87;
//     final cardColor = isDark ? const Color(0xFF334756) : Colors.white;
//     final statTextColor = isDark ? Colors.white70 : Colors.black54;
//     final statValueColor = isDark ? Colors.white : Colors.black87;
//     final messageBg = _getMessageBackgroundColor(_messageColor).withOpacity(0.3);
//     final inputFillColor = isDark ? const Color(0xFF1E2E43) : Colors.blue.shade50;
//     final inputHintColor = isDark ? Colors.grey[400] : Colors.blueGrey[300];
//     final restartBtnColor = isDark ? const Color(0xFF334756) : Colors.blue.shade200;
//     final submitBtnColor = _isPlaying
//         ? (isDark ? const Color(0xFF00B8D4) : Colors.green)
//         : (isDark ? const Color(0xFF26A69A) : Colors.blueAccent);
//     final submitTextColor = Colors.white;
//     final restartTextColor = isDark ? Colors.white70 : Colors.black87;
//     final displayMessageColor =
//         _message == 'Press START to begin' ? (isDark ? Colors.white : Colors.blueGrey.shade800) : _messageColor;

//     return Container(
//       decoration: BoxDecoration(gradient: backgroundGradient),
//       child: Scaffold(
//         backgroundColor: Colors.transparent,
//         appBar: AppBar(
//           title: Text('N.Sequence', style: TextStyle(color: appBarTextColor)),
//           centerTitle: true,
//           backgroundColor: appBarColor,
//           elevation: 0,
//           leading: IconButton(
//             icon: Icon(Icons.arrow_back, color: appBarTextColor),
//             onPressed: () => Navigator.of(context).pop(),
//           ),
//           actions: [
//             IconButton(
//               icon: Icon(Icons.leaderboard, color: appBarTextColor),
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => const LeaderboardScreen2()),
//                 );
//               },
//             ),
//             IconButton(
//               icon: Icon(Icons.help_outline, color: appBarTextColor),
//               onPressed: () {
//                 setState(() {
//                   _showTutorial = true;
//                 });
//               },
//             ),
//           ],
//         ),
//         body: Stack(
//           children: [
//             SingleChildScrollView(
//               padding: const EdgeInsets.all(16),
//               reverse: true,
//               child: Column(
//                 children: [
//                   const SizedBox(height: 20),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       _buildStatCard('Level', _level, cardColor, statTextColor, statValueColor),
//                       _buildStatCard('Score', _score, cardColor, statTextColor, statValueColor),
//                       _buildStatCard('Record', _personalRecord, cardColor, statTextColor, statValueColor),
//                     ],
//                   ),
//                   const SizedBox(height: 20),
//                   AnimatedContainer(
//                     duration: const Duration(milliseconds: 500),
//                     padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
//                     decoration: BoxDecoration(
//                       color: messageBg,
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: AnimatedDefaultTextStyle(
//                       duration: const Duration(milliseconds: 300),
//                       style: TextStyle(
//                         color: displayMessageColor,
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       child: Text(_message),
//                     ),
//                   ),
//                   const SizedBox(height: 30),
//                   GestureDetector(
//                     onTap: !_isPlaying
//                         ? () {
//                             _startGame();
//                           }
//                         : null,
//                     child: ScaleTransition(
//                       scale: _scaleController,
//                       child: Container(
//                         width: 150,
//                         height: 150,
//                         decoration: BoxDecoration(
//                           gradient: isDark
//                               ? const LinearGradient(
//                                   colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
//                                   begin: Alignment.topLeft,
//                                   end: Alignment.bottomRight,
//                                 )
//                               : const LinearGradient(
//                                   colors: [Color(0xFFB3E5FC), Color(0xFFFFF9C4)],
//                                   begin: Alignment.topLeft,
//                                   end: Alignment.bottomRight,
//                                 ),
//                           shape: BoxShape.circle,
//                           boxShadow: const [
//                             BoxShadow(
//                               color: Colors.black45,
//                               blurRadius: 15,
//                               offset: Offset(0, 6),
//                             ),
//                           ],
//                         ),
//                         child: Center(
//                           child: AnimatedSwitcher(
//                             duration: const Duration(milliseconds: 300),
//                             child: FittedBox(
//                               fit: BoxFit.scaleDown,
//                               child: Text(
//                                 _playerInput.isEmpty && !_isDisplaying
//                                     ? _isPlaying ? '?' : 'GO'
//                                     : _playerInput,
//                                 key: ValueKey<String>(_playerInput),
//                                 style: TextStyle(
//                                   fontSize: 60,
//                                   fontWeight: FontWeight.bold,
//                                   color: isDark ? Colors.white : Colors.black,
//                                   shadows: [
//                                     Shadow(
//                                       color: isDark ? Colors.black54 : Colors.grey.shade200,
//                                       offset: const Offset(1, 1),
//                                       blurRadius: 2,
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 30),
//                   TextField(
//                     controller: _inputController,
//                     focusNode: _inputFocusNode,
//                     autofocus: true,
//                     onChanged: _checkInput,
//                     onSubmitted: (_) => _submitInput(),
//                     enabled: _isPlaying && !_isDisplaying,
//                     keyboardType: TextInputType.number,
//                     inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontSize: 24,
//                       color: isDark ? Colors.white : Colors.black,
//                       fontWeight: FontWeight.bold,
//                       shadows: [
//                         Shadow(
//                           color: isDark ? Colors.black87 : Colors.grey.shade200,
//                           offset: const Offset(0, 1),
//                           blurRadius: 2,
//                         )
//                       ],
//                     ),
//                     decoration: InputDecoration(
//                       filled: true,
//                       fillColor: inputFillColor,
//                       hintText: 'Enter full sequence',
//                       hintStyle: TextStyle(color: inputHintColor),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide.none,
//                       ),
//                       contentPadding: const EdgeInsets.symmetric(vertical: 20),
//                     ),
//                     autofillHints: const [],
//                     enableSuggestions: false,
//                     autocorrect: false,
//                   ),
//                   const SizedBox(height: 30),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: ElevatedButton(
//                           onPressed: _restartGame,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: restartBtnColor,
//                             padding: const EdgeInsets.symmetric(vertical: 16),
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                           ),
//                           child: Text(
//                             'RESTART',
//                             style: TextStyle(fontWeight: FontWeight.bold, color: restartTextColor),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: ElevatedButton(
//                           onPressed: (_isPlaying && !_isDisplaying) ? _submitInput : null,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: submitBtnColor,
//                             padding: const EdgeInsets.symmetric(vertical: 16),
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                           ),
//                           child: Text(
//                             _isPlaying ? 'SUBMIT' : 'START',
//                             style: TextStyle(fontWeight: FontWeight.bold, color: submitTextColor),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 30),
//                 ],
//               ),
//             ),
//             Align(
//               alignment: Alignment.topCenter,
//               child: ConfettiWidget(
//                 confettiController: _confettiController,
//                 blastDirectionality: BlastDirectionality.explosive,
//                 shouldLoop: false,
//                 colors: const [
//                   Color(0xFF00B8D4),
//                   Color(0xFF26A69A),
//                   Color(0xFFFF6F61),
//                   Color(0xFFFFC107),
//                   Color(0xFF8E24AA),
//                 ],
//               ),
//             ),
//             if (_showTutorial) _buildTutorialOverlay(), // This is the key addition
//           ],
//         ),
//       ),
//     );
//   }
// }/////////////////////////////////////////////////
// import 'dart:async';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:confetti/confetti.dart';
// import '/screens/leaderboard_screen2.dart';

// import 'package:audioplayers/audioplayers.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:provider/provider.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// import '../controllers/settings_controller.dart';


// class NumberSequenceMemoryGame extends StatefulWidget {
//   const NumberSequenceMemoryGame({super.key});

//   @override
//   _NumberSequenceMemoryGameState createState() => _NumberSequenceMemoryGameState();
// }

// class _NumberSequenceMemoryGameState extends State<NumberSequenceMemoryGame> with SingleTickerProviderStateMixin {
//   final TextEditingController _inputController = TextEditingController();
//   final FocusNode _inputFocusNode = FocusNode();
//    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   late ConfettiController _confettiController;
//   late AnimationController _scaleController;
//   late AudioPlayer _audioPlayer;

//   final List<int> _sequence = [];
//   String _playerInput = '';
//   int _level = 1;
//   int _score = 0;
//   int _highScore = 0;
//   int _initialHighScore = 0; // Track the high score at session start

//   String _message = 'Press START to begin';
//   Color _messageColor = Colors.blueGrey; // Use a visible color for both themes

//   bool _isPlaying = false;
//   bool _isDisplaying = false;
//   bool _showTutorial = false;

//   @override
//   void initState() {
//     super.initState();
//     _confettiController = ConfettiController(duration: const Duration(seconds: 3));
//     _scaleController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 400),
//       lowerBound: 0.8,
//       upperBound: 1.0,
//     )..repeat(reverse: true);
//     _audioPlayer = AudioPlayer();
//     _loadHighScore();
//   }

//   @override
//   void dispose() {
//     _inputController.dispose();
//     _inputFocusNode.dispose();
//     _confettiController.dispose();
//     _scaleController.dispose();
//     super.dispose();
//   }


  

//   Future<void> _loadHighScore() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       _highScore = prefs.getInt('highScore') ?? 0;
//       _initialHighScore = _highScore; // Save initial high score for session
//     });
//   }



// Future<void> _saveHighScore() async {
//   final prefs = await SharedPreferences.getInstance();
//   await prefs.setInt('highScore', _highScore);
  
//   final user = FirebaseAuth.instance.currentUser;
//   if (user != null) {
//     await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
//       'username': user.displayName ?? 'Player',
//       'profileImageUrl': user.photoURL ?? '',
//       'lastUpdated': FieldValue.serverTimestamp(),
//       'gameStats': {
//         'numberSequence': {
//           'highScore': _highScore,
//           'highestLevel': _level,
//           'lastPlayed': FieldValue.serverTimestamp(),
//         }
//       }
//     }, SetOptions(merge: true));
//   }
// }
//   Future<void> _playSound(String asset) async {
//     await _audioPlayer.play(AssetSource(asset));
//   }

//   void _startGame() {
//     setState(() {
//       _sequence.clear();
//       _playerInput = '';
//       _level = 1;
//       _score = 0;
//       _message = 'Watch the sequence!';
//       _messageColor = Colors.blueAccent;
//       _isPlaying = true;
//       _showTutorial = false;
//     });
//     _addNumberToSequence();
//   }

//   void _restartGame() {
//     setState(() {
//       _sequence.clear();
//       _playerInput = '';
//       _level = 1;
//       _score = 0;
//       _message = 'Game reset. Press START to begin';
//       _messageColor = Theme.of(context).brightness == Brightness.dark
//           ? Colors.white
//           : Colors.blueGrey.shade800;
//       _isPlaying = false;
//       _showTutorial = false;
//     });
//   }

//   void _addNumberToSequence() {
//     setState(() {
//       _isDisplaying = true;
//       _playerInput = '';
//       _sequence.add(1 + (DateTime.now().millisecondsSinceEpoch % 9)); // random 1-9
//       _displaySequence();
//     });
//   }

//   Future<void> _displaySequence() async {
//     for (int number in _sequence) {
//       setState(() {
//         _playerInput = number.toString();
//       });
//       _playSound('sounds/beep.mp3'); // Play beep sound for each number
//       await Future.delayed(const Duration(seconds: 1));
//       setState(() {
//         _playerInput = '';
//       });
//       await Future.delayed(const Duration(milliseconds: 500));
//     }
//     setState(() {
//       _message = 'Your turn. Enter the full sequence.';
//       _messageColor = Colors.orange;
//       _isDisplaying = false;
//     });
//     // Always request focus and show keyboard for direct typing
//     Future.delayed(const Duration(milliseconds: 100), () {
//       if (mounted) {
//         FocusScope.of(context).requestFocus(_inputFocusNode);
//         SystemChannels.textInput.invokeMethod('TextInput.show');
//       }
//     });
//   }

//   void _checkInput(String input) {
//     setState(() {
//       _playerInput = input;
//     });
//   }

//   Future<void> _submitInput() async {
//     if (_isDisplaying || !_isPlaying) return;
//     // Disable input immediately to prevent double submit
//     setState(() {
//       _isDisplaying = true;
//     });

//     if (_playerInput == _sequence.join()) {
//       _score += _level * 10;
//       _level++;
//       // Show "Great!" or "Awesome!" before next turn
//       setState(() {
//         _message = (_level % 2 == 0) ? 'Awesome!' : 'Great!';
//         _messageColor = Colors.green;
//       });
//       _playSound('sounds/success.mp3');
//       if (_score > _initialHighScore && _highScore == _initialHighScore) {
//         _highScore = _score;
//         _saveHighScore();
//         _confettiController.play();
//       } else if (_score > _highScore) {
//         _highScore = _score;
//         _saveHighScore();
//       }
//       _inputController.clear();
//       await Future.delayed(const Duration(seconds: 1));
//       setState(() {
//         _message = 'Correct! Next level...';
//         _messageColor = Colors.green;
//       });
//       await Future.delayed(const Duration(milliseconds: 600));
//       _addNumberToSequence();
//     } else {
//       setState(() {
//         _message = 'Wrong! Game over.';
//         _messageColor = Colors.red;
//         _isPlaying = false;
//         _isDisplaying = false;
//       });
//       _playSound('sounds/fail.mp3');
//       _inputController.clear();
//       _inputFocusNode.unfocus();
//     }
//   }

//   Color _getMessageBackgroundColor(Color messageColor) {
//     if (messageColor == Colors.green) {
//       return const Color(0xFF81C784);
//     } else if (messageColor == Colors.red) {
//       return const Color(0xFFE57373);
//     } else if (messageColor == Colors.orange) {
//       return const Color(0xFFFFB74D);
//     } else if (messageColor == Colors.blueAccent) {
//       return const Color(0xFF64B5F6);
//     } else if (messageColor == Colors.white) {
//       return const Color(0xFFE0E0E0);
//     }
//     return Colors.grey.withOpacity(0.3);
//   }

//   Widget _buildStatCard(String label, int value, Color cardColor, Color labelColor, Color valueColor) {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//       decoration: BoxDecoration(
//         color: cardColor,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         children: [
//           Text(label, style: TextStyle(color: labelColor)),
//           const SizedBox(height: 6),
//           Text(value.toString(), style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 18)),
//         ],
//       ),
//     );
//   }

//   Widget _buildTutorialOverlay() {
//     final isDark = Provider.of<SettingsController>(context, listen: false).isDarkMode;
//     return Container(
//       color: Colors.black54,
//       child: Center(
//         child: Container(
//           margin: const EdgeInsets.all(24),
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: isDark ? const Color(0xFF222B3A) : Colors.white.withOpacity(0.95),
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 'How to Play',
//                 style: TextStyle(
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold,
//                   color: isDark ? Colors.white : Colors.black,
//                 ),
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 '1. Press START to begin.\n'
//                 '2. Watch the number sequence carefully.\n'
//                 '3. Enter the full sequence in the input box.\n'
//                 '4. Press SUBMIT to check.\n'
//                 '5. If correct, level up and repeat.\n'
//                 '6. If wrong, game over.\n\n'
//                 'Good luck!',
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: isDark ? Colors.white70 : Colors.black87,
//                 ),
//               ),
//               const SizedBox(height: 16),
//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF26A69A),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                   padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                 ),
//                 onPressed: () {
//                   setState(() {
//                     _showTutorial = false;
//                   });
//                 },
//                 child: const Text('Got it!', style: TextStyle(fontSize: 18)),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Provider.of<SettingsController>(context).isDarkMode;
//     final backgroundGradient = isDark
//         ? const LinearGradient(
//             colors: [Color(0xFF0D1B2A), Color(0xFF071B2B)],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           )
//         : const LinearGradient(
//             colors: [Color(0xFFFFF8E1), Color(0xFFE1F5FE)],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           );
//     final appBarColor = isDark ? const Color(0xFF102B44) : Colors.blue.shade100;
//     final appBarTextColor = isDark ? Colors.white : Colors.black87;
//     final cardColor = isDark ? const Color(0xFF334756) : Colors.white;
//     final statTextColor = isDark ? Colors.white70 : Colors.black54;
//     final statValueColor = isDark ? Colors.white : Colors.black87;
//     final messageBg = _getMessageBackgroundColor(_messageColor).withOpacity(0.3);
//     final inputFillColor = isDark ? const Color(0xFF1E2E43) : Colors.blue.shade50;
//     final inputHintColor = isDark ? Colors.grey[400] : Colors.blueGrey[300];
//     final restartBtnColor = isDark ? const Color(0xFF334756) : Colors.blue.shade200;
//     final submitBtnColor = _isPlaying
//         ? (isDark ? const Color(0xFF00B8D4) : Colors.green)
//         : (isDark ? const Color(0xFF26A69A) : Colors.blueAccent);
//     final submitTextColor = Colors.white;
//     final restartTextColor = isDark ? Colors.white70 : Colors.black87;

//     // Set message color for initial state based on theme
//     final initialMessageColor = isDark ? Colors.white : Colors.blueGrey.shade800;
//     // If the message is the initial one, override the color
//     final displayMessageColor =
//         _message == 'Press START to begin' ? initialMessageColor : _messageColor;

//     return Container(
//       decoration: BoxDecoration(gradient: backgroundGradient),
//       child: Scaffold(
//         backgroundColor: Colors.transparent,
//         appBar: AppBar(
//           title: Text('N.Sequence', style: TextStyle(color: appBarTextColor)),
//           centerTitle: true,
//           backgroundColor: appBarColor,
//           elevation: 0,
//           leading: IconButton(
//             icon: Icon(Icons.arrow_back, color: appBarTextColor),
//             onPressed: () => Navigator.of(context).pop(),
//           ),
//           actions: [
//             IconButton(
//               icon: Icon(Icons.leaderboard, color: appBarTextColor),
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => const LeaderboardScreen2()),
//                 );
//               },
//             ),
//             IconButton(
//               icon: Icon(Icons.help_outline, color: appBarTextColor),
//               onPressed: () {
//                 setState(() {
//                   _showTutorial = true;
//                 });
//               },
//             ),
//           ],
//         ),
//         body: Stack(
//           children: [
//             SingleChildScrollView(
//               padding: const EdgeInsets.all(16),
//               reverse: true,
//               child: Column(
//                 children: [
//                   const SizedBox(height: 20),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       _buildStatCard('Level', _level, cardColor, statTextColor, statValueColor),
//                       _buildStatCard('Score', _score, cardColor, statTextColor, statValueColor),
//                       _buildStatCard('High Score', _highScore, cardColor, statTextColor, statValueColor),
//                     ],
//                   ),
//                   const SizedBox(height: 20),
//                   AnimatedContainer(
//                     duration: const Duration(milliseconds: 500),
//                     padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
//                     decoration: BoxDecoration(
//                       color: messageBg,
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: AnimatedDefaultTextStyle(
//                       duration: const Duration(milliseconds: 300),
//                       style: TextStyle(
//                         color: displayMessageColor,
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       child: Text(_message),
//                     ),
//                   ),
//                   const SizedBox(height: 30),
//                   GestureDetector(
//                     onTap: !_isPlaying
//                         ? () {
//                             _startGame();
//                           }
//                         : null,
//                     child: ScaleTransition(
//                       scale: _scaleController,
//                       child: Container(
//                         width: 150,
//                         height: 150,
//                         decoration: BoxDecoration(
//                           gradient: isDark
//                               ? const LinearGradient(
//                                   colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
//                                   begin: Alignment.topLeft,
//                                   end: Alignment.bottomRight,
//                                 )
//                               : const LinearGradient(
//                                   colors: [Color(0xFFB3E5FC), Color(0xFFFFF9C4)],
//                                   begin: Alignment.topLeft,
//                                   end: Alignment.bottomRight,
//                                 ),
//                           shape: BoxShape.circle,
//                           boxShadow: const [
//                             BoxShadow(
//                               color: Colors.black45,
//                               blurRadius: 15,
//                               offset: Offset(0, 6),
//                             ),
//                           ],
//                         ),
//                         child: Center(
//                           child: AnimatedSwitcher(
//                             duration: const Duration(milliseconds: 300),
//                             child: FittedBox(
//                               fit: BoxFit.scaleDown,
//                               child: Text(
//                                 _playerInput.isEmpty && !_isDisplaying
//                                     ? _isPlaying ? '?' : 'GO'
//                                     : _playerInput,
//                                 key: ValueKey<String>(_playerInput),
//                                 style: TextStyle(
//                                   fontSize: 60,
//                                   fontWeight: FontWeight.bold,
//                                   color: isDark ? Colors.white : Colors.black,
//                                   shadows: [
//                                     Shadow(
//                                       color: isDark ? Colors.black54 : Colors.grey.shade200,
//                                       offset: const Offset(1, 1),
//                                       blurRadius: 2,
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 30),
//                   TextField(
//                     controller: _inputController,
//                     focusNode: _inputFocusNode,
//                     autofocus: true,
//                     onChanged: _checkInput,
//                     onSubmitted: (_) => _submitInput(),
//                     enabled: _isPlaying && !_isDisplaying,
//                     keyboardType: TextInputType.number,
//                     inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontSize: 24,
//                       color: isDark ? Colors.white : Colors.black,
//                       fontWeight: FontWeight.bold,
//                       shadows: [
//                         Shadow(
//                           color: isDark ? Colors.black87 : Colors.grey.shade200,
//                           offset: const Offset(0, 1),
//                           blurRadius: 2,
//                         )
//                       ],
//                     ),
//                     decoration: InputDecoration(
//                       filled: true,
//                       fillColor: inputFillColor,
//                       hintText: 'Enter full sequence',
//                       hintStyle: TextStyle(color: inputHintColor),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide.none,
//                       ),
//                       contentPadding: const EdgeInsets.symmetric(vertical: 20),
//                     ),
//                     autofillHints: const [], // Disable autofill suggestions
//                     enableSuggestions: false, // Disable suggestions
//                     autocorrect: false, // Disable autocorrect
//                   ),
//                   const SizedBox(height: 30),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: ElevatedButton(
//                           onPressed: _restartGame,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: restartBtnColor,
//                             padding: const EdgeInsets.symmetric(vertical: 16),
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                           ),
//                           child: Text(
//                             'RESTART',
//                             style: TextStyle(fontWeight: FontWeight.bold, color: restartTextColor),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: ElevatedButton(
//                           onPressed: (_isPlaying && !_isDisplaying) ? _submitInput : null,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: submitBtnColor,
//                             padding: const EdgeInsets.symmetric(vertical: 16),
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                           ),
//                           child: Text(
//                             _isPlaying ? 'SUBMIT' : 'START',
//                             style: TextStyle(fontWeight: FontWeight.bold, color: submitTextColor),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 30),
//                 ],
//               ),
//             ),
//             Align(
//               alignment: Alignment.topCenter,
//               child: ConfettiWidget(
//                 confettiController: _confettiController,
//                 blastDirectionality: BlastDirectionality.explosive,
//                 shouldLoop: false,
//                 colors: const [
//                   Color(0xFF00B8D4),
//                   Color(0xFF26A69A),
//                   Color(0xFFFF6F61),
//                   Color(0xFFFFC107),
//                   Color(0xFF8E24AA),
//                 ],
//               ),
//             ),
//             if (_showTutorial) _buildTutorialOverlay(),
//           ],
//         ),
//       ),
//     );
//   }
// }