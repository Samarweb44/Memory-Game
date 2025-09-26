// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '/screens/profile_screen.dart';
// import 'Amemorytile.dart';
// import '__levels_screen.dart';
// import '__settings_screen.dart';
// import '__modes_screen.dart';
// import '/screens/auth_screen.dart'; // This will be our new auth screen

// import '../controllers/settings_controller.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen>
//     with SingleTickerProviderStateMixin {
//   late AudioPlayer _player;
//   late SettingsController _settings;
//   late AnimationController _animationController;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   User? _currentUser;

//   @override
//   void initState() {
//     super.initState();
//     _player = AudioPlayer();
//     _settings = Provider.of<SettingsController>(context, listen: false);
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 60),
//     )..repeat();

//     // Listen for auth state changes
//     _auth.authStateChanges().listen((User? user) {
//       setState(() {
//         _currentUser = user;
//       });
//     });
//   }

//   Future<void> _signOut() async {
//     try {
//       await _auth.signOut();
//       if (!mounted) return;
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Signed out successfully')));
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error signing out: $e')));
//     }
//   }

//   @override
//   void dispose() {
//     _player.dispose();
//     _animationController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final Color iconColor = isDark ? Colors.white : Colors.black;

//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors:
//                 isDark
//                     ? [Colors.black, Colors.black]
//                     : [
//                       const Color.fromARGB(255, 255, 166, 107),
//                       const Color.fromARGB(255, 199, 133, 250),
//                     ],
//           ),
//         ),
//         child: Stack(
//           children: [
//             // Background animation
//             AnimatedBuilder(
//               animation: _animationController,
//               builder: (context, child) {
//                 return CustomPaint(
//                   painter: _AnimatedSpacePainter(
//                     animation: _animationController,
//                     isDark: isDark,
//                   ),
//                   child: Container(),
//                 );
//               },
//             ),

//             // User profile or login button (top-left)
//             Positioned(
//               top: 40,
//               left: 20,
//               child:
//                   _currentUser != null
//                       ? // Replace the existing PopupMenuButton in your HomeScreen with this:
//                       PopupMenuButton(
//                         icon: CircleAvatar(
//                           backgroundColor: Colors.deepPurple,
//                           child: Text(
//                             _currentUser!.email!.substring(0, 1).toUpperCase(),
//                             style: const TextStyle(color: Colors.white),
//                           ),
//                         ),
//                         itemBuilder:
//                             (context) => [
//                               PopupMenuItem(
//                                 child: const Text('Profile'),
//                                 onTap: () {
//                                   // Need to delay the navigation to allow the menu to close
//                                   Future.delayed(Duration.zero, () {
//                                     Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder: (_) => const ProfileScreen(),
//                                       ),
//                                     );
//                                   });
//                                 },
//                               ),
//                               PopupMenuItem(
//                                 child: const Text('Sign out'),
//                                 onTap: _signOut,
//                               ),
//                             ],
//                       )
//                       : IconButton(
//                         icon: Icon(Icons.login, color: iconColor, size: 30),
//                         onPressed: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => const AuthScreen(),
//                             ),
//                           );
//                         },
//                       ),
//             ),

//             // Settings button (top-right)
//             Positioned(
//               top: 40,
//               right: 20,
//               child: IconButton(
//                 icon: Icon(Icons.settings, color: iconColor, size: 30),
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (_) => const SettingsScreen()),
//                   );
//                 },
//               ),
//             ),

//             // Main content
//             Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   // Game start button
//                   GestureDetector(
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (_) => const ModesScreen()),
//                       );
//                     },
//                     child: Container(
//                       width: 200,
//                       height: 200,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         color: Colors.white.withOpacity(0.1),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.blueAccent.withOpacity(0.6),
//                             blurRadius: 30,
//                             spreadRadius: 15,
//                           ),
//                         ],
//                       ),
//                       child: Center(
//                         child: Text(
//                           'START',
//                           style: TextStyle(
//                             fontSize: 36,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                             shadows: [
//                               Shadow(
//                                 blurRadius: 10,
//                                 color: Colors.black,
//                                 offset: const Offset(1, 1),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),

//                   // Welcome message (if logged in)
//                   if (_currentUser != null)
//                     Padding(
//                       padding: const EdgeInsets.only(top: 20),
//                       child: Column(
//                         children: [
//                           Text(
//                             'Welcome, ${_currentUser!.email!.split('@')[0]}!',
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontSize: 18,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           const Text(
//                             'Your scores will be saved to the leaderboard',
//                             style: TextStyle(
//                               color: Colors.white70,
//                               fontSize: 14,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _AnimatedSpacePainter extends CustomPainter {
//   final Animation<double> animation;
//   final bool isDark;
//   _AnimatedSpacePainter({required this.animation, required this.isDark});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final Paint starPaint =
//         Paint()
//           ..color =
//               isDark
//                   ? Colors.white.withOpacity(0.8)
//                   : Colors.black.withOpacity(0.7);
//     final Random random = Random(42);
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
//   bool shouldRepaint(covariant _AnimatedSpacePainter oldDelegate) => true;
// }
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '__settings_screen.dart';
import '__modes_screen.dart';
import '/screens/auth_screen.dart';
import '/screens/profile_screen.dart';
import '../controllers/settings_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AudioPlayer _player;
  late AnimationController _animationController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    );
    
    // Check initial animation setting and start if enabled
    final settings = Provider.of<SettingsController>(context, listen: false);
    if (settings.enableAnimations) {
      _animationController.repeat();
    }

    _auth.authStateChanges().listen((User? user) {
      setState(() {
        _currentUser = user;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen to animation setting changes
    final settings = Provider.of<SettingsController>(context);
    if (settings.enableAnimations) {
      _animationController.repeat();
    } else {
      _animationController.stop();
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signed out successfully')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')));
    }
  }

  Future<String?> _getProfileImageUrl() async {
    if (_currentUser == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(_currentUser!.uid).get();
      return doc.data()?['profileImageUrl'];
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsController>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color iconColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [Colors.black, Colors.black]
                : [
                    const Color.fromARGB(255, 255, 166, 107),
                    const Color.fromARGB(255, 199, 133, 250),
                  ],
          ),
        ),
        child: Stack(
          children: [
            // Only show animation if enabled in settings
            if (settings.enableAnimations)
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _AnimatedSpacePainter(
                      animation: _animationController,
                      isDark: isDark,
                    ),
                    child: Container(),
                  );
                },
              ),

            Positioned(
              top: 40,
              left: 20,
              child: _currentUser != null
                  ? FutureBuilder<String?>(
                      future: _getProfileImageUrl(),
                      builder: (context, snapshot) {
                        final theme = Theme.of(context);
                        final isDark = theme.brightness == Brightness.dark;

                        return PopupMenuButton<String>(
                          position: PopupMenuPosition.under,
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          color: isDark ? Colors.grey.shade900 : Colors.white,
                          surfaceTintColor:
                              isDark ? Colors.grey.shade900 : Colors.white,
                          offset: const Offset(0, 10),
                          icon: CircleAvatar(
                            radius: 20,
                            backgroundColor: theme.colorScheme.primary,
                            backgroundImage: snapshot.hasData &&
                                    snapshot.data != null &&
                                    snapshot.data!.isNotEmpty
                                ? NetworkImage(snapshot.data!)
                                : null,
                            child: snapshot.hasData &&
                                    snapshot.data != null &&
                                    snapshot.data!.isNotEmpty
                                ? null
                                : Text(
                                    _currentUser!.email!
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: TextStyle(
                                      color: theme.colorScheme.onPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                          onSelected: (value) {
                            if (value == 'profile') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ProfileScreen(),
                                ),
                              );
                            } else if (value == 'signout') {
                              _signOut();
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem<String>(
                              value: 'profile',
                              height: 48,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    size: 22,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Profile',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuDivider(
                              height: 4,
                              color: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade200,
                            ),
                            PopupMenuItem<String>(
                              value: 'signout',
                              height: 48,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.logout,
                                    size: 22,
                                    color: theme.colorScheme.error,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Sign out',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    )
                  : IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.account_circle,
                          color: iconColor,
                          size: 30,
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AuthScreen(),
                          ),
                        );
                      },
                    ),
            ),

            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: Icon(Icons.settings, color: iconColor, size: 30),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ),

            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ModesScreen()),
                      );
                    },
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.6),
                            blurRadius: 30,
                            spreadRadius: 15,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'START',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 10,
                                color: Colors.black,
                                offset: const Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (_currentUser != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Column(
                        children: [
                          Text(
                            'Welcome, ${_currentUser!.email!.split('@')[0]}!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'TO MEMORUSH',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedSpacePainter extends CustomPainter {
  final Animation<double> animation;
  final bool isDark;
  _AnimatedSpacePainter({required this.animation, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint starPaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.8) : Colors.black.withOpacity(0.7);
    final Random random = Random(42);
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
  bool shouldRepaint(covariant _AnimatedSpacePainter oldDelegate) => true;
}
// import 'dart:math';/////////////////////////////
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// import '__settings_screen.dart';
// import '__modes_screen.dart';
// import '/screens/auth_screen.dart';
// import '/screens/profile_screen.dart';
// import '../controllers/settings_controller.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen>
//     with SingleTickerProviderStateMixin {
//   late AudioPlayer _player;
//   late SettingsController _settings;
//   late AnimationController _animationController;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   User? _currentUser;

//   @override
//   void initState() {
//     super.initState();
//     _player = AudioPlayer();
//     _settings = Provider.of<SettingsController>(context, listen: false);
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 60),
//     )..repeat();

//     _auth.authStateChanges().listen((User? user) {
//       setState(() {
//         _currentUser = user;
//       });
//     });
//   }

//   Future<void> _signOut() async {
//     try {
//       await _auth.signOut();
//       if (!mounted) return;
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Signed out successfully')));
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error signing out: $e')));
//     }
//   }

//   Future<String?> _getProfileImageUrl() async {
//     if (_currentUser == null) return null;

//     try {
//       final doc =
//           await _firestore.collection('users').doc(_currentUser!.uid).get();
//       return doc.data()?['profileImageUrl'];
//     } catch (e) {
//       return null;
//     }
//   }

//   @override
//   void dispose() {
//     _player.dispose();
//     _animationController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final Color iconColor = isDark ? Colors.white : Colors.black;

//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors:
//                 isDark
//                     ? [Colors.black, Colors.black]
//                     : [
//                       const Color.fromARGB(255, 255, 166, 107),
//                       const Color.fromARGB(255, 199, 133, 250),
//                     ],
//           ),
//         ),
//         child: Stack(
//           children: [
//             AnimatedBuilder(
//               animation: _animationController,
//               builder: (context, child) {
//                 return CustomPaint(
//                   painter: _AnimatedSpacePainter(
//                     animation: _animationController,
//                     isDark: isDark,
//                   ),
//                   child: Container(),
//                 );
//               },
//             ),

//             Positioned(
//               top: 40,
//               left: 20,
//               child:
//                   _currentUser != null
//                       ? FutureBuilder<String?>(
//                         future: _getProfileImageUrl(),
//                         builder: (context, snapshot) {
//                           final theme = Theme.of(context);
//                           final isDark = theme.brightness == Brightness.dark;

//                           return PopupMenuButton<String>(
//                             position: PopupMenuPosition.under,
//                             elevation: 8,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               side: BorderSide(
//                                 color:
//                                     isDark
//                                         ? Colors.grey.shade800
//                                         : Colors.grey.shade300,
//                                 width: 1,
//                               ),
//                             ),
//                             color: isDark ? Colors.grey.shade900 : Colors.white,
//                             surfaceTintColor:
//                                 isDark ? Colors.grey.shade900 : Colors.white,
//                             offset: const Offset(0, 10),

//                             // Avatar button
//                             icon: CircleAvatar(
//                               radius: 20,
//                               backgroundColor: theme.colorScheme.primary,
//                               backgroundImage:
//                                   snapshot.hasData &&
//                                           snapshot.data != null &&
//                                           snapshot.data!.isNotEmpty
//                                       ? NetworkImage(snapshot.data!)
//                                       : null,
//                               child:
//                                   snapshot.hasData &&
//                                           snapshot.data != null &&
//                                           snapshot.data!.isNotEmpty
//                                       ? null
//                                       : Text(
//                                         _currentUser!.email!
//                                             .substring(0, 1)
//                                             .toUpperCase(),
//                                         style: TextStyle(
//                                           color: theme.colorScheme.onPrimary,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                             ),

//                             // Handle selections
//                             onSelected: (value) {
//                               if (value == 'profile') {
//                                 Navigator.push(
//                                   context,
//                                   MaterialPageRoute(
//                                     builder: (_) => const ProfileScreen(),
//                                   ),
//                                 );
//                               } else if (value == 'signout') {
//                                 _signOut();
//                               }
//                             },

//                             // Menu items
//                             itemBuilder:
//                                 (context) => [
//                                   PopupMenuItem<String>(
//                                     value: 'profile',
//                                     height: 48,
//                                     child: Row(
//                                       children: [
//                                         Icon(
//                                           Icons.person_outline,
//                                           size: 22,
//                                           color: theme.colorScheme.primary,
//                                         ),
//                                         const SizedBox(width: 12),
//                                         Text(
//                                           'Profile',
//                                           style: TextStyle(
//                                             fontSize: 15,
//                                             color: theme.colorScheme.onSurface,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                   PopupMenuDivider(
//                                     height: 4,
//                                     color:
//                                         isDark
//                                             ? Colors.grey.shade800
//                                             : Colors.grey.shade200,
//                                   ),
//                                   PopupMenuItem<String>(
//                                     value: 'signout',
//                                     height: 48,
//                                     child: Row(
//                                       children: [
//                                         Icon(
//                                           Icons.logout,
//                                           size: 22,
//                                           color: theme.colorScheme.error,
//                                         ),
//                                         const SizedBox(width: 12),
//                                         Text(
//                                           'Sign out',
//                                           style: TextStyle(
//                                             fontSize: 15,
//                                             color: theme.colorScheme.onSurface,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ],
//                           );
//                         },
//                       )
//                      : IconButton(
//                         icon: Container(
//                           padding: const EdgeInsets.all(6),
//                           // decoration: BoxDecoration(
//                           //   color: Colors.white.withOpacity(0.2),
//                           //   borderRadius: BorderRadius.circular(10),
//                           //   border: Border.all(
//                           //     color: iconColor.withOpacity(0.5),
//                           //     width: 1,
//                           //   ),
//                           // ),
//                           child: Icon(
//                             Icons.account_circle, // Changed from Icons.login
//                             color: iconColor,
//                             size: 30,
//                           ),
//                         ),
//                         onPressed: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => const AuthScreen(),
//                             ),
//                           );
//                         },
//                       ),
//             ),

//             Positioned(
//               top: 40,
//               right: 20,
//               child: IconButton(
//                 icon: Icon(Icons.settings, color: iconColor, size: 30),
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (_) => const SettingsScreen()),
//                   );
//                 },
//               ),
//             ),

//             Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   GestureDetector(
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (_) => const ModesScreen()),
//                       );
//                     },
//                     child: Container(
//                       width: 200,
//                       height: 200,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         color: Colors.white.withOpacity(0.1),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.blueAccent.withOpacity(0.6),
//                             blurRadius: 30,
//                             spreadRadius: 15,
//                           ),
//                         ],
//                       ),
//                       child: Center(
//                         child: Text(
//                           'START',
//                           style: TextStyle(
//                             fontSize: 36,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                             shadows: [
//                               Shadow(
//                                 blurRadius: 10,
//                                 color: Colors.black,
//                                 offset: const Offset(1, 1),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),

//                   if (_currentUser != null)
//                     Padding(
//                       padding: const EdgeInsets.only(top: 20),
//                       child: Column(
//                         children: [
//                           Text(
//                             'Welcome, ${_currentUser!.email!.split('@')[0]}!',
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontSize: 18,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           const Text(
//                             'TO MEMORUSH',
//                             style: TextStyle(
//                               color: Colors.white70,
//                               fontSize: 14,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _AnimatedSpacePainter extends CustomPainter {
//   final Animation<double> animation;
//   final bool isDark;
//   _AnimatedSpacePainter({required this.animation, required this.isDark});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final Paint starPaint =
//         Paint()
//           ..color =
//               isDark
//                   ? Colors.white.withOpacity(0.8)
//                   : Colors.black.withOpacity(0.7);
//     final Random random = Random(42);
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
//   bool shouldRepaint(covariant _AnimatedSpacePainter oldDelegate) => true;
// }





// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:audioplayers/audioplayers.dart';

// // ignore: unused_import
// import 'Amemorytile.dart';
// // ignore: unused_import
// import '__levels_screen.dart';
// import '__settings_screen.dart';
// import '__modes_screen.dart';

// import '../controllers/settings_controller.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen>
//     with SingleTickerProviderStateMixin {
//   // ignore: unused_field
//   late AudioPlayer _player;
//   // ignore: unused_field
//   late SettingsController _settings;
//   late AnimationController _animationController;

//   @override
//   void initState() {
//     super.initState();
//     _player = AudioPlayer();
//     _settings = Provider.of<SettingsController>(context, listen: false);
//     // _playBackgroundMusic();
//     // _settings.addListener(_handleSettingsChange);

//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 60),
//     )..repeat();
//   }

//   // void _handleSettingsChange() async {
//   //   if (_settings.backgroundMusic) {
//   //     await _player.setReleaseMode(ReleaseMode.loop);
//   //     await _player.play(AssetSource('audio/background_music.mp3'));
//   //   } else {
//   //     await _player.stop();
//   //   }
//   // }

//   // Future<void> _playBackgroundMusic() async {
//   //   if (_settings.backgroundMusic) {
//   //     await _player.setReleaseMode(ReleaseMode.loop);
//   //     await _player.play(AssetSource('audio/background_music.mp3'));
//   //   }
//   // }

//   // @override
//   // void dispose() {
//   //   _settings.removeListener(_handleSettingsChange);
//   //   _player.stop();
//   //   _player.dispose();
//   //   _animationController.dispose();
//   //   super.dispose();
//   // }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: isDark ? [Colors.black, Colors.black] : [const Color.fromARGB(255, 255, 166, 107), const Color.fromARGB(255, 199, 133, 250)],
//           ),
//         ),
//         child: Stack(
//           children: [
//             AnimatedBuilder(
//               animation: _animationController,
//               builder: (context, child) {
//                 return CustomPaint(
//                   painter: _AnimatedSpacePainter(
//                     animation: _animationController,
//                     isDark: isDark,
//                   ),
//                   child: Container(),
//                 );
//               },
//             ),
//             Positioned(
//               top: 40,
//               right: 20,
//               child: IconButton(
//                 icon: Icon(Icons.settings, color: isDark ? Colors.white : Colors.black, size: 30),
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (_) => const SettingsScreen()),
//                   );
//                 },
//               ),
//             ),
//             Center(
//               child: GestureDetector(
//                 onTap: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (_) => const ModesScreen()),
//                   );
//                 },
//                 child: Container(
//                   width: 200,
//                   height: 200,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: Colors.white.withOpacity(0.1),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.blueAccent.withOpacity(0.6),
//                         blurRadius: 30,
//                         spreadRadius: 15,
//                       ),
//                     ],
//                   ),
//                   child: Center(
//                     child: Text(
//                       'START',
//                       style: TextStyle(
//                         fontSize: 36,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                         shadows: [
//                           Shadow(
//                             blurRadius: 10,
//                             color: Colors.black,
//                             offset: Offset(1, 1),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _AnimatedSpacePainter extends CustomPainter {
//   final Animation<double> animation;
//   final bool isDark;
//   _AnimatedSpacePainter({required this.animation, required this.isDark});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final Paint starPaint = Paint()
//       ..color = isDark ? Colors.white.withOpacity(0.8) : Colors.black.withOpacity(0.7);
//     final Random random = Random(42);
//     for (int i = 0; i < 100; i++) {
//       final double x = random.nextDouble() * size.width;
//       final double y = (random.nextDouble() * size.height +
//               animation.value * size.height) %
//           size.height;
//       final double radius = random.nextDouble() * 2 + 1;
//       canvas.drawCircle(Offset(x, y), radius, starPaint);
//     }
//   }

//   @override
//   bool shouldRepaint(covariant _AnimatedSpacePainter oldDelegate) => true;
// }