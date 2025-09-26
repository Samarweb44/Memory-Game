// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'game_screen.dart';

// class LevelsScreen extends StatefulWidget {
//   const LevelsScreen({super.key});

//   @override
//   State<LevelsScreen> createState() => _LevelsScreenState();
// }

// class _LevelsScreenState extends State<LevelsScreen> {
//   int highestUnlockedLevel = 1;

//   @override
//   void initState() {
//     super.initState();
//     loadUnlockedLevel();
//   }

//   Future<void> loadUnlockedLevel() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       highestUnlockedLevel = prefs.getInt('highestLevel') ?? 1;
//       print('Loaded highestUnlockedLevel: $highestUnlockedLevel');
//     });
//   }

//   void onLevelSelected(int level) async {
//     final result = await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => GameScreen(level: level),
//       ),
//     );

//     print('Level $level finished with result: $result');
//     print('Current highestUnlockedLevel: $highestUnlockedLevel');

//     if (result == true && level >= highestUnlockedLevel) {
//       final prefs = await SharedPreferences.getInstance();
//       int newLevel = level + 1;
//       print('Unlocking next level: $newLevel');
//       await prefs.setInt('highestLevel', newLevel);
//       setState(() {
//         highestUnlockedLevel = newLevel;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Select Level'),
//         backgroundColor: Colors.teal.shade700,
//       ),
//       body: GridView.builder(
//         padding: const EdgeInsets.all(20),
//         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 3,
//           crossAxisSpacing: 10,
//           mainAxisSpacing: 10,
//         ),
//         itemCount: 20,
//         itemBuilder: (context, index) {
//           int level = index + 1;
//           bool isUnlocked = level <= highestUnlockedLevel;

//           return ElevatedButton(
//             onPressed: isUnlocked ? () => onLevelSelected(level) : null,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: isUnlocked ? Colors.teal.shade600 : Colors.grey,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text('Level $level'),
//                 if (!isUnlocked)
//                   const Icon(Icons.lock, size: 18, color: Colors.white70),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }









// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'game_screen.dart';

// class LevelsScreen extends StatefulWidget {
//   const LevelsScreen({super.key});

//   @override
//   State<LevelsScreen> createState() => _LevelsScreenState();
// }

// class _LevelsScreenState extends State<LevelsScreen> {
//   int highestUnlockedLevel = 1;

//   @override
//   void initState() {
//     super.initState();
//     loadUnlockedLevel();
//   }

//   Future<void> loadUnlockedLevel() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       highestUnlockedLevel = prefs.getInt('highestLevel') ?? 1;
//       print('Loaded highestUnlockedLevel: $highestUnlockedLevel');
//     });
//   }

//   Future<void> resetProgress() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setInt('highestLevel', 1);
//     setState(() {
//       highestUnlockedLevel = 1;
//     });
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Progress reset to Level 1')),
//     );
//   }

//   void onLevelSelected(int level) async {
//     final result = await Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => GameScreen(level: level)),
//     );

//     print('Level $level finished with result: $result');
//     print('Current highestUnlockedLevel: $highestUnlockedLevel');

//     if (result == true && level >= highestUnlockedLevel) {
//       final prefs = await SharedPreferences.getInstance();
//       int newLevel = level + 1;
//       print('Unlocking next level: $newLevel');
//       await prefs.setInt('highestLevel', newLevel);
//       setState(() {
//         highestUnlockedLevel = newLevel;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Select Level'),
//         backgroundColor: Colors.teal.shade700,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             tooltip: 'Reset Progress',
//             onPressed: resetProgress,
//           ),
//         ],
//       ),
//       body: GridView.builder(
//         padding: const EdgeInsets.all(20),
//         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 3,
//           crossAxisSpacing: 10,
//           mainAxisSpacing: 10,
//         ),
//         itemCount: 20,
//         itemBuilder: (context, index) {
//           int level = index + 1;
//           bool isUnlocked = level <= highestUnlockedLevel;
//           bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

