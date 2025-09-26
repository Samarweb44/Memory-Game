import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../controllers/settings_controller.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _email = '';
  String _password = '';
  String _username = '';
  
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    );
    
    // Check initial animation setting
    final settings = Provider.of<SettingsController>(context, listen: false);
    if (settings.enableAnimations) {
      _animationController.repeat();
    }
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    _formKey.currentState!.save();

    try {
      if (_isLogin) {
        await _auth.signInWithEmailAndPassword(
          email: _email,
          password: _password,
        );
      } else {
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: _email,
          password: _password,
        );
        
        if (_username.isNotEmpty) {
          await userCredential.user?.updateDisplayName(_username);
          await userCredential.user?.reload();
          
          await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user?.uid)
            .set({
              'username': _username,
              'highScore': 0,
              'createdAt': FieldValue.serverTimestamp(),
              'profileImageUrl': '',
            });
        }
      }

      if (mounted) {
        if (!_isLogin) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome ${_username.isNotEmpty ? _username : 'Player'}!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Authentication failed';
      if (e.code == 'weak-password') {
        message = 'Password should be at least 6 characters';
      } else if (e.code == 'email-already-in-use') {
        message = 'Email is already registered';
      } else if (e.code == 'user-not-found') {
        message = 'No user found with this email';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  
 @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = Provider.of<SettingsController>(context);

    return Scaffold(
      body: Stack(
        children: [
          // Static gradient background (always visible)
          Container(
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
          ),
          
          // Animated stars - only show if animations are enabled
          if (settings.enableAnimations)
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _AnimatedStarsPainter(
                    animation: _animationController,
                    isDark: isDark,
                  ),
                  child: Container(),
                );
              },
            ),
          
          // Content (unchanged)
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Header
                    Text(
                      _isLogin ? 'Sign In' : 'Register \n      &',
                      style: TextStyle(
                        fontSize: 32,
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
                    const SizedBox(height: 8),
                    Text(
                      _isLogin ? 'Continue your game journey' : 'Start your adventure',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Form container
                    Container(
                      width: 400,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade800.withOpacity(0.8) : Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            if (!_isLogin)
                              TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Username',
                                  labelStyle: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                  prefixIcon: Icon(Icons.person, color: isDark ? Colors.blueAccent : Colors.blue.shade800),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: isDark ? Colors.grey.shade700.withOpacity(0.6) : Colors.grey.shade50,
                                ),
                                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                validator: (value) => value!.isEmpty ? 'Enter a username' : null,
                                onSaved: (value) => _username = value!,
                              ),
                            if (!_isLogin) const SizedBox(height: 16),
                            
                            // Email field
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Email',
                                labelStyle: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                prefixIcon: Icon(Icons.email, color: isDark ? Colors.blueAccent : Colors.blue.shade800),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: isDark ? Colors.grey.shade700.withOpacity(0.6) : Colors.grey.shade50,
                              ),
                              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) => 
                                  !value!.contains('@') ? 'Enter a valid email' : null,
                              onSaved: (value) => _email = value!,
                            ),
                            const SizedBox(height: 16),
                            
                            // Password field
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                prefixIcon: Icon(Icons.lock, color: isDark ? Colors.blueAccent : Colors.blue.shade800),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: isDark ? Colors.white70 : Colors.black54,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: isDark ? Colors.grey.shade700.withOpacity(0.6) : Colors.grey.shade50,
                              ),
                              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                              obscureText: _obscurePassword,
                              validator: (value) => 
                                  value!.length < 6 ? 'Password must be at least 6 characters' : null,
                              onSaved: (value) => _password = value!,
                            ),
                            const SizedBox(height: 24),
                            
                            // Submit button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? Colors.blueAccent : Colors.blue.shade800,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 5,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        _isLogin ? 'Sign In' : 'Register',
                                        style: const TextStyle(
                                          fontSize: 16,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Toggle button
                            TextButton(
                              onPressed: _isLoading ? null : () => setState(() => _isLogin = !_isLogin),
                              child: Text(
                                _isLogin 
                                    ? 'Create new account' 
                                    : 'Already have an account? Sign in',
                                style: TextStyle(
                                  color: isDark ? Colors.orangeAccent : Colors.orange.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedStarsPainter extends CustomPainter {
  final Animation<double> animation;
  final bool isDark;
  _AnimatedStarsPainter({required this.animation, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint starPaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.8) : Colors.black.withOpacity(0.7);
    final Random random = Random(42);
    for (int i = 0; i < 100; i++) {
      final double x = random.nextDouble() * size.width;
      final double y = (random.nextDouble() * size.height +
              animation.value * size.height) %
          size.height;
      final double radius = random.nextDouble() * 2 + 1;
      canvas.drawCircle(Offset(x, y), radius, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AnimatedStarsPainter oldDelegate) => true;
}

// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class AuthScreen extends StatefulWidget {
//   const AuthScreen({super.key});

//   @override
//   State<AuthScreen> createState() => _AuthScreenState();
// }

// class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
//   final _auth = FirebaseAuth.instance;
//   final _formKey = GlobalKey<FormState>();
//   bool _isLogin = true;
//   bool _isLoading = false;
//   bool _obscurePassword = true;
//   String _email = '';
//   String _password = '';
//   String _username = '';
  
//   late AnimationController _animationController;

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

//   Future<void> _submit() async {
//     if (!_formKey.currentState!.validate()) return;
    
//     setState(() => _isLoading = true);
//     _formKey.currentState!.save();

//     try {
//       if (_isLogin) {
//         await _auth.signInWithEmailAndPassword(
//           email: _email,
//           password: _password,
//         );
//       } else {
//         final userCredential = await _auth.createUserWithEmailAndPassword(
//           email: _email,
//           password: _password,
//         );
        
//         if (_username.isNotEmpty) {
//           await userCredential.user?.updateDisplayName(_username);
//           await userCredential.user?.reload();
          
//           await FirebaseFirestore.instance
//             .collection('users')
//             .doc(userCredential.user?.uid)
//             .set({
//               'username': _username,
//               'highScore': 0,
//               'createdAt': FieldValue.serverTimestamp(),
//               'profileImageUrl': '',
//             });
//         }
//       }

//       if (mounted) {
//         if (!_isLogin) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('Welcome ${_username.isNotEmpty ? _username : 'Player'}!'),
//               backgroundColor: Colors.green,
//             ),
//           );
//         }
//         Navigator.pop(context);
//       }
//     } on FirebaseAuthException catch (e) {
//       String message = 'Authentication failed';
//       if (e.code == 'weak-password') {
//         message = 'Password should be at least 6 characters';
//       } else if (e.code == 'email-already-in-use') {
//         message = 'Email is already registered';
//       } else if (e.code == 'user-not-found') {
//         message = 'No user found with this email';
//       } else if (e.code == 'wrong-password') {
//         message = 'Incorrect password';
//       } else if (e.code == 'invalid-email') {
//         message = 'Invalid email address';
//       }
      
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(message),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('An error occurred: ${e.toString()}'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final isDark = theme.brightness == Brightness.dark;

//     return Scaffold(
//       body: Stack(
//         children: [
//           // Animated background
//           AnimatedBuilder(
//             animation: _animationController,
//             builder: (context, child) {
//               return CustomPaint(
//                 painter: _AnimatedSpacePainter(
//                   animation: _animationController,
//                   isDark: isDark,
//                 ),
//                 child: Container(),
//               );
//             },
//           ),
          
//           // Content
//           Center(
//             child: SingleChildScrollView(
//               child: Padding(
//                 padding: const EdgeInsets.all(24),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     // Header
//                     Text(
//                       _isLogin ? 'Sign In' : 'Register \n      &',
//                       style: TextStyle(
//                         fontSize: 32,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                         shadows: [
//                           Shadow(
//                             blurRadius: 10,
//                             color: Colors.black,
//                             offset: const Offset(1, 1),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       _isLogin ? 'Continue your game journey' : 'Start your adventure',
//                       style: TextStyle(
//                         fontSize: 16,
//                         color: Colors.white70,
//                       ),
//                     ),
//                     const SizedBox(height: 40),
                    
//                     // Form container
//                     Container(
//                       width: 400,
//                       padding: const EdgeInsets.all(24),
//                       decoration: BoxDecoration(
//                         color: isDark ? Colors.grey.shade800.withOpacity(0.8) : Colors.white.withOpacity(0.8),
//                         borderRadius: BorderRadius.circular(16),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.2),
//                             blurRadius: 20,
//                             spreadRadius: 5,
//                           ),
//                         ],
//                       ),
//                       child: Form(
//                         key: _formKey,
//                         child: Column(
//                           children: [
//                             if (!_isLogin)
//                               TextFormField(
//                                 decoration: InputDecoration(
//                                   labelText: 'Username',
//                                   labelStyle: TextStyle(color: isDark ? Colors.white : Colors.black87),
//                                   prefixIcon: Icon(Icons.person, color: isDark ? Colors.blueAccent : Colors.blue.shade800),
//                                   border: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                   filled: true,
//                                   fillColor: isDark ? Colors.grey.shade700.withOpacity(0.6) : Colors.grey.shade50,
//                                 ),
//                                 style: TextStyle(color: isDark ? Colors.white : Colors.black87),
//                                 validator: (value) => value!.isEmpty ? 'Enter a username' : null,
//                                 onSaved: (value) => _username = value!,
//                               ),
//                             if (!_isLogin) const SizedBox(height: 16),
                            
//                             // Email field
//                             TextFormField(
//                               decoration: InputDecoration(
//                                 labelText: 'Email',
//                                 labelStyle: TextStyle(color: isDark ? Colors.white : Colors.black87),
//                                 prefixIcon: Icon(Icons.email, color: isDark ? Colors.blueAccent : Colors.blue.shade800),
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                                 filled: true,
//                                 fillColor: isDark ? Colors.grey.shade700.withOpacity(0.6) : Colors.grey.shade50,
//                               ),
//                               style: TextStyle(color: isDark ? Colors.white : Colors.black87),
//                               keyboardType: TextInputType.emailAddress,
//                               validator: (value) => 
//                                   !value!.contains('@') ? 'Enter a valid email' : null,
//                               onSaved: (value) => _email = value!,
//                             ),
//                             const SizedBox(height: 16),
                            
//                             // Password field
//                             TextFormField(
//                               decoration: InputDecoration(
//                                 labelText: 'Password',
//                                 labelStyle: TextStyle(color: isDark ? Colors.white : Colors.black87),
//                                 prefixIcon: Icon(Icons.lock, color: isDark ? Colors.blueAccent : Colors.blue.shade800),
//                                 suffixIcon: IconButton(
//                                   icon: Icon(
//                                     _obscurePassword ? Icons.visibility_off : Icons.visibility,
//                                     color: isDark ? Colors.white70 : Colors.black54,
//                                   ),
//                                   onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
//                                 ),
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                                 filled: true,
//                                 fillColor: isDark ? Colors.grey.shade700.withOpacity(0.6) : Colors.grey.shade50,
//                               ),
//                               style: TextStyle(color: isDark ? Colors.white : Colors.black87),
//                               obscureText: _obscurePassword,
//                               validator: (value) => 
//                                   value!.length < 6 ? 'Password must be at least 6 characters' : null,
//                               onSaved: (value) => _password = value!,
//                             ),
//                             const SizedBox(height: 24),
                            
//                             // Submit button
//                             SizedBox(
//                               width: double.infinity,
//                               height: 50,
//                               child: ElevatedButton(
//                                 onPressed: _isLoading ? null : _submit,
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: isDark ? Colors.blueAccent : Colors.blue.shade800,
//                                   foregroundColor: Colors.white,
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                   elevation: 5,
//                                 ),
//                                 child: _isLoading
//                                     ? const SizedBox(
//                                         width: 20,
//                                         height: 20,
//                                         child: CircularProgressIndicator(
//                                           strokeWidth: 2,
//                                           color: Colors.white,
//                                         ),
//                                       )
//                                     : Text(
//                                         _isLogin ? 'Sign In' : 'Register',
//                                         style: const TextStyle(
//                                           fontSize: 16,
//                                         ),
//                                       ),
//                               ),
//                             ),
//                             const SizedBox(height: 16),
                            
//                             // Toggle button
//                             TextButton(
//                               onPressed: _isLoading ? null : () => setState(() => _isLogin = !_isLogin),
//                               child: Text(
//                                 _isLogin 
//                                     ? 'Create new account' 
//                                     : 'Already have an account? Sign in',
//                                 style: TextStyle(
//                                   color: isDark ? Colors.orangeAccent : Colors.orange.shade800,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
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
//     final gradient = LinearGradient(
//       begin: Alignment.topCenter,
//       end: Alignment.bottomCenter,
//       colors: isDark
//           ? [Colors.black, Colors.black]
//           : [
//               const Color.fromARGB(255, 255, 166, 107),
//               const Color.fromARGB(255, 199, 133, 250),
//             ],
//     );
    
//     final rect = Rect.fromPoints(Offset.zero, Offset(size.width, size.height));
//     final paint = Paint()..shader = gradient.createShader(rect);
//     canvas.drawRect(rect, paint);

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


// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class AuthScreen extends StatefulWidget {
//   const AuthScreen({super.key});

//   @override
//   State<AuthScreen> createState() => _AuthScreenState();
// }

// class _AuthScreenState extends State<AuthScreen> {
//   final _auth = FirebaseAuth.instance;
//   final _formKey = GlobalKey<FormState>();
//   bool _isLogin = true;
//   bool _isLoading = false;
//   String _email = '';
//   String _password = '';
//   String _username = '';

// Future<void> _submit() async {
//   if (!_formKey.currentState!.validate()) return;
  
//   setState(() => _isLoading = true);
//   _formKey.currentState!.save();

//   try {
//     if (_isLogin) {
//       // Login existing user
//       await _auth.signInWithEmailAndPassword(
//         email: _email,
//         password: _password,
//       );
//     } else {
//       // Register new user
//       final userCredential = await _auth.createUserWithEmailAndPassword(
//         email: _email,
//         password: _password,
//       );
      
//       // Update user profile with username
//       if (_username.isNotEmpty) {
//         await userCredential.user?.updateDisplayName(_username);
//         await userCredential.user?.reload();
        
//         // Create user document in Firestore
//         await FirebaseFirestore.instance
//           .collection('users')
//           .doc(userCredential.user?.uid)
//           .set({
//             'username': _username,
//             'highScore': 0,
//             'createdAt': FieldValue.serverTimestamp(),
//           });
//       }
//     }

//     if (mounted) {
//       if (!_isLogin) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Welcome ${_username.isNotEmpty ? _username : 'Player'}!'),
//             duration: const Duration(seconds: 2),
//           ),
//         );
//       }
//       Navigator.pop(context);
//     }
//   }  on FirebaseAuthException catch (e) {
//     String message = 'Authentication failed';
//     if (e.code == 'weak-password') {
//       message = 'Password should be at least 6 characters';
//     } else if (e.code == 'email-already-in-use') {
//       message = 'Email is already registered';
//     } else if (e.code == 'user-not-found') {
//       message = 'No user found with this email';
//     } else if (e.code == 'wrong-password') {
//       message = 'Incorrect password';
//     } else if (e.code == 'invalid-email') {
//       message = 'Invalid email address';
//     }
    
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(message),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   } catch (e) {
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('An error occurred: ${e.toString()}'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   } finally {
//     if (mounted) setState(() => _isLoading = false);
//   }
// }
//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(_isLogin ? 'Sign In' : 'Register'),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: isDark
//                 ? [Colors.black, Colors.black]
//                 : [
//                     const Color.fromARGB(255, 255, 166, 107),
//                     const Color.fromARGB(255, 199, 133, 250),
//                   ],
//           ),
//         ),
//         child: Center(
//           child: SingleChildScrollView(
//             child: Padding(
//               padding: const EdgeInsets.all(20),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     if (!_isLogin)
//                       TextFormField(
//                         decoration: InputDecoration(
//                           labelText: 'Username',
//                           labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
//                           prefixIcon: Icon(Icons.person, color: isDark ? Colors.white70 : Colors.black54),
//                         ),
//                         style: TextStyle(color: isDark ? Colors.white : Colors.black),
//                         validator: (value) => value!.isEmpty ? 'Enter a username' : null,
//                         onSaved: (value) => _username = value!,
//                       ),
//                     const SizedBox(height: 20),
//                     TextFormField(
//                       decoration: InputDecoration(
//                         labelText: 'Email',
//                         labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
//                         prefixIcon: Icon(Icons.email, color: isDark ? Colors.white70 : Colors.black54),
//                       ),
//                       style: TextStyle(color: isDark ? Colors.white : Colors.black),
//                       keyboardType: TextInputType.emailAddress,
//                       validator: (value) => 
//                           !value!.contains('@') ? 'Enter a valid email' : null,
//                       onSaved: (value) => _email = value!,
//                     ),
//                     const SizedBox(height: 20),
//                     TextFormField(
//                       decoration: InputDecoration(
//                         labelText: 'Password',
//                         labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
//                         prefixIcon: Icon(Icons.lock, color: isDark ? Colors.white70 : Colors.black54),
//                       ),
//                       style: TextStyle(color: isDark ? Colors.white : Colors.black),
//                       obscureText: true,
//                       validator: (value) => 
//                           value!.length < 6 ? 'Password must be at least 6 characters' : null,
//                       onSaved: (value) => _password = value!,
//                     ),
//                     const SizedBox(height: 30),
//                     _isLoading
//                         ? const CircularProgressIndicator()
//                         : ElevatedButton(
//                             onPressed: _submit,
//                             style: ElevatedButton.styleFrom(
//                               minimumSize: const Size(double.infinity, 50),
//                               backgroundColor: isDark ? Colors.deepPurple : Colors.white,
//                               foregroundColor: isDark ? Colors.white : Colors.black,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(30),
//                               ),
//                             ),
//                             child: Text(
//                               _isLogin ? 'Sign In' : 'Register',
//                               style: const TextStyle(fontSize: 18),
//                             ),
//                           ),
//                     const SizedBox(height: 20),
//                     TextButton(
//                       onPressed: () => setState(() => _isLogin = !_isLogin),
//                       child: Text(
//                         _isLogin 
//                             ? 'Create new account' 
//                             : 'Already have an account? Sign in',
//                         style: TextStyle(
//                           color: isDark ? Colors.white70 : Colors.black54,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }