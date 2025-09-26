// import 'dart:math';

// import 'package:flame/components.dart';
// import 'package:flame/events.dart';
// import 'package:flame/game.dart';
// import 'package:flame/input.dart';
// import 'package:flutter/material.dart';

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
//   late List<String> rules;
//   double lastDt = 0.0;
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
    
//     // Handle rule changes using dt
//     ruleChangeTimer += dt;
//     if (ruleChangeTimer >= ruleChangeInterval) {
//       _setRandomRule();
//       ruleChangeTimer = 0;
//     }

//     // Handle stimulus spawning
//     stimulusSpawnTimer += dt;
//     if (stimulusSpawnTimer >= stimulusSpawnInterval) {
//       spawnStimulus();
//       stimulusSpawnTimer = 0;
//     }
//   }

//   void spawnStimulus() {
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

//   @override
//   void onTapDown(TapDownEvent event) {
//     if (gameOver) return;
//     final now = DateTime.now().millisecondsSinceEpoch;
//     final tapPosition = event.localPosition;
//     final tappedComponents = componentsAtPoint(tapPosition);
//     for (final component in tappedComponents) {
//       if (component is NeuroStimulus) {
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
