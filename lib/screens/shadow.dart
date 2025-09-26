
// enum GameState { notStarted, playing, paused, gameOver }
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../controllers/settings_controller.dart';

class ColorConfusionGame extends StatefulWidget {
  const ColorConfusionGame({super.key});

  @override
  State<ColorConfusionGame> createState() => _ColorConfusionGameState();
}

class _ColorConfusionGameState extends State<ColorConfusionGame>
    with TickerProviderStateMixin {
  // Game Constants
  static const _kInitialTime = 3.0;
  static const _kMinTime = 0.5;
  static const _kTimeDecreaseFactor = 0.9;
  static const _kBaseScore = 10;
  static const _kLevelUpThreshold = 50;
  static const _kTimerInterval = Duration(milliseconds: 100);
  static const _kButtonPadding = EdgeInsets.symmetric(
    vertical: 16,
    horizontal: 24,
  );
  static const _kCardRadius = 20.0;
  static const _kButtonRadius = 16.0;

  // Game State
  GameState _gameState = GameState.notStarted;
  int _score = 0;
  int _highScore = 0;
  int _level = 1;
  double _timeLeft = _kInitialTime;
  double _timerSpeed = _kInitialTime;
  bool _hasPlayedCongrats = false;

  // Current Challenge
  String _currentColorName = "";
  Color _currentTextColor = Colors.black;
  List<Color> _buttonColors = [];
  List<String> _colorNames = [];

  // Effects
  late final ConfettiController _confettiController;
  late final AudioPlayer _audioPlayer;
  late final AudioPlayer _backgroundMusicPlayer;
  late final AnimationController _scaleController;
  late AnimationController _animationController;
  Timer? _gameTimer;

  static const _colors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.pink,
    Colors.teal,
    Colors.brown,
    Colors.indigo,
    Colors.cyan,
    Colors.lime,
    Colors.amber,
    Colors.grey,
  ];
  
  static const _colorOptions = [
    "RED",
    "BLUE",
    "GREEN",
    "YELLOW",
    "PURPLE",
    "ORANGE",
    "PINK",
    "TEAL",
    "BROWN",
    "INDIGO",
    "CYAN",
    "LIME",
    "AMBER",
    "GREY",
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );
    _audioPlayer = AudioPlayer();
    _backgroundMusicPlayer = AudioPlayer();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadHighScore();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _audioPlayer.dispose();
    _backgroundMusicPlayer.dispose();
    _animationController.dispose();
    _scaleController.dispose();
    _gameTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _highScore = prefs.getInt('highScore') ?? 0);
  }

  Future<void> _saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('highScore', _highScore);
  }

  Future<void> _playSound(String asset) async {
    final settings = Provider.of<SettingsController>(context, listen: false);
    
    // Only play sound if sound effects are enabled
    if (!settings.soundEffects) return;
    
    try {
      await _audioPlayer.setVolume(settings.volumeLevel);
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/$asset'));
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  Future<void> _playBackgroundMusic() async {
    final settings = Provider.of<SettingsController>(context, listen: false);
    
    // Only play music if sound effects are enabled
    if (!settings.soundEffects) return;
    
    try {
      await _backgroundMusicPlayer.setVolume(settings.volumeLevel * 0.5); // Background music at half volume
      await _backgroundMusicPlayer.play(AssetSource('sounds/game_music.mp3'));
    } catch (e) {
      debugPrint('Error playing background music: $e');
    }
  }

  void _startGame() {
    _gameTimer?.cancel();

    setState(() {
      _gameState = GameState.playing;
      _score = 0;
      _level = 1;
      _timeLeft = _kInitialTime;
      _timerSpeed = _kInitialTime;
      _hasPlayedCongrats = false;
    });

    _playSound('game_start.mp3');
    _playBackgroundMusic();
    _generateNewChallenge();
    _startTimer();
  }

  void _startTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(_kTimerInterval, (timer) {
      if (_gameState != GameState.playing) return;

      setState(() {
        _timeLeft -= 0.1;
        if (_timeLeft <= 0) {
          _timeLeft = 0;
          _endGame();
        }
      });
    });
  }

  void _generateNewChallenge() {
    if (_gameState != GameState.playing) return;

    final random = Random();

    setState(() {
      _timeLeft = _timerSpeed;
    });

    final correctColorName = _colorOptions[random.nextInt(_colorOptions.length)];

    Color textColor;
    do {
      textColor = _colors[random.nextInt(_colors.length)];
    } while (textColor == _colorNameToColor(correctColorName));

    final buttonColors = <Color>[];
    final colorNames = <String>[];

    buttonColors.add(_colorNameToColor(correctColorName));
    colorNames.add(correctColorName);

    while (buttonColors.length < 4) {
      final wrongColorName = _colorOptions[random.nextInt(_colorOptions.length)];
      if (wrongColorName != correctColorName && !colorNames.contains(wrongColorName)) {
        buttonColors.add(_colorNameToColor(wrongColorName));
        colorNames.add(wrongColorName);
      }
    }

    buttonColors.shuffle();
    colorNames.shuffle();

    setState(() {
      _currentColorName = correctColorName;
      _currentTextColor = textColor;
      _buttonColors = buttonColors;
      _colorNames = colorNames;
    });

    _scaleController.forward(from: 0);
  }

  Color _colorNameToColor(String name) {
    switch (name.toUpperCase()) {
      case "RED": return Colors.red;
      case "BLUE": return Colors.blue;
      case "GREEN": return Colors.green;
      case "YELLOW": return Colors.yellow;
      case "PURPLE": return Colors.purple;
      case "ORANGE": return Colors.orange;
      case "PINK": return Colors.pink;
      case "TEAL": return Colors.teal;
      case "BROWN": return Colors.brown;
      case "INDIGO": return Colors.indigo;
      case "CYAN": return Colors.cyan;
      case "LIME": return Colors.lime;
      case "AMBER": return Colors.amber;
      case "GREY": return Colors.grey;
      default: return Colors.black;
    }
  }

  Color _getContrastColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  void _checkAnswer(String selectedColorName) {
    if (_gameState != GameState.playing) return;

    if (selectedColorName == _currentColorName) {
      _correctAnswer();
    } else {
      _endGame();
    }
  }

  void _correctAnswer() {
    final wasHighScore = _score <= _highScore;
    final isNewHighScore = _score + (_kBaseScore * _level) > _highScore;

    _playSound('success.mp3');

    setState(() {
      _score += _kBaseScore * _level;
      if (_score > _highScore) {
        _highScore = _score;
        _saveHighScore();
        if (wasHighScore && isNewHighScore && !_hasPlayedCongrats) {
          _playSound('congrats.mp3');
          _confettiController.play();
          _hasPlayedCongrats = true;
        }
      }
      if (_score % _kLevelUpThreshold == 0) {
        _level++;
        _timerSpeed = (_timerSpeed * _kTimeDecreaseFactor).clamp(
          _kMinTime,
          _kInitialTime,
        );
      }
    });

    _gameTimer?.cancel();
    _generateNewChallenge();
    _startTimer();
  }

  void _endGame() {
    if (_gameState != GameState.playing) return;

    _playSound('fail.mp3');
    _backgroundMusicPlayer.stop();
    setState(() {
      _gameState = GameState.gameOver;
      _timeLeft = 0;
    });
    _gameTimer?.cancel();
  }

  void _togglePause() {
    if (_gameState != GameState.playing && _gameState != GameState.paused) return;

    setState(() {
      _gameState = _gameState == GameState.playing 
          ? GameState.paused 
          : GameState.playing;
    });

    if (_gameState == GameState.paused) {
      _backgroundMusicPlayer.pause();
      _playSound('pause.mp3');
    } else {
      _backgroundMusicPlayer.resume();
      _playSound('resume.mp3');
    }
  }

  Widget _buildGameButton(int index) {
    final theme = Theme.of(context);
    final textColor = _getContrastColor(_buttonColors[index]);

    return Padding(
      padding: const EdgeInsets.all(8),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.95, end: 1.0).animate(
          CurvedAnimation(
            parent: _scaleController,
            curve: Interval(
              0.1 * index,
              0.1 * (index + 1),
              curve: Curves.easeOut,
            ),
          ),
        ),
        child: Material(
          color: _buttonColors[index],
          borderRadius: BorderRadius.circular(_kButtonRadius),
          elevation: 4,
          child: InkWell(
            borderRadius: BorderRadius.circular(_kButtonRadius),
            onTap: () => _checkAnswer(_colorNames[index]),
            splashColor: Colors.white.withOpacity(0.3),
            highlightColor: Colors.white.withOpacity(0.2),
            child: Container(
              width: double.infinity,
              padding: _kButtonPadding,
              child: Center(
                child: Text(
                  _colorNames[index],
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 4,
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverScreen() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final isNewRecord = _score == _highScore && _score > 0;

    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final cardColor = isDarkMode ? Colors.grey[900] : Colors.grey[100];
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode ? Colors.white70 : Colors.grey[700];
    final accentColor = isDarkMode ? const Color.fromARGB(255, 22, 114, 93) : const Color.fromARGB(255, 0, 0, 0);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "GAME OVER",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDarkMode ? Colors.white12 : Colors.black12,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      "Your Score",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "$_score",
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Divider(thickness: 1, color: Colors.grey),
                    const SizedBox(height: 10),
                    Text(
                      "High Score: $_highScore",
                      style: TextStyle(
                        fontSize: 16,
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Level Reached: $_level",
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryTextColor,
                      ),
                    ),
                    if (isNewRecord) ...[
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.star, color: Colors.amber, size: 28),
                          SizedBox(width: 8),
                          Text(
                            "New High Score!",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    "PLAY AGAIN",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 255, 255, 255),
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameScreen() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildScoreCard("Level", "$_level", Icons.star),
                _buildScoreCard("Score", "$_score", Icons.leaderboard),
              ],
            ),
            const SizedBox(height: 40),
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_kCardRadius),
              ),
              color: theme.cardColor,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      "Click the button where the text is:",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.textTheme.bodyLarge?.color?.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FittedBox(
                      child: Text(
                        _currentColorName,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _colorNameToColor(_currentColorName),
                          shadows: [
                            Shadow(
                              blurRadius: 8,
                              color: _colorNameToColor(_currentColorName).withOpacity(0.5),
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    LinearProgressIndicator(
                      value: _timeLeft / _timerSpeed,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _timeLeft > _timerSpeed * 0.3
                            ? Colors.green
                            : _timeLeft > _timerSpeed * 0.1
                                ? Colors.orange
                                : Colors.red,
                      ),
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Time: ${_timeLeft.toStringAsFixed(1)}s",
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              padding: const EdgeInsets.all(8),
              children: List.generate(4, (index) => _buildGameButton(index)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartScreen(AnimationController controller) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final primaryColor = isDarkMode ? Colors.lightBlueAccent : const Color.fromARGB(255, 0, 0, 0);
    final bgColor = isDarkMode ? Colors.black : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Color Clash",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 12),

              Text(
                "Match the text color, not the word!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 40),

              ScaleTransition(
                scale: Tween(begin: 0.98, end: 1.0).animate(
                  CurvedAnimation(
                    parent: controller,
                    curve: Curves.easeInOut,
                  ),
                ),
                child: ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    "START GAME",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              OutlinedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => _buildTutorialDialog(),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: BorderSide(color: primaryColor, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "How to Play",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard(String title, String value, IconData icon) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_kButtonRadius),
      ),
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 24),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPauseOverlay() {
    final theme = Theme.of(context);

    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "PAUSED",
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: _togglePause,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_kButtonRadius),
                  ),
                  elevation: 8,
                ),
                child: Text(
                  "RESUME",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialDialog() {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_kCardRadius),
      ),
      elevation: 12,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'How to Play',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _buildMiniTutorialStep(
                icon: Icons.color_lens,
                color: Colors.deepPurple,
                title: "Match the Text Color",
                description: "Tap the button whose **TEXT COLOR** matches the color name.",
              ),
              _buildMiniTutorialStep(
                icon: Icons.timer,
                color: Colors.teal,
                title: "Be Quick!",
                description: "React before time runs out. It speeds up at higher levels!",
              ),
              _buildMiniTutorialStep(
                icon: Icons.star,
                color: Colors.orange,
                title: "Score Points",
                description: "Higher levels give more points. Beat your high score!",
              ),
              _buildMiniTutorialStep(
                icon: Icons.music_note,
                color: Colors.blueGrey,
                title: "Sound & Music",
                description: "Toggle sound/music in the settings menu.",
              ),
              const SizedBox(height: 24),

              Center(
                child: SizedBox(
                  width: 150,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_kButtonRadius),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      'Got it',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onPrimary,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniTutorialStep({
    required IconData icon,
    required String title,
    required String description,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: color ?? Colors.grey,
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Colors.black, Colors.grey.shade900]
              : [Color(0xFFECEFF1), Color(0xFFCFD8DC)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Color Clash',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          backgroundColor: isDark ? Colors.grey.shade900.withOpacity(0.95) : Colors.white.withOpacity(0.9),
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back,
                color: isDark ? Colors.white : Colors.black87, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            if (_gameState == GameState.playing || _gameState == GameState.paused)
              IconButton(
                icon: Icon(
                  _gameState == GameState.paused ? Icons.play_arrow : Icons.pause,
                  color: isDark ? Colors.white : Colors.black87,
                  size: 28,
                ),
                onPressed: _togglePause,
              ),
            IconButton(
              icon: Icon(Icons.help_outline,
                  color: isDark ? Colors.white : Colors.black87, size: 28),
              onPressed: () => showDialog(
                context: context,
                builder: (context) => _buildTutorialDialog(),
              ),
            ),
          ],
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
        ),
        body: Stack(
          children: [
            switch (_gameState) {
              GameState.notStarted => _buildStartScreen(_animationController),
              GameState.playing => _buildGameScreen(),
              GameState.paused => _buildGameScreen(),
              GameState.gameOver => _buildGameOverScreen(),
            },
            if (_gameState == GameState.paused) _buildPauseOverlay(),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                colors: const [
                  Color(0xFF42A5F5),
                  Color(0xFF66BB6A),
                  Color(0xFFFFA726),
                  Color(0xFFAB47BC),
                ],
                createParticlePath: (size) {
                  final path = Path();
                  path.addOval(
                    Rect.fromCircle(center: Offset.zero, radius: size.width / 2),
                  );
                  return path;
                },
                emissionFrequency: 0.05,
                numberOfParticles: 20,
                gravity: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum GameState { notStarted, playing, paused, gameOver }









// // enum GameState { notStarted, playing, paused, gameOver }
// import 'dart:math';
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:confetti/confetti.dart';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:provider/provider.dart';
// import '../controllers/settings_controller.dart';

// class ColorConfusionGame extends StatefulWidget {
//   const ColorConfusionGame({super.key});

//   @override
//   State<ColorConfusionGame> createState() => _ColorConfusionGameState();
// }

// class _ColorConfusionGameState extends State<ColorConfusionGame>
//     with TickerProviderStateMixin {
//   // Game Constants
//   static const _kInitialTime = 3.0;
//   static const _kMinTime = 0.5;
//   static const _kTimeDecreaseFactor = 0.9;
//   static const _kBaseScore = 10;
//   static const _kLevelUpThreshold = 50;
//   static const _kTimerInterval = Duration(milliseconds: 100);
//   static const _kButtonPadding = EdgeInsets.symmetric(
//     vertical: 16,
//     horizontal: 24,
//   );
//   static const _kCardRadius = 20.0;
//   static const _kButtonRadius = 16.0;

//   // Game State
//   GameState _gameState = GameState.notStarted;
//   int _score = 0;
//   int _highScore = 0;
//   int _level = 1;
//   double _timeLeft = _kInitialTime;
//   double _timerSpeed = _kInitialTime;
//   bool _hasPlayedCongrats = false;

//   // Current Challenge
//   String _currentColorName = "";
//   Color _currentTextColor = Colors.black;
//   List<Color> _buttonColors = [];
//   List<String> _colorNames = [];

//   // Effects
//   late final ConfettiController _confettiController;
//   late final AudioPlayer _audioPlayer;
//   late final AudioPlayer _backgroundMusicPlayer;
//   late final AnimationController _scaleController;
//   late AnimationController _animationController;
//   Timer? _gameTimer;

  
// static const _colors = [
//   Colors.red,
//   Colors.blue,
//   Colors.green,
//   Colors.yellow,
//   Colors.purple,
//   Colors.orange,
//   Colors.pink,
//   Colors.teal,
//   Colors.brown,
//   Colors.indigo,
//   Colors.cyan,
//   Colors.lime,
//   Colors.amber,
//   Colors.grey,
// ];
// static const _colorOptions = [
//   "RED",
//   "BLUE",
//   "GREEN",
//   "YELLOW",
//   "PURPLE",
//   "ORANGE",
//   "PINK",
//   "TEAL",
//   "BROWN",
//   "INDIGO",
//   "CYAN",
//   "LIME",
//   "AMBER",
//   "GREY",
// ];


//   @override
//   void initState() {
//     super.initState();
//      _animationController = AnimationController(
//     vsync: this,
//     duration: Duration(milliseconds: 1500),
//   )..repeat(reverse: true);
//     _confettiController = ConfettiController(
//       duration: const Duration(seconds: 1),
//     );
//     _audioPlayer = AudioPlayer();
//     _backgroundMusicPlayer = AudioPlayer();
//     _scaleController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 300),
//     );
//     _loadHighScore();
//     _initializeSounds();
//   }

//   @override
//   void dispose() {
//     _confettiController.dispose();
//     _audioPlayer.dispose();
//     _backgroundMusicPlayer.dispose();
//      _animationController.dispose();
//     _scaleController.dispose();
//     _gameTimer?.cancel();
//     super.dispose();
//   }

//   Future<void> _initializeSounds() async {
//     await _audioPlayer.setVolume(0.7);
//     await _backgroundMusicPlayer.setVolume(0.3);
//   }

//   Future<void> _loadHighScore() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() => _highScore = prefs.getInt('highScore') ?? 0);
//   }

//   Future<void> _saveHighScore() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setInt('highScore', _highScore);
//   }

//   Future<void> _playSound(String asset) async {
//     if (Provider.of<SettingsController>(context, listen: false).soundEffects) {
//       await _audioPlayer.stop();
//       await _audioPlayer.play(AssetSource(asset));
//     }
//   }

//   void _startGame() {
//     _gameTimer?.cancel();

//     setState(() {
//       _gameState = GameState.playing;
//       _score = 0;
//       _level = 1;
//       _timeLeft = _kInitialTime;
//       _timerSpeed = _kInitialTime;
//       _hasPlayedCongrats = false;
//     });

//     _playSound('sounds/game_start.mp3');
//     _generateNewChallenge();
//     _startTimer();
//   }

//   void _startTimer() {
//     _gameTimer?.cancel();
//     _gameTimer = Timer.periodic(_kTimerInterval, (timer) {
//       if (_gameState != GameState.playing) return;

//       setState(() {
//         _timeLeft -= 0.1;
//         if (_timeLeft <= 0) {
//           _timeLeft = 0;
//           _endGame();
//         }
//       });
//     });
//   }

//   void _generateNewChallenge() {
//     if (_gameState != GameState.playing) return;

//     final random = Random();

//     setState(() {
//       _timeLeft = _timerSpeed;
//     });

//     final correctColorName =
//         _colorOptions[random.nextInt(_colorOptions.length)];

//     Color textColor;
//     do {
//       textColor = _colors[random.nextInt(_colors.length)];
//     } while (textColor == _colorNameToColor(correctColorName));

//     final buttonColors = <Color>[];
//     final colorNames = <String>[];

//     buttonColors.add(_colorNameToColor(correctColorName));
//     colorNames.add(correctColorName);

//     while (buttonColors.length < 4) {
//       final wrongColorName =
//           _colorOptions[random.nextInt(_colorOptions.length)];
//       if (wrongColorName != correctColorName &&
//           !colorNames.contains(wrongColorName)) {
//         buttonColors.add(_colorNameToColor(wrongColorName));
//         colorNames.add(wrongColorName);
//       }
//     }

//     buttonColors.shuffle();
//     colorNames.shuffle();

//     setState(() {
//       _currentColorName = correctColorName;
//       _currentTextColor = textColor;
//       _buttonColors = buttonColors;
//       _colorNames = colorNames;
//     });

//     _scaleController.forward(from: 0);
//   }

// Color _colorNameToColor(String name) {
//   switch (name.toUpperCase()) {
//     case "RED":
//       return Colors.red;
//     case "BLUE":
//       return Colors.blue;
//     case "GREEN":
//       return Colors.green;
//     case "YELLOW":
//       return Colors.yellow;
//     case "PURPLE":
//       return Colors.purple;
//     case "ORANGE":
//       return Colors.orange;
//     case "PINK":
//       return Colors.pink;
//     case "TEAL":
//       return Colors.teal;
//     case "BROWN":
//       return Colors.brown;
//     case "INDIGO":
//       return Colors.indigo;
//     case "CYAN":
//       return Colors.cyan;
//     case "LIME":
//       return Colors.lime;
//     case "AMBER":
//       return Colors.amber;
//     case "GREY":
//       return Colors.grey;
//     default:
//       return Colors.black;
//   }
// }


//   Color _getContrastColor(Color backgroundColor) {
//     final luminance = backgroundColor.computeLuminance();
//     return luminance > 0.5 ? Colors.black : Colors.white;
//   }

//   void _checkAnswer(String selectedColorName) {
//     if (_gameState != GameState.playing) return;

//     if (selectedColorName == _currentColorName) {
//       _correctAnswer();
//     } else {
//       _endGame();
//     }
//   }

//   void _correctAnswer() {
//     final wasHighScore = _score <= _highScore;
//     final isNewHighScore = _score + (_kBaseScore * _level) > _highScore;

//     _playSound('sounds/success.mp3');

//     setState(() {
//       _score += _kBaseScore * _level;
//       if (_score > _highScore) {
//         _highScore = _score;
//         _saveHighScore();
//         if (wasHighScore && isNewHighScore && !_hasPlayedCongrats) {
//           _playSound('sounds/congrats.mp3');
//           _confettiController.play();
//           _hasPlayedCongrats = true;
//         }
//       }
//       if (_score % _kLevelUpThreshold == 0) {
//         _level++;
//         _timerSpeed = (_timerSpeed * _kTimeDecreaseFactor).clamp(
//           _kMinTime,
//           _kInitialTime,
//         );
//       }
//     });

//     _gameTimer?.cancel();
//     _generateNewChallenge();
//     _startTimer();
//   }

//   void _endGame() {
//     if (_gameState != GameState.playing) return;

//     _playSound('sounds/fail.mp3');
//     _backgroundMusicPlayer.stop();
//     setState(() {
//       _gameState = GameState.gameOver;
//       _timeLeft = 0;
//     });
//     _gameTimer?.cancel();
//   }

//   void _togglePause() {
//     if (_gameState != GameState.playing && _gameState != GameState.paused)
//       return;

//     setState(() {
//       _gameState =
//           _gameState == GameState.playing
//               ? GameState.paused
//               : GameState.playing;
//     });

//     if (_gameState == GameState.paused) {
//       _backgroundMusicPlayer.pause();
//       _playSound('sounds/pause.mp3');
//     } else {
//       _backgroundMusicPlayer.resume();
//       _playSound('sounds/resume.mp3');
//     }
//   }

//   Widget _buildGameButton(int index) {
//     final theme = Theme.of(context);
//     final textColor = _getContrastColor(_buttonColors[index]);

//     return Padding(
//       padding: const EdgeInsets.all(8),
//       child: ScaleTransition(
//         scale: Tween<double>(begin: 0.95, end: 1.0).animate(
//           CurvedAnimation(
//             parent: _scaleController,
//             curve: Interval(
//               0.1 * index,
//               0.1 * (index + 1),
//               curve: Curves.easeOut,
//             ),
//           ),
//         ),
//         child: Material(
//           color: _buttonColors[index],
//           borderRadius: BorderRadius.circular(_kButtonRadius),
//           elevation: 4,
//           child: InkWell(
//             borderRadius: BorderRadius.circular(_kButtonRadius),
//             onTap: () => _checkAnswer(_colorNames[index]),
//             splashColor: Colors.white.withOpacity(0.3),
//             highlightColor: Colors.white.withOpacity(0.2),
//             child: Container(
//               width: double.infinity,
//               padding: _kButtonPadding,
//               child: Center(
//                 child: Text(
//                   _colorNames[index],
//                   textAlign: TextAlign.center,
//                   style: theme.textTheme.titleLarge?.copyWith(
//                     color: textColor,
//                     fontWeight: FontWeight.bold,
//                     shadows: [
//                       Shadow(
//                         blurRadius: 4,
//                         color: Colors.black.withOpacity(0.3),
//                         offset: const Offset(1, 1),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }


// Widget _buildGameOverScreen() {
//   final theme = Theme.of(context);
//   final isDarkMode = theme.brightness == Brightness.dark;
//   final isNewRecord = _score == _highScore && _score > 0;

//   final backgroundColor = isDarkMode ? Colors.black : Colors.white;
//   final cardColor = isDarkMode ? Colors.grey[900] : Colors.grey[100];
//   final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
//   final secondaryTextColor = isDarkMode ? Colors.white70 : Colors.grey[700];
//   final accentColor = isDarkMode ? const Color.fromARGB(255, 22, 114, 93) : const Color.fromARGB(255, 0, 0, 0);

//   return Scaffold(
//     backgroundColor: backgroundColor,
//     body: Center(
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 24.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // Title
//             Text(
//               "GAME OVER",
//               style: TextStyle(
//                 fontSize: 32,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.redAccent,
//                 letterSpacing: 2,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 32),

//             // Score Card
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(24),
//               decoration: BoxDecoration(
//                 color: cardColor,
//                 borderRadius: BorderRadius.circular(16),
//                 border: Border.all(
//                   color: isDarkMode ? Colors.white12 : Colors.black12,
//                 ),
//               ),
//               child: Column(
//                 children: [
//                   Text(
//                     "Your Score",
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                       color: secondaryTextColor,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   Text(
//                     "$_score",
//                     style: TextStyle(
//                       fontSize: 40,
//                       fontWeight: FontWeight.bold,
//                       color: accentColor,
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   Divider(thickness: 1, color: Colors.grey),
//                   const SizedBox(height: 10),
//                   Text(
//                     "High Score: $_highScore",
//                     style: TextStyle(
//                       fontSize: 16,
//                       color: secondaryTextColor,
//                     ),
//                   ),
//                   const SizedBox(height: 6),
//                   Text(
//                     "Level Reached: $_level",
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: secondaryTextColor,
//                     ),
//                   ),
//                   if (isNewRecord) ...[
//                     const SizedBox(height: 20),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: const [
//                         Icon(Icons.star, color: Colors.amber, size: 28),
//                         SizedBox(width: 8),
//                         Text(
//                           "New High Score!",
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.amber,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//             const SizedBox(height: 36),

//             // Play Again Button
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: _startGame,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: accentColor,
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   elevation: 4,
//                 ),
//                 child: Text(
//                   "PLAY AGAIN",
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: const Color.fromARGB(255, 255, 255, 255), // Ensure visibility
//                     letterSpacing: 1,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     ),
//   );
// }


  

//   Widget _buildGameScreen() {
//     final theme = Theme.of(context);

//     return SingleChildScrollView(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const SizedBox(height: 20),
//             Wrap(
//               alignment: WrapAlignment.center,
//               spacing: 16,
//               runSpacing: 16,
//               children: [
//                 _buildScoreCard("Level", "$_level", Icons.star),
//                 _buildScoreCard("Score", "$_score", Icons.leaderboard),
//               ],
//             ),
//             const SizedBox(height: 40),
//             Card(
//               elevation: 8,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(_kCardRadius),
//               ),
//               color: theme.cardColor,
//               child: Padding(
//                 padding: const EdgeInsets.all(24),
//                 child: Column(
//                   children: [
//                     Text(
//                       "Click the button where the text is:",
//                       textAlign: TextAlign.center,
//                       style: theme.textTheme.titleMedium?.copyWith(
//                         color: theme.textTheme.bodyLarge?.color?.withOpacity(
//                           0.8,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     FittedBox(
//                       child: Text(
//                         _currentColorName,
//                         textAlign: TextAlign.center,
//                         style: theme.textTheme.displayLarge?.copyWith(
//                           fontWeight: FontWeight.bold,
//                           color: _colorNameToColor(_currentColorName),
//                           shadows: [
//                             Shadow(
//                               blurRadius: 8,
//                               color: _colorNameToColor(
//                                 _currentColorName,
//                               ).withOpacity(0.5),
//                               offset: const Offset(2, 2),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 24),
//                     LinearProgressIndicator(
//                       value: _timeLeft / _timerSpeed,
//                       backgroundColor: theme.colorScheme.surfaceContainerHighest,
//                       valueColor: AlwaysStoppedAnimation<Color>(
//                         _timeLeft > _timerSpeed * 0.3
//                             ? Colors.green
//                             : _timeLeft > _timerSpeed * 0.1
//                             ? Colors.orange
//                             : Colors.red,
//                       ),
//                       minHeight: 12,
//                       borderRadius: BorderRadius.circular(6),
//                     ),
//                     const SizedBox(height: 12),
//                     Text(
//                       "Time: ${_timeLeft.toStringAsFixed(1)}s",
//                       style: theme.textTheme.bodyLarge?.copyWith(
//                         color: theme.textTheme.bodyLarge?.color?.withOpacity(
//                           0.7,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 40),
//             GridView.count(
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               crossAxisCount: 2,
//               childAspectRatio: 1.5,
//               padding: const EdgeInsets.all(8),
//               children: List.generate(4, (index) => _buildGameButton(index)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }


// Widget _buildStartScreen(AnimationController controller) {
//   final theme = Theme.of(context);
//   final isDarkMode = theme.brightness == Brightness.dark;
//   final primaryColor = isDarkMode ? Colors.lightBlueAccent : const Color.fromARGB(255, 0, 0, 0);
//   final bgColor = isDarkMode ? Colors.black : Colors.white;
//   final textColor = isDarkMode ? Colors.white : Colors.black87;

//   return Scaffold(
//     backgroundColor: bgColor,
//     body: Center(
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 24),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // Game Title
//             Text(
//               "Color Clash",
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 36,
//                 fontWeight: FontWeight.w800,
//                 color: primaryColor,
//               ),
//             ),
//             const SizedBox(height: 12),

//             // Tagline
//             Text(
//               "Match the text color, not the word!",
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//                 color: textColor,
//               ),
//             ),
//             const SizedBox(height: 40),

//             // Start Game Button with subtle animation
//             ScaleTransition(
//               scale: Tween(begin: 0.98, end: 1.0).animate(
//                 CurvedAnimation(
//                   parent: controller,
//                   curve: Curves.easeInOut,
//                 ),
//               ),
//               child: ElevatedButton(
//                 onPressed: _startGame,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: primaryColor,
//                   padding: const EdgeInsets.symmetric(
//                       vertical: 16, horizontal: 32),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   elevation: 4,
//                 ),
//                 child: const Text(
//                   "START GAME",
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     letterSpacing: 1.1,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),

//             // How to Play
//             OutlinedButton(
//               onPressed: () => showDialog(
//                 context: context,
//                 builder: (context) => _buildTutorialDialog(),
//               ),
//               style: OutlinedButton.styleFrom(
//                 foregroundColor: primaryColor,
//                 side: BorderSide(color: primaryColor, width: 2),
//                 padding:
//                     const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               child: const Text(
//                 "How to Play",
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),

//             const SizedBox(height: 40),

//             // Theme Icon (just a touch of game style)
//             // Icon(
//             //   isDarkMode ? Icons.nightlight : Icons.wb_sunny,
//             //   color: isDarkMode ? Colors.amber : Colors.orange,
//             //   size: 28,
//             // ),
//           ],
//         ),
//       ),
//     ),
//   );
// }



//   Widget _buildScoreCard(String title, String value, IconData icon) {
//     final theme = Theme.of(context);

//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(_kButtonRadius),
//       ),
//       color: theme.cardColor,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(icon, color: theme.colorScheme.primary, size: 24),
//             const SizedBox(width: 12),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: theme.textTheme.bodySmall?.copyWith(
//                     color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
//                   ),
//                 ),
//                 Text(
//                   value,
//                   style: theme.textTheme.titleLarge?.copyWith(
//                     fontWeight: FontWeight.bold,
//                     color: theme.textTheme.bodyLarge?.color,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildPauseOverlay() {
//     final theme = Theme.of(context);

//     return Container(
//       color: Colors.black.withOpacity(0.7),
//       child: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               "PAUSED",
//               style: theme.textTheme.displayMedium?.copyWith(
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//             const SizedBox(height: 40),
//             SizedBox(
//               width: 200,
//               child: ElevatedButton(
//                 onPressed: _togglePause,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: theme.colorScheme.primary,
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(_kButtonRadius),
//                   ),
//                   elevation: 8,
//                 ),
//                 child: Text(
//                   "RESUME",
//                   style: theme.textTheme.titleMedium?.copyWith(
//                     fontWeight: FontWeight.bold,
//                     color: theme.colorScheme.onPrimary,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

  
//   Widget _buildTutorialDialog() {
//   final theme = Theme.of(context);

//   return Dialog(
//     backgroundColor: theme.cardColor,
//     shape: RoundedRectangleBorder(
//       borderRadius: BorderRadius.circular(_kCardRadius),
//     ),
//     elevation: 12,
//     child: SingleChildScrollView(
//       child: Padding(
//         padding: const EdgeInsets.all(16), // tighter padding
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Center(
//               child: Text(
//                 'How to Play',
//                 style: theme.textTheme.titleMedium?.copyWith(
//                   fontWeight: FontWeight.w800,
//                   fontSize: 18,
//                   letterSpacing: 1,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),

//             // Steps
//             _buildMiniTutorialStep(
//               icon: Icons.color_lens,
//               color: Colors.deepPurple,
//               title: "Match the Text Color",
//               description:
//                   "Tap the button whose **TEXT COLOR** matches the color name.",
//             ),
//             _buildMiniTutorialStep(
//               icon: Icons.timer,
//               color: Colors.teal,
//               title: "Be Quick!",
//               description:
//                   "React before time runs out. It speeds up at higher levels!",
//             ),
//             _buildMiniTutorialStep(
//               icon: Icons.star,
//               color: Colors.orange,
//               title: "Score Points",
//               description:
//                   "Higher levels give more points. Beat your high score!",
//             ),
//             _buildMiniTutorialStep(
//               icon: Icons.music_note,
//               color: Colors.blueGrey,
//               title: "Sound & Music",
//               description:
//                   "Toggle sound/music in the settings menu.",
//             ),
//             const SizedBox(height: 24),

//             // Button
//             Center(
//               child: SizedBox(
//                 width: 150,
//                 child: ElevatedButton(
//                   onPressed: () => Navigator.pop(context),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: theme.colorScheme.primary,
//                     padding: const EdgeInsets.symmetric(vertical: 12),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(_kButtonRadius),
//                     ),
//                     elevation: 2,
//                   ),
//                   child: Text(
//                     'Got it',
//                     style: theme.textTheme.labelLarge?.copyWith(
//                       fontWeight: FontWeight.w600,
//                       color: theme.colorScheme.onPrimary,
//                       letterSpacing: 1,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     ),
//   );
// }

// Widget _buildMiniTutorialStep({
//   required IconData icon,
//   required String title,
//   required String description,
//   Color? color,
// }) {
//   return Padding(
//     padding: const EdgeInsets.symmetric(vertical: 6),
//     child: Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         CircleAvatar(
//           radius: 14,
//           backgroundColor: color ?? Colors.grey,
//           child: Icon(icon, size: 16, color: Colors.white),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 title,
//                 style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                       fontWeight: FontWeight.bold,
//                     ),
//               ),
//               const SizedBox(height: 2),
//               Text(
//                 description,
//                 style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                       color: Colors.grey.shade700,
//                     ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     ),
//   );
// }


//   Widget _buildTutorialStep({
//     required IconData icon,
//     required String title,
//     required String description,
//   }) {
//     final theme = Theme.of(context);

//     return Container(
//       margin: const EdgeInsets.only(bottom: 24),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: 48,
//             height: 48,
//             decoration: BoxDecoration(
//               color: theme.colorScheme.primary.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Icon(icon, color: theme.colorScheme.primary, size: 28),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: theme.textTheme.titleMedium?.copyWith(
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   description,
//                   style: theme.textTheme.bodyMedium?.copyWith(
//                     color: theme.textTheme.bodyLarge?.color?.withOpacity(0.8),
//                     height: 1.5,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

 
//   @override
// Widget build(BuildContext context) {
//   final theme = Theme.of(context);
//   final isDark = theme.brightness == Brightness.dark;

//   return Container(
//     decoration: BoxDecoration(
//       gradient: LinearGradient(
//         begin: Alignment.topLeft,
//         end: Alignment.bottomRight,
//         colors: isDark
//             ? [Colors.black, Colors.grey.shade900]
//             : [Color(0xFFECEFF1), Color(0xFFCFD8DC)],
//       ),
//     ),
//     child: Scaffold(
//       backgroundColor: Colors.transparent,
//       appBar: AppBar(
//         title: Text(
//           'Color Clash',
//           style: theme.textTheme.titleLarge?.copyWith(
//             fontWeight: FontWeight.bold,
//             letterSpacing: 1.2,
//             color: isDark ? Colors.white : Colors.black87,
//           ),
//         ),
//         backgroundColor:
//             isDark ? Colors.grey.shade900.withOpacity(0.95) : Colors.white.withOpacity(0.9),
//         elevation: 0,
//         centerTitle: true,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back,
//               color: isDark ? Colors.white : Colors.black87, size: 28),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//         actions: [
//           if (_gameState == GameState.playing || _gameState == GameState.paused)
//             IconButton(
//               icon: Icon(
//                 _gameState == GameState.paused ? Icons.play_arrow : Icons.pause,
//                 color: isDark ? Colors.white : Colors.black87,
//                 size: 28,
//               ),
//               onPressed: _togglePause,
//             ),
//           IconButton(
//             icon: Icon(Icons.help_outline,
//                 color: isDark ? Colors.white : Colors.black87, size: 28),
//             onPressed: () => showDialog(
//               context: context,
//               builder: (context) => _buildTutorialDialog(),
//             ),
//           ),
//         ],
//         shape: const RoundedRectangleBorder(
//           borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
//         ),
//       ),
//       body: Stack(
//         children: [
//           switch (_gameState) {
//             GameState.notStarted => _buildStartScreen(_animationController),
//             GameState.playing => _buildGameScreen(),
//             GameState.paused => _buildGameScreen(),
//             GameState.gameOver => _buildGameOverScreen(),
//           },
//           if (_gameState == GameState.paused) _buildPauseOverlay(),
//           Align(
//             alignment: Alignment.topCenter,
//             child: ConfettiWidget(
//               confettiController: _confettiController,
//               blastDirectionality: BlastDirectionality.explosive,
//               colors: const [
//                 Color(0xFF42A5F5), // Soft Blue
//                 Color(0xFF66BB6A), // Soft Green
//                 Color(0xFFFFA726), // Soft Orange
//                 Color(0xFFAB47BC), // Soft Purple
//               ],
//               createParticlePath: (size) {
//                 final path = Path();
//                 path.addOval(
//                   Rect.fromCircle(center: Offset.zero, radius: size.width / 2),
//                 );
//                 return path;
//               },
//               emissionFrequency: 0.05,
//               numberOfParticles: 20,
//               gravity: 0.2,
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }

// }

// enum GameState { notStarted, playing, paused, gameOver }