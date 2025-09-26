import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

class ColorClashDuel extends StatefulWidget {
  const ColorClashDuel({super.key});

  @override
  _ColorClashDuelState createState() => _ColorClashDuelState();
}

class _ColorClashDuelState extends State<ColorClashDuel> 
    with SingleTickerProviderStateMixin {
  // ========== Game Constants ==========
  static const int MAX_LIVES = 3;
  static const int MAX_SHAPES = 10;
  static const double BASE_SPEED = 0.4;
  static const int BASE_SPAWN_INTERVAL = 1500;
  static const List<Color> PLAYER_COLORS = [
    Colors.blueAccent,
    Colors.redAccent,
  ];
  static const List<Color> SHAPE_COLORS = [
    Colors.blueAccent,
    Colors.redAccent,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
  ];
  static const List<String> SHAPE_TYPES = ['circle', 'square', 'triangle'];
  
  // ========== Game Variables ==========
  late List<List<FallingShape>> playerShapes;
  late List<int> scores;
  late List<int> lives;
  late List<int> powerUps;
  late List<bool> isStunned;
  late List<double> playerSpeeds;
  
  bool gameOver = false;
  bool gameStarted = false;
  int gameTime = 0;
  int difficultyLevel = 1;
  int spawnInterval = BASE_SPAWN_INTERVAL;
  
  // ========== Game Elements ==========
  final List<FallingShape> fallingShapes = [];
  final List<PowerUp> activePowerUps = [];
  final Random _random = Random();
  
  // ========== Game Controllers ==========
  late Timer spawnTimer;
  late Timer gameTimer;
  late AnimationController animationController;
  late AudioPlayer soundPlayer;
  late AudioPlayer musicPlayer;
  
  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    playerShapes = List.generate(2, (_) => []);
    scores = List.generate(2, (_) => 0);
    lives = List.generate(2, (_) => MAX_LIVES);
    powerUps = List.generate(2, (_) => 0);
    isStunned = List.generate(2, (_) => false);
    playerSpeeds = List.generate(2, (_) => BASE_SPEED);
    
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updateGame);
    
    soundPlayer = AudioPlayer();
    musicPlayer = AudioPlayer();
  }

  void resetGame() {
    playerShapes = List.generate(2, (_) => []);
    scores = List.generate(2, (_) => 0);
    lives = List.generate(2, (_) => MAX_LIVES);
    powerUps = List.generate(2, (_) => 0);
    isStunned = List.generate(2, (_) => false);
    playerSpeeds = List.generate(2, (_) => BASE_SPEED);
    
    fallingShapes.clear();
    activePowerUps.clear();
    gameOver = false;
    gameTime = 0;
    difficultyLevel = 1;
    spawnInterval = BASE_SPAWN_INTERVAL;
  }

  void startGame() {
    resetGame();
    setState(() => gameStarted = true);
    
    _playSound('sounds/game_start.mp3');
    _startBackgroundMusic();
    
    animationController.reset();
    animationController.repeat();
    
    spawnTimer = Timer.periodic(
      Duration(milliseconds: spawnInterval), 
      (_) => spawnShape()
    );
    
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!gameOver && mounted) {
        setState(() {
          gameTime++;
          if (gameTime % 30 == 0) _increaseDifficulty();
          if (_random.nextDouble() < 0.1) spawnPowerUp();
        });
      }
    });
  }

  void _increaseDifficulty() {
    difficultyLevel++;
    spawnInterval = (BASE_SPAWN_INTERVAL / (1 + difficultyLevel / 10))
        .clamp(800, BASE_SPAWN_INTERVAL).toInt();
    
    spawnTimer.cancel();
    spawnTimer = Timer.periodic(
      Duration(milliseconds: spawnInterval), 
      (_) => spawnShape()
    );
    
    _showDifficultyNotification();
  }

  void spawnShape() {
    if (!mounted || fallingShapes.length > MAX_SHAPES * 2) return;
    
    final color = SHAPE_COLORS[_random.nextInt(SHAPE_COLORS.length)];
    final type = SHAPE_TYPES[_random.nextInt(SHAPE_TYPES.length)];
    final xPosition = 0.1 + _random.nextDouble() * 0.8;
    
    setState(() {
      fallingShapes.add(FallingShape(
        color: color,
        type: type,
        x: xPosition,
        y: 0.0,
        speed: BASE_SPEED * (1 + difficultyLevel / 15),
        size: 30.0 + _random.nextDouble() * 15.0,
      ));
    });
    
    _playSound('sounds/shape_spawn.mp3');
  }

  void spawnPowerUp() {
    final powerUpTypes = ['speed', 'stun', 'clear'];
    final type = powerUpTypes[_random.nextInt(powerUpTypes.length)];
    final xPosition = 0.1 + _random.nextDouble() * 0.8;
    
    setState(() {
      activePowerUps.add(PowerUp(
        type: type,
        x: xPosition,
        y: 0.0,
        speed: BASE_SPEED * 0.7,
        size: 40.0,
      ));
    });
  }

  void _updateGame() {
    if (gameOver || !gameStarted || !mounted) return;

    final double deltaTime = animationController.duration != null
        ? animationController.duration!.inMilliseconds / 1000.0
        : 0.016;

    setState(() {
      // Update falling shapes
      for (var shape in List.from(fallingShapes)) {
        shape.y += shape.speed * deltaTime;

        // Check if shape reached bottom
        if (shape.y >= 0.9) {
          _handleMissedShape(shape);
          fallingShapes.remove(shape);
        }
      }
      
      // Update power-ups
      for (var powerUp in List.from(activePowerUps)) {
        powerUp.y += powerUp.speed * deltaTime;
        
        if (powerUp.y >= 1.0) {
          activePowerUps.remove(powerUp);
        }
      }
      
      // Check game over condition
      if (lives.any((life) => life <= 0)) {
        gameOver = true;
        endGame();
      }
    });
  }

  void _handleMissedShape(FallingShape shape) {
    // When a shape reaches bottom without being caught
    _playSound('sounds/missed.mp3');
  }

  void handlePlayerTap(int playerIndex, double tapX) {
    if (gameOver || !gameStarted || isStunned[playerIndex]) return;
    
    // Check if caught any shapes
    for (var shape in List.from(fallingShapes)) {
      if (shape.x >= tapX - 0.1 && shape.x <= tapX + 0.1) {
        if (shape.color == PLAYER_COLORS[playerIndex]) {
          // Correct catch
          _handleCorrectCatch(playerIndex, shape);
        } else {
          // Wrong catch
          _handleWrongCatch(playerIndex);
        }
        fallingShapes.remove(shape);
        break;
      }
    }
    
    // Check if caught any power-ups
    for (var powerUp in List.from(activePowerUps)) {
      if (powerUp.x >= tapX - 0.1 && powerUp.x <= tapX + 0.1) {
        _activatePowerUp(playerIndex, powerUp.type);
        activePowerUps.remove(powerUp);
        break;
      }
    }
  }

  void _handleCorrectCatch(int playerIndex, FallingShape shape) {
    setState(() {
      scores[playerIndex] += 10 * difficultyLevel;
      playerShapes[playerIndex].add(shape);
      _playSound('sounds/correct.mp3');
      
      // Special bonus for matching shape type
      if (shape.type == 'triangle') {
        powerUps[playerIndex] = (powerUps[playerIndex] + 1).clamp(0, 3);
      }
      
      // Check for life bonus
      if (scores[playerIndex] % 500 == 0 && lives[playerIndex] < MAX_LIVES) {
        lives[playerIndex]++;
        _showLifeBonus(playerIndex);
      }
    });
  }

  void _handleWrongCatch(int playerIndex) {
    setState(() {
      lives[playerIndex]--;
      _playSound('sounds/wrong.mp3');
      
      if (lives[playerIndex] > 0) {
        _showPenalty(playerIndex);
      }
    });
  }

  void _activatePowerUp(int playerIndex, String type) {
    setState(() {
      _playSound('sounds/powerup.mp3');
      
      switch (type) {
        case 'speed':
          playerSpeeds[playerIndex] = BASE_SPEED * 1.5;
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) {
              setState(() => playerSpeeds[playerIndex] = BASE_SPEED);
            }
          });
          break;
          
        case 'stun':
          final opponent = (playerIndex + 1) % 2;
          isStunned[opponent] = true;
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() => isStunned[opponent] = false);
            }
          });
          break;
          
        case 'clear':
          fallingShapes.clear();
          break;
      }
      
      _showPowerUpEffect(playerIndex, type);
    });
  }

  void endGame() {
    spawnTimer.cancel();
    gameTimer.cancel();
    musicPlayer.stop();
    animationController.stop();
    _playSound('sounds/game_over.mp3');
  }

  Future<void> _playSound(String asset) async {
    await soundPlayer.play(AssetSource(asset));
  }

  Future<void> _startBackgroundMusic() async {
    await musicPlayer.play(AssetSource('sounds/game_music.mp3'));
    musicPlayer.setReleaseMode(ReleaseMode.loop);
  }

  void _showDifficultyNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Level $difficultyLevel!'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showLifeBonus(int playerIndex) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Player ${playerIndex + 1} gained a life!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showPenalty(int playerIndex) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Player ${playerIndex + 1} lost a life!'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showPowerUpEffect(int playerIndex, String type) {
    String message = '';
    Color color = Colors.blue;
    
    switch (type) {
      case 'speed':
        message = 'Player ${playerIndex + 1} got SPEED BOOST!';
        color = Colors.orange;
        break;
      case 'stun':
        message = 'Player ${playerIndex + 1} STUNNED opponent!';
        color = Colors.purple;
        break;
      case 'clear':
        message = 'Player ${playerIndex + 1} CLEARED the board!';
        color = Colors.green;
        break;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    spawnTimer.cancel();
    gameTimer.cancel();
    animationController.dispose();
    soundPlayer.dispose();
    musicPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Color Clash Duel'),
        centerTitle: true,
        actions: [
          if (gameStarted) Text('Level: $difficultyLevel'),
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: _showGameInfo,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primaryContainer.withOpacity(0.7),
              colorScheme.secondaryContainer.withOpacity(0.7),
            ],
          ),
        ),
        child: Stack(
          children: [
            if (!gameStarted) _buildStartScreen(),
            if (gameOver) _buildGameOverScreen(),
            if (gameStarted) ..._buildGameElements(screenWidth, screenHeight),
          ],
        ),
      ),
    );
  }

  Widget _buildStartScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'COLOR CLASH DUEL',
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Text(
            'A 2-Player Competitive Game',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: startGame,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            ),
            child: const Text('START GAME', style: TextStyle(fontSize: 24)),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: _showGameInfo,
            child: const Text('How to Play'),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverScreen() {
    final winner = scores[0] > scores[1] ? 1 : 2;
    final isTie = scores[0] == scores[1];
    
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isTie ? 'DRAW!' : 'PLAYER $winner WINS!',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Text('Player 1', style: TextStyle(color: Colors.blue)),
                    Text('${scores[0]}', style: const TextStyle(fontSize: 24)),
                  ],
                ),
                Column(
                  children: [
                    const Text('Player 2', style: TextStyle(color: Colors.red)),
                    Text('${scores[1]}', style: const TextStyle(fontSize: 24)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: startGame,
              child: const Text('PLAY AGAIN'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGameElements(double width, double height) {
    return [
      // Player 1 area (top half)
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: height * 0.5,
        child: GestureDetector(
          onTapDown: (details) {
            final tapX = details.localPosition.dx / width;
            handlePlayerTap(0, tapX);
          },
          child: Container(
            color: Colors.blue.withOpacity(0.1),
            child: Column(
              children: [
                _buildPlayerHeader(0),
                Expanded(
                  child: Stack(
                    children: [
                      // Falling shapes (only in player's area)
                      ...fallingShapes.where((s) => s.y < 0.5).map((shape) => 
                        _buildFallingShape(shape, width, height * 0.5)),
                      
                      // Power-ups
                      ...activePowerUps.where((p) => p.y < 0.5).map((powerUp) => 
                        _buildPowerUp(powerUp, width, height * 0.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      
      // Player 2 area (bottom half)
      Positioned(
        top: height * 0.5,
        left: 0,
        right: 0,
        height: height * 0.5,
        child: GestureDetector(
          onTapDown: (details) {
            final tapX = details.localPosition.dx / width;
            handlePlayerTap(1, tapX);
          },
          child: Container(
            color: Colors.red.withOpacity(0.1),
            child: Column(
              children: [
                _buildPlayerHeader(1),
                Expanded(
                  child: Stack(
                    children: [
                      // Falling shapes (only in player's area)
                      ...fallingShapes.where((s) => s.y >= 0.5).map((shape) => 
                        _buildFallingShape(shape, width, height * 0.5)),
                      
                      // Power-ups
                      ...activePowerUps.where((p) => p.y >= 0.5).map((powerUp) => 
                        _buildPowerUp(powerUp, width, height * 0.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      
      // Divider line
      Positioned(
        top: height * 0.5 - 2,
        left: 0,
        right: 0,
        child: Container(
          height: 4,
          color: Colors.black.withOpacity(0.5),
        ),
      ),
    ];
  }

  Widget _buildPlayerHeader(int playerIndex) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: PLAYER_COLORS[playerIndex].withOpacity(0.3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Player ${playerIndex + 1}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: PLAYER_COLORS[playerIndex],
            ),
          ),
          Row(
            children: [
              Text(
                'Score: ${scores[playerIndex]}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 10),
              Text(
                'Lives: ${lives[playerIndex]}',
                style: const TextStyle(fontSize: 16),
              ),
              if (isStunned[playerIndex]) 
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.block, color: Colors.red),
                ),
              if (powerUps[playerIndex] > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    '${powerUps[playerIndex]}x',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFallingShape(FallingShape shape, double width, double height) {
    return Positioned(
      left: shape.x * width - shape.size / 2,
      top: (shape.y % 0.5) * height - shape.size / 2,
      child: Container(
        width: shape.size,
        height: shape.size,
        decoration: BoxDecoration(
          color: shape.color,
          shape: shape.type == 'circle' ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: shape.type == 'square' 
              ? BorderRadius.circular(8) 
              : null,
        ),
        child: shape.type == 'triangle'
            ? CustomPaint(
                painter: TrianglePainter(color: shape.color),
              )
            : null,
      ),
    );
  }

  Widget _buildPowerUp(PowerUp powerUp, double width, double height) {
    IconData icon;
    Color color;
    
    switch (powerUp.type) {
      case 'speed':
        icon = Icons.bolt;
        color = Colors.orange;
        break;
      case 'stun':
        icon = Icons.block;
        color = Colors.purple;
        break;
      case 'clear':
        icon = Icons.clear_all;
        color = Colors.green;
        break;
      default:
        icon = Icons.star;
        color = Colors.yellow;
    }
    
    return Positioned(
      left: powerUp.x * width - powerUp.size / 2,
      top: (powerUp.y % 0.5) * height - powerUp.size / 2,
      child: Container(
        width: powerUp.size,
        height: powerUp.size,
        decoration: BoxDecoration(
          color: color.withOpacity(0.8),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: powerUp.size * 0.6),
      ),
    );
  }

  void _showGameInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Play'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('🏆 COMPETE AGAINST A FRIEND', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Each player controls half of the screen'),
              SizedBox(height: 16),
              Text('🎯 MATCH THE SHAPES', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Tap shapes that match your color (blue for Player 1, red for Player 2)'),
              SizedBox(height: 16),
              Text('⚡ COLLECT POWER-UPS', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Speed Boost: Move faster for 5 seconds'),
              Text('Stun: Freeze your opponent for 3 seconds'),
              Text('Clear: Remove all shapes from the board'),
              SizedBox(height: 16),
              Text('💔 AVOID MISTAKES', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Wrong matches cost you lives!'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}

class FallingShape {
  final Color color;
  final String type;
  double x;
  double y;
  final double speed;
  final double size;

  FallingShape({
    required this.color,
    required this.type,
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
  });
}

class PowerUp {
  final String type;
  double x;
  double y;
  final double speed;
  final double size;

  PowerUp({
    required this.type,
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
  });
}

class TrianglePainter extends CustomPainter {
  final Color color;
  
  TrianglePainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}