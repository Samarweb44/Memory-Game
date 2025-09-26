// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../controllers/settings_controller.dart';

// class TicTacToeScreen extends StatefulWidget {
//   const TicTacToeScreen({super.key});

//   @override
//   State<TicTacToeScreen> createState() => _TicTacToeScreenState();
// }

// class _TicTacToeScreenState extends State<TicTacToeScreen> {
//   List<String> _board = List.filled(9, '');
//   String _currentPlayer = 'X';
//   String? _winner;

//   void _resetGame() {
//     setState(() {
//       _board = List.filled(9, '');
//       _currentPlayer = 'X';
//       _winner = null;
//     });
//   }

//   void _handleTap(int index) {
//     if (_board[index] == '' && _winner == null) {
//       setState(() {
//         _board[index] = _currentPlayer;
//         _winner = _checkWinner();
//         if (_winner == null) {
//           _currentPlayer = _currentPlayer == 'X' ? 'O' : 'X';
//         }
//       });
//     }
//   }

//   String? _checkWinner() {
//     const List<List<int>> winPatterns = [
//       [0, 1, 2],
//       [3, 4, 5],
//       [6, 7, 8],
//       [0, 3, 6],
//       [1, 4, 7],
//       [2, 5, 8],
//       [0, 4, 8],
//       [2, 4, 6],
//     ];

//     for (var pattern in winPatterns) {
//       String a = _board[pattern[0]];
//       String b = _board[pattern[1]];
//       String c = _board[pattern[2]];
//       if (a != '' && a == b && b == c) {
//         return a;
//       }
//     }

//     if (!_board.contains('')) {
//       return 'Draw';
//     }

//     return null;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final settings = Provider.of<SettingsController>(context);
//     final isDark = settings.isDarkMode;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Tic Tac Toe'),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         foregroundColor: isDark ? Colors.white : Colors.black,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _resetGame,
//             tooltip: 'Restart',
//           )
//         ],
//       ),
//       backgroundColor: isDark ? Colors.black : Colors.white,
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             Text(
//               _winner != null
//                   ? (_winner == 'Draw' ? "It's a Draw!" : '$_winner Wins!')
//                   : 'Current Turn: $_currentPlayer',
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: isDark ? Colors.amberAccent : Colors.deepPurple,
//               ),
//             ),
//             const SizedBox(height: 20),
//             Expanded(
//               child: GridView.builder(
//                 itemCount: 9,
//                 gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                   crossAxisCount: 3,
//                   mainAxisSpacing: 12,
//                   crossAxisSpacing: 12,
//                 ),
//                 itemBuilder: (context, index) {
//                   return InkWell(
//                     onTap: () => _handleTap(index),
//                     borderRadius: BorderRadius.circular(12),
//                     child: Container(
//                       decoration: BoxDecoration(
//                         color: isDark ? Colors.grey[850] : Colors.grey[300],
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Center(
//                         child: Text(
//                           _board[index],
//                           style: TextStyle(
//                             fontSize: 48,
//                             fontWeight: FontWeight.bold,
//                             color: _board[index] == 'X'
//                                 ? Colors.blue
//                                 : Colors.redAccent,
//                           ),
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import '../controllers/settings_controller.dart';

class TicTacToeScreen extends StatefulWidget {
  const TicTacToeScreen({super.key});

  @override
  State<TicTacToeScreen> createState() => _TicTacToeScreenState();
}

class _TicTacToeScreenState extends State<TicTacToeScreen>
    with SingleTickerProviderStateMixin {
  List<String> _board = List.filled(9, '');
  String _currentPlayer = 'X';
  String? _winner;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  int _xWins = 0;
  int _oWins = 0;
  int _draws = 0;
  late AudioPlayer _audioPlayer;
  late ConfettiController _confettiController;
  List<int> _winningIndices = [];
  bool _isCelebrating = false;
  bool _isAgainstCPU = true;
  bool _isCPUTurn = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showGameModeDialog();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioPlayer.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _playSound(String sound) async {
    final settings = Provider.of<SettingsController>(context, listen: false);
    
    if (!settings.soundEffects) return;
    
    try {
      await _audioPlayer.setVolume(settings.volumeLevel);
      await _audioPlayer.play(AssetSource('sounds/$sound.mp3'));
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  void _resetGame() {
    setState(() {
      _board = List.filled(9, '');
      _currentPlayer = 'X';
      _winner = null;
      _winningIndices = [];
      _isCelebrating = false;
      _isCPUTurn = false;
      _animationController.reset();
      _animationController.forward();
    });
    _playSound('beep');
  }

  void _showGameModeDialog() {
    final settings = Provider.of<SettingsController>(context, listen: false);
    final isDark = settings.isDarkMode;
    final themeColor = isDark ? Colors.amberAccent : Colors.deepPurple;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 10,
          backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.videogame_asset_rounded,
                  size: 48,
                  color: themeColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Select Game Mode',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose how you want to play:',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildModeButton(
                      icon: Icons.group,
                      label: '2 Players',
                      isSelected: !_isAgainstCPU,
                      onTap: () {
                        Navigator.of(context).pop();
                        setState(() => _isAgainstCPU = false);
                        _resetGame();
                      },
                      themeColor: themeColor,
                      isDark: isDark,
                    ),
                    _buildModeButton(
                      icon: Icons.computer,
                      label: 'VS CPU',
                      isSelected: _isAgainstCPU,
                      onTap: () {
                        Navigator.of(context).pop();
                        setState(() => _isAgainstCPU = true);
                        _resetGame();
                      },
                      themeColor: themeColor,
                      isDark: isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModeButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color themeColor,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? themeColor.withOpacity(0.2)
              : isDark ? Colors.grey[800] : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? themeColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? themeColor : isDark ? Colors.white : Colors.black,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? themeColor : isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _makeCPUMove() {
    if (!_isAgainstCPU || _currentPlayer != 'O' || _winner != null || _isCelebrating) {
      return;
    }

    setState(() {
      _isCPUTurn = true;
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (_winner != null || !mounted) return;

      int? winningMove = _findWinningMove('O');
      if (winningMove == null) winningMove = _findWinningMove('X');
      if (winningMove == null) {
        List<int> emptySpots = [];
        for (int i = 0; i < _board.length; i++) {
          if (_board[i].isEmpty) emptySpots.add(i);
        }
        if (emptySpots.isNotEmpty) {
          winningMove = emptySpots[Random().nextInt(emptySpots.length)];
        }
      }

      if (winningMove != null) {
        _board[winningMove] = 'O';
        _winner = _checkWinner();
        
        if (_winner != null) {
          if (_winner == 'O') {
            _oWins++;
            _playSound('lose'); // Changed from 'congrats' to 'lose'
          } else if (_winner == 'Draw') {
            _draws++;
            _playSound('draw');
          }
        } else {
          _currentPlayer = 'X';
        }
        
        _animationController.reset();
        _animationController.forward();
      }

      setState(() {
        _isCPUTurn = false;
      });
    });
  }

  int? _findWinningMove(String player) {
    const winPatterns = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6]
    ];

    for (var pattern in winPatterns) {
      int playerCount = 0;
      int emptySpot = -1;
      
      for (int i = 0; i < pattern.length; i++) {
        if (_board[pattern[i]] == player) playerCount++;
        else if (_board[pattern[i]].isEmpty) emptySpot = pattern[i];
      }
      
      if (playerCount == 2 && emptySpot != -1) {
        return emptySpot;
      }
    }
    
    return null;
  }

  void _handleTap(int index) {
    if (_board[index] != '' || _winner != null || _isCelebrating || _isCPUTurn) {
      return;
    }

    setState(() {
      _board[index] = _currentPlayer;
      _playSound('beep');
      _winner = _checkWinner();
      
      if (_winner != null) {
        if (_winner == 'X') {
          _xWins++;
          _isCelebrating = true;
          _confettiController.play();
          _playSound('congrats');
        } else if (_winner == 'O') {
          _oWins++;
          _playSound('lose'); // Added lose sound for CPU win
        } else if (_winner == 'Draw') {
          _draws++;
          _playSound('draw');
        }
      } else {
        _currentPlayer = _currentPlayer == 'X' ? 'O' : 'X';
        _playSound('beep');
        
        if (_isAgainstCPU && _currentPlayer == 'O') {
          _makeCPUMove();
        }
      }
      
      _animationController.reset();
      _animationController.forward();
    });
  }

  String? _checkWinner() {
    const List<List<int>> winPatterns = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6],
    ];

    for (var pattern in winPatterns) {
      String a = _board[pattern[0]];
      String b = _board[pattern[1]];
      String c = _board[pattern[2]];
      if (a != '' && a == b && b == c) {
        _winningIndices = pattern;
        return a;
      }
    }

    if (!_board.contains('')) {
      return 'Draw';
    }

    return null;
  }

  Widget _buildScoreCard(String label, int score, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            score.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoardCell(int index) {
    final isWinningCell = _winningIndices.contains(index);
    final isDark = Provider.of<SettingsController>(context).isDarkMode;
    
    return InkWell(
      onTap: () => _handleTap(index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isWinningCell
              ? (_board[index] == 'X' 
                  ? Colors.blue.withOpacity(0.2) 
                  : Colors.red.withOpacity(0.2))
              : isDark 
                  ? Colors.grey[800] 
                  : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isWinningCell
                ? (_board[index] == 'X' ? Colors.blue : Colors.red)
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.5)
                  : Colors.grey.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: _board[index].isEmpty
                ? const SizedBox()
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isWinningCell)
                        Positioned(
                          top: 0,
                          child: Icon(
                            Icons.star,
                            color: _board[index] == 'X' 
                                ? Colors.blue 
                                : Colors.red,
                            size: 24,
                          ),
                        ),
                      Text(
                        _board[index],
                        key: ValueKey<String>('${_board[index]}$index'),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: _board[index] == 'X'
                              ? Colors.blue
                              : Colors.redAccent,
                          shadows: [
                            Shadow(
                              blurRadius: 10,
                              color: _board[index] == 'X'
                                  ? Colors.blue.withOpacity(0.3)
                                  : Colors.red.withOpacity(0.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  void _toggleGameMode() {
    setState(() {
      _isAgainstCPU = !_isAgainstCPU;
      _resetGame();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsController>(context);
    final isDark = settings.isDarkMode;
    final themeColor = isDark ? Colors.amberAccent : Colors.deepPurple;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Tic Tac Toe'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: isDark ? Colors.white : Colors.black,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _resetGame,
                tooltip: 'Restart',
              ),
              IconButton(
                icon: Icon(_isAgainstCPU ? Icons.person : Icons.computer),
                onPressed: _toggleGameMode,
                tooltip: _isAgainstCPU ? 'Play against human' : 'Play against CPU',
              ),
            ],
          ),
          backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: themeColor, width: 1),
                  ),
                  child: Text(
                    _isAgainstCPU ? 'Playing vs CPU' : 'Playing vs Human',
                    style: TextStyle(
                      fontSize: 16,
                      color: themeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildScoreCard('X Wins', _xWins, Colors.blue),
                    _buildScoreCard('Draws', _draws, Colors.grey),
                    _buildScoreCard('O Wins', _oWins, Colors.red),
                  ],
                ),
                const SizedBox(height: 20),
                
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: Container(
                    key: ValueKey<String>(_winner ?? _currentPlayer),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: themeColor, width: 2),
                    ),
                    child: Text(
                      _winner != null
                          ? (_winner == 'Draw' 
                              ? "It's a Draw! 🎭" 
                              : (_isAgainstCPU
                                  ? (_winner == 'X' 
                                      ? 'You Win! 🎉' 
                                      : 'CPU Wins! 😢')
                                  : 'Player $_winner Wins! 🎉'))
                          : 'Player $_currentPlayer\'s Turn ${_currentPlayer == 'X' ? '❌' : '⭕'}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                Expanded(
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 9,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                      ),
                      itemBuilder: (context, index) => _buildBoardCell(index),
                    ),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: ElevatedButton.icon(
                    onPressed: _resetGame,
                    icon: const Icon(Icons.refresh),
                    label: const Text('New Game'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: themeColor,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Confetti only shows when player wins (X wins in CPU mode)
        if (_isCelebrating)
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.blue,
                Colors.red,
                Colors.green,
                Colors.yellow,
                Colors.purple,
              ],
              createParticlePath: (size) {
                final path = Path();
                path.addOval(Rect.fromCircle(
                  center: Offset.zero,
                  radius: size.width / 2,
                ));
                return path;
              },
            ),
          ),
        
        if (_winner != null && _winner != 'Draw')
          Positioned(
            top: MediaQuery.of(context).size.height * 0.3,
            left: 0,
            right: 0,
            child: Center(
              child: Transform.rotate(
                angle: -0.1,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 40),
                  decoration: BoxDecoration(
                    color: _winner == 'X' ? Colors.blue : Colors.red,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Text(
                    _isAgainstCPU
                        ? (_winner == 'X' ? 'YOU WIN!' : 'YOU LOSE!')
                        : 'WINNER!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        
        if (_isCPUTurn)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}

// import 'package:flutter/material.dart';////////////////////////////////
// import 'package:provider/provider.dart';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:confetti/confetti.dart';
// import 'dart:math';
// import '../controllers/settings_controller.dart';

// class TicTacToeScreen extends StatefulWidget {
//   const TicTacToeScreen({super.key});

//   @override
//   State<TicTacToeScreen> createState() => _TicTacToeScreenState();
// }

// class _TicTacToeScreenState extends State<TicTacToeScreen>
//     with SingleTickerProviderStateMixin {
//   List<String> _board = List.filled(9, '');
//   String _currentPlayer = 'X';
//   String? _winner;
//   late AnimationController _animationController;
//   late Animation<double> _scaleAnimation;
//   int _xWins = 0;
//   int _oWins = 0;
//   int _draws = 0;
//   late AudioPlayer _audioPlayer;
//   late ConfettiController _confettiController;
//   List<int> _winningIndices = [];
//   bool _isCelebrating = false;
//   bool _isAgainstCPU = true; // Added flag for CPU mode
//   bool _isCPUTurn = false; // Added flag to track CPU's turn



// // Add this in your _TicTacToeScreenState class

// @override
// void initState() {
//   super.initState();
//   _audioPlayer = AudioPlayer();
//   _confettiController = ConfettiController(duration: const Duration(seconds: 5));
  
//   _animationController = AnimationController(
//     vsync: this,
//     duration: const Duration(milliseconds: 300),
//   );
//   _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
//     CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeOutBack,
//     ),
//   );
  
//   // Show mode selection dialog after initialization
//   WidgetsBinding.instance.addPostFrameCallback((_) {
//     _showGameModeDialog();
//   });
// }

// void _showGameModeDialog() {
//   final settings = Provider.of<SettingsController>(context, listen: false);
//   final isDark = settings.isDarkMode;
//   final themeColor = isDark ? Colors.amberAccent : Colors.deepPurple;

//   showDialog(
//     context: context,
//     barrierDismissible: false,
//     builder: (BuildContext context) {
//       return Dialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(24),
//         ),
//         elevation: 10,
//         backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(
//                 Icons.videogame_asset_rounded,
//                 size: 48,
//                 color: themeColor,
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 'Select Game Mode',
//                 style: TextStyle(
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold,
//                   color: themeColor,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 'Choose how you want to play:',
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: isDark ? Colors.grey[300] : Colors.grey[700],
//                 ),
//               ),
//               const SizedBox(height: 24),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   _buildModeButton(
//                     icon: Icons.group,
//                     label: '2 Players',
//                     isSelected: !_isAgainstCPU,
//                     onTap: () {
//                       Navigator.of(context).pop();
//                       setState(() => _isAgainstCPU = false);
//                       _resetGame();
//                     },
//                     themeColor: themeColor,
//                     isDark: isDark,
//                   ),
//                   _buildModeButton(
//                     icon: Icons.computer,
//                     label: 'VS CPU',
//                     isSelected: _isAgainstCPU,
//                     onTap: () {
//                       Navigator.of(context).pop();
//                       setState(() => _isAgainstCPU = true);
//                       _resetGame();
//                     },
//                     themeColor: themeColor,
//                     isDark: isDark,
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       );
//     },
//   );
// }

// Widget _buildModeButton({
//   required IconData icon,
//   required String label,
//   required bool isSelected,
//   required VoidCallback onTap,
//   required Color themeColor,
//   required bool isDark,
// }) {
//   return InkWell(
//     onTap: onTap,
//     borderRadius: BorderRadius.circular(16),
//     child: AnimatedContainer(
//       duration: const Duration(milliseconds: 200),
//       padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
//       decoration: BoxDecoration(
//         color: isSelected
//             ? themeColor.withOpacity(0.2)
//             : isDark ? Colors.grey[800] : Colors.grey[200],
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//           color: isSelected ? themeColor : Colors.transparent,
//           width: 2,
//         ),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             icon,
//             size: 32,
//             color: isSelected ? themeColor : isDark ? Colors.white : Colors.black,
//           ),
//           const SizedBox(height: 8),
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: isSelected ? themeColor : isDark ? Colors.white : Colors.black,
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }


//   // @override
//   // void initState() {
//   //   super.initState();
//   //   _audioPlayer = AudioPlayer();
//   //   _confettiController = ConfettiController(duration: const Duration(seconds: 5));
    
//   //   _animationController = AnimationController(
//   //     vsync: this,
//   //     duration: const Duration(milliseconds: 300),
//   //   );
//   //   _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
//   //     CurvedAnimation(
//   //       parent: _animationController,
//   //       curve: Curves.easeOutBack,
//   //     ),
//   //   );
//   //   _animationController.forward();
//   // }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     _audioPlayer.dispose();
//     _confettiController.dispose();
//     super.dispose();
//   }

//   Future<void> _playSound(String sound) async {
//     try {
//       await _audioPlayer.play(AssetSource('sounds/$sound.mp3'));
//     } catch (e) {
//       debugPrint('Error playing sound: $e');
//     }
//   }

//   void _resetGame() {
//     setState(() {
//       _board = List.filled(9, '');
//       _currentPlayer = 'X';
//       _winner = null;
//       _winningIndices = [];
//       _isCelebrating = false;
//       _isCPUTurn = false;
//       _animationController.reset();
//       _animationController.forward();
//     });
//     _playSound('beep');
//   }
// void _makeCPUMove() {
//   if (!_isAgainstCPU || _currentPlayer != 'O' || _winner != null || _isCelebrating) {
//     return;
//   }

//   setState(() {
//     _isCPUTurn = true;
//   });

//   Future.delayed(const Duration(milliseconds: 800), () {
//     if (_winner != null || !mounted) return;

//     // 1. First check if CPU can win immediately
//     int? winningMove = _findWinningMove('O');
//     // 2. If not, check if player can win and block them
//     if (winningMove == null) winningMove = _findWinningMove('X');
//     // 3. If none, pick a random move
//     if (winningMove == null) {
//       List<int> emptySpots = [];
//       for (int i = 0; i < _board.length; i++) {
//         if (_board[i].isEmpty) emptySpots.add(i);
//       }
//       if (emptySpots.isNotEmpty) {
//         winningMove = emptySpots[Random().nextInt(emptySpots.length)];
//       }
//     }

//     if (winningMove != null) {
//       _board[winningMove] = 'O';
//       _winner = _checkWinner();
      
//       if (_winner != null) {
//         if (_winner == 'O') {
//           _oWins++;
//           _isCelebrating = true;
//           _confettiController.play();
//           _playSound('congrats');
//         } else if (_winner == 'Draw') {
//           _draws++;
//           _playSound('draw');
//         }
//       } else {
//         _currentPlayer = 'X'; // Switch back to player
//       }
      
//       _animationController.reset();
//       _animationController.forward();
//     }

//     setState(() {
//       _isCPUTurn = false;
//     });
//   });
// }

// int? _findWinningMove(String player) {
//   const winPatterns = [
//     [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
//     [0, 3, 6], [1, 4, 7], [2, 5, 8], // columns
//     [0, 4, 8], [2, 4, 6]             // diagonals
//   ];

//   for (var pattern in winPatterns) {
//     // Count player marks and empty spots in this pattern
//     int playerCount = 0;
//     int emptySpot = -1;
    
//     for (int i = 0; i < pattern.length; i++) {
//       if (_board[pattern[i]] == player) playerCount++;
//       else if (_board[pattern[i]].isEmpty) emptySpot = pattern[i];
//     }
    
//     // If 2 marks and 1 empty, return the empty spot
//     if (playerCount == 2 && emptySpot != -1) {
//       return emptySpot;
//     }
//   }
  
//   return null;
// }
//  void _handleTap(int index) {
//   // Don't allow moves if game is over, cell is occupied, or CPU is "thinking"
//   if (_board[index] != '' || _winner != null || _isCelebrating || _isCPUTurn) {
//     return;
//   }

//   setState(() {
//     _board[index] = _currentPlayer;
//     _playSound('beep');
//     _winner = _checkWinner();
    
//     if (_winner != null) {
//       if (_winner == 'X') _xWins++;
//       if (_winner == 'O') _oWins++;
//       if (_winner == 'Draw') _draws++;
      
//       if (_winner != 'Draw') {
//         _isCelebrating = true;
//         _confettiController.play();
//         _playSound('congrats');
//       } else {
//         _playSound('draw');
//       }
//     } else {
//       // Switch player
//       _currentPlayer = _currentPlayer == 'X' ? 'O' : 'X';
//       _playSound('beep');
      
//       // If playing against CPU and it's now CPU's turn (O)
//       if (_isAgainstCPU && _currentPlayer == 'O') {
//         _makeCPUMove(); // Trigger CPU move
//       }
//     }
    
//     _animationController.reset();
//     _animationController.forward();
//   });
// }
//   String? _checkWinner() {
//     const List<List<int>> winPatterns = [
//       [0, 1, 2],
//       [3, 4, 5],
//       [6, 7, 8],
//       [0, 3, 6],
//       [1, 4, 7],
//       [2, 5, 8],
//       [0, 4, 8],
//       [2, 4, 6],
//     ];

//     for (var pattern in winPatterns) {
//       String a = _board[pattern[0]];
//       String b = _board[pattern[1]];
//       String c = _board[pattern[2]];
//       if (a != '' && a == b && b == c) {
//         _winningIndices = pattern;
//         return a;
//       }
//     }

//     if (!_board.contains('')) {
//       return 'Draw';
//     }

//     return null;
//   }

//   Widget _buildScoreCard(String label, int score, Color color) {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: color, width: 1.5),
//       ),
//       child: Column(
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.bold,
//               color: color,
//             ),
//           ),
//           Text(
//             score.toString(),
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: color,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBoardCell(int index) {
//     final isWinningCell = _winningIndices.contains(index);
//     final isDark = Provider.of<SettingsController>(context).isDarkMode;
    
//     return InkWell(
//       onTap: () => _handleTap(index),
//       borderRadius: BorderRadius.circular(16),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 300),
//         decoration: BoxDecoration(
//           color: isWinningCell
//               ? (_board[index] == 'X' 
//                   ? Colors.blue.withOpacity(0.2) 
//                   : Colors.red.withOpacity(0.2))
//               : isDark 
//                   ? Colors.grey[800] 
//                   : Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(
//             color: isWinningCell
//                 ? (_board[index] == 'X' ? Colors.blue : Colors.red)
//                 : Colors.transparent,
//             width: 2,
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: isDark
//                   ? Colors.black.withOpacity(0.5)
//                   : Colors.grey.withOpacity(0.3),
//               blurRadius: 10,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Center(
//           child: AnimatedSwitcher(
//             duration: const Duration(milliseconds: 300),
//             transitionBuilder: (Widget child, Animation<double> animation) {
//               return ScaleTransition(scale: animation, child: child);
//             },
//             child: _board[index].isEmpty
//                 ? const SizedBox()
//                 : Stack(
//                     alignment: Alignment.center,
//                     children: [
//                       if (isWinningCell)
//                         Positioned(
//                           top: 0,
//                           child: Icon(
//                             Icons.star,
//                             color: _board[index] == 'X' 
//                                 ? Colors.blue 
//                                 : Colors.red,
//                             size: 24,
//                           ),
//                         ),
//                       Text(
//                         _board[index],
//                         key: ValueKey<String>('${_board[index]}$index'),
//                         style: TextStyle(
//                           fontSize: 48,
//                           fontWeight: FontWeight.bold,
//                           color: _board[index] == 'X'
//                               ? Colors.blue
//                               : Colors.redAccent,
//                           shadows: [
//                             Shadow(
//                               blurRadius: 10,
//                               color: _board[index] == 'X'
//                                   ? Colors.blue.withOpacity(0.3)
//                                   : Colors.red.withOpacity(0.3),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//           ),
//         ),
//       ),
//     );
//   }

//   void _toggleGameMode() {
//     setState(() {
//       _isAgainstCPU = !_isAgainstCPU;
//       _resetGame();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final settings = Provider.of<SettingsController>(context);
//     final isDark = settings.isDarkMode;
//     final themeColor = isDark ? Colors.amberAccent : Colors.deepPurple;

//     return Stack(
//       children: [
//         Scaffold(
//           appBar: AppBar(
//             title: const Text('Tic Tac Toe'),
//             backgroundColor: Colors.transparent,
//             elevation: 0,
//             foregroundColor: isDark ? Colors.white : Colors.black,
//             actions: [
//               IconButton(
//                 icon: const Icon(Icons.refresh),
//                 onPressed: _resetGame,
//                 tooltip: 'Restart',
//               ),
//               IconButton(
//                 icon: Icon(_isAgainstCPU ? Icons.person : Icons.computer),
//                 onPressed: _toggleGameMode,
//                 tooltip: _isAgainstCPU ? 'Play against human' : 'Play against CPU',
//               ),
//             ],
//           ),
//           backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
//           body: Padding(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               children: [
//                 // Game mode indicator
//                 Container(
//                   padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//                   decoration: BoxDecoration(
//                     color: themeColor.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(20),
//                     border: Border.all(color: themeColor, width: 1),
//                   ),
//                   child: Text(
//                     _isAgainstCPU ? 'Playing vs CPU' : 'Playing vs Human',
//                     style: TextStyle(
//                       fontSize: 16,
//                       color: themeColor,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 10),
                
//                 // Score board
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceAround,
//                   children: [
//                     _buildScoreCard('X Wins', _xWins, Colors.blue),
//                     _buildScoreCard('Draws', _draws, Colors.grey),
//                     _buildScoreCard('O Wins', _oWins, Colors.red),
//                   ],
//                 ),
//                 const SizedBox(height: 20),
                
//                 // Game status
//                 AnimatedSwitcher(
//                   duration: const Duration(milliseconds: 300),
//                   transitionBuilder: (Widget child, Animation<double> animation) {
//                     return FadeTransition(opacity: animation, child: child);
//                   },
//                   child: Container(
//                     key: ValueKey<String>(_winner ?? _currentPlayer),
//                     padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
//                     decoration: BoxDecoration(
//                       color: themeColor.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(20),
//                       border: Border.all(color: themeColor, width: 2),
//                     ),
//                     child: Text(
//                       _winner != null
//                           ? (_winner == 'Draw' ? "It's a Draw! 🎭" : 'Player $_winner Wins! 🎉')
//                           : 'Player $_currentPlayer\'s Turn ${_currentPlayer == 'X' ? '❌' : '⭕'}',
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: themeColor,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
                
//                 // Game board
//                 Expanded(
//                   child: ScaleTransition(
//                     scale: _scaleAnimation,
//                     child: GridView.builder(
//                       physics: const NeverScrollableScrollPhysics(),
//                       itemCount: 9,
//                       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                         crossAxisCount: 3,
//                         mainAxisSpacing: 12,
//                         crossAxisSpacing: 12,
//                       ),
//                       itemBuilder: (context, index) => _buildBoardCell(index),
//                     ),
//                   ),
//                 ),
                
//                 // Restart button
//                 Padding(
//                   padding: const EdgeInsets.only(top: 20),
//                   child: ElevatedButton.icon(
//                     onPressed: _resetGame,
//                     icon: const Icon(Icons.refresh),
//                     label: const Text('New Game'),
//                     style: ElevatedButton.styleFrom(
//                       foregroundColor: Colors.white,
//                       backgroundColor: themeColor,
//                       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       elevation: 5,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
        
//         // Confetti celebration
//         if (_isCelebrating)
//           Align(
//             alignment: Alignment.topCenter,
//             child: ConfettiWidget(
//               confettiController: _confettiController,
//               blastDirectionality: BlastDirectionality.explosive,
//               shouldLoop: false,
//               colors: const [
//                 Colors.blue,
//                 Colors.red,
//                 Colors.green,
//                 Colors.yellow,
//                 Colors.purple,
//               ],
//               createParticlePath: (size) {
//                 final path = Path();
//                 path.addOval(Rect.fromCircle(
//                   center: Offset.zero,
//                   radius: size.width / 2,
//                 ));
//                 return path;
//               },
//             ),
//           ),
        
//         // Winner ribbon effect
//         if (_winner != null && _winner != 'Draw')
//           Positioned(
//             top: MediaQuery.of(context).size.height * 0.3,
//             left: 0,
//             right: 0,
//             child: Center(
//               child: Transform.rotate(
//                 angle: -0.1,
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 40),
//                   decoration: BoxDecoration(
//                     color: _winner == 'X' ? Colors.blue : Colors.red,
//                     borderRadius: BorderRadius.circular(4),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.3),
//                         blurRadius: 10,
//                         offset: const Offset(0, 5),
//                       ),
//                     ],
//                   ),
//                   child: Text(
//                     'WINNER!',
//                     style: const TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                       letterSpacing: 2,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
        
//         // CPU thinking indicator
//         if (_isCPUTurn)
//           const Center(
//             child: CircularProgressIndicator(),
//           ),
//       ],
//     );
//   }
// }////////////////




// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:flutter/services.dart';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:confetti/confetti.dart';
// import '../controllers/settings_controller.dart';

// class TicTacToeScreen extends StatefulWidget {
//   const TicTacToeScreen({super.key});

//   @override
//   State<TicTacToeScreen> createState() => _TicTacToeScreenState();
// }

// class _TicTacToeScreenState extends State<TicTacToeScreen>
//     with SingleTickerProviderStateMixin {
//   List<String> _board = List.filled(9, '');
//   String _currentPlayer = 'X';
//   String? _winner;
//   late AnimationController _animationController;
//   late Animation<double> _scaleAnimation;
//   int _xWins = 0;
//   int _oWins = 0;
//   int _draws = 0;
//   late AudioPlayer _audioPlayer;
//   late ConfettiController _confettiController;
//   List<int> _winningIndices = [];
//   bool _isCelebrating = false;

//   @override
//   void initState() {
//     super.initState();
//     _audioPlayer = AudioPlayer();
//     _confettiController = ConfettiController(duration: const Duration(seconds: 5));
    
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 300),
//     );
//     _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
//       CurvedAnimation(
//         parent: _animationController,
//         curve: Curves.easeOutBack,
//       ),
//     );
//     _animationController.forward();
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     _audioPlayer.dispose();
//     _confettiController.dispose();
//     super.dispose();
//   }

//   Future<void> _playSound(String sound) async {
//     try {
//       await _audioPlayer.play(AssetSource('sounds/$sound.mp3'));
//     } catch (e) {
//       debugPrint('Error playing sound: $e');
//     }
//   }

//   void _resetGame() {
//     setState(() {
//       _board = List.filled(9, '');
//       _currentPlayer = 'X';
//       _winner = null;
//       _winningIndices = [];
//       _isCelebrating = false;
//       _animationController.reset();
//       _animationController.forward();
//     });
//     _playSound('beep'); // Play beep sound when resetting
//   }

//   void _handleTap(int index) {
//     if (_board[index] == '' && _winner == null && !_isCelebrating) {
//       setState(() {
//         _board[index] = _currentPlayer;
//         _playSound('beep'); // Play beep sound when tapping
//         _winner = _checkWinner();
        
//         if (_winner != null) {
//           if (_winner == 'X') _xWins++;
//           if (_winner == 'O') _oWins++;
//           if (_winner == 'Draw') _draws++;
          
//           if (_winner != 'Draw') {
//             _isCelebrating = true;
//             _confettiController.play();
//             _playSound('congrats'); // Play congrats sound for winner
//           } else {
//             _playSound('draw');
//           }
//         } else {
//           _currentPlayer = _currentPlayer == 'X' ? 'O' : 'X';
//           _playSound('beep'); // Play beep sound when switching turns
//         }
        
//         _animationController.reset();
//         _animationController.forward();
//       });
//     }
//   }

//   // ... [keep all other existing methods the same] ...

//   String? _checkWinner() {
//     const List<List<int>> winPatterns = [
//       [0, 1, 2],
//       [3, 4, 5],
//       [6, 7, 8],
//       [0, 3, 6],
//       [1, 4, 7],
//       [2, 5, 8],
//       [0, 4, 8],
//       [2, 4, 6],
//     ];

//     for (var pattern in winPatterns) {
//       String a = _board[pattern[0]];
//       String b = _board[pattern[1]];
//       String c = _board[pattern[2]];
//       if (a != '' && a == b && b == c) {
//         _winningIndices = pattern;
//         return a;
//       }
//     }

//     if (!_board.contains('')) {
//       return 'Draw';
//     }

//     return null;
//   }

//   Widget _buildScoreCard(String label, int score, Color color) {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: color, width: 1.5),
//       ),
//       child: Column(
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.bold,
//               color: color,
//             ),
//           ),
//           Text(
//             score.toString(),
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: color,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBoardCell(int index) {
//     final isWinningCell = _winningIndices.contains(index);
//     final isDark = Provider.of<SettingsController>(context).isDarkMode;
    
//     return InkWell(
//       onTap: () => _handleTap(index),
//       borderRadius: BorderRadius.circular(16),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 300),
//         decoration: BoxDecoration(
//           color: isWinningCell
//               ? (_board[index] == 'X' 
//                   ? Colors.blue.withOpacity(0.2) 
//                   : Colors.red.withOpacity(0.2))
//               : isDark 
//                   ? Colors.grey[800] 
//                   : Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(
//             color: isWinningCell
//                 ? (_board[index] == 'X' ? Colors.blue : Colors.red)
//                 : Colors.transparent,
//             width: 2,
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: isDark
//                   ? Colors.black.withOpacity(0.5)
//                   : Colors.grey.withOpacity(0.3),
//               blurRadius: 10,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Center(
//           child: AnimatedSwitcher(
//             duration: const Duration(milliseconds: 300),
//             transitionBuilder: (Widget child, Animation<double> animation) {
//               return ScaleTransition(scale: animation, child: child);
//             },
//             child: _board[index].isEmpty
//                 ? const SizedBox()
//                 : Stack(
//                     alignment: Alignment.center,
//                     children: [
//                       if (isWinningCell)
//                         Positioned(
//                           top: 0,
//                           child: Icon(
//                             Icons.star,
//                             color: _board[index] == 'X' 
//                                 ? Colors.blue 
//                                 : Colors.red,
//                             size: 24,
//                           ),
//                         ),
//                       Text(
//                         _board[index],
//                         key: ValueKey<String>('${_board[index]}$index'),
//                         style: TextStyle(
//                           fontSize: 48,
//                           fontWeight: FontWeight.bold,
//                           color: _board[index] == 'X'
//                               ? Colors.blue
//                               : Colors.redAccent,
//                           shadows: [
//                             Shadow(
//                               blurRadius: 10,
//                               color: _board[index] == 'X'
//                                   ? Colors.blue.withOpacity(0.3)
//                                   : Colors.red.withOpacity(0.3),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final settings = Provider.of<SettingsController>(context);
//     final isDark = settings.isDarkMode;
//     final themeColor = isDark ? Colors.amberAccent : Colors.deepPurple;

//     return Stack(
//       children: [
//         Scaffold(
//           appBar: AppBar(
//             title: const Text('Tic Tac Toe'),
//             backgroundColor: Colors.transparent,
//             elevation: 0,
//             foregroundColor: isDark ? Colors.white : Colors.black,
//             actions: [
//               IconButton(
//                 icon: const Icon(Icons.refresh),
//                 onPressed: _resetGame,
//                 tooltip: 'Restart',
//               ),
//             ],
//           ),
//           backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
//           body: Padding(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               children: [
//                 // Score board
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceAround,
//                   children: [
//                     _buildScoreCard('X Wins', _xWins, Colors.blue),
//                     _buildScoreCard('Draws', _draws, Colors.grey),
//                     _buildScoreCard('O Wins', _oWins, Colors.red),
//                   ],
//                 ),
//                 const SizedBox(height: 20),
                
//                 // Game status
//                 AnimatedSwitcher(
//                   duration: const Duration(milliseconds: 300),
//                   transitionBuilder: (Widget child, Animation<double> animation) {
//                     return FadeTransition(opacity: animation, child: child);
//                   },
//                   child: Container(
//                     key: ValueKey<String>(_winner ?? _currentPlayer),
//                     padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
//                     decoration: BoxDecoration(
//                       color: themeColor.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(20),
//                       border: Border.all(color: themeColor, width: 2),
//                     ),
//                     child: Text(
//                       _winner != null
//                           ? (_winner == 'Draw' ? "It's a Draw! 🎭" : 'Player $_winner Wins! 🎉')
//                           : 'Player $_currentPlayer\'s Turn ${_currentPlayer == 'X' ? '❌' : '⭕'}',
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: themeColor,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
                
//                 // Game board
//                 Expanded(
//                   child: ScaleTransition(
//                     scale: _scaleAnimation,
//                     child: GridView.builder(
//                       physics: const NeverScrollableScrollPhysics(),
//                       itemCount: 9,
//                       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                         crossAxisCount: 3,
//                         mainAxisSpacing: 12,
//                         crossAxisSpacing: 12,
//                       ),
//                       itemBuilder: (context, index) => _buildBoardCell(index),
//                     ),
//                   ),
//                 ),
                
//                 // Restart button
//                 Padding(
//                   padding: const EdgeInsets.only(top: 20),
//                   child: ElevatedButton.icon(
//                     onPressed: _resetGame,
//                     icon: const Icon(Icons.refresh),
//                     label: const Text('New Game'),
//                     style: ElevatedButton.styleFrom(
//                       foregroundColor: Colors.white,
//                       backgroundColor: themeColor,
//                       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       elevation: 5,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
        
//         // Confetti celebration
//         if (_isCelebrating)
//           Align(
//             alignment: Alignment.topCenter,
//             child: ConfettiWidget(
//               confettiController: _confettiController,
//               blastDirectionality: BlastDirectionality.explosive,
//               shouldLoop: false,
//               colors: const [
//                 Colors.blue,
//                 Colors.red,
//                 Colors.green,
//                 Colors.yellow,
//                 Colors.purple,
//               ],
//               createParticlePath: (size) {
//                 final path = Path();
//                 path.addOval(Rect.fromCircle(
//                   center: Offset.zero,
//                   radius: size.width / 2,
//                 ));
//                 return path;
//               },
//             ),
//           ),
        
//         // Winner ribbon effect
//         if (_winner != null && _winner != 'Draw')
//           Positioned(
//             top: MediaQuery.of(context).size.height * 0.3,
//             left: 0,
//             right: 0,
//             child: Center(
//               child: Transform.rotate(
//                 angle: -0.1,
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 40),
//                   decoration: BoxDecoration(
//                     color: _winner == 'X' ? Colors.blue : Colors.red,
//                     borderRadius: BorderRadius.circular(4),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.3),
//                         blurRadius: 10,
//                         offset: const Offset(0, 5),
//                       ),
//                     ],
//                   ),
//                   child: Text(
//                     'WINNER!',
//                     style: const TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                       letterSpacing: 2,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//       ],
//     );
//   }
// }