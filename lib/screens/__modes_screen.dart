
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:memorush/screens/Bnumber_seq.dart';
import 'package:memorush/screens/Amemorytile.dart';
import 'package:memorush/screens/clash_duel_screen.dart';
import 'package:memorush/screens/nish_game.dart';
import 'package:memorush/screens/ball_sorting_game.dart';
import 'package:memorush/screens/shadow.dart';
import '../controllers/settings_controller.dart';

class ModesScreen extends StatefulWidget {
  const ModesScreen({super.key});

  @override
  State<ModesScreen> createState() => _ModesScreenState();
}

class _ModesScreenState extends State<ModesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  final List<_GameMode> gameModes = [
    _GameMode(
      title: 'Memory tiles',
      subtitle: 'Improve your memory with tiles',
      imagePath: 'assets/images/memory.png',
      onTap: (context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GameScreen()),
      ),
    ),
    _GameMode(
      title: 'Number Sequence',
      subtitle: 'memorize the sequence of numbers',
      imagePath: 'assets/images/bubblymem.png',
      onTap: (context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NumberSequenceMemoryGame()),
      ),
    ),
    _GameMode(
      title: 'Tic Tac Toe',
      subtitle: 'Three in a row, or game over',
      imagePath: 'assets/images/Tic.jpg',
      onTap: (context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TicTacToeScreen()),
      ),
    ),
    _GameMode(
      title: 'Color Clash',
      subtitle: 'your brain says yes, but your eyes screams no',
      imagePath: 'assets/images/col2.jpg',
      onTap: (context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ColorConfusionGame()),
      ),
    ),
    _GameMode(
      title: 'Ball Sort',
      subtitle: 'Sort the balls by color',
      imagePath: 'assets/images/BallSort.jpg',
      onTap: (context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BallSortingGame()),
      ),
    ),
    // _GameMode(
    //   title: 'Clash Duel',
    //   subtitle: 'Battle your way to victory',
    //   imagePath: 'assets/images/ques.jpg',
    //   onTap: (context) => Navigator.push(
    //     context,
    //     MaterialPageRoute(builder: (_) => const ColorClashDuel()),
    //   ),
    // ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    );
    
    final settings = Provider.of<SettingsController>(context, listen: false);
    if (settings.enableAnimations) {
      _animationController.repeat();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = Provider.of<SettingsController>(context);
    if (settings.enableAnimations) {
      _animationController.repeat();
    } else {
      _animationController.stop();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsController>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Game Mode',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [Colors.black, Colors.black]
                : [
                    const Color.fromARGB(255, 255, 166, 107),
                    const Color.fromARGB(255, 199, 133, 250),
                  ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            if (settings.enableAnimations)
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _AnimatedModesStarsPainter(
                      animation: _animationController,
                      isDark: isDark,
                    ),
                    child: Container(),
                  );
                },
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: ListView.builder(
                itemCount: gameModes.length,
                itemBuilder: (context, index) {
                  final mode = gameModes[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    child: GestureDetector(
                      onTap: () => mode.onTap(context),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.65, // Further decreased width
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black12 : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFFFD700),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Image at top
                            Container(
                              width: 190, // Increased image size
                              height: 190, // Increased image size
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.black.withOpacity(0.05),
                                border: Border.all(
                                  color: const Color(0xFFFFD700),
                                  width: 4,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                image: mode.imagePath != null
                                    ? DecorationImage(
                                        image: AssetImage(mode.imagePath!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Title
                            Text(
                              mode.title,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            // Subtitle
                            Text(
                              mode.subtitle,
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark
                                    ? Colors.white.withOpacity(0.8)
                                    : Colors.black54,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedModesStarsPainter extends CustomPainter {
  final Animation<double> animation;
  final bool isDark;

  _AnimatedModesStarsPainter({required this.animation, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint starPaint =
        Paint()..color = isDark ? Colors.white : Colors.black.withOpacity(0.6);

    final Random random = Random(24);
    for (int i = 0; i < 100; i++) {
      final double x = random.nextDouble() * size.width;
      final double y =
          (random.nextDouble() * size.height + animation.value * size.height) %
              size.height;
      final double radius = random.nextDouble() * 2 + 1;
      canvas.drawCircle(Offset(x, y), radius, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AnimatedModesStarsPainter oldDelegate) => true;
}

class _GameMode {
  final String title;
  final String subtitle;
  final String? imagePath;
  final void Function(BuildContext) onTap;

  _GameMode({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.imagePath,
  });
}







// import 'dart:math';////////////////////////////////
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:memorush/screens/Bnumber_seq.dart';
// import 'package:memorush/screens/Amemorytile.dart';
// import 'package:memorush/screens/clash_duel_screen.dart';
// import 'package:memorush/screens/nish_game.dart';
// import 'package:memorush/screens/ball_sorting_game.dart';
// import 'package:memorush/screens/shadow.dart';
// import '../controllers/settings_controller.dart';

// class ModesScreen extends StatefulWidget {
//   const ModesScreen({super.key});

//   @override
//   State<ModesScreen> createState() => _ModesScreenState();
// }

// class _ModesScreenState extends State<ModesScreen>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _animationController;

//   final List<_GameMode> gameModes = [
//     _GameMode(
//       title: 'Memory tiles',
//       subtitle: 'Improve your memory with tiles',
//       imagePath: 'assets/images/memory.png',
//       onTap: (context) => Navigator.push(
//         context,
//         MaterialPageRoute(builder: (_) => const GameScreen()),
//       ),
//     ),
//     _GameMode(
//       title: 'Number Sequence',
//       subtitle: 'memorize the sequence of numbers',
//       imagePath: 'assets/images/bubblymem.png',
//       onTap: (context) => Navigator.push(
//         context,
//         MaterialPageRoute(builder: (_) => const NumberSequenceMemoryGame()),
//       ),
//     ),
//     _GameMode(
//       title: 'Tic Tac Toe',
//       subtitle: 'Three in a row, or game over',
//       imagePath: 'assets/images/Tic.jpg',
//       onTap: (context) => Navigator.push(
//         context,
//         MaterialPageRoute(builder: (_) => const TicTacToeScreen()),
//       ),
//     ),
//     _GameMode(
//       title: 'Color Clash',
//       subtitle: 'your brain says yes, but your eyes screams no',
//       imagePath: 'assets/images/col2.jpg',
//       onTap: (context) => Navigator.push(
//         context,
//         MaterialPageRoute(builder: (_) => const ColorConfusionGame()),
//       ),
//     ),
//     _GameMode(
//       title: 'Ball Sort',
//       subtitle: 'Sort the balls by color',
//       imagePath: 'assets/images/BallSort.jpg',
//       onTap: (context) => Navigator.push(
//         context,
//         MaterialPageRoute(builder: (_) => const BallSortingGame()),
//       ),
//     ),
//     _GameMode(
//       title: 'Clash Duel',
//       subtitle: 'Battle your way to victory',
//       imagePath: 'assets/images/ques.jpg',
//       onTap: (context) => Navigator.push(
//         context,
//         MaterialPageRoute(builder: (_) => const ColorClashDuel()),
//       ),
//     ),
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 60),
//     );
    
//     // Check initial animation setting
//     final settings = Provider.of<SettingsController>(context, listen: false);
//     if (settings.enableAnimations) {
//       _animationController.repeat();
//     }
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     // Listen to animation setting changes
//     final settings = Provider.of<SettingsController>(context);
//     if (settings.enableAnimations) {
//       _animationController.repeat();
//     } else {
//       _animationController.stop();
//     }
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final settings = Provider.of<SettingsController>(context);
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           'Select Game Mode',
//           style: TextStyle(
//             color: isDark ? Colors.white : Colors.black,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         foregroundColor: isDark ? Colors.white : Colors.black,
//       ),
//       extendBodyBehindAppBar: true,
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: isDark
//                 ? [Colors.black, Colors.black]
//                 : [
//                     const Color.fromARGB(255, 255, 166, 107),
//                     const Color.fromARGB(255, 199, 133, 250),
//                   ],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: Stack(
//           children: [
//             // Only show animation if enabled in settings
//             if (settings.enableAnimations)
//               AnimatedBuilder(
//                 animation: _animationController,
//                 builder: (context, child) {
//                   return CustomPaint(
//                     painter: _AnimatedModesStarsPainter(
//                       animation: _animationController,
//                       isDark: isDark,
//                     ),
//                     child: Container(),
//                   );
//                 },
//               ),
//             Padding(
//               padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
//               child: GridView.builder(
//                 itemCount: gameModes.length,
//                 gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                   crossAxisCount: 2,
//                   crossAxisSpacing: 16,
//                   mainAxisSpacing: 16,
//                   childAspectRatio: 0.75,
//                 ),
//                 itemBuilder: (context, index) {
//                   final mode = gameModes[index];
//                   return GestureDetector(
//                     onTap: () => mode.onTap(context),
//                     child: Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: isDark ? Colors.black12 : Colors.white,
//                         borderRadius: BorderRadius.circular(16),
//                         border: Border.all(
//                           color: const Color(0xFFFFD700),
//                           width: 2,
//                         ),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.1),
//                             blurRadius: 4,
//                             offset: const Offset(2, 2),
//                           ),
//                         ],
//                       ),
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Container(
//                             width: 110,
//                             height: 110,
//                             decoration: BoxDecoration(
//                               color: isDark
//                                   ? Colors.white.withOpacity(0.1)
//                                   : Colors.black.withOpacity(0.05),
//                               border: Border.all(
//                                 color: const Color(0xFFFFD700),
//                                 width: 4,
//                               ),
//                               borderRadius: BorderRadius.circular(12),
//                               image: mode.imagePath != null
//                                   ? DecorationImage(
//                                       image: AssetImage(mode.imagePath!),
//                                       fit: BoxFit.cover,
//                                     )
//                                   : null,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             mode.title,
//                             style: TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.bold,
//                               color: isDark ? Colors.white : Colors.black87,
//                             ),
//                             textAlign: TextAlign.center,
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             mode.subtitle,
//                             style: TextStyle(
//                               fontSize: 12,
//                               color: isDark
//                                   ? const Color.fromARGB(255, 255, 255, 255)
//                                   : Colors.black54,
//                             ),
//                             textAlign: TextAlign.center,
//                           ),
//                         ],
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

// class _AnimatedModesStarsPainter extends CustomPainter {
//   final Animation<double> animation;
//   final bool isDark;

//   _AnimatedModesStarsPainter({required this.animation, required this.isDark});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final Paint starPaint =
//         Paint()..color = isDark ? Colors.white : Colors.black.withOpacity(0.6);

//     final Random random = Random(24);
//     for (int i = 0; i < 100; i++) {
//       final double x = random.nextDouble() * size.width;
//       final double y =
//           (random.nextDouble() * size.height + animation.value * size.height) %
//               size.height;
//       final double radius = random.nextDouble() * 2 + 1;
//       canvas.drawCircle(Offset(x, y), radius, starPaint);
//     }
//   }

//   @override
//   bool shouldRepaint(covariant _AnimatedModesStarsPainter oldDelegate) => true;
// }

// class _GameMode {
//   final String title;
//   final String subtitle;
//   final String? imagePath;
//   final void Function(BuildContext) onTap;

//   _GameMode({
//     required this.title,
//     required this.subtitle,
//     required this.onTap,
//     this.imagePath,
//   });
// }///////////////////////////////////////////////////




// import 'dart:math';
// import 'package:flutter/material.dart';
// // import 'package:memory/screens/Cpeecha_mat_karo.dart';
// import 'package:memorush/screens/Bnumber_seq.dart';
// import 'package:memorush/screens/Amemorytile.dart';
// import 'package:memorush/screens/clash_duel_screen.dart';
// import 'package:memorush/screens/nish_game.dart';
// import 'package:memorush/screens/ball_sorting_game.dart';
// import 'package:memorush/screens/shadow.dart';

// // Your memory game screen

// class ModesScreen extends StatefulWidget {
//   const ModesScreen({super.key});

//   @override
//   State<ModesScreen> createState() => _ModesScreenState();
// }

// class _ModesScreenState extends State<ModesScreen>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _animationController;

//   final List<_GameMode> gameModes = [
//     // _GameMode(
//     //   title: 'Memory Game',
//     //   subtitle: 'Improve your memory',
//     //   imagePath: 'assets/images/memory.png',
//     //   onTap:
//     //       (context) => Navigator.push(
//     //         context,
//     //         MaterialPageRoute(builder: (_) => const ModesScreen()),
//     //       ),
//     // ),
//     _GameMode(
//       title: 'Memory tiles',
//       subtitle: 'Improve your memory with tiles',
//       imagePath: 'assets/images/memory.png',
//       onTap:
//           (context) => Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder:
//                   (_) => const GameScreen(), // Provide required level argument
//             ),
//           ),
//     ),
//     _GameMode(
//       title: 'Number Sequence',
//       subtitle: 'memorize the sequence of numbers',
//       imagePath: 'assets/images/bubblymem.png',
//       onTap:
//           (context) => Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder:
//                   (_) =>
//                       const NumberSequenceMemoryGame(), // Use the correct class name
//             ),
//           ),
//     ),
//     _GameMode(
//       title: 'Tic Tac Toe',
//       subtitle: 'Three in a row, or game over',
//       imagePath: 'assets/images/Tic.jpg',
//       onTap:
//           (context) => Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder:
//                   (_) =>
//                       const TicTacToeScreen(), // Use the wrapper screen for NeuroDash
//             ),
//           ),
//     ),
//     _GameMode(
//       title: 'Color Clash',
//       subtitle: 'your brain says yes, but your eyes screams no',
//       imagePath: 'assets/images/col2.jpg',
//       onTap:
//           (context) => Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder:
//                   (_) =>
//                       const ColorConfusionGame(), // Use the correct class name
//             ),
//           ),
//     ),

//     //     _GameMode(
//     //       title: 'Number Sequence',
//     //       subtitle: 'memorize the sequence of numbers',
//     //       imagePath: 'assets/images/splash_logo.png',
//     //       onTap: (context) => Navigator.push(
//     //     context,
//     //     MaterialPageRoute(
//     //       builder: (_) => const DanceBattleGame(), // ✅ push GameScreen, not ModesScreen
//     //     ),
//     //   ),
//     // ),

//  _GameMode(
//       title: 'Ball Sort',
//       subtitle: 'Sort the balls by color',
//       imagePath: 'assets/images/BallSort.jpg',
//       onTap:
//           (context) => Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder:
//                   (_) =>
//                       const BallSortingGame(), // Use the wrapper screen for NeuroDash
//             ),
//           ),
//     ),


//  _GameMode(
//       title: 'Clash Duel',
//       subtitle: 'Battle your way to victory',
//       imagePath: 'assets/images/ques.jpg',
//       onTap:
//           (context) => Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (_) => const ColorClashDuel(),
//             ),
//           ),
//     ),
//     // _GameMode(
//     //   title: 'Game 5',
//     //   subtitle: 'Coming soon',
//     //   imagePath: 'assets/images/ques.jpg',
//     //   onTap:
//     //       (context) => Navigator.push(
//     //         context,
//     //         MaterialPageRoute(
//     //           builder: (_) => const NumberSequenceGameScreen(level: 1),
//     //         ),
//     //       ),
//     // ),
    
//     // for (int i = 4; i <= 4; i++)
//     //   _GameMode(
//     //     title: 'Game $i',
//     //     subtitle: 'Coming soon',
//     //     imagePath: 'assets/images/ques.jpg',
//     //     onTap: (context) {
//     //       ScaffoldMessenger.of(context);
//     //       // .showSnackBar(const SnackBar(content: Text('Coming soon!')));
//     //     },
//     //   ),
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 60),
//     )..repeat();
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     return Scaffold(
//       // appBar: AppBar(
//       //   title: const Text('Select Game Mode'),
//       //   backgroundColor: Colors.transparent,
//       //   elevation: 0,
//       //   foregroundColor: isDark ? Colors.white : Colors.black,
//       // ),
//       appBar: AppBar(
//         title: Text(
//           'Select Game Mode',
//           style: TextStyle(
//             color: isDark ? Colors.white : Colors.black,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         foregroundColor: isDark ? Colors.white : Colors.black,
//       ),

//       extendBodyBehindAppBar: true,
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors:
//                 isDark
//                     ? [Colors.black, Colors.black]
//                     : [
//                       const Color.fromARGB(255, 255, 166, 107),
//                       const Color.fromARGB(255, 199, 133, 250),
//                     ],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: Stack(
//           children: [
//             AnimatedBuilder(
//               animation: _animationController,
//               builder: (context, child) {
//                 return CustomPaint(
//                   painter: _AnimatedModesStarsPainter(
//                     animation: _animationController,
//                     isDark: isDark,
//                   ),
//                   child: Container(),
//                 );
//               },
//             ),
//             Padding(
//               padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
//               child: GridView.builder(
//                 itemCount: gameModes.length,
//                 gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                   crossAxisCount: 2,
//                   crossAxisSpacing: 16,
//                   mainAxisSpacing: 16,
//                   childAspectRatio: 0.75,
//                 ),
//                 itemBuilder: (context, index) {
//                   final mode = gameModes[index];
//                   return GestureDetector(
//                     onTap: () => mode.onTap(context),
//                     child: Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: isDark ? Colors.black12 : Colors.white,
//                         borderRadius: BorderRadius.circular(16),
//                         border: Border.all(
//                           color: const Color(0xFFFFD700), // golden outer border
//                           width: 2,
//                         ),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.1),
//                             blurRadius: 4,
//                             offset: const Offset(2, 2),
//                           ),
//                         ],
//                       ),
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Container(
//                             width: 110,
//                             height: 110,
//                             decoration: BoxDecoration(
//                               color:
//                                   isDark
//                                       ? Colors.white.withOpacity(0.1)
//                                       : Colors.black.withOpacity(0.05),
//                               border: Border.all(
//                                 color: const Color(0xFFFFD700),
//                                 width: 4,
//                               ),
//                               borderRadius: BorderRadius.circular(12),
//                               image:
//                                   mode.imagePath != null
//                                       ? DecorationImage(
//                                         image: AssetImage(mode.imagePath!),
//                                         fit: BoxFit.cover,
//                                       )
//                                       : null,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             mode.title,
//                             style: TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.bold,
//                               color: isDark ? Colors.white : Colors.black87,
//                             ),
//                             textAlign: TextAlign.center,
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             mode.subtitle,
//                             style: TextStyle(
//                               fontSize: 12,
//                               color:
//                                   isDark
//                                       ? const Color.fromARGB(255, 255, 255, 255)
//                                       : Colors.black54,
//                             ),
//                             textAlign: TextAlign.center,
//                           ),
//                         ],
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

// class _AnimatedModesStarsPainter extends CustomPainter {
//   final Animation<double> animation;
//   final bool isDark;

//   _AnimatedModesStarsPainter({required this.animation, required this.isDark});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final Paint starPaint =
//         Paint()..color = isDark ? Colors.white : Colors.black.withOpacity(0.6);

//     final Random random = Random(24);
//     for (int i = 0; i < 100; i++) {
//       final double x = random.nextDouble() * size.width;
//       final double y =
//           (random.nextDouble() * size.height + animation.value * size.height) %
//           size.height;
//       final double radius = random.nextDouble() * 2 + 1;
//       canvas.drawCircle(Offset(x, y), radius, starPaint);
//     }
//   }

//   @override
//   bool shouldRepaint(covariant _AnimatedModesStarsPainter oldDelegate) => true;
// }

// class _GameMode {
//   final String title;
//   final String subtitle;
//   final String? imagePath;
//   final void Function(BuildContext) onTap;

//   _GameMode({
//     required this.title,
//     required this.subtitle,
//     required this.onTap,
//     this.imagePath,
//   });
// }
