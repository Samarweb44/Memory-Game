// import 'package:flutter/material.dart';
// import 'screens/splash_screen.dart';
// import 'screens/home_screen.dart';
// import 'screens/game_screen.dart';
// import 'screens/settings_screen.dart';
// import 'screens/levels_screen.dart';

// void main() {
//   runApp(const MemoryGameApp());
// }

// class MemoryGameApp extends StatelessWidget {
//   const MemoryGameApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Memory Blink Game',
//       theme: ThemeData.dark(),
//       initialRoute: '/',
//       routes: {
//         '/': (context) => const SplashScreen(),
//         '/home': (context) => const HomeScreen(),
//         '/game': (context) => const GameScreen(level: 1),
//         '/settings': (context) => const SettingsScreen(),
//         '/levels': (context) => const LevelsScreen(),
//       },
//     );
//   }
// }



//  import 'screens/splash_screen.dart';
//  import 'screens/home_screen.dart';
//  import 'screens/game_screen.dart';
//  import 'screens/settings_screen.dart';
//  import 'screens/levels_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'controllers/settings_controller.dart';
// // import 'home_screen.dart'; // Your main screen
// void main() {
//   runApp(
//     ChangeNotifierProvider(
//       create: (_) => SettingsController(),
//       child: const MyApp(),
//     ),
//   );
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final settings = Provider.of<SettingsController>(context);

//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Memory Game',
//       theme: ThemeData(
//         brightness: Brightness.light,
//         primarySwatch: Colors.deepPurple,
//         scaffoldBackgroundColor: Colors.white,
//         // Define your light theme colors here
//       ),
//       darkTheme: ThemeData(
//         brightness: Brightness.dark,
//         primarySwatch: Colors.deepPurple,
//         scaffoldBackgroundColor: Colors.black,
//         // Define your dark theme colors here (backgrounds, buttons, text, etc.)
//       ),
//       themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
//       home: const HomeScreen(),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import 'controllers/settings_controller.dart';
// import 'screens/splash_screen.dart';
// import 'screens/home_screen.dart';
// import 'screens/game_screen.dart';
// import 'screens/settings_screen.dart';
// import 'screens/levels_screen.dart';

// void main() {
//   runApp(
//     ChangeNotifierProvider(
//       create: (_) => SettingsController(),
//       child: const MemoryGameApp(),
//     ),
//   );
// }

// class MemoryGameApp extends StatelessWidget {
//   const MemoryGameApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final settings = Provider.of<SettingsController>(context);

//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Memory Blink Game',
//       theme: ThemeData(
//         brightness: Brightness.light,
//         primarySwatch: Colors.deepPurple,
//         scaffoldBackgroundColor: Colors.white,
//       ),
//       darkTheme: ThemeData(
//         brightness: Brightness.dark,
//         primarySwatch: Colors.deepPurple,
//         scaffoldBackgroundColor: Colors.black,
//       ),
//       themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
//       initialRoute: '/', // ✅ Show splash screen first
//       routes: {
//         '/': (context) => const SplashScreen(),
//         '/home': (context) => const HomeScreen(),
//         '/game': (context) => const GameScreen(level: 1),
//         '/settings': (context) => const SettingsScreen(),
//         '/levels': (context) => const LevelsScreen(),
//       },
//     );
//   }
// }





//-------------------------------------------------------------------------
import 'package:flutter/material.dart';
// import 'package:memory/screens/Bnumber_seq.dart';
import 'package:memorush/screens/__modes_screen.dart';
import 'package:memorush/screens/Egamefive.dart';
import 'package:memorush/screens/nish_game.dart';
import 'package:memorush/screens/shadow.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
// import 'screens/Cpeecha_mat_karo.dart';
// import 'screens/number_sequence_game_screen.dart';
import 'controllers/settings_controller.dart';
import 'screens/__splash_screen.dart';
import 'screens/__home_screen.dart';
import 'screens/ball_sorting_game.dart';
import 'screens/clash_duel_screen.dart';
import 'screens/Amemorytile.dart';
import 'screens/__settings_screen.dart';
// ignore: unused_import
import 'screens/Dgamefour.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => SettingsController(),
      child: const MemoryGameApp(),
    ),
  );
}

class MemoryGameApp extends StatefulWidget {
  const MemoryGameApp({super.key});

  @override
  State<MemoryGameApp> createState() => _MemoryGameAppState();
}

class _MemoryGameAppState extends State<MemoryGameApp> with WidgetsBindingObserver {
  late SettingsController settings;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Delay to get provider after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      settings = Provider.of<SettingsController>(context, listen: false);
    });
  }

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   print('App lifecycle state changed: $state');

  //   // Defensive null check (should never be null after init)
  //   if (!mounted || settings == null) return;

  //   if (state == AppLifecycleState.paused ||
  //       state == AppLifecycleState.inactive ||
  //       state == AppLifecycleState.detached) {
  //     // Pause music on app background
  //     settings.toggleBackgroundMusic(false);
  //   } else if (state == AppLifecycleState.resumed) {
  //     // Resume music only if background music was enabled before
  //     if (settings.backgroundMusic) {
  //       settings.toggleBackgroundMusic(true);
  //     }
  //   }
  // }






  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsController>(
      builder: (context, settings, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Memory Blink Game',
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.deepPurple,
            scaffoldBackgroundColor: Colors.white,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.deepPurple,
            scaffoldBackgroundColor: Colors.black,
          ),
          themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          initialRoute: '/', // splash screen first
          routes: {
            '/': (context) => const SplashScreen(),
            '/home': (context) => const HomeScreen(),
            '/game': (context) => const GameScreen(),
            '/nish': (context) => const TicTacToeScreen(),
            // '/shadow': (context) => const BrainGameScreen(),
            // '/sound_echo_game': (context) => const DanceBattleGame(),
            '/number_sequence': (context) => const NumberSequenceGameScreen(level: 1),
            '/shadow': (context) => const ColorConfusionGame(),
            '/ball_sorting': (context) => const BallSortingGame(),
            '/clash_duel': (context) => const ColorClashDuel(),

            '/settings': (context) => const SettingsScreen(),
              '/modes': (context) => const ModesScreen(),
            // '/levels': (context) => const LevelsScreen(),


            //  '/game': (context) => const GameScreen(level: 1),
            // '/settings': (context) => const SettingsScreen(),
            //   '/modes': (context) => const LevelsScreen(),
            // '/levels': (context) => const LevelsScreen(),
          },
        );
      },
    );
  }
}
