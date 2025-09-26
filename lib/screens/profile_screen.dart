import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '/screens/auth_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _currentUser;
  Map<String, dynamic>? _userData;
  bool _isEditing = false;
  bool _isLoading = true;
  String? _imageError;
  
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _imageError = null;
    });
    
    _currentUser = _auth.currentUser;
    
    if (_currentUser != null) {
      try {
        final doc = await _firestore.collection('users').doc(_currentUser!.uid).get();
        if (doc.exists) {
          setState(() {
            _userData = doc.data();
            _usernameController.text = _userData?['username'] ?? '';
            _emailController.text = _currentUser!.email ?? '';
            _imageUrlController.text = _userData?['profileImageUrl'] ?? '';
          });
        }
      } catch (e) {
        print('Error loading user data: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading profile data')),
        );
      }
    }
    
    setState(() => _isLoading = false);
  }

  bool _isValidImageUrl(String url) {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null || !uri.isAbsolute) return false;
      
      final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'];
      final path = uri.path.toLowerCase();
      
      return imageExtensions.any((ext) => path.endsWith(ext)) ||
          uri.host.contains('imgur') ||
          uri.host.contains('flickr') ||
          uri.host.contains('unsplash') ||
          uri.host.contains('picsum');
    } catch (e) {
      return false;
    }
  }

  Future<void> _updateProfile() async {
    if (_currentUser == null) return;
    
    setState(() {
      _isLoading = true;
      _imageError = null;
    });
    
    try {
      if (_imageUrlController.text.isNotEmpty) {
        if (!_isValidImageUrl(_imageUrlController.text)) {
          throw 'Please enter a valid image URL (jpg, png, etc.)';
        }
      }
      
      await _firestore.collection('users').doc(_currentUser!.uid).update({
        'username': _usernameController.text,
        'profileImageUrl': _imageUrlController.text,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      await _currentUser!.updateDisplayName(_usernameController.text);
      await _currentUser!.reload();
      
      setState(() {
        _userData?['username'] = _usernameController.text;
        _userData?['profileImageUrl'] = _imageUrlController.text;
        _isEditing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      setState(() => _imageError = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildProfileImage() {
    final imageUrl = _userData?['profileImageUrl'];
    
    if (imageUrl == null || imageUrl.isEmpty) {
      return Icon(Icons.person, size: 60, color: Theme.of(context).colorScheme.onSurface);
    }
    
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(imageUrl)),
      child: CircleAvatar(
        radius: 60,
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            width: 120,
            height: 120,
            placeholder: (context, url) => CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            errorWidget: (context, url, error) => Icon(
              Icons.broken_image, 
              size: 60, 
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      ),
    );
  }

  Color _getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
  }

  Color _getContainerColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.grey[900]!
        : Colors.white.withOpacity(0.85);
  }

  // Helper method to format timestamp
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Never played';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = _getTextColor(context);
    final containerColor = _getContainerColor(context);

    // Extract game stats
    final gameStats = _userData?['gameStats'] ?? {};
    final memoryTileStats = gameStats['memoryTile'] ?? {};
    final numberSequenceStats = gameStats['numberSequence'] ?? {};

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? Colors.black : const Color.fromARGB(255, 255, 166, 107),
        body: Center(child: CircularProgressIndicator(
          color: theme.colorScheme.primary,
        )),
      );
    }
    
    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: isDark ? Colors.black : const Color.fromARGB(255, 255, 166, 107),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Please sign in to view your profile',
                style: TextStyle(color: textColor),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                  );
                },
                child: const Text('Sign In'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _updateProfile,
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [Colors.grey[900]!, Colors.grey[800]!]
                : [
                    const Color.fromARGB(255, 255, 166, 107),
                    const Color.fromARGB(255, 199, 133, 250),
                  ],
          ),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildProfileImage(),
                
                if (_imageError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _imageError!,
                      style: TextStyle(color: theme.colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                
                const SizedBox(height: 20),
                
                if (_isEditing) ...[
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      labelStyle: TextStyle(color: textColor),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: containerColor,
                    ),
                    style: TextStyle(color: textColor),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: containerColor,
                      enabled: false,
                    ),
                    style: TextStyle(color: textColor.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _imageUrlController,
                    decoration: InputDecoration(
                      labelText: 'Profile Image URL',
                      labelStyle: TextStyle(color: textColor),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: containerColor,
                      hintText: 'https://example.com/image.jpg',
                      hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
                    ),
                    style: TextStyle(color: textColor),
                    onChanged: (_) => setState(() => _imageError = null),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Enter any valid image URL (jpg, png, gif, etc.)\nYou can use links from Imgur, Flickr, etc.',
                    style: TextStyle(
                      color: textColor.withOpacity(0.7),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  Text(
                    _userData?['username'] ?? 'No username set',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _currentUser!.email ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor.withOpacity(0.8),
                    ),
                  ),
                ],
                const SizedBox(height: 30),
                
                // Memory Tile Game Stats
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: containerColor,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Memory Tile Game',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 15),
                      _StatItem(
                        icon: Icons.star,
                        label: 'High Score',
                        value: memoryTileStats['highScore']?.toString() ?? '0',
                        textColor: textColor,
                      ),
                      _StatItem(
                        icon: Icons.calendar_today,
                        label: 'Last Played',
                        value: _formatTimestamp(memoryTileStats['lastPlayed']),
                        textColor: textColor,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Number Sequence Game Stats
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: containerColor,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Number Sequence Game',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 15),
                      _StatItem(
                        icon: Icons.star,
                        label: 'High Score',
                        value: numberSequenceStats['highScore']?.toString() ?? '0',
                        textColor: textColor,
                      ),
                      _StatItem(
                        icon: Icons.leaderboard,
                        label: 'Highest Level',
                        value: numberSequenceStats['highestLevel']?.toString() ?? '0',
                        textColor: textColor,
                      ),
                      _StatItem(
                        icon: Icons.calendar_today,
                        label: 'Last Played',
                        value: _formatTimestamp(numberSequenceStats['lastPlayed']),
                        textColor: textColor,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () async {
                    await _auth.signOut();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  child: Text(
                    'Sign Out',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.onError,
                    ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color textColor;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 15),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: textColor,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}








// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:universal_html/html.dart' as html;
// import 'package:url_launcher/url_launcher.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:http/http.dart' as http;
// import '/screens/auth_screen.dart';
// import 'package:path_provider/path_provider.dart';
// import 'dart:io';
// import 'package:cached_network_image/cached_network_image.dart';

// class ProfileScreen extends StatefulWidget {
//   const ProfileScreen({super.key});

//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }

// class _ProfileScreenState extends State<ProfileScreen> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
//   User? _currentUser;
//   Map<String, dynamic>? _userData;
//   bool _isEditing = false;
//   bool _isLoading = true;
//   String? _imageError;
  
//   final TextEditingController _usernameController = TextEditingController();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _imageUrlController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     _loadUserData();
//   }

//   Future<void> _loadUserData() async {
//     setState(() {
//       _isLoading = true;
//       _imageError = null;
//     });
    
//     _currentUser = _auth.currentUser;
    
//     if (_currentUser != null) {
//       try {
//         final doc = await _firestore.collection('users').doc(_currentUser!.uid).get();
//         if (doc.exists) {
//           setState(() {
//             _userData = doc.data();
//             _usernameController.text = _userData?['username'] ?? '';
//             _emailController.text = _currentUser!.email ?? '';
//             _imageUrlController.text = _userData?['profileImageUrl'] ?? '';
//           });
//         }
//       } catch (e) {
//         print('Error loading user data: $e');
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Error loading profile data')),
//         );
//       }
//     }
    
//     setState(() => _isLoading = false);
//   }

//   bool _isValidImageUrl(String url) {
//     try {
//       final uri = Uri.tryParse(url);
//       if (uri == null || !uri.isAbsolute) return false;
      
//       final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'];
//       final path = uri.path.toLowerCase();
      
//       return imageExtensions.any((ext) => path.endsWith(ext)) ||
//           uri.host.contains('imgur') ||
//           uri.host.contains('flickr') ||
//           uri.host.contains('unsplash') ||
//           uri.host.contains('picsum');
//     } catch (e) {
//       return false;
//     }
//   }

//   Future<void> _updateProfile() async {
//     if (_currentUser == null) return;
    
//     setState(() {
//       _isLoading = true;
//       _imageError = null;
//     });
    
//     try {
//       if (_imageUrlController.text.isNotEmpty) {
//         if (!_isValidImageUrl(_imageUrlController.text)) {
//           throw 'Please enter a valid image URL (jpg, png, etc.)';
//         }
//       }
      
//       await _firestore.collection('users').doc(_currentUser!.uid).update({
//         'username': _usernameController.text,
//         'profileImageUrl': _imageUrlController.text,
//       });
      
//       await _currentUser!.updateDisplayName(_usernameController.text);
//       await _currentUser!.reload();
      
//       setState(() {
//         _userData?['username'] = _usernameController.text;
//         _userData?['profileImageUrl'] = _imageUrlController.text;
//         _isEditing = false;
//       });
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Profile updated successfully!')),
//       );
//     } catch (e) {
//       setState(() => _imageError = e.toString());
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(e.toString())),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   Widget _buildProfileImage() {
//     final imageUrl = _userData?['profileImageUrl'];
    
//     if (imageUrl == null || imageUrl.isEmpty) {
//       return Icon(Icons.person, size: 60, color: Theme.of(context).colorScheme.onBackground);
//     }
    
//     return GestureDetector(
//       onTap: () => launchUrl(Uri.parse(imageUrl)),
//       child: CircleAvatar(
//         radius: 60,
//         backgroundColor: Theme.of(context).colorScheme.surface,
//         child: ClipOval(
//           child: CachedNetworkImage(
//             imageUrl: imageUrl,
//             fit: BoxFit.cover,
//             width: 120,
//             height: 120,
//             placeholder: (context, url) => CircularProgressIndicator(
//               color: Theme.of(context).colorScheme.primary,
//             ),
//             errorWidget: (context, url, error) => Icon(
//               Icons.broken_image, 
//               size: 60, 
//               color: Theme.of(context).colorScheme.error,
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Color _getTextColor(BuildContext context) {
//     return Theme.of(context).brightness == Brightness.dark
//         ? Colors.white
//         : Colors.black;
//   }

//   Color _getContainerColor(BuildContext context) {
//     return Theme.of(context).brightness == Brightness.dark
//         ? Colors.grey[900]!
//         : Colors.white.withOpacity(0.85);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final isDark = theme.brightness == Brightness.dark;
//     final textColor = _getTextColor(context);
//     final containerColor = _getContainerColor(context);

//     if (_isLoading) {
//       return Scaffold(
//         backgroundColor: isDark ? Colors.black : const Color.fromARGB(255, 255, 166, 107),
//         body: Center(child: CircularProgressIndicator(
//           color: theme.colorScheme.primary,
//         )),
//       );
//     }
    
//     if (_currentUser == null) {
//       return Scaffold(
//         backgroundColor: isDark ? Colors.black : const Color.fromARGB(255, 255, 166, 107),
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 'Please sign in to view your profile',
//                 style: TextStyle(color: textColor),
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (_) => const AuthScreen()),
//                   );
//                 },
//                 child: const Text('Sign In'),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Profile'),
//         actions: [
//           if (!_isEditing)
//             IconButton(
//               icon: const Icon(Icons.edit),
//               onPressed: () => setState(() => _isEditing = true),
//             ),
//           if (_isEditing)
//             IconButton(
//               icon: const Icon(Icons.check),
//               onPressed: _updateProfile,
//             ),
//         ],
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: isDark
//                 ? [Colors.grey[900]!, Colors.grey[800]!]
//                 : [
//                     const Color.fromARGB(255, 255, 166, 107),
//                     const Color.fromARGB(255, 199, 133, 250),
//                   ],
//           ),
//         ),
//         child: ConstrainedBox(
//           constraints: BoxConstraints(
//             minHeight: MediaQuery.of(context).size.height,
//           ),
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 _buildProfileImage(),
                
//                 if (_imageError != null)
//                   Padding(
//                     padding: const EdgeInsets.only(top: 8),
//                     child: Text(
//                       _imageError!,
//                       style: TextStyle(color: theme.colorScheme.error),
//                       textAlign: TextAlign.center,
//                     ),
//                   ),
                
//                 const SizedBox(height: 20),
                
//                 if (_isEditing) ...[
//                   TextFormField(
//                     controller: _usernameController,
//                     decoration: InputDecoration(
//                       labelText: 'Username',
//                       labelStyle: TextStyle(color: textColor),
//                       border: OutlineInputBorder(),
//                       filled: true,
//                       fillColor: containerColor,
//                     ),
//                     style: TextStyle(color: textColor),
//                   ),
//                   const SizedBox(height: 15),
//                   TextFormField(
//                     controller: _emailController,
//                     decoration: InputDecoration(
//                       labelText: 'Email',
//                       labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
//                       border: OutlineInputBorder(),
//                       filled: true,
//                       fillColor: containerColor,
//                       enabled: false,
//                     ),
//                     style: TextStyle(color: textColor.withOpacity(0.7)),
//                   ),
//                   const SizedBox(height: 15),
//                   TextFormField(
//                     controller: _imageUrlController,
//                     decoration: InputDecoration(
//                       labelText: 'Profile Image URL',
//                       labelStyle: TextStyle(color: textColor),
//                       border: OutlineInputBorder(),
//                       filled: true,
//                       fillColor: containerColor,
//                       hintText: 'https://example.com/image.jpg',
//                       hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
//                     ),
//                     style: TextStyle(color: textColor),
//                     onChanged: (_) => setState(() => _imageError = null),
//                   ),
//                   const SizedBox(height: 20),
//                   Text(
//                     'Enter any valid image URL (jpg, png, gif, etc.)\nYou can use links from Imgur, Flickr, etc.',
//                     style: TextStyle(
//                       color: textColor.withOpacity(0.7),
//                       fontSize: 12,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ] else ...[
//                   Text(
//                     _userData?['username'] ?? 'No username set',
//                     style: TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                       color: textColor,
//                     ),
//                   ),
//                   const SizedBox(height: 5),
//                   Text(
//                     _currentUser!.email ?? '',
//                     style: TextStyle(
//                       fontSize: 16,
//                       color: textColor.withOpacity(0.8),
//                     ),
//                   ),
//                 ],
//                 const SizedBox(height: 30),
//                 Container(
//                   padding: const EdgeInsets.all(20),
//                   decoration: BoxDecoration(
//                     color: containerColor,
//                     borderRadius: BorderRadius.circular(15),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.1),
//                         blurRadius: 10,
//                         offset: const Offset(0, 5),
//                       )
//                     ],
//                   ),
//                   child: Column(
//                     children: [
//                       Text(
//                         'Game Statistics',
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                           color: textColor,
//                         ),
//                       ),
//                       const SizedBox(height: 15),
//                       _StatItem(
//                         icon: Icons.star,
//                         label: 'High Score',
//                         value: _userData?['highScore']?.toString() ?? '0',
//                         textColor: textColor,
//                       ),
//                       _StatItem(
//                         icon: Icons.games,
//                         label: 'Games Played',
//                         value: _userData?['gamesPlayed']?.toString() ?? '0',
//                         textColor: textColor,
//                       ),
//                       _StatItem(
//                         icon: Icons.emoji_events,
//                         label: 'Achievements',
//                         value: _userData?['achievements']?.length.toString() ?? '0',
//                         textColor: textColor,
//                       ),
//                     ],
//                   ),
//                 ),
                
//                 const SizedBox(height: 30),
//                 ElevatedButton(
//                   onPressed: () async {
//                     await _auth.signOut();
//                     Navigator.pop(context);
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: theme.colorScheme.error,
//                     padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
//                   ),
//                   child: Text(
//                     'Sign Out',
//                     style: TextStyle(
//                       fontSize: 16,
//                       color: theme.colorScheme.onError,
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: MediaQuery.of(context).padding.bottom),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _StatItem extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final String value;
//   final Color textColor;

//   const _StatItem({
//     required this.icon,
//     required this.label,
//     required this.value,
//     required this.textColor,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         children: [
//           Icon(icon, color: Theme.of(context).colorScheme.primary),
//           const SizedBox(width: 15),
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 16,
//               color: textColor,
//             ),
//           ),
//           const Spacer(),
//           Text(
//             value,
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: textColor,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }








// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:universal_html/html.dart' as html;
// import 'package:url_launcher/url_launcher.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:http/http.dart' as http;
// import '/screens/auth_screen.dart';
// import 'package:path_provider/path_provider.dart';
// import 'dart:io';
// import 'package:cached_network_image/cached_network_image.dart';
// class ProfileScreen extends StatefulWidget {
//   const ProfileScreen({super.key});

//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }

// class _ProfileScreenState extends State<ProfileScreen> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
//   User? _currentUser;
//   Map<String, dynamic>? _userData;
//   bool _isEditing = false;
//   bool _isLoading = true;
//   String? _imageError;
  
//   final TextEditingController _usernameController = TextEditingController();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _imageUrlController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     _loadUserData();
//   }

//   Future<void> _loadUserData() async {
//     setState(() {
//       _isLoading = true;
//       _imageError = null;
//     });
    
//     _currentUser = _auth.currentUser;
    
//     if (_currentUser != null) {
//       try {
//         final doc = await _firestore.collection('users').doc(_currentUser!.uid).get();
//         if (doc.exists) {
//           setState(() {
//             _userData = doc.data();
//             _usernameController.text = _userData?['username'] ?? '';
//             _emailController.text = _currentUser!.email ?? '';
//             _imageUrlController.text = _userData?['profileImageUrl'] ?? '';
//           });
//         }
//       } catch (e) {
//         print('Error loading user data: $e');
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Error loading profile data')),
//         );
//       }
//     }
    
//     setState(() => _isLoading = false);
//   }

//   bool _isValidImageUrl(String url) {
//     try {
//       final uri = Uri.tryParse(url);
//       if (uri == null || !uri.isAbsolute) return false;
      
//       // Accept any URL that looks like it could be an image
//       // You can add more extensions if needed
//       final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'];
//       final path = uri.path.toLowerCase();
      
//       return imageExtensions.any((ext) => path.endsWith(ext)) ||
//           uri.host.contains('imgur') ||
//           uri.host.contains('flickr') ||
//           uri.host.contains('unsplash') ||
//           uri.host.contains('picsum');
//     } catch (e) {
//       return false;
//     }
//   }

//   Future<void> _updateProfile() async {
//     if (_currentUser == null) return;
    
//     setState(() {
//       _isLoading = true;
//       _imageError = null;
//     });
    
//     try {
//       // Validate URL if provided
//       if (_imageUrlController.text.isNotEmpty) {
//         if (!_isValidImageUrl(_imageUrlController.text)) {
//           throw 'Please enter a valid image URL (jpg, png, etc.)';
//         }
//       }
      
//       // Update user data in Firestore
//       await _firestore.collection('users').doc(_currentUser!.uid).update({
//         'username': _usernameController.text,
//         'profileImageUrl': _imageUrlController.text,
//       });
      
//       // Update Firebase Auth display name
//       await _currentUser!.updateDisplayName(_usernameController.text);
//       await _currentUser!.reload();
      
//       setState(() {
//         _userData?['username'] = _usernameController.text;
//         _userData?['profileImageUrl'] = _imageUrlController.text;
//         _isEditing = false;
//       });
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Profile updated successfully!')),
//       );
//     } catch (e) {
//       setState(() => _imageError = e.toString());
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(e.toString())),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   Widget _buildProfileImage() {
//     final imageUrl = _userData?['profileImageUrl'];
    
//     if (imageUrl == null || imageUrl.isEmpty) {
//       return const Icon(Icons.person, size: 60, color: Colors.white);
//     }
    
//     return GestureDetector(
//       onTap: () => launchUrl(Uri.parse(imageUrl)),
//       child: CircleAvatar(
//         radius: 60,
//         backgroundColor: Colors.grey[300],
//         child: ClipOval(
//           child: CachedNetworkImage(
//             imageUrl: imageUrl,
//             fit: BoxFit.cover,
//             width: 120,
//             height: 120,
//             placeholder: (context, url) => const CircularProgressIndicator(),
//             errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 60, color: Colors.red),
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
    
//     if (_isLoading) {
//       return Scaffold(
//         backgroundColor: isDark ? Colors.black : const Color.fromARGB(255, 255, 166, 107),
//         body: const Center(child: CircularProgressIndicator()),
//       );
//     }
    
//     if (_currentUser == null) {
//       return Scaffold(
//         backgroundColor: isDark ? Colors.black : const Color.fromARGB(255, 255, 166, 107),
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Text('Please sign in to view your profile'),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (_) => const AuthScreen()),
//                   );
//                 },
//                 child: const Text('Sign In'),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Profile'),
//         actions: [
//           if (!_isEditing)
//             IconButton(
//               icon: const Icon(Icons.edit),
//               onPressed: () => setState(() => _isEditing = true),
//             ),
//           if (_isEditing)
//             IconButton(
//               icon: const Icon(Icons.check),
//               onPressed: _updateProfile,
//             ),
//         ],
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
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               _buildProfileImage(),
              
//               if (_imageError != null)
//                 Padding(
//                   padding: const EdgeInsets.only(top: 8),
//                   child: Text(
//                     _imageError!,
//                     style: const TextStyle(color: Colors.red),
//                     textAlign: TextAlign.center,
//                   ),
//                 ),
              
//               const SizedBox(height: 20),
              
//               if (_isEditing) ...[
//                 TextFormField(
//                   controller: _usernameController,
//                   decoration: InputDecoration(
//                     labelText: 'Username',
//                     border: OutlineInputBorder(),
//                     filled: true,
//                     fillColor: isDark ? Colors.grey[800] : Colors.white,
//                   ),
//                   style: TextStyle(color: isDark ? Colors.white : Colors.black),
//                 ),
//                 const SizedBox(height: 15),
//                 TextFormField(
//                   controller: _emailController,
//                   decoration: InputDecoration(
//                     labelText: 'Email',
//                     border: OutlineInputBorder(),
//                     filled: true,
//                     fillColor: isDark ? Colors.grey[800] : Colors.white,
//                     enabled: false,
//                   ),
//                   style: TextStyle(color: isDark ? Colors.grey[400] : Colors.black54),
//                 ),
//                 const SizedBox(height: 15),
//                 TextFormField(
//                   controller: _imageUrlController,
//                   decoration: InputDecoration(
//                     labelText: 'Profile Image URL',
//                     border: OutlineInputBorder(),
//                     filled: true,
//                     fillColor: isDark ? Colors.grey[800] : Colors.white,
//                     hintText: 'https://example.com/image.jpg',
//                   ),
//                   style: TextStyle(color: isDark ? Colors.white : Colors.black),
//                   onChanged: (_) => setState(() => _imageError = null),
//                 ),
//                 const SizedBox(height: 20),
//                 Text(
//                   'Enter any valid image URL (jpg, png, gif, etc.)\nYou can use links from Imgur, Flickr, etc.',
//                   style: TextStyle(
//                     color: isDark ? Colors.grey[400] : Colors.black54,
//                     fontSize: 12,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               ] else ...[
//                 Text(
//                   _userData?['username'] ?? 'No username set',
//                   style: TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//                 const SizedBox(height: 5),
//                 Text(
//                   _currentUser!.email ?? '',
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: Colors.white70,
//                   ),
//                 ),
//               ],
//               const SizedBox(height: 30),
//               Container(
//                 padding: const EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   color: isDark ? Colors.grey[900] : Colors.white.withOpacity(0.2),
//                   borderRadius: BorderRadius.circular(15),
//                 ),
//                 child: Column(
//                   children: [
//                     Text(
//                       'Game Statistics',
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                     const SizedBox(height: 15),
//                     _StatItem(
//                       icon: Icons.star,
//                       label: 'High Score',
//                       value: _userData?['highScore']?.toString() ?? '0',
//                       isDark: isDark,
//                     ),
//                     _StatItem(
//                       icon: Icons.games,
//                       label: 'Games Played',
//                       value: _userData?['gamesPlayed']?.toString() ?? '0',
//                       isDark: isDark,
//                     ),
//                     _StatItem(
//                       icon: Icons.emoji_events,
//                       label: 'Achievements',
//                       value: _userData?['achievements']?.length.toString() ?? '0',
//                       isDark: isDark,
//                     ),
//                   ],
//                 ),
//               ),
              
//               const SizedBox(height: 30),
//               ElevatedButton(
//                 onPressed: () async {
//                   await _auth.signOut();
//                   Navigator.pop(context);
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.red,
//                   padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
//                 ),
//                 child: const Text(
//                   'Sign Out',
//                   style: TextStyle(fontSize: 16),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _StatItem extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final String value;
//   final bool isDark;

//   const _StatItem({
//     required this.icon,
//     required this.label,
//     required this.value,
//     required this.isDark,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         children: [
//           Icon(icon, color: isDark ? Colors.deepPurpleAccent : Colors.white),
//           const SizedBox(width: 15),
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 16,
//               color: Colors.white,
//             ),
//           ),
//           const Spacer(),
//           Text(
//             value,
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }