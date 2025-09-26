
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import '../controllers/settings_controller.dart';

class BallSortingGame extends StatefulWidget {
  const BallSortingGame({super.key});

  @override
  _BallSortingGameState createState() => _BallSortingGameState();
}

class _BallSortingGameState extends State<BallSortingGame> 
    with SingleTickerProviderStateMixin {
  // ========== Game Constants ==========
  static const int MAX_LIVES = 5;
  static const int MAX_BALLS_PER_BOX = 15;
  static const int MAX_FALLING_BALLS = 20;
  static const double BASE_BALL_SPEED = 0.5;
  static const int BASE_SPAWN_INTERVAL = 2000;
  static const List<Color> DEFAULT_COLORS = [
    Colors.redAccent,
    Colors.blueAccent,
    Colors.greenAccent,
    Colors.amber,
    Colors.purpleAccent,
  ];
  
  // ========== Game Variables ==========
  late List<Color> colors;
  final List<double> boxPositions = [0.1, 0.3, 0.5, 0.7, 0.9];
  final List<double> boxWidths = [0.15, 0.15, 0.15, 0.15, 0.15];
  final List<List<Ball>> boxes = [[], [], [], [], []];
  final List<Ball> fallingBalls = [];
  
  int? selectedBoxIndex;
  int score = 0;
  int highScore = 0;
  int lives = MAX_LIVES;
  bool gameOver = false;
  bool gameStarted = false;
  double currentBallSpeed = BASE_BALL_SPEED;
  int ballSpawnInterval = BASE_SPAWN_INTERVAL;
  int gameTime = 0;
  int difficultyLevel = 1;
  bool hasShownNewHighScoreConfetti = false;
  int ballsCaught = 0;
  int ballsMissed = 0;
  
  // ========== Effects & Audio ==========
  late Timer ballSpawnTimer;
  late Timer gameTimer;
  late AnimationController animationController;
  late AudioPlayer soundPlayer;
  late AudioPlayer musicPlayer;
  late ConfettiController confettiController;
  final Random _random = Random();
  
  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    colors = List.from(DEFAULT_COLORS);
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8),
    )..addListener(_safeUpdateGame);
    
    soundPlayer = AudioPlayer();
    musicPlayer = AudioPlayer();
    confettiController = ConfettiController(duration: const Duration(seconds: 2));
    
    await _loadHighScore();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => highScore = prefs.getInt('highScore') ?? 0);
  }

  Future<void> _saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('highScore', highScore);
  }

  Future<void> _playSound(String asset) async {
    final settings = Provider.of<SettingsController>(context, listen: false);
    
    // Only play sound if sound effects are enabled
    if (!settings.soundEffects) return;
    
    try {
      await soundPlayer.setVolume(settings.volumeLevel);
      await soundPlayer.stop();
      await soundPlayer.play(AssetSource('sounds/$asset'));
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  Future<void> _playBackgroundMusic() async {
    final settings = Provider.of<SettingsController>(context, listen: false);
    
    // Only play music if sound effects are enabled
    if (!settings.soundEffects) return;
    
    try {
      await musicPlayer.setVolume(settings.volumeLevel * 0.5); // Background music at half volume
      await musicPlayer.play(AssetSource('sounds/game_music.mp3'));
      musicPlayer.setReleaseMode(ReleaseMode.loop);
    } catch (e) {
      debugPrint('Error playing background music: $e');
    }
  }

  // ========== Game Logic ==========
  void resetGame() {
    colors = List.from(DEFAULT_COLORS);
    boxes.forEach((box) => box.clear());
    fallingBalls.clear();
    score = 0;
    lives = MAX_LIVES;
    gameOver = false;
    currentBallSpeed = BASE_BALL_SPEED;
    ballSpawnInterval = BASE_SPAWN_INTERVAL;
    gameTime = 0;
    selectedBoxIndex = null;
    difficultyLevel = 1;
    hasShownNewHighScoreConfetti = false;
    ballsCaught = 0;
    ballsMissed = 0;
  }

  void startGame() {
    resetGame();
    setState(() => gameStarted = true);
    
    _playSound('game_start.mp3');
    _playBackgroundMusic();
    
    animationController.reset();
    animationController.repeat();
    
    _startTimers();
  }

  void _startTimers() {
    ballSpawnTimer = Timer.periodic(
      Duration(milliseconds: ballSpawnInterval), 
      (_) => spawnBall()
    );
    
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!gameOver && mounted) {
        setState(() {
          gameTime++;
          if (gameTime % 30 == 0) _increaseDifficulty();
        });
      }
    });
  }

  void _increaseDifficulty() {
    difficultyLevel++;
    
    // More balanced difficulty progression:
    currentBallSpeed = BASE_BALL_SPEED * (1 + difficultyLevel / 10);  // Reduced denominator from 20 to 10
    ballSpawnInterval = (BASE_SPAWN_INTERVAL / (1 + difficultyLevel / 15))  // Reduced denominator from 10 to 15
        .clamp(800, BASE_SPAWN_INTERVAL).toInt();  // Increased minimum interval from 1000 to 800
    
    ballSpawnTimer.cancel();
    ballSpawnTimer = Timer.periodic(
      Duration(milliseconds: ballSpawnInterval), 
      (_) => spawnBall()
    );
    
    _showDifficultyNotification();
  }

  void _showDifficultyNotification() {
    final theme = Theme.of(context);
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 100,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.9),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                'Level $difficultyLevel',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: theme.colorScheme.shadow,
                      blurRadius: 4,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    
    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () => overlayEntry.remove());
  }

  void spawnBall() {
    if (!mounted || fallingBalls.length > MAX_FALLING_BALLS) return;
    
    final color = colors[_random.nextInt(colors.length)];
    final xPosition = boxPositions[_random.nextInt(boxPositions.length)];
    
    setState(() {
      fallingBalls.add(Ball(
        color: color,
        x: xPosition,
        y: 0.0,
        speed: currentBallSpeed,
        size: 30.0 + _random.nextDouble() * 10.0,
      ));
    });
    
    _playSound('ball_spawn.mp3');
  }

  void _safeUpdateGame() {
    if (mounted) updateGame();
  }

  void updateGame() {
    if (gameOver || !gameStarted || !mounted) return;

    final double deltaTime = animationController.duration != null
        ? animationController.duration!.inMilliseconds / 1000.0
        : 0.016;
    final speedFactor = currentBallSpeed * deltaTime;

    setState(() {
      for (var ball in List.from(fallingBalls)) {
        ball.y += speedFactor;

        if (ball.y >= 0.8) {
          _handleBallCollision(ball);
          fallingBalls.remove(ball);

          if (lives <= 0) {
            gameOver = true;
            endGame();
          }
        }
      }
    });
  }

  void _handleBallCollision(Ball ball) {
    bool caught = false;
    
    for (int i = 0; i < boxPositions.length; i++) {
      if (ball.x >= boxPositions[i] - boxWidths[i]/2 && 
          ball.x <= boxPositions[i] + boxWidths[i]/2) {
        caught = true;
        
        if (ball.color == colors[i]) {
          if (boxes[i].length < MAX_BALLS_PER_BOX) {
            boxes[i].add(ball);
            _handleCorrectCatch(i);
          } else {
            _handlePenalty();
            _showBoxFullWarning(i);
          }
        } else {
          _handlePenalty();
        }
        break;
      }
    }
    
    if (!caught) {
      _handlePenalty();
      ballsMissed++;
    }
  }

  void _showBoxFullWarning(int boxIndex) {
    final theme = Theme.of(context);
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: (boxPositions[boxIndex] - boxWidths[boxIndex]/2) * MediaQuery.of(context).size.width,
        bottom: 90,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'BOX FULL!',
              style: TextStyle(
                color: theme.colorScheme.onError,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
    
    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 1), () => overlayEntry.remove());
  }

  void _handleCorrectCatch(int boxIndex) {
    ballsCaught++;
    score += (10 + (difficultyLevel ~/ 2)).toInt();
    _playSound('success.mp3');
    
    if (score > highScore) {
      highScore = score;
      _saveHighScore();
      if (!hasShownNewHighScoreConfetti && score > 100) {
        confettiController.play();
        _playSound('congrats.mp3');
        hasShownNewHighScoreConfetti = true;
      }
    }
    
    if (ballsCaught % 50 == 0 && lives < MAX_LIVES) {
      setState(() => lives++);
      _showBonusLifeNotification();
    }
  }

  void _showBonusLifeNotification() {
    final theme = Theme.of(context);
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 150,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiary.withOpacity(0.9),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                'BONUS LIFE!',
                style: TextStyle(
                  color: theme.colorScheme.onTertiary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: theme.colorScheme.shadow,
                      blurRadius: 4,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    
    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () => overlayEntry.remove());
  }

  void _handlePenalty() {
    setState(() => lives--);
    _playSound('fail.mp3');
    
    if (lives > 0) {
      _showPenaltyNotification();
    }
  }

  void _showPenaltyNotification() {
    final theme = Theme.of(context);
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 150,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withOpacity(0.9),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                'MISSED!',
                style: TextStyle(
                  color: theme.colorScheme.onError,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: theme.colorScheme.shadow,
                      blurRadius: 4,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    
    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 1), () => overlayEntry.remove());
  }

  void endGame() {
    ballSpawnTimer.cancel();
    gameTimer.cancel();
    musicPlayer.stop();
    animationController.stop();
    _playSound('fail.mp3');
  }

  void handleBoxTap(int boxIndex) {
    if (gameOver || !gameStarted) return;
    
    setState(() {
      if (selectedBoxIndex == null) {
        selectedBoxIndex = boxIndex;
        _playSound('beep.mp3');
      } else if (selectedBoxIndex == boxIndex) {
        selectedBoxIndex = null;
      } else {
        _swapBoxColors(boxIndex);
        selectedBoxIndex = null;
        score += 3;
        _playSound('swap.mp3');
      }
    });
  }

  void _swapBoxColors(int boxIndex) {
    final tempColor = colors[selectedBoxIndex!];
    colors[selectedBoxIndex!] = colors[boxIndex];
    colors[boxIndex] = tempColor;
  }

  @override
  void dispose() {
    ballSpawnTimer.cancel();
    gameTimer.cancel();
    animationController.dispose();
    soundPlayer.dispose();
    musicPlayer.dispose();
    confettiController.dispose();
    super.dispose();
  }

  // ========== UI Components ==========
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: _buildAppBar(colorScheme),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface.withOpacity(0.9),
              colorScheme.surface.withOpacity(0.7),
            ],
          ),
        ),
        child: Stack(
          children: [
            _buildGameContent(colorScheme),
            if (gameStarted && !gameOver) 
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  colors: const [
                    Colors.blueAccent,
                    Colors.greenAccent,
                    Colors.redAccent,
                    Colors.amber,
                    Colors.purpleAccent,
                  ],
                  shouldLoop: false,
                  emissionFrequency: 0.05,
                  numberOfParticles: 30,
                  maxBlastForce: 20,
                  minBlastForce: 10,
                ),
              ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(ColorScheme colorScheme) {
    return AppBar(
      backgroundColor: colorScheme.primaryContainer,
      iconTheme: IconThemeData(
        color: colorScheme.onPrimaryContainer,
      ),
      title: Text(
        'BALL SORTING',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          color: colorScheme.onPrimaryContainer,
          shadows: [
            Shadow(
              blurRadius: 4,
              offset: const Offset(1, 1),
              color: colorScheme.shadow.withOpacity(0.3),
            ),
          ],
        ),
      ),
      centerTitle: true,
      actions: [
        if (gameStarted)
          IconButton(
            icon: Icon(Icons.info, color: colorScheme.onPrimaryContainer),
            onPressed: _showGameInfo,
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (gameStarted)
                Text('Score: $score', 
                  style: TextStyle(color: colorScheme.onPrimaryContainer)),
              if (gameStarted)
                const SizedBox(width: 8),
              if (gameStarted)
                Text('Lives: $lives', 
                  style: TextStyle(color: colorScheme.onPrimaryContainer)),
              const SizedBox(width: 8),
              Text('High: $highScore', 
                style: TextStyle(color: colorScheme.onPrimaryContainer)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGameContent(ColorScheme colorScheme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            if (!gameStarted) _buildStartScreen(colorScheme),
            if (gameOver) _buildGameOverScreen(colorScheme),
            if (gameStarted) ..._buildGameElements(constraints, colorScheme),
          ],
        );
      },
    );
  }

  Widget _buildStartScreen(ColorScheme colorScheme) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Ball Sorting Game',
              style: TextStyle(
                fontSize: 36, 
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'Match falling balls to box colors\nTap two boxes to swap colors',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Icon(Icons.sports_soccer, size: 100, color: colorScheme.primary),
                ],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Start Game', style: TextStyle(fontSize: 24, color: colorScheme.onPrimary)),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _showGameInfo,
              child: Text(
                'How to Play',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOverScreen(ColorScheme colorScheme) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Game Over!',
              style: TextStyle(
                fontSize: 48, 
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
                shadows: [
                  Shadow(
                    blurRadius: 8,
                    color: colorScheme.shadow.withOpacity(0.8),
                    offset: const Offset(2, 2),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Score: $score',
                    style: TextStyle(
                      fontSize: 36,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'High Score: ${score > highScore ? score : highScore}',
                    style: TextStyle(
                      fontSize: 24,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Icon(Icons.check_circle,
                              color: colorScheme.tertiary, size: 30),
                          const SizedBox(height: 4),
                          Text(
                            '$ballsCaught',
                            style: TextStyle(
                              fontSize: 18,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            'Caught',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Icon(Icons.cancel,
                              color: colorScheme.error, size: 30),
                          const SizedBox(height: 4),
                          Text(
                            '$ballsMissed',
                            style: TextStyle(
                              fontSize: 18,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            'Missed',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 8,
                shadowColor: colorScheme.shadow.withOpacity(0.3),
              ),
              child: Text(
                'Play Again',
                style: TextStyle(fontSize: 20, color: colorScheme.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGameElements(
    BoxConstraints constraints, 
    ColorScheme colorScheme,
  ) {
    return [
      // Falling balls
      ...fallingBalls.map((ball) => Positioned(
        left: ball.x * constraints.maxWidth - ball.size/2,
        top: ball.y * constraints.maxHeight - ball.size/2,
        child: Container(
          width: ball.size,
          height: ball.size,
          decoration: BoxDecoration(
            color: ball.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: ball.color.withOpacity(0.7),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      )),
      
      // Boxes
      ...List.generate(colors.length, (i) => Positioned(
        left: (boxPositions[i] - boxWidths[i]/2) * constraints.maxWidth,
        bottom: 20,
        child: GestureDetector(
          onTap: () => handleBoxTap(i),
          child: Container(
            width: boxWidths[i] * constraints.maxWidth,
            height: 60,
            decoration: BoxDecoration(
              color: colors[i].withOpacity(selectedBoxIndex == i ? 0.9 : 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selectedBoxIndex == i 
                    ? colorScheme.primary 
                    : colorScheme.onSurface.withOpacity(0.8),
                width: selectedBoxIndex == i ? 4 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(2, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Collected balls
                ...List.generate(boxes[i].length, (j) => Positioned(
                  left: (j % 5) * 20.0,
                  bottom: (j ~/ 5) * 20.0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: boxes[i][j].color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: boxes[i][j].color.withOpacity(0.7),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                )),
                if (boxes[i].length >= MAX_BALLS_PER_BOX)
                  Positioned(
                    top: -12,
                    right: -12,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colorScheme.error,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(1, 1),
                          ),
                        ],
                      ),
                      child: Icon(Icons.warning, 
                        color: colorScheme.onError, size: 16),
                    ),
                  ),
              ],
            ),
          ),
        ),
      )),
    ];
  }

  void _showGameInfo() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 10,
        title: Text(
          'How to Play',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInstructionStep(
                Icons.games, 
                "Match falling balls", 
                "Catch balls in boxes with matching colors",
                colorScheme
              ),
              const SizedBox(height: 12),
              _buildInstructionStep(
                Icons.swap_horiz, 
                "Swap box colors", 
                "Tap two boxes to swap their colors",
                colorScheme
              ),
              const SizedBox(height: 12),
              _buildInstructionStep(
                Icons.star, 
                "Fill boxes for points", 
                "Each correct match gives you points",
                colorScheme
              ),
              const SizedBox(height: 12),
              _buildInstructionStep(
                Icons.favorite, 
                "Avoid mistakes", 
                "Wrong matches will cost you lives",
                colorScheme
              ),
              const SizedBox(height: 12),
              _buildInstructionStep(
                Icons.speed, 
                "Game speeds up", 
                "The game gradually gets faster over time",
                colorScheme
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.primary,
            ),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(
    IconData icon, 
    String title, 
    String description, 
    ColorScheme colorScheme
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4, right: 12),
          child: Icon(icon, color: colorScheme.primary, size: 24),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class Ball {
  final Color color;
  double x;
  double y;
  final double speed;
  final double size;

  Ball({
    required this.color,
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
  });
}





// import 'package:flutter/material.dart';/////////////////////////////////////////////////
// import 'dart:math';
// import 'dart:async';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:confetti/confetti.dart';

// class BallSortingGame extends StatefulWidget {
//   const BallSortingGame({super.key});

//   @override
//   _BallSortingGameState createState() => _BallSortingGameState();
// }

// class _BallSortingGameState extends State<BallSortingGame> 
//     with SingleTickerProviderStateMixin {
//   // ========== Game Constants ==========
//   static const int MAX_LIVES = 5;
//   static const int MAX_BALLS_PER_BOX = 15;
//   static const int MAX_FALLING_BALLS = 20;
//   static const double BASE_BALL_SPEED = 0.5;
//   static const int BASE_SPAWN_INTERVAL = 2000;
//   static const List<Color> DEFAULT_COLORS = [
//     Colors.redAccent,
//     Colors.blueAccent,
//     Colors.greenAccent,
//     Colors.amber,
//     Colors.purpleAccent,
//   ];
  
//   // ========== Game Variables ==========
//   late List<Color> colors;
//   final List<double> boxPositions = [0.1, 0.3, 0.5, 0.7, 0.9];
//   final List<double> boxWidths = [0.15, 0.15, 0.15, 0.15, 0.15];
//   final List<List<Ball>> boxes = [[], [], [], [], []];
//   final List<Ball> fallingBalls = [];
  
//   int? selectedBoxIndex;
//   int score = 0;
//   int highScore = 0;
//   int lives = MAX_LIVES;
//   bool gameOver = false;
//   bool gameStarted = false;
//   double currentBallSpeed = BASE_BALL_SPEED;
//   int ballSpawnInterval = BASE_SPAWN_INTERVAL;
//   int gameTime = 0;
//   int difficultyLevel = 1;
//   bool hasShownNewHighScoreConfetti = false;
//   int ballsCaught = 0;
//   int ballsMissed = 0;
  
//   // ========== Effects & Audio ==========
//   late Timer ballSpawnTimer;
//   late Timer gameTimer;
//   late AnimationController animationController;
//   late AudioPlayer soundPlayer;
//   late AudioPlayer musicPlayer;
//   late ConfettiController confettiController;
//   final Random _random = Random();
  
//   @override
//   void initState() {
//     super.initState();
//     _initializeGame();
//   }

//   Future<void> _initializeGame() async {
//     colors = List.from(DEFAULT_COLORS);
//     animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 8),
//     )..addListener(_safeUpdateGame);
    
//     soundPlayer = AudioPlayer();
//     musicPlayer = AudioPlayer();
//     confettiController = ConfettiController(duration: const Duration(seconds: 2));
    
//     await _loadHighScore();
//     await _initializeAudio();
//   }

//   Future<void> _initializeAudio() async {
//     await soundPlayer.setVolume(0.7);
//     await musicPlayer.setVolume(0.3);
//   }

//   Future<void> _loadHighScore() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() => highScore = prefs.getInt('highScore') ?? 0);
//   }

//   Future<void> _saveHighScore() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setInt('highScore', highScore);
//   }

//   Future<void> _playSound(String asset) async {
//     await soundPlayer.play(AssetSource(asset));
//   }

//   // ========== Game Logic ==========
//   void resetGame() {
//     colors = List.from(DEFAULT_COLORS);
//     boxes.forEach((box) => box.clear());
//     fallingBalls.clear();
//     score = 0;
//     lives = MAX_LIVES;
//     gameOver = false;
//     currentBallSpeed = BASE_BALL_SPEED;
//     ballSpawnInterval = BASE_SPAWN_INTERVAL;
//     gameTime = 0;
//     selectedBoxIndex = null;
//     difficultyLevel = 1;
//     hasShownNewHighScoreConfetti = false;
//     ballsCaught = 0;
//     ballsMissed = 0;
//   }

//   void startGame() {
//     resetGame();
//     setState(() => gameStarted = true);
    
//     _playSound('sounds/game_start.mp3');
//     _startBackgroundMusic();
    
//     animationController.reset();
//     animationController.repeat();
    
//     _startTimers();
//   }

//   void _startBackgroundMusic() async {
//     await musicPlayer.play(AssetSource('sounds/game_music.mp3'));
//     musicPlayer.setReleaseMode(ReleaseMode.loop);
//   }

//   void _startTimers() {
//     ballSpawnTimer = Timer.periodic(
//       Duration(milliseconds: ballSpawnInterval), 
//       (_) => spawnBall()
//     );
    
//     gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (!gameOver && mounted) {
//         setState(() {
//           gameTime++;
//           if (gameTime % 30 == 0) _increaseDifficulty();
//         });
//       }
//     });
//   }

//   // void _increaseDifficulty() {
//   //   difficultyLevel++;
//   //   currentBallSpeed = BASE_BALL_SPEED * (1 + difficultyLevel / 20);
//   //   ballSpawnInterval = (BASE_SPAWN_INTERVAL / (1 + difficultyLevel / 10))
//   //       .clamp(1000, BASE_SPAWN_INTERVAL).toInt();
    
//   //   ballSpawnTimer.cancel();
//   //   ballSpawnTimer = Timer.periodic(
//   //     Duration(milliseconds: ballSpawnInterval), 
//   //     (_) => spawnBall()
//   //   );
    
//   //   _showDifficultyNotification();
//   // }

// void _increaseDifficulty() {
//   difficultyLevel++;
  
//   // More balanced difficulty progression:
//   currentBallSpeed = BASE_BALL_SPEED * (1 + difficultyLevel / 10);  // Reduced denominator from 20 to 10
//   ballSpawnInterval = (BASE_SPAWN_INTERVAL / (1 + difficultyLevel / 15))  // Reduced denominator from 10 to 15
//       .clamp(800, BASE_SPAWN_INTERVAL).toInt();  // Increased minimum interval from 1000 to 800
  
//   ballSpawnTimer.cancel();
//   ballSpawnTimer = Timer.periodic(
//     Duration(milliseconds: ballSpawnInterval), 
//     (_) => spawnBall()
//   );
  
//   _showDifficultyNotification();
// }

//   void _showDifficultyNotification() {
//     final theme = Theme.of(context);
//     final overlay = Overlay.of(context);
//     final overlayEntry = OverlayEntry(
//       builder: (context) => Positioned(
//         top: 100,
//         left: 0,
//         right: 0,
//         child: Material(
//           color: Colors.transparent,
//           child: Center(
//             child: AnimatedContainer(
//               duration: const Duration(milliseconds: 300),
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               decoration: BoxDecoration(
//                 color: theme.colorScheme.primary.withOpacity(0.9),
//                 borderRadius: BorderRadius.circular(24),
//                 boxShadow: [
//                   BoxShadow(
//                     color: theme.colorScheme.shadow.withOpacity(0.5),
//                     blurRadius: 10,
//                     offset: const Offset(0, 4),
//                   ),
//                 ],
//               ),
//               child: Text(
//                 'Level $difficultyLevel',
//                 style: TextStyle(
//                   color: theme.colorScheme.onPrimary,
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold,
//                   shadows: [
//                     Shadow(
//                       color: theme.colorScheme.shadow,
//                       blurRadius: 4,
//                       offset: const Offset(1, 1),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
    
//     overlay.insert(overlayEntry);
//     Future.delayed(const Duration(seconds: 2), () => overlayEntry.remove());
//   }

//   void spawnBall() {
//     if (!mounted || fallingBalls.length > MAX_FALLING_BALLS) return;
    
//     final color = colors[_random.nextInt(colors.length)];
//     final xPosition = boxPositions[_random.nextInt(boxPositions.length)];
    
//     setState(() {
//       fallingBalls.add(Ball(
//         color: color,
//         x: xPosition,
//         y: 0.0,
//         speed: currentBallSpeed,
//         size: 30.0 + _random.nextDouble() * 10.0,
//       ));
//     });
    
//     _playSound('sounds/ball_spawn.mp3');
//   }

//   void _safeUpdateGame() {
//     if (mounted) updateGame();
//   }

//   void updateGame() {
//     if (gameOver || !gameStarted || !mounted) return;

//     final double deltaTime = animationController.duration != null
//         ? animationController.duration!.inMilliseconds / 1000.0
//         : 0.016;
//     final speedFactor = currentBallSpeed * deltaTime;

//     setState(() {
//       for (var ball in List.from(fallingBalls)) {
//         ball.y += speedFactor;

//         if (ball.y >= 0.8) {
//           _handleBallCollision(ball);
//           fallingBalls.remove(ball);

//           if (lives <= 0) {
//             gameOver = true;
//             endGame();
//           }
//         }
//       }
//     });
//   }

//   void _handleBallCollision(Ball ball) {
//     bool caught = false;
    
//     for (int i = 0; i < boxPositions.length; i++) {
//       if (ball.x >= boxPositions[i] - boxWidths[i]/2 && 
//           ball.x <= boxPositions[i] + boxWidths[i]/2) {
//         caught = true;
        
//         if (ball.color == colors[i]) {
//           if (boxes[i].length < MAX_BALLS_PER_BOX) {
//             boxes[i].add(ball);
//             _handleCorrectCatch(i);
//           } else {
//             _handlePenalty();
//             _showBoxFullWarning(i);
//           }
//         } else {
//           _handlePenalty();
//         }
//         break;
//       }
//     }
    
//     if (!caught) {
//       _handlePenalty();
//       ballsMissed++;
//     }
//   }

//   void _showBoxFullWarning(int boxIndex) {
//     final theme = Theme.of(context);
//     final overlay = Overlay.of(context);
//     final overlayEntry = OverlayEntry(
//       builder: (context) => Positioned(
//         left: (boxPositions[boxIndex] - boxWidths[boxIndex]/2) * MediaQuery.of(context).size.width,
//         bottom: 90,
//         child: Material(
//           color: Colors.transparent,
//           child: Container(
//             padding: const EdgeInsets.all(6),
//             decoration: BoxDecoration(
//               color: theme.colorScheme.error.withOpacity(0.9),
//               borderRadius: BorderRadius.circular(8),
//               boxShadow: [
//                 BoxShadow(
//                   color: theme.colorScheme.shadow.withOpacity(0.2),
//                   blurRadius: 6,
//                   offset: const Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: Text(
//               'BOX FULL!',
//               style: TextStyle(
//                 color: theme.colorScheme.onError,
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
    
//     overlay.insert(overlayEntry);
//     Future.delayed(const Duration(seconds: 1), () => overlayEntry.remove());
//   }

//   void _handleCorrectCatch(int boxIndex) {
//     ballsCaught++;
//     score += (10 + (difficultyLevel ~/ 2)).toInt();
//     _playSound('sounds/success.mp3');
    
//     if (score > highScore) {
//       highScore = score;
//       _saveHighScore();
//       if (!hasShownNewHighScoreConfetti && score > 100) {
//         confettiController.play();
//         _playSound('sounds/congrats.mp3');
//         hasShownNewHighScoreConfetti = true;
//       }
//     }
    
//     if (ballsCaught % 50 == 0 && lives < MAX_LIVES) {
//       setState(() => lives++);
//       _showBonusLifeNotification();
//     }
//   }

//   void _showBonusLifeNotification() {
//     final theme = Theme.of(context);
//     final overlay = Overlay.of(context);
//     final overlayEntry = OverlayEntry(
//       builder: (context) => Positioned(
//         top: 150,
//         left: 0,
//         right: 0,
//         child: Material(
//           color: Colors.transparent,
//           child: Center(
//             child: AnimatedContainer(
//               duration: const Duration(milliseconds: 300),
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               decoration: BoxDecoration(
//                 color: theme.colorScheme.tertiary.withOpacity(0.9),
//                 borderRadius: BorderRadius.circular(24),
//                 boxShadow: [
//                   BoxShadow(
//                     color: theme.colorScheme.shadow.withOpacity(0.3),
//                     blurRadius: 10,
//                     offset: const Offset(0, 4),
//                   ),
//                 ],
//               ),
//               child: Text(
//                 'BONUS LIFE!',
//                 style: TextStyle(
//                   color: theme.colorScheme.onTertiary,
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold,
//                   shadows: [
//                     Shadow(
//                       color: theme.colorScheme.shadow,
//                       blurRadius: 4,
//                       offset: const Offset(1, 1),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
    
//     overlay.insert(overlayEntry);
//     Future.delayed(const Duration(seconds: 2), () => overlayEntry.remove());
//   }

//   void _handlePenalty() {
//     setState(() => lives--);
//     _playSound('sounds/fail.mp3');
    
//     if (lives > 0) {
//       _showPenaltyNotification();
//     }
//   }

//   void _showPenaltyNotification() {
//     final theme = Theme.of(context);
//     final overlay = Overlay.of(context);
//     final overlayEntry = OverlayEntry(
//       builder: (context) => Positioned(
//         top: 150,
//         left: 0,
//         right: 0,
//         child: Material(
//           color: Colors.transparent,
//           child: Center(
//             child: AnimatedContainer(
//               duration: const Duration(milliseconds: 300),
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               decoration: BoxDecoration(
//                 color: theme.colorScheme.error.withOpacity(0.9),
//                 borderRadius: BorderRadius.circular(24),
//                 boxShadow: [
//                   BoxShadow(
//                     color: theme.colorScheme.shadow.withOpacity(0.3),
//                     blurRadius: 10,
//                     offset: const Offset(0, 4),
//                   ),
//                 ],
//               ),
//               child: Text(
//                 'MISSED!',
//                 style: TextStyle(
//                   color: theme.colorScheme.onError,
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold,
//                   shadows: [
//                     Shadow(
//                       color: theme.colorScheme.shadow,
//                       blurRadius: 4,
//                       offset: const Offset(1, 1),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
    
//     overlay.insert(overlayEntry);
//     Future.delayed(const Duration(seconds: 1), () => overlayEntry.remove());
//   }

//   void endGame() {
//     ballSpawnTimer.cancel();
//     gameTimer.cancel();
//     musicPlayer.stop();
//     animationController.stop();
//     _playSound('sounds/fail.mp3');
//   }

//   void handleBoxTap(int boxIndex) {
//     if (gameOver || !gameStarted) return;
    
//     setState(() {
//       if (selectedBoxIndex == null) {
//         selectedBoxIndex = boxIndex;
//         _playSound('sounds/beep.mp3');
//       } else if (selectedBoxIndex == boxIndex) {
//         selectedBoxIndex = null;
//       } else {
//         _swapBoxColors(boxIndex);
//         selectedBoxIndex = null;
//         score += 3;
//         _playSound('sounds/swap.mp3');
//       }
//     });
//   }

//   void _swapBoxColors(int boxIndex) {
//     final tempColor = colors[selectedBoxIndex!];
//     colors[selectedBoxIndex!] = colors[boxIndex];
//     colors[boxIndex] = tempColor;
//   }

//   @override
//   void dispose() {
//     ballSpawnTimer.cancel();
//     gameTimer.cancel();
//     animationController.dispose();
//     soundPlayer.dispose();
//     musicPlayer.dispose();
//     confettiController.dispose();
//     super.dispose();
//   }

//   // ========== UI Components ==========
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final isDarkMode = theme.brightness == Brightness.dark;
//     final colorScheme = theme.colorScheme;

//     return Scaffold(
//       appBar: _buildAppBar(colorScheme),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               colorScheme.surface.withOpacity(0.9),
//               colorScheme.surface.withOpacity(0.7),
//             ],
//           ),
//         ),
//         child: Stack(
//           children: [
//             _buildGameContent(colorScheme),
//             if (gameStarted && !gameOver) 
//               Align(
//                 alignment: Alignment.topCenter,
//                 child: ConfettiWidget(
//                   confettiController: confettiController,
//                   blastDirectionality: BlastDirectionality.explosive,
//                   colors: const [
//                     Colors.blueAccent,
//                     Colors.greenAccent,
//                     Colors.redAccent,
//                     Colors.amber,
//                     Colors.purpleAccent,
//                   ],
//                   shouldLoop: false,
//                   emissionFrequency: 0.05,
//                   numberOfParticles: 30,
//                   maxBlastForce: 20,
//                   minBlastForce: 10,
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   AppBar _buildAppBar(ColorScheme colorScheme) {
//     return AppBar(
//       backgroundColor: colorScheme.primaryContainer,
//       iconTheme: IconThemeData(
//         color: colorScheme.onPrimaryContainer,
//       ),
//       title: Text(
//         'BALL SORTING',
//         style: TextStyle(
//           fontSize: 20,
//           fontWeight: FontWeight.bold,
//           letterSpacing: 1.5,
//           color: colorScheme.onPrimaryContainer,
//           shadows: [
//             Shadow(
//               blurRadius: 4,
//               offset: const Offset(1, 1),
//               color: colorScheme.shadow.withOpacity(0.3),
//             ),
//           ],
//         ),
//       ),
//       centerTitle: true,
//       actions: [
//         if (gameStarted)
//           IconButton(
//             icon: Icon(Icons.info, color: colorScheme.onPrimaryContainer),
//             onPressed: _showGameInfo,
//           ),
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 8.0),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               if (gameStarted)
//                 Text('Score: $score', 
//                   style: TextStyle(color: colorScheme.onPrimaryContainer)),
//               if (gameStarted)
//                 const SizedBox(width: 8),
//               if (gameStarted)
//                 Text('Lives: $lives', 
//                   style: TextStyle(color: colorScheme.onPrimaryContainer)),
//               const SizedBox(width: 8),
//               Text('High: $highScore', 
//                 style: TextStyle(color: colorScheme.onPrimaryContainer)),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildGameContent(ColorScheme colorScheme) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         return Stack(
//           children: [
//             if (!gameStarted) _buildStartScreen(colorScheme),
//             if (gameOver) _buildGameOverScreen(colorScheme),
//             if (gameStarted) ..._buildGameElements(constraints, colorScheme),
//           ],
//         );
//       },
//     );
//   }

//   Widget _buildStartScreen(ColorScheme colorScheme) {
//     return Center(
//       child: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               'Ball Sorting Game',
//               style: TextStyle(
//                 fontSize: 36, 
//                 fontWeight: FontWeight.bold,
//                 color: colorScheme.onSurface,
//               ),
//             ),
//             const SizedBox(height: 20),
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: colorScheme.surfaceContainerHighest.withOpacity(0.7),
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Column(
//                 children: [
//                   Text(
//                     'Match falling balls to box colors\nTap two boxes to swap colors',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontSize: 18,
//                       color: colorScheme.onSurfaceVariant,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   Icon(Icons.sports_soccer, size: 100, color: colorScheme.primary),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 30),
//             ElevatedButton(
//               onPressed: startGame,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: colorScheme.primary,
//                 foregroundColor: colorScheme.onPrimary,
//                 padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//               child: Text('Start Game', style: TextStyle(fontSize: 24, color: colorScheme.onPrimary)),
//             ),
//             const SizedBox(height: 20),
//             TextButton(
//               onPressed: _showGameInfo,
//               child: Text(
//                 'How to Play',
//                 style: TextStyle(
//                   color: colorScheme.primary,
//                   fontSize: 16,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildGameOverScreen(ColorScheme colorScheme) {
//     return Center(
//       child: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               'Game Over!',
//               style: TextStyle(
//                 fontSize: 48, 
//                 fontWeight: FontWeight.bold,
//                 color: colorScheme.onSurface,
//                 shadows: [
//                   Shadow(
//                     blurRadius: 8,
//                     color: colorScheme.shadow.withOpacity(0.8),
//                     offset: const Offset(2, 2),
//                   )
//                 ],
//               ),
//             ),
//             const SizedBox(height: 20),
//             Container(
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: colorScheme.surfaceContainerHighest.withOpacity(0.8),
//                 borderRadius: BorderRadius.circular(20),
//                 boxShadow: [
//                   BoxShadow(
//                     color: colorScheme.shadow.withOpacity(0.2),
//                     blurRadius: 15,
//                     offset: const Offset(0, 5),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 children: [
//                   Text(
//                     'Score: $score',
//                     style: TextStyle(
//                       fontSize: 36,
//                       color: colorScheme.onSurfaceVariant,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   Text(
//                     'High Score: ${score > highScore ? score : highScore}',
//                     style: TextStyle(
//                       fontSize: 24,
//                       color: colorScheme.onSurfaceVariant,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       Column(
//                         children: [
//                           Icon(Icons.check_circle,
//                               color: colorScheme.tertiary, size: 30),
//                           const SizedBox(height: 4),
//                           Text(
//                             '$ballsCaught',
//                             style: TextStyle(
//                               fontSize: 18,
//                               color: colorScheme.onSurfaceVariant,
//                             ),
//                           ),
//                           Text(
//                             'Caught',
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: colorScheme.onSurfaceVariant,
//                             ),
//                           ),
//                         ],
//                       ),
//                       Column(
//                         children: [
//                           Icon(Icons.cancel,
//                               color: colorScheme.error, size: 30),
//                           const SizedBox(height: 4),
//                           Text(
//                             '$ballsMissed',
//                             style: TextStyle(
//                               fontSize: 18,
//                               color: colorScheme.onSurfaceVariant,
//                             ),
//                           ),
//                           Text(
//                             'Missed',
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: colorScheme.onSurfaceVariant,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 30),
//             ElevatedButton(
//               onPressed: startGame,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: colorScheme.primary,
//                 foregroundColor: colorScheme.onPrimary,
//                 padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 elevation: 8,
//                 shadowColor: colorScheme.shadow.withOpacity(0.3),
//               ),
//               child: Text(
//                 'Play Again',
//                 style: TextStyle(fontSize: 20, color: colorScheme.onPrimary),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   List<Widget> _buildGameElements(
//     BoxConstraints constraints, 
//     ColorScheme colorScheme,
//   ) {
//     return [
//       // Falling balls
//       ...fallingBalls.map((ball) => Positioned(
//         left: ball.x * constraints.maxWidth - ball.size/2,
//         top: ball.y * constraints.maxHeight - ball.size/2,
//         child: Container(
//           width: ball.size,
//           height: ball.size,
//           decoration: BoxDecoration(
//             color: ball.color,
//             shape: BoxShape.circle,
//             boxShadow: [
//               BoxShadow(
//                 color: ball.color.withOpacity(0.7),
//                 blurRadius: 10,
//                 spreadRadius: 2,
//               ),
//             ],
//           ),
//         ),
//       )),
      
//       // Boxes
//       ...List.generate(colors.length, (i) => Positioned(
//         left: (boxPositions[i] - boxWidths[i]/2) * constraints.maxWidth,
//         bottom: 20,
//         child: GestureDetector(
//           onTap: () => handleBoxTap(i),
//           child: Container(
//             width: boxWidths[i] * constraints.maxWidth,
//             height: 60,
//             decoration: BoxDecoration(
//               color: colors[i].withOpacity(selectedBoxIndex == i ? 0.9 : 0.6),
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(
//                 color: selectedBoxIndex == i 
//                     ? colorScheme.primary 
//                     : colorScheme.onSurface.withOpacity(0.8),
//                 width: selectedBoxIndex == i ? 4 : 2,
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: colorScheme.shadow.withOpacity(0.3),
//                   blurRadius: 8,
//                   offset: const Offset(2, 4),
//                 ),
//               ],
//             ),
//             child: Stack(
//               children: [
//                 // Collected balls
//                 ...List.generate(boxes[i].length, (j) => Positioned(
//                   left: (j % 5) * 20.0,
//                   bottom: (j ~/ 5) * 20.0,
//                   child: Container(
//                     width: 16,
//                     height: 16,
//                     decoration: BoxDecoration(
//                       color: boxes[i][j].color,
//                       shape: BoxShape.circle,
//                       boxShadow: [
//                         BoxShadow(
//                           color: boxes[i][j].color.withOpacity(0.7),
//                           blurRadius: 4,
//                           spreadRadius: 1,
//                         ),
//                       ],
//                     ),
//                   ),
//                 )),
//                 if (boxes[i].length >= MAX_BALLS_PER_BOX)
//                   Positioned(
//                     top: -12,
//                     right: -12,
//                     child: Container(
//                       padding: const EdgeInsets.all(4),
//                       decoration: BoxDecoration(
//                         color: colorScheme.error,
//                         shape: BoxShape.circle,
//                         boxShadow: [
//                           BoxShadow(
//                             color: colorScheme.shadow.withOpacity(0.3),
//                             blurRadius: 4,
//                             offset: const Offset(1, 1),
//                           ),
//                         ],
//                       ),
//                       child: Icon(Icons.warning, 
//                         color: colorScheme.onError, size: 16),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ),
//       )),
//     ];
//   }

//   void _showGameInfo() {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;
    
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: colorScheme.surface,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(20),
//         ),
//         elevation: 10,
//         title: Text(
//           'How to Play',
//           style: TextStyle(
//             color: colorScheme.onSurface,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         content: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildInstructionStep(
//                 Icons.games, 
//                 "Match falling balls", 
//                 "Catch balls in boxes with matching colors",
//                 colorScheme
//               ),
//               const SizedBox(height: 12),
//               _buildInstructionStep(
//                 Icons.swap_horiz, 
//                 "Swap box colors", 
//                 "Tap two boxes to swap their colors",
//                 colorScheme
//               ),
//               const SizedBox(height: 12),
//               _buildInstructionStep(
//                 Icons.star, 
//                 "Fill boxes for points", 
//                 "Each correct match gives you points",
//                 colorScheme
//               ),
//               const SizedBox(height: 12),
//               _buildInstructionStep(
//                 Icons.favorite, 
//                 "Avoid mistakes", 
//                 "Wrong matches will cost you lives",
//                 colorScheme
//               ),
//               const SizedBox(height: 12),
//               _buildInstructionStep(
//                 Icons.speed, 
//                 "Game speeds up", 
//                 "The game gradually gets faster over time",
//                 colorScheme
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             style: TextButton.styleFrom(
//               foregroundColor: colorScheme.primary,
//             ),
//             child: const Text('Got it!'),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildInstructionStep(
//     IconData icon, 
//     String title, 
//     String description, 
//     ColorScheme colorScheme
//   ) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Container(
//           margin: const EdgeInsets.only(top: 4, right: 12),
//           child: Icon(icon, color: colorScheme.primary, size: 24),
//         ),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 title,
//                 style: TextStyle(
//                   color: colorScheme.onSurface,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16,
//                 ),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 description,
//                 style: TextStyle(
//                   color: colorScheme.onSurface.withOpacity(0.8),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }

// class Ball {
//   final Color color;
//   double x;
//   double y;
//   final double speed;
//   final double size;

//   Ball({
//     required this.color,
//     required this.x,
//     required this.y,
//     required this.speed,
//     required this.size,
//   });
// }
/////////////////////////////////////////////////////////










// import 'package:flutter/material.dart';
// import 'dart:math';
// import 'dart:async';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:confetti/confetti.dart';

// class BallSortingGame extends StatefulWidget {
//   const BallSortingGame({super.key});

//   @override
//   _BallSortingGameState createState() => _BallSortingGameState();
// }

// class _BallSortingGameState extends State<BallSortingGame> 
//     with SingleTickerProviderStateMixin {
//   // ========== Game Constants ==========
//   static const int MAX_LIVES = 5;
//   static const int MAX_BALLS_PER_BOX = 15;
//   static const int MAX_FALLING_BALLS = 20;
//   static const double BASE_BALL_SPEED = 0.5;
//   static const int BASE_SPAWN_INTERVAL = 2000;
//   static const List<Color> DEFAULT_COLORS = [
//     Colors.redAccent,
//     Colors.blueAccent,
//     Colors.greenAccent,
//     Colors.amber,
//     Colors.purpleAccent,
//   ];
  
//   // ========== Game Variables ==========
//   late List<Color> colors;
//   final List<double> boxPositions = [0.1, 0.3, 0.5, 0.7, 0.9];
//   final List<double> boxWidths = [0.15, 0.15, 0.15, 0.15, 0.15];
//   final List<List<Ball>> boxes = [[], [], [], [], []];
//   final List<Ball> fallingBalls = [];
  
//   int? selectedBoxIndex;
//   int score = 0;
//   int highScore = 0;
//   int lives = MAX_LIVES;
//   bool gameOver = false;
//   bool gameStarted = false;
//   double currentBallSpeed = BASE_BALL_SPEED;
//   int ballSpawnInterval = BASE_SPAWN_INTERVAL;
//   int gameTime = 0;
//   int difficultyLevel = 1;
//   bool hasShownNewHighScoreConfetti = false;
//   int ballsCaught = 0;
//   int ballsMissed = 0;
  
//   // ========== Effects & Audio ==========
//   late Timer ballSpawnTimer;
//   late Timer gameTimer;
//   late AnimationController animationController;
//   late AudioPlayer soundPlayer;
//   late AudioPlayer musicPlayer;
//   late ConfettiController confettiController;
//   final Random _random = Random();
  
//   @override
//   void initState() {
//     super.initState();
//     _initializeGame();
//   }

//   Future<void> _initializeGame() async {
//     colors = List.from(DEFAULT_COLORS);
//     animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 8), // Higher frame rate for smoother animation
//     )..addListener(_safeUpdateGame);
    
//     soundPlayer = AudioPlayer();
//     musicPlayer = AudioPlayer();
//     confettiController = ConfettiController(duration: const Duration(seconds: 2));
    
//     await _loadHighScore();
//     await _initializeAudio();
//   }

//   Future<void> _initializeAudio() async {
//     await soundPlayer.setVolume(0.7);
//     await musicPlayer.setVolume(0.3);
//   }

//   Future<void> _loadHighScore() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() => highScore = prefs.getInt('highScore') ?? 0);
//   }

//   Future<void> _saveHighScore() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setInt('highScore', highScore);
//   }

//   Future<void> _playSound(String asset) async {
//     await soundPlayer.play(AssetSource(asset));
//   }

//   // ========== Game Logic ==========
//   void resetGame() {
//     colors = List.from(DEFAULT_COLORS);
//     boxes.forEach((box) => box.clear());
//     fallingBalls.clear();
//     score = 0;
//     lives = MAX_LIVES;
//     gameOver = false;
//     currentBallSpeed = BASE_BALL_SPEED;
//     ballSpawnInterval = BASE_SPAWN_INTERVAL;
//     gameTime = 0;
//     selectedBoxIndex = null;
//     difficultyLevel = 1;
//     hasShownNewHighScoreConfetti = false;
//     ballsCaught = 0;
//     ballsMissed = 0;
//   }

//   void startGame() {
//     resetGame();
//     setState(() => gameStarted = true);
    
//     _playSound('sounds/game_start.mp3');
//     _startBackgroundMusic();
    
//     animationController.reset();
//     animationController.repeat();
    
//     _startTimers();
//   }

//   void _startBackgroundMusic() async {
//     await musicPlayer.play(AssetSource('sounds/game_music.mp3'));
//     musicPlayer.setReleaseMode(ReleaseMode.loop);
//   }

//   void _startTimers() {
//     ballSpawnTimer = Timer.periodic(
//       Duration(milliseconds: ballSpawnInterval), 
//       (_) => spawnBall()
//     );
    
//     gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (!gameOver && mounted) {
//         setState(() {
//           gameTime++;
//           if (gameTime % 30 == 0) _increaseDifficulty();
//         });
//       }
//     });
//   }

//   void _increaseDifficulty() {
//     difficultyLevel++;
//     currentBallSpeed = BASE_BALL_SPEED * (1 + difficultyLevel / 20);
//     ballSpawnInterval = (BASE_SPAWN_INTERVAL / (1 + difficultyLevel / 10))
//         .clamp(1000, BASE_SPAWN_INTERVAL).toInt();
    
//     ballSpawnTimer.cancel();
//     ballSpawnTimer = Timer.periodic(
//       Duration(milliseconds: ballSpawnInterval), 
//       (_) => spawnBall()
//     );
    
//     _showDifficultyNotification();
//   }

//   void _showDifficultyNotification() {
//     final overlay = Overlay.of(context);
//     final overlayEntry = OverlayEntry(
//       builder: (context) => Positioned(
//         top: 100,
//         left: 0,
//         right: 0,
//         child: Material(
//           color: Colors.transparent,
//           child: Center(
//             child: AnimatedContainer(
//               duration: const Duration(milliseconds: 300),
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               decoration: BoxDecoration(
//                 color: Theme.of(context).colorScheme.primary.withOpacity(0.9),
//                 borderRadius: BorderRadius.circular(24),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black,
//                     blurRadius: 10,
//                     offset: const Offset(0, 4),
//                   ),
//                 ],
//               ),
//               child: Text(
//                 'Level $difficultyLevel',
//                 style: TextStyle(
//                   color: Theme.of(context).colorScheme.onPrimary,
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold,
//                   shadows: [
//                     Shadow(
//                       color: Colors.black, // Opacity removed for const context
//                       blurRadius: 4,
//                       offset: const Offset(1, 1),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
    
//     overlay.insert(overlayEntry);
//     Future.delayed(const Duration(seconds: 2), () => overlayEntry.remove());
//   }

//   void spawnBall() {
//     if (!mounted || fallingBalls.length > MAX_FALLING_BALLS) return;
    
//     final color = colors[_random.nextInt(colors.length)];
//     final xPosition = boxPositions[_random.nextInt(boxPositions.length)];
    
//     setState(() {
//       fallingBalls.add(Ball(
//         color: color,
//         x: xPosition,
//         y: 0.0,
//         speed: currentBallSpeed,
//         size: 30.0 + _random.nextDouble() * 10.0,
//       ));
//     });
    
//     _playSound('sounds/ball_spawn.mp3');
//   }

//   void _safeUpdateGame() {
//     if (mounted) updateGame();
//   }

//   void updateGame() {
//     if (gameOver || !gameStarted || !mounted) return;

//     // Use a more precise delta time for smoother movement
//     final double deltaTime = animationController.duration != null
//         ? animationController.duration!.inMilliseconds / 1000.0
//         : 0.016; // fallback to ~60fps
//     final speedFactor = currentBallSpeed * deltaTime;

//     setState(() {
//       for (var ball in List.from(fallingBalls)) {
//         ball.y += speedFactor;

//         if (ball.y >= 0.8) {
//           _handleBallCollision(ball);
//           fallingBalls.remove(ball);

//           if (lives <= 0) {
//             gameOver = true;
//             endGame();
//           }
//         }
//       }
//     });
//   }

//   void _handleBallCollision(Ball ball) {
//     bool caught = false;
    
//     for (int i = 0; i < boxPositions.length; i++) {
//       if (ball.x >= boxPositions[i] - boxWidths[i]/2 && 
//           ball.x <= boxPositions[i] + boxWidths[i]/2) {
//         caught = true;
        
//         if (ball.color == colors[i]) {
//           if (boxes[i].length < MAX_BALLS_PER_BOX) {
//             boxes[i].add(ball);
//             _handleCorrectCatch(i);
//           } else {
//             _handlePenalty();
//             _showBoxFullWarning(i);
//           }
//         } else {
//           _handlePenalty();
//         }
//         break;
//       }
//     }
    
//     if (!caught) {
//       _handlePenalty();
//       ballsMissed++;
//     }
//   }

//   void _showBoxFullWarning(int boxIndex) {
//     final overlay = Overlay.of(context);
//     final overlayEntry = OverlayEntry(
//       builder: (context) => Positioned(
//         left: (boxPositions[boxIndex] - boxWidths[boxIndex]/2) * MediaQuery.of(context).size.width,
//         bottom: 90,
//         child: Material(
//           color: Colors.transparent,
//           child: Container(
//             padding: const EdgeInsets.all(6),
//             decoration: BoxDecoration(
//               color: Colors.redAccent.withOpacity(0.9),
//               borderRadius: BorderRadius.circular(8),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.2),
//                   blurRadius: 6,
//                   offset: const Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: const Text(
//               'BOX FULL!',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
    
//     overlay.insert(overlayEntry);
//     Future.delayed(const Duration(seconds: 1), () => overlayEntry.remove());
//   }

//   void _handleCorrectCatch(int boxIndex) {
//     ballsCaught++;
//     score += (10 + (difficultyLevel ~/ 2)).toInt();
//     _playSound('sounds/success.mp3');
    
//     if (score > highScore) {
//       highScore = score;
//       _saveHighScore();
//       if (!hasShownNewHighScoreConfetti && score > 100) {
//         confettiController.play();
//         _playSound('sounds/congrats.mp3');
//         hasShownNewHighScoreConfetti = true;
//       }
//     }
    
//     if (ballsCaught % 50 == 0 && lives < MAX_LIVES) {
//       setState(() => lives++);
//       _showBonusLifeNotification();
//     }
//   }

//   void _showBonusLifeNotification() {
//     final overlay = Overlay.of(context);
//     final overlayEntry = OverlayEntry(
//       builder: (context) => Positioned(
//         top: 150,
//         left: 0,
//         right: 0,
//         child: Material(
//           color: Colors.transparent,
//           child: Center(
//             child: AnimatedContainer(
//               duration: const Duration(milliseconds: 300),
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               decoration: BoxDecoration(
//                 color: Colors.greenAccent.withOpacity(0.9),
//                 borderRadius: BorderRadius.circular(24),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.3),
//                     blurRadius: 10,
//                     offset: const Offset(0, 4),
//                   ),
//                 ],
//               ),
//               child: const Text(
//                 'BONUS LIFE!',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold,
//                   shadows: [
//                     Shadow(
//                       color: Colors.black,
//                       blurRadius: 4,
//                       offset: const Offset(1, 1),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
    
//     overlay.insert(overlayEntry);
//     Future.delayed(const Duration(seconds: 2), () => overlayEntry.remove());
//   }

//   void _handlePenalty() {
//     setState(() => lives--);
//     _playSound('sounds/fail.mp3');
    
//     if (lives > 0) {
//       _showPenaltyNotification();
//     }
//   }

//   void _showPenaltyNotification() {
//     final overlay = Overlay.of(context);
//     final overlayEntry = OverlayEntry(
//       builder: (context) => Positioned(
//         top: 150,
//         left: 0,
//         right: 0,
//         child: Material(
//           color: Colors.transparent,
//           child: Center(
//             child: AnimatedContainer(
//               duration: const Duration(milliseconds: 300),
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               decoration: BoxDecoration(
//                 color: Colors.redAccent.withOpacity(0.9),
//                 borderRadius: BorderRadius.circular(24),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.3),
//                     blurRadius: 10,
//                     offset: const Offset(0, 4),
//                   ),
//                 ],
//               ),
//               child: const Text(
//                 'MISSED!',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold,
//                   shadows: [
//                     Shadow(
//                       color: Colors.black,
//                       blurRadius: 4,
//                       offset: const Offset(1, 1),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
    
//     overlay.insert(overlayEntry);
//     Future.delayed(const Duration(seconds: 1), () => overlayEntry.remove());
//   }

//   void endGame() {
//     ballSpawnTimer.cancel();
//     gameTimer.cancel();
//     musicPlayer.stop();
//     animationController.stop();
//     _playSound('sounds/fail.mp3');
//   }

//   void handleBoxTap(int boxIndex) {
//     if (gameOver || !gameStarted) return;
    
//     setState(() {
//       if (selectedBoxIndex == null) {
//         selectedBoxIndex = boxIndex;
//         _playSound('sounds/beep.mp3');
//       } else if (selectedBoxIndex == boxIndex) {
//         selectedBoxIndex = null;
//       } else {
//         _swapBoxColors(boxIndex);
//         selectedBoxIndex = null;
//         score += 3;
//         _playSound('sounds/swap.mp3');
//       }
//     });
//   }

//   void _swapBoxColors(int boxIndex) {
//     final tempColor = colors[selectedBoxIndex!];
//     colors[selectedBoxIndex!] = colors[boxIndex];
//     colors[boxIndex] = tempColor;
//   }

//   @override
//   void dispose() {
//     ballSpawnTimer.cancel();
//     gameTimer.cancel();
//     animationController.dispose();
//     soundPlayer.dispose();
//     musicPlayer.dispose();
//     confettiController.dispose();
//     super.dispose();
//   }

//   // ========== UI Components ==========
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final isDarkMode = theme.brightness == Brightness.dark;
//     final colorScheme = theme.colorScheme;

//     return Scaffold(
//       appBar: _buildAppBar(colorScheme, isDarkMode),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: isDarkMode
//               ? LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   colors: [
//                     colorScheme.surface.withOpacity(0.9),
//                     colorScheme.surface.withOpacity(0.7),
//                   ],
//                 )
//               : LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   colors: [
//                     colorScheme.background.withOpacity(0.9),
//                     colorScheme.background.withOpacity(0.7),
//                   ],
//                 ),
//         ),
//         child: Stack(
//           children: [
//             _buildGameContent(isDarkMode, colorScheme),
//             if (gameStarted && !gameOver) 
//               Align(
//                 alignment: Alignment.topCenter,
//                 child: ConfettiWidget(
//                   confettiController: confettiController,
//                   blastDirectionality: BlastDirectionality.explosive,
//                   colors: const [
//                     Colors.blueAccent,
//                     Colors.greenAccent,
//                     Colors.redAccent,
//                     Colors.amber,
//                     Colors.purpleAccent,
//                   ],
//                   shouldLoop: false,
//                   emissionFrequency: 0.05,
//                   numberOfParticles: 30,
//                   maxBlastForce: 20,
//                   minBlastForce: 10,
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   AppBar _buildAppBar(ColorScheme colorScheme, bool isDarkMode) {
//     return AppBar(
//       backgroundColor: isDarkMode
//           ? colorScheme.primaryContainer
//           : colorScheme.primary.withOpacity(0.8),
//       iconTheme: IconThemeData(
//         color: colorScheme.onPrimary,
//       ),
//       title: Text(
//         'BALL SORTING',
//         style: TextStyle(
//           fontSize: 20,
//           fontWeight: FontWeight.bold,
//           letterSpacing: 1.5,
//           color: colorScheme.onPrimary,
//           shadows: [
//             Shadow(
//               blurRadius: 4,
//               offset: const Offset(1, 1),
//               color: Colors.black.withOpacity(0.3),
//             ),
//           ],
//         ),
//       ),
//       centerTitle: true,
//       actions: [
//         if (gameStarted)
//           IconButton(
//             icon: Icon(Icons.info, color: colorScheme.onPrimary),
//             onPressed: _showGameInfo,
//           ),
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 8.0),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               if (gameStarted)
//                 Text('Score: $score', 
//                   style: TextStyle(color: colorScheme.onPrimary)),
//               if (gameStarted)
//                 const SizedBox(width: 8),
//               if (gameStarted)
//                 Text('Lives: $lives', 
//                   style: TextStyle(color: colorScheme.onPrimary)),
//               const SizedBox(width: 8),
//               Text('High: $highScore', 
//                 style: TextStyle(color: colorScheme.onPrimary)),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildGameContent(bool isDarkMode, ColorScheme colorScheme) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         return Stack(
//           children: [
//             if (!gameStarted) _buildStartScreen(isDarkMode, colorScheme),
//             if (gameOver) _buildGameOverScreen(isDarkMode, colorScheme),
//             if (gameStarted) ..._buildGameElements(constraints, isDarkMode, colorScheme),
//           ],
//         );
//       },
//     );
//   }

//  Widget _buildStartScreen(bool isDarkMode, ColorScheme colorScheme) {
//     return Center(
//       child: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               'Ball Sorting Game',
//               style: TextStyle(
//                 fontSize: 36, 
//                 fontWeight: FontWeight.bold,
//                 color: colorScheme.onBackground,
//               ),
//             ),
//             const SizedBox(height: 20),
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: colorScheme.surface.withOpacity(0.7),
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Column(
//                 children: [
//                   Text(
//                     'Match falling balls to box colors\nTap two boxes to swap colors',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontSize: 18,
//                       color: colorScheme.onSurface,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   Icon(Icons.sports_soccer, size: 100, color: colorScheme.primary),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 30),
//             ElevatedButton(
//               onPressed: startGame,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: colorScheme.primary,
//                 foregroundColor: colorScheme.onPrimary,
//                 padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//               child: Text('Start Game', style: TextStyle(fontSize: 24, color: colorScheme.onPrimary)),
//             ),
//             const SizedBox(height: 20),
//             TextButton(
//               onPressed: _showGameInfo,
//               child: Text(
//                 'How to Play',
//                 style: TextStyle(
//                   color: colorScheme.primary,
//                   fontSize: 16,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildGameOverScreen(bool isDarkMode, ColorScheme colorScheme) {
//     return Center(
//       child: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               'Game Over!',
//               style: TextStyle(
//                 fontSize: 48, 
//                 fontWeight: FontWeight.bold,
//                 color: colorScheme.onBackground,
//                 shadows: [
//                   Shadow(
//                     blurRadius: 8,
//                     color: isDarkMode
//                         ? Colors.black.withOpacity(0.8)
//                         : Colors.white.withOpacity(0.7),
//                     offset: const Offset(2, 2),
//                   )
//                 ],
//               ),
//             ),
//             const SizedBox(height: 20),
//             Container(
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: colorScheme.surface.withOpacity(0.8),
//                 borderRadius: BorderRadius.circular(20),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.2),
//                     blurRadius: 15,
//                     offset: const Offset(0, 5),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 children: [
//                   Text(
//                     'Score: $score',
//                     style: TextStyle(
//                       fontSize: 36,
//                       color: colorScheme.onSurface,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   Text(
//                     'High Score: ${score > highScore ? score : highScore}',
//                     style: TextStyle(
//                       fontSize: 24,
//                       color: colorScheme.onSurface,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       Column(
//                         children: [
//                           Icon(Icons.check_circle,
//                               color: Colors.greenAccent, size: 30),
//                           const SizedBox(height: 4),
//                           Text(
//                             '$ballsCaught',
//                             style: TextStyle(
//                               fontSize: 18,
//                               color: colorScheme.onSurface,
//                             ),
//                           ),
//                           Text(
//                             'Caught',
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: colorScheme.onSurface,
//                             ),
//                           ),
//                         ],
//                       ),
//                       Column(
//                         children: [
//                           Icon(Icons.cancel,
//                               color: Colors.redAccent, size: 30),
//                           const SizedBox(height: 4),
//                           Text(
//                             '$ballsMissed',
//                             style: TextStyle(
//                               fontSize: 18,
//                               color: colorScheme.onSurface,
//                             ),
//                           ),
//                           Text(
//                             'Missed',
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: colorScheme.onSurface,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 30),
//             ElevatedButton(
//               onPressed: startGame,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: colorScheme.primary,
//                 foregroundColor: colorScheme.onPrimary,
//                 padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 elevation: 8,
//                 shadowColor: Colors.black.withOpacity(0.3),
//               ),
//               child: Text(
//                 'Play Again',
//                 style: TextStyle(fontSize: 20, color: colorScheme.onPrimary),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   List<Widget> _buildGameElements(
//     BoxConstraints constraints, 
//     bool isDarkMode,
//     ColorScheme colorScheme,
//   ) {
//     return [
//       // Falling balls
//       ...fallingBalls.map((ball) => Positioned(
//         left: ball.x * constraints.maxWidth - ball.size/2,
//         top: ball.y * constraints.maxHeight - ball.size/2,
//         child: Container(
//           width: ball.size,
//           height: ball.size,
//           decoration: BoxDecoration(
//             color: ball.color,
//             shape: BoxShape.circle,
//             boxShadow: [
//               BoxShadow(
//                 color: ball.color.withOpacity(0.7),
//                 blurRadius: 10,
//                 spreadRadius: 2,
//               ),
//             ],
//           ),
//         ),
//       )),
      
//       // Boxes
//       ...List.generate(colors.length, (i) => Positioned(
//         left: (boxPositions[i] - boxWidths[i]/2) * constraints.maxWidth,
//         bottom: 20,
//         child: GestureDetector(
//           onTap: () => handleBoxTap(i),
//           child: Container(
//             width: boxWidths[i] * constraints.maxWidth,
//             height: 60,
//             decoration: BoxDecoration(
//               color: colors[i].withOpacity(selectedBoxIndex == i ? 0.9 : 0.6),
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(
//                 color: selectedBoxIndex == i 
//                     ? colorScheme.onPrimary 
//                     : colorScheme.onSurface.withOpacity(0.8),
//                 width: selectedBoxIndex == i ? 4 : 2,
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.3),
//                   blurRadius: 8,
//                   offset: const Offset(2, 4),
//                 ),
//               ],
//             ),
//             child: Stack(
//               children: [
//                 // Collected balls
//                 ...List.generate(boxes[i].length, (j) => Positioned(
//                   left: (j % 5) * 20.0,
//                   bottom: (j ~/ 5) * 20.0,
//                   child: Container(
//                     width: 16,
//                     height: 16,
//                     decoration: BoxDecoration(
//                       color: boxes[i][j].color,
//                       shape: BoxShape.circle,
//                       boxShadow: [
//                         BoxShadow(
//                           color: boxes[i][j].color.withOpacity(0.7),
//                           blurRadius: 4,
//                           spreadRadius: 1,
//                         ),
//                       ],
//                     ),
//                   ),
//                 )),
//                 if (boxes[i].length >= MAX_BALLS_PER_BOX)
//                   Positioned(
//                     top: -12,
//                     right: -12,
//                     child: Container(
//                       padding: const EdgeInsets.all(4),
//                       decoration: BoxDecoration(
//                         color: Colors.redAccent,
//                         shape: BoxShape.circle,
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.3),
//                             blurRadius: 4,
//                             offset: const Offset(1, 1),
//                           ),
//                         ],
//                       ),
//                       child: const Icon(Icons.warning, 
//                         color: Colors.white, size: 16),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ),
//       )),
//     ];
//   }

//   void _showGameInfo() {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;
    
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: colorScheme.surface,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(20),
//         ),
//         elevation: 10,
//         title: Text(
//           'How to Play',
//           style: TextStyle(
//             color: colorScheme.onSurface,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         content: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildInstructionStep(
//                 Icons.games, 
//                 "Match falling balls", 
//                 "Catch balls in boxes with matching colors",
//                 colorScheme
//               ),
//               const SizedBox(height: 12),
//               _buildInstructionStep(
//                 Icons.swap_horiz, 
//                 "Swap box colors", 
//                 "Tap two boxes to swap their colors",
//                 colorScheme
//               ),
//               const SizedBox(height: 12),
//               _buildInstructionStep(
//                 Icons.star, 
//                 "Fill boxes for points", 
//                 "Each correct match gives you points",
//                 colorScheme
//               ),
//               const SizedBox(height: 12),
//               _buildInstructionStep(
//                 Icons.favorite, 
//                 "Avoid mistakes", 
//                 "Wrong matches will cost you lives",
//                 colorScheme
//               ),
//               const SizedBox(height: 12),
//               _buildInstructionStep(
//                 Icons.speed, 
//                 "Game speeds up", 
//                 "The game gradually gets faster over time",
//                 colorScheme
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             style: TextButton.styleFrom(
//               foregroundColor: colorScheme.primary,
//             ),
//             child: const Text('Got it!'),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildInstructionStep(
//     IconData icon, 
//     String title, 
//     String description, 
//     ColorScheme colorScheme
//   ) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Container(
//           margin: const EdgeInsets.only(top: 4, right: 12),
//           child: Icon(icon, color: colorScheme.primary, size: 24),
//         ),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 title,
//                 style: TextStyle(
//                   color: colorScheme.onSurface,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16,
//                 ),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 description,
//                 style: TextStyle(
//                   color: colorScheme.onSurface.withOpacity(0.8),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }

// class Ball {
//   final Color color;
//   double x;
//   double y;
//   final double speed;
//   final double size;

//   Ball({
//     required this.color,
//     required this.x,
//     required this.y,
//     required this.speed,
//     required this.size,
//   });
// }


// import 'package:flutter/material.dart';
// import 'dart:math';
// import 'dart:async';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:confetti/confetti.dart';

// class BallSortingGame extends StatefulWidget {
//   const BallSortingGame({super.key});

//   @override
//   _BallSortingGameState createState() => _BallSortingGameState();
// }

// class _BallSortingGameState extends State<BallSortingGame> 
//     with SingleTickerProviderStateMixin {
//   // ========== Game Constants ==========
//   static const int MAX_LIVES = 5;
//   static const int MAX_BALLS_PER_BOX = 15;
//   static const int MAX_FALLING_BALLS = 20;
//   static const double BASE_BALL_SPEED = 0.5;
//   static const int BASE_SPAWN_INTERVAL = 2000;
//   static const List<Color> DEFAULT_COLORS = [
//     Colors.red,
//     Colors.blue,
//     Colors.green,
//     Colors.yellow,
//     Colors.purple,
//   ];
  
//   // ========== Game Variables ==========
//   late List<Color> colors;
//   final List<double> boxPositions = [0.1, 0.3, 0.5, 0.7, 0.9];
//   final List<double> boxWidths = [0.15, 0.15, 0.15, 0.15, 0.15];
//   final List<List<Ball>> boxes = [[], [], [], [], []];
//   final List<Ball> fallingBalls = [];
  
//   int? selectedBoxIndex;
//   int score = 0;
//   int highScore = 0;
//   int lives = MAX_LIVES;
//   bool gameOver = false;
//   bool gameStarted = false;
//   double currentBallSpeed = BASE_BALL_SPEED;
//   int ballSpawnInterval = BASE_SPAWN_INTERVAL;
//   int gameTime = 0;
//   int difficultyLevel = 1;
  
//   // ========== Effects & Audio ==========
//   late Timer ballSpawnTimer;
//   late Timer gameTimer;
//   late AnimationController animationController;
//   late AudioPlayer soundPlayer;
//   late AudioPlayer musicPlayer;
//   late ConfettiController confettiController;
//   final Random _random = Random();
  
//   // ========== Theme ==========
//   bool isDarkMode = true;
//   ThemeData get currentTheme => isDarkMode ? _darkTheme : _lightTheme;
  
//   static final ThemeData _lightTheme = ThemeData(
//     primarySwatch: Colors.blue,
//     brightness: Brightness.light,
//     scaffoldBackgroundColor: Colors.grey[200],
//     cardColor: Colors.white,
//   );
  
//   static final ThemeData _darkTheme = ThemeData(
//     primarySwatch: Colors.blue,
//     brightness: Brightness.dark,
//     scaffoldBackgroundColor: Colors.grey[900],
//     cardColor: Colors.grey[800],
//   );

//   @override
//   void initState() {
//     super.initState();
//     _initializeGame();
//   }

//   Future<void> _initializeGame() async {
//     colors = List.from(DEFAULT_COLORS);
//     animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 16),
//     )..addListener(_safeUpdateGame);
    
//     soundPlayer = AudioPlayer();
//     musicPlayer = AudioPlayer();
//     confettiController = ConfettiController(duration: const Duration(seconds: 2));
    
//     await _loadHighScore();
//     await _initializeAudio();
//   }

//   Future<void> _initializeAudio() async {
//     await soundPlayer.setVolume(0.7);
//     await musicPlayer.setVolume(0.3);
//   }

//   Future<void> _loadHighScore() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() => highScore = prefs.getInt('highScore') ?? 0);
//   }

//   Future<void> _saveHighScore() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setInt('highScore', highScore);
//   }

//   Future<void> _playSound(String asset) async {
//     await soundPlayer.play(AssetSource(asset));
//   }

//   void _toggleTheme() {
//     setState(() => isDarkMode = !isDarkMode);
//   }

//   // ========== Game Logic ==========
//   void resetGame() {
//     colors = List.from(DEFAULT_COLORS);
//     boxes.forEach((box) => box.clear());
//     fallingBalls.clear();
//     score = 0;
//     lives = MAX_LIVES;
//     gameOver = false;
//     currentBallSpeed = BASE_BALL_SPEED;
//     ballSpawnInterval = BASE_SPAWN_INTERVAL;
//     gameTime = 0;
//     selectedBoxIndex = null;
//     difficultyLevel = 1;
//   }

//   void startGame() {
//     resetGame();
//     setState(() => gameStarted = true);
    
//     _playSound('sounds/game_start.mp3');
//     _startBackgroundMusic();
    
//     animationController.reset();
//     animationController.repeat();
    
//     _startTimers();
//   }

//   void _startBackgroundMusic() async {
//     await musicPlayer.play(AssetSource('sounds/game_music.mp3'));
//     musicPlayer.setReleaseMode(ReleaseMode.loop);
//   }

//   void _startTimers() {
//     ballSpawnTimer = Timer.periodic(
//       Duration(milliseconds: ballSpawnInterval), 
//       (_) => spawnBall()
//     );
    
//     gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (!gameOver && mounted) {
//         setState(() {
//           gameTime++;
//           if (gameTime % 15 == 0) _increaseDifficulty();
//         });
//       }
//     });
//   }

//   void _increaseDifficulty() {
//     difficultyLevel++;
//     currentBallSpeed = BASE_BALL_SPEED * (1 + difficultyLevel / 10);
//     ballSpawnInterval = (BASE_SPAWN_INTERVAL / (1 + difficultyLevel / 5))
//         .clamp(500, BASE_SPAWN_INTERVAL).toInt();
    
//     ballSpawnTimer.cancel();
//     ballSpawnTimer = Timer.periodic(
//       Duration(milliseconds: ballSpawnInterval), 
//       (_) => spawnBall()
//     );
//   }

//   void spawnBall() {
//     if (!mounted || fallingBalls.length > MAX_FALLING_BALLS) return;
    
//     final color = colors[_random.nextInt(colors.length)];
//     final xPosition = boxPositions[_random.nextInt(boxPositions.length)];
    
//     setState(() {
//       fallingBalls.add(Ball(
//         color: color,
//         x: xPosition,
//         y: 0.0,
//         speed: currentBallSpeed,
//         size: 30.0 + _random.nextDouble() * 10.0,
//       ));
//     });
    
//     _playSound('sounds/ball_spawn.mp3');
//   }

//   void _safeUpdateGame() {
//     if (mounted) updateGame();
//   }

//   void updateGame() {
//     if (gameOver || !gameStarted || !mounted) return;

//     final speedFactor = currentBallSpeed / 60;
    
//     setState(() {
//       for (var ball in List.from(fallingBalls)) {
//         ball.y += speedFactor;
        
//         if (ball.y >= 0.8) {
//           _handleBallCollision(ball);
//           fallingBalls.remove(ball);
          
//           if (lives <= 0) {
//             gameOver = true;
//             endGame();
//           }
//         }
//       }
//     });
//   }

//   void _handleBallCollision(Ball ball) {
//     bool caught = false;
    
//     for (int i = 0; i < boxPositions.length; i++) {
//       if (ball.x >= boxPositions[i] - boxWidths[i]/2 && 
//           ball.x <= boxPositions[i] + boxWidths[i]/2) {
//         caught = true;
        
//         if (ball.color == colors[i]) {
//           if (boxes[i].length < MAX_BALLS_PER_BOX) {
//             boxes[i].add(ball);
//             _handleCorrectCatch(i);
//           } else {
//             _handlePenalty();
//           }
//         } else {
//           _handlePenalty();
//         }
//         break;
//       }
//     }
    
//     if (!caught) _handlePenalty();
//   }

//   void _handleCorrectCatch(int boxIndex) {
//     score += (10 * difficultyLevel).toInt();
//     _playSound('sounds/correct.mp3');
    
//     if (score > highScore) {
//       highScore = score;
//       _saveHighScore();
//       if (score > 100) { // Only show confetti after some score
//         confettiController.play();
//         _playSound('sounds/high_score.mp3');
//       }
//     }
//   }

//   void _handlePenalty() {
//     lives--;
//     _playSound('sounds/wrong.mp3');
//   }

//   void endGame() {
//     ballSpawnTimer.cancel();
//     gameTimer.cancel();
//     musicPlayer.stop();
//     animationController.stop();
//     _playSound('sounds/game_over.mp3');
//   }

//   void handleBoxTap(int boxIndex) {
//     if (gameOver || !gameStarted) return;
    
//     setState(() {
//       if (selectedBoxIndex == null) {
//         selectedBoxIndex = boxIndex;
//         _playSound('sounds/select.mp3');
//       } else if (selectedBoxIndex == boxIndex) {
//         selectedBoxIndex = null;
//       } else {
//         _swapBoxColors(boxIndex);
//         selectedBoxIndex = null;
//         score += 5; // Bonus for strategic swaps
//         _playSound('sounds/swap.mp3');
//       }
//     });
//   }

//   void _swapBoxColors(int boxIndex) {
//     final tempColor = colors[selectedBoxIndex!];
//     colors[selectedBoxIndex!] = colors[boxIndex];
//     colors[boxIndex] = tempColor;
//   }

//   @override
//   void dispose() {
//     ballSpawnTimer.cancel();
//     gameTimer.cancel();
//     animationController.dispose();
//     soundPlayer.dispose();
//     musicPlayer.dispose();
//     confettiController.dispose();
//     super.dispose();
//   }

//   // ========== UI Components ==========
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       theme: currentTheme,
//       debugShowCheckedModeBanner: false,
//       home: Scaffold(
//         appBar: _buildAppBar(),
//         body: Stack(
//           children: [
//             _buildGameContent(),
//             if (gameStarted && !gameOver) 
//               Align(
//                 alignment: Alignment.topCenter,
//                 child: ConfettiWidget(
//                   confettiController: confettiController,
//                   blastDirectionality: BlastDirectionality.explosive,
//                   colors: const [Colors.blue, Colors.green, Colors.red, Colors.yellow],
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   AppBar _buildAppBar() {
//     return AppBar(
//       title: const Text('🌈 Ball Sorting Game'),
//       actions: [
//         if (gameStarted) ...[
//           IconButton(
//             icon: const Icon(Icons.info),
//             onPressed: _showGameInfo,
//           ),
//           IconButton(
//             icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
//             onPressed: _toggleTheme,
//           ),
//         ],
//         Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               if (gameStarted) Text('Score: $score'),
//               if (gameStarted) Text('Lives: $lives'),
//               Text('High: $highScore'),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildGameContent() {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         return Stack(
//           children: [
//             if (!gameStarted) _buildStartScreen(),
//             if (gameOver) _buildGameOverScreen(),
//             if (gameStarted) ..._buildGameElements(constraints),
//           ],
//         );
//       },
//     );
//   }

//   Widget _buildStartScreen() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Text(
//             'Ball Sorting Game',
//             style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 20),
//           const Text(
//             'Match falling balls to box colors\nTap two boxes to swap colors',
//             textAlign: TextAlign.center,
//             style: TextStyle(fontSize: 18),
//           ),
//           const SizedBox(height: 30),
//          ElevatedButton(
//       onPressed: startGame,
//       child: const Text('Start Game', style: TextStyle(fontSize: 24)),
//     ),
//     const SizedBox(height: 20),
//     TextButton(
//       onPressed: _showGameInfo,
//       child: const Text('How to Play'),
//     ),
//         ],
//       ),
//     );
//   }

//   Widget _buildGameOverScreen() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Text(
//             'Game Over!',
//             style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
//           ),
//           Text(
//             'Score: $score',
//             style: const TextStyle(fontSize: 36),
//           ),
//           Text(
//             'High Score: ${score > highScore ? score : highScore}',
//             style: const TextStyle(fontSize: 24),
//           ),
//           const SizedBox(height: 20),
//           ElevatedButton(
//             onPressed: startGame,
//             child: const Text('Play Again'),
//           ),
//         ],
//       ),
//     );
//   }

//   List<Widget> _buildGameElements(BoxConstraints constraints) {
//     return [
//       // Falling balls
//       ...fallingBalls.map((ball) => Positioned(
//         left: ball.x * constraints.maxWidth - ball.size/2,
//         top: ball.y * constraints.maxHeight - ball.size/2,
//         child: Container(
//           width: ball.size,
//           height: ball.size,
//           decoration: BoxDecoration(
//             color: ball.color,
//             shape: BoxShape.circle,
//             boxShadow: [BoxShadow(
//               color: ball.color.withOpacity(0.7),
//               blurRadius: 10,
//               spreadRadius: 2,
//             )],
//           ),
//         ),
//       )),
      
//       // Boxes
//       ...List.generate(colors.length, (i) => Positioned(
//         left: (boxPositions[i] - boxWidths[i]/2) * constraints.maxWidth,
//         bottom: 20,
//         child: GestureDetector(
//           onTap: () => handleBoxTap(i),
//           child: Container(
//             width: boxWidths[i] * constraints.maxWidth,
//             height: 60,
//             decoration: BoxDecoration(
//               color: colors[i].withOpacity(selectedBoxIndex == i ? 0.8 : 0.5),
//               borderRadius: BorderRadius.circular(10),
//               border: Border.all(
//                 color: selectedBoxIndex == i ? Colors.white : colors[i],
//                 width: selectedBoxIndex == i ? 3 : 2,
//               ),
//             ),
//             child: Stack(
//               children: [
//                 // Collected balls
//                 ...List.generate(boxes[i].length, (j) => Positioned(
//                   left: (j % 5) * 20.0,
//                   bottom: (j ~/ 5) * 20.0,
//                   child: Container(
//                     width: 15,
//                     height: 15,
//                     decoration: BoxDecoration(
//                       color: boxes[i][j].color,
//                       shape: BoxShape.circle,
//                     ),
//                   ),
//                 )),
//                 if (boxes[i].length >= MAX_BALLS_PER_BOX)
//                   const Positioned(
//                     top: -10,
//                     right: -10,
//                     child: Icon(Icons.warning, color: Colors.red),
//                   ),
//               ],
//             ),
//           ),
//         ),
//       )),
//     ];
//   }

//   void _showGameInfo() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('How to Play'),
//         content: SingleChildScrollView(
//           child: Column(
//             children: const [
//               Text('• Match falling balls to box colors'),
//               Text('• Tap two boxes to swap their colors'),
//               Text('• Fill boxes with matching balls for points'),
//               Text('• Wrong matches lose lives'),
//               Text('• Game gets faster over time!'),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class Ball {
//   final Color color;
//   double x;
//   double y;
//   final double speed;
//   final double size;

//   Ball({
//     required this.color,
//     required this.x,
//     required this.y,
//     required this.speed,
//     required this.size,
//   });
// }
