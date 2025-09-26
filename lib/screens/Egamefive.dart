import 'dart:async';

import 'package:flutter/material.dart';

class NumberSequenceGameScreen extends StatefulWidget {
  final int level;

  const NumberSequenceGameScreen({super.key, required this.level});

  @override
  State<NumberSequenceGameScreen> createState() => _NumberSequenceGameScreenState();
}

class _NumberSequenceGameScreenState extends State<NumberSequenceGameScreen> {
  late List<int> _numberSequence;
  late List<int> _shuffledSequence;
  int _currentIndex = 0;
  int _timeLeft = 5;
  int _score = 0;
  bool _isGameOver = false;
  Timer? _countdownTimer;
  bool _isDarkMode = false;
  bool _isAwaitingInput = false;

  @override
  void initState() {
    super.initState();
    _generateSequence();
    _startCountdown();
  }

  void _generateSequence() {
    final length = 3 + widget.level;
    _numberSequence = List.generate(length, (index) => index + 1);
    _shuffledSequence = List.from(_numberSequence);
    _shuffledSequence.shuffle();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _isAwaitingInput = true;
          _countdownTimer?.cancel();
        }
      });
    });
  }

  void _onNumberTap(int number) {
    if (!_isAwaitingInput || _isGameOver) return;

    setState(() {
      if (number == _numberSequence[_currentIndex]) {
        _currentIndex++;
        _score++;
        if (_currentIndex >= _numberSequence.length) {
          _showLevelCompleteDialog();
        }
      } else {
        _isGameOver = true;
        _showGameOverDialog();
      }
    });
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Game Over'),
        content: Text('Your score: $_score'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  void _showLevelCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Level Complete!'),
        content: Text('Great job! Score: $_score'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String title, String value, bool isDarkMode) {
    return Card(
      color: isDarkMode ? Colors.black54 : Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt, color: Colors.purpleAccent),
            tooltip: 'Restart Level',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => NumberSequenceGameScreen(level: widget.level),
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!_isAwaitingInput) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatusCard('Level', '${widget.level}', _isDarkMode),
                  _buildStatusCard('Time', '$_timeLeft s', _isDarkMode),
                  _buildStatusCard('Score', '$_score', _isDarkMode),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                itemCount: _shuffledSequence.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.0,
                ),
                itemBuilder: (context, index) {
                  return Card(
                    color: Colors.deepPurpleAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: Center(
                      child: Text(
                        '${_shuffledSequence[index]}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'Enter the Sequence:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                itemCount: _shuffledSequence.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.0,
                ),
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () => _onNumberTap(_shuffledSequence[index]),
                    borderRadius: BorderRadius.circular(8),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: Colors.purple,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${_shuffledSequence[index]}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