//           return ElevatedButton(
//             onPressed: isUnlocked ? () => onLevelSelected(level) : null,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: isUnlocked ? Colors.teal.shade600 : Colors.grey,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(
//                   'Level $level',
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: TextStyle(
//                     fontSize: 13,
//                     fontWeight: FontWeight.bold,
//                     color: isUnlocked
//                         ? Colors.white
//                         : (isDarkMode ? Colors.white70 : Colors.black54),
//                   ),
//                 ),
//                 if (!isUnlocked)
//                   Icon(
//                     Icons.lock,
//                     size: 18,
//                     color: isDarkMode ? Colors.white70 : Colors.black45,
//                   ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }




//;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart'; // Import Provider
// import 'game_screen.dart';
// import '../controllers/settings_controller.dart'; // Adjust path if necessary

// class LevelsScreen extends StatefulWidget {
//   const LevelsScreen({super.key});

//   @override
//   State<LevelsScreen> createState() => _LevelsScreenState();
// }

// class _LevelsScreenState extends State<LevelsScreen> {
//   // No need for highestUnlockedLevel here anymore, it comes from the controller

//   @override
//   void initState() {
//     super.initState();
//     // No need to loadUnlockedLevel() here, SettingsController does it.
//     // However, if you're returning from GameScreen and want to ensure the LevelsScreen is
//     // showing the *very latest* state, you can call a method on the controller to reload
//     // or just rely on notifyListeners from the controller.
//     // For now, let's rely on notifyListeners.
//   }

//   // The onLevelSelected method will still push to GameScreen.
//   // The unlocking logic is now entirely within GameScreen calling SettingsController.
//   void onLevelSelected(int level) async {
//     // We don't need to await a result for unlocking here anymore,
//     // as GameScreen now handles the unlock logic via SettingsController.
//     // However, keeping 'result' might be useful for other logic later.
//     final result = await Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => GameScreen(level: level)),
//     );

//     // This print will still be useful for debugging if you get a result from GameScreen
//     print('GameScreen for level $level finished. Result: $result');

//     // After returning from GameScreen, the LevelsScreen will automatically rebuild
//     // because it listens to SettingsController, and SettingsController calls notifyListeners()
//     // when a level is unlocked. So, no explicit setState or loadUnlockedLevel is needed here.
//   }

//   @override
//   Widget build(BuildContext context) {
//     // WATCH the SettingsController for changes
//     final settings = Provider.of<SettingsController>(context);
//     final highestUnlockedLevel = settings.highestUnlockedLevel; // Get it from the controller

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Select Level'),
//         backgroundColor: Colors.teal.shade700,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             tooltip: 'Reset Progress',
//             onPressed: () {
//               settings.resetProgress(); // Call reset from the controller
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text('Progress reset to Level 1')),
//               );
//             },
//           ),
//         ],
//       ),
//       body: GridView.builder(
//         padding: const EdgeInsets.all(20),
//         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 3,
//           crossAxisSpacing: 10,
//           mainAxisSpacing: 10,
//         ),
//         itemCount: 20,
//         itemBuilder: (context, index) {
//           int level = index + 1;
//           // Use the highestUnlockedLevel from the controller
//           bool isUnlocked = level <= highestUnlockedLevel;
//           bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

//           return ElevatedButton(
//             onPressed: isUnlocked ? () => onLevelSelected(level) : null,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: isUnlocked ? Colors.teal.shade600 : Colors.grey,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(
//                   'Level $level',
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: TextStyle(
//                     fontSize: 13,
//                     fontWeight: FontWeight.bold,
//                     color: isUnlocked
//                         ? Colors.white
//                         : (isDarkMode ? Colors.white70 : Colors.black54),
//                   ),
//                 ),
//                 if (!isUnlocked)
//                   Icon(
//                     Icons.lock,
//                     size: 18,
//                     color: isDarkMode ? Colors.white70 : Colors.black45,
//                   ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }