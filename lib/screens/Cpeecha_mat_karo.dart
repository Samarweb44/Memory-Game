// import 'dart:math';
// import 'dart:async';

// import 'package:flame/components.dart';
// import 'package:flame/events.dart';
// import 'package:flame/game.dart';
// import 'package:flame/input.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';

// class NeuroSwitchGame extends FlameGame
//     with TapCallbacks, PanDetector {
//   final Brightness brightness;
//   int lives = 3;
//   int score = 0;
//   double stimulusSpawnTimer = 0;
//   double ruleChangeTimer = 0;
//   double stimulusSpawnInterval = 1.2;
//   double ruleChangeInterval = 4.0;
//   final Random random = Random();
//   late TextPaint textPaint;
//   late String currentRule;
//   late List<String> rules;  double lastDt = 0.0;
//   bool gameOver = false;
//   int _lastTapTime = 0;
//   NeuroStimulus? _lastTappedStimulus;

//   NeuroSwitchGame({required this.brightness});

//   @override
//   Future<void> onLoad() async {
//     await super.onLoad();
//     textPaint = TextPaint(
//       style: TextStyle(
//         color: brightness == Brightness.dark ? Colors.white : Colors.black,
//         fontSize: 20,
//         fontWeight: FontWeight.bold,
//       ),
//     );
//     add(RectangleComponent(
//       size: size,
//       paint: Paint()
//         ..color = brightness == Brightness.dark ? Colors.black : Colors.white,
//     )..priority = -1);
//     for (int i = 0; i < 40; i++) {
//       add(Star(random, size, brightness));
//     }
//     rules = [
//       'Tap BLUE',
//       'Swipe GREEN',
//       'Double-tap YELLOW',
//       'Avoid RED',
//       'Tap SHAPE',
//       'Swipe CIRCLE',
//       'Double-tap SQUARE',
//     ];
//     _setRandomRule();
//     ruleTimer = Timer.periodic(Duration(milliseconds: (ruleChangeInterval * 1000).toInt()), (_) {
//       _setRandomRule();
//     });
//   }

//   void _setRandomRule() {
//     currentRule = rules[random.nextInt(rules.length)];
//     ruleChangeTimer = 0;
//   }

//   @override
//   void update(double dt) {
//     if (gameOver) return;
//     super.update(dt);
//     lastDt = dt;
//     stimulusSpawnTimer += dt;
//     ruleChangeTimer += dt;
//     if (stimulusSpawnTimer > stimulusSpawnInterval) {
//       spawnStimulus();
//       stimulusSpawnTimer = 0;
//     }
//     if (ruleChangeTimer > ruleChangeInterval) {
//       _setRandomRule();
//     }
//   }

//   void spawnStimulus() {
//     // Randomly choose color and shape
//     final colors = [Colors.blue, Colors.green, Colors.yellow, Colors.red];
//     final shapes = ['circle', 'square', 'triangle'];
//     final color = colors[random.nextInt(colors.length)];
//     final shape = shapes[random.nextInt(shapes.length)];
//     final stimulus = NeuroStimulus(
//       color: color,
//       shape: shape,
//       position: Vector2(
//         random.nextDouble() * size.x,
//         random.nextDouble() * size.y,
//       ),
//       speed: 80 + random.nextDouble() * 120,
//     );
//     add(stimulus);
//   }

//   void loseLife() {
//     lives--;
//     if (lives <= 0) {
//       gameOver = true;
//       overlays.add('GameOver');
//       pauseEngine();
//       ruleTimer?.cancel();
//     }
//   }

//   void increaseScore(int points) {
//     score += points;
//   }

//   @override
//   void render(Canvas canvas) {
//     super.render(canvas);
//     textPaint.render(canvas, 'Score: $score', Vector2(20, 20));
//     textPaint.render(canvas, 'Lives: $lives', Vector2(20, 50));
//     textPaint.render(canvas, 'Rule: $currentRule', Vector2(20, 80));
//   }

//   // --- Input Handling ---
//   @override
//   void onTapDown(TapDownEvent event) {
//     if (gameOver) return;
//     final now = DateTime.now().millisecondsSinceEpoch;
//     final tapPosition = event.localPosition;
//     final tappedComponents = componentsAtPoint(tapPosition);
//     for (final component in tappedComponents) {
//       if (component is NeuroStimulus) {
//         // Double-tap detection
//         if (_lastTappedStimulus == component && now - _lastTapTime < 400) {
//           if (_isCorrectAction(component, 'double-tap')) {
//             increaseScore(20);
//             component.removeFromParent();
//           } else {
//             loseLife();
//             component.removeFromParent();
//           }
//           _lastTappedStimulus = null;
//         } else {
//           if (_isCorrectAction(component, 'tap')) {
//             increaseScore(10);
//             component.removeFromParent();
//           } else {
//             loseLife();
//             component.removeFromParent();
//           }
//           _lastTappedStimulus = component;
//           _lastTapTime = now;
//         }
//         return;
//       }
//     }
//   }

//   @override
//   void onPanUpdate(DragUpdateInfo info) {
//     if (gameOver) return;
//     final dragPosition = info.eventPosition.global;
//     final draggedComponents = componentsAtPoint(dragPosition);
//     for (final component in draggedComponents) {
//       if (component is NeuroStimulus) {
//         if (_isCorrectAction(component, 'swipe')) {
//           increaseScore(12);
//           component.removeFromParent();
//         } else {
//           loseLife();
//           component.removeFromParent();
//         }
//         return;
//       }
//     }
//   }

//   bool _isCorrectAction(NeuroStimulus stimulus, String action) {
//     // Rule parsing
//     if (currentRule == 'Tap BLUE') {
//       return action == 'tap' && stimulus.color == Colors.blue;
//     } else if (currentRule == 'Swipe GREEN') {
//       return action == 'swipe' && stimulus.color == Colors.green;
//     } else if (currentRule == 'Double-tap YELLOW') {
//       return action == 'double-tap' && stimulus.color == Colors.yellow;
//     } else if (currentRule == 'Avoid RED') {
//       return stimulus.color == Colors.red ? false : true;
//     } else if (currentRule == 'Tap SHAPE') {
//       return action == 'tap' && stimulus.shape == 'triangle';
//     } else if (currentRule == 'Swipe CIRCLE') {
//       return action == 'swipe' && stimulus.shape == 'circle';
//     } else if (currentRule == 'Double-tap SQUARE') {
//       return action == 'double-tap' && stimulus.shape == 'square';
//     }
//     return false;
//   }
// }

// class NeuroStimulus extends PositionComponent with HasGameRef<NeuroSwitchGame> {
//   final Color color;
//   final String shape;
//   final double speed;
//   double timeAlive = 0;
//   NeuroStimulus({
//     required this.color,
//     required this.shape,
//     required Vector2 position,
//     required this.speed,
//   }) : super(position: position, size: Vector2.all(40));

//   @override
//   void render(Canvas canvas) {
//     final paint = Paint()..color = color;
//     if (shape == 'circle') {
//       canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, paint);
//     } else if (shape == 'square') {
//       canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), paint);
//     } else if (shape == 'triangle') {
//       final path = Path();
//       path.moveTo(size.x / 2, 0);
//       path.lineTo(0, size.y);
//       path.lineTo(size.x, size.y);
//       path.close();
//       canvas.drawPath(path, paint);
//     }
//   }

//   @override
//   void update(double dt) {
//     super.update(dt);
//     timeAlive += dt;
//     // Move randomly
//     position += Vector2((Random().nextDouble() - 0.5) * speed * dt, (Random().nextDouble() - 0.5) * speed * dt);
//     // Remove if off screen
//     if (position.x < -size.x || position.x > gameRef.size.x + size.x ||
//         position.y < -size.y || position.y > gameRef.size.y + size.y) {
//       removeFromParent();
//     }
//     // If not interacted with in 3 seconds, penalize if not "Avoid RED"
//     if (timeAlive > 3.0) {
//       if (gameRef.currentRule != 'Avoid RED') {
//         gameRef.loseLife();
//       }
//       removeFromParent();
//     }
//   }
// }

// class Star extends CircleComponent with HasGameRef<NeuroSwitchGame> {
//   final Random _random;
//   final Brightness brightness;
//   Star(Random random, Vector2 screenSize, this.brightness)
//       : _random = random,
//         super(
//           radius: random.nextDouble() * 2 + 1,
//           position: Vector2(
//             random.nextDouble() * screenSize.x,
//             random.nextDouble() * screenSize.y,
//           ),
//           paint: Paint()
//             ..color = brightness == Brightness.dark
//                 ? Colors.white.withOpacity(random.nextDouble() * 0.5 + 0.5)
//                 : Color.lerp(Colors.amber, Colors.yellow, random.nextDouble())!
//                     .withOpacity(random.nextDouble() * 0.5 + 0.5),
//         );

//   @override
//   void update(double dt) {
//     super.update(dt);
//     // Make stars twinkle
//     if (_random.nextDouble() < 0.01) {
//       paint.color = brightness == Brightness.dark
//           ? paint.color.withOpacity(_random.nextDouble() * 0.5 + 0.5)
//           : Color.lerp(Colors.amber, Colors.yellow, _random.nextDouble())!
//               .withOpacity(_random.nextDouble() * 0.5 + 0.5);
//     }
//   }
// }

// class BrainGameScreen extends StatelessWidget {
//   const BrainGameScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final brightness = Theme.of(context).brightness;
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Color(0xFF1A0033), Color(0xFF000000)],
//           ),
//         ),
//         child: GameWidget(
//           game: NeuroSwitchGame(brightness: brightness),
//           overlayBuilderMap: {
//             'GameOver': (context, game) {
//               final neuroGame = game as NeuroSwitchGame;
//               return Center(
//                 child: Container(
//                   padding: const EdgeInsets.all(20),
//                   decoration: BoxDecoration(
//                     color: Colors.black.withOpacity(0.8),
//                     borderRadius: BorderRadius.circular(20),
//                     border: Border.all(color: Colors.purpleAccent, width: 2),
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       const Text(
//                         'Game Over',
//                         style: TextStyle(
//                           fontSize: 40,
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                           fontFamily: 'Arial',
//                         ),
//                       ),
//                       const SizedBox(height: 10),
//                       Text(
//                         'Score:  24{neuroGame.score}',
//                         style: const TextStyle(
//                           fontSize: 24,
//                           color: Colors.white,
//                         ),
//                       ),
//                       const SizedBox(height: 30),
//                       ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.purple,
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 30, vertical: 15),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(30),
//                           ),
//                         ),
//                         onPressed: () {
//                           neuroGame.resumeEngine();
//                           neuroGame.overlays.remove('GameOver');
//                           neuroGame.lives = 3;
//                           neuroGame.score = 0;
//                           neuroGame.children.whereType<NeuroStimulus>().forEach(
//                               (e) => e.removeFromParent());
//                           neuroGame.gameOver = false;
//                           neuroGame._setRandomRule();
//                           neuroGame.ruleTimer = Timer.periodic(
//                               Duration(milliseconds: (neuroGame.ruleChangeInterval * 1000).toInt()), (_) {
//                             neuroGame._setRandomRule();
//                           });
//                         },
//                         child: const Text(
//                           'Play Again',
//                           style: TextStyle(fontSize: 20),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           },
//         ),
//       ),
//     );
//   }
// }