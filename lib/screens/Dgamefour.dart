import 'dart:math';
import 'package:flutter/material.dart';

class ImpostorPixelScreen extends StatefulWidget {
  const ImpostorPixelScreen({super.key});

  @override
  State<ImpostorPixelScreen> createState() => _ImpostorPixelScreenState();
}

class _ImpostorPixelScreenState extends State<ImpostorPixelScreen> {
  final int gridSize = 6;
  late int impostorRow;
  late int impostorCol;
  late Color baseColor;
  late Color impostorColor;
  bool gameOver = false;

  @override
  void initState() {
    super.initState();
    _setupNewGame();
  }

  void _setupNewGame() {
    final rand = Random();
    impostorRow = rand.nextInt(gridSize);
    impostorCol = rand.nextInt(gridSize);

    int baseR = rand.nextInt(200) + 30;
    int baseG = rand.nextInt(200) + 30;
    int baseB = rand.nextInt(200) + 30;

    baseColor = Color.fromRGBO(baseR, baseG, baseB, 1);
    impostorColor = Color.fromRGBO(
      (baseR + rand.nextInt(20) - 10).clamp(0, 255),
      (baseG + rand.nextInt(20) - 10).clamp(0, 255),
      (baseB + rand.nextInt(20) - 10).clamp(0, 255),
      1,
    );

    setState(() {
      gameOver = false;
    });
  }

  void _handleTap(int row, int col) {
    if (gameOver) return;

    final correct = row == impostorRow && col == impostorCol;
    setState(() {
      gameOver = true;
    });

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(correct ? '🎯 Correct!' : '❌ Wrong'),
        content: Text(correct
            ? 'You found the impostor pixel!'
            : 'Oops! That wasn’t the one.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _setupNewGame();
            },
            child: const Text('Play Again'),
          )
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return Column(
      children: List.generate(gridSize, (row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(gridSize, (col) {
            final isImpostor = row == impostorRow && col == impostorCol;
            final color = isImpostor ? impostorColor : baseColor;
            return GestureDetector(
              onTap: () => _handleTap(row, col),
              child: Container(
                margin: const EdgeInsets.all(4),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostor Pixel'),
        backgroundColor: Colors.deepPurple,
      ),
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Find the different pixel!',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            _buildGrid(),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _setupNewGame,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
              child: const Text('New Round'),
            ),
          ],
        ),
      ),
    );
  }
}
