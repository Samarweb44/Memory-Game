// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter_animate/flutter_animate.dart'; // Add this
// import 'package:shimmer/shimmer.dart'; // Add this
// import 'dart:ui'; // For ImageFilter.blur

// class LeaderboardScreen2 extends StatefulWidget {
//   const LeaderboardScreen2({super.key});

//   @override
//   State<LeaderboardScreen2> createState() => _LeaderboardScreen2State();
// }

// class _LeaderboardScreen2State extends State<LeaderboardScreen2> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   String? _currentUserId;

//   @override
//   void initState() {
//     super.initState();
//     _currentUserId = _auth.currentUser?.uid;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     // Define custom colors for this leaderboard's theme
//     final Color lightPrimary = Colors.blue.shade50;
//     final Color lightSecondary = Colors.lightBlue.shade50;
//     final Color darkPrimary = const Color(0xFF0D1B2A); // Deep blue-black
//     final Color darkSecondary = const Color(0xFF1B263B); // Slightly lighter blue-black

//     // Colors for current user highlights and accents
//     final Color currentUserLight = Colors.blue.shade100;
//     final Color currentUserDark = Colors.blue.shade800;
//     final Color accentColorLight = Colors.blue.shade700;
//     final Color accentColorDark = Colors.blueAccent.shade400;

//     return Scaffold(
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         title: const Text(
//           'Number Sequence Leaderboard',
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             letterSpacing: 0.8,
//             color: Colors.white, // Ensure text is white on the gradient AppBar
//           ),
//         ),
//         centerTitle: true,
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         flexibleSpace: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: isDark
//                   ? [darkPrimary.withOpacity(0.8), darkSecondary.withOpacity(0.8)]
//                   : [accentColorLight.withOpacity(0.8), Colors.blue.shade400.withOpacity(0.8)],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//         ),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: isDark
//                 ? [darkPrimary, darkSecondary]
//                 : [lightPrimary, lightSecondary],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: StreamBuilder<QuerySnapshot>(
//           stream: _firestore
//               .collection('users')
//               .where('gameStats.numberSequence.highScore', isGreaterThan: 0)
//               .orderBy('gameStats.numberSequence.highScore', descending: true)
//               .limit(100)
//               .snapshots(),
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return _buildShimmerLoading(isDark, darkPrimary, darkSecondary, lightPrimary, lightSecondary);
//             }

//             if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//               return Center(
//                 child: Text(
//                   'No leaderboard data yet. Play a game to see your score!',
//                   style: TextStyle(
//                     color: isDark ? Colors.white70 : Colors.black54,
//                     fontSize: 16,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               );
//             }

//             final users = snapshot.data!.docs;

//             return CustomScrollView(
//               slivers: [
//                 SliverToBoxAdapter(
//                   child: _buildHeroSection(context, isDark, darkPrimary, lightPrimary),
//                 ),
//                 SliverPadding(
//                   padding: const EdgeInsets.all(16.0),
//                   sliver: SliverList(
//                     delegate: SliverChildBuilderDelegate(
//                       (context, index) {
//                         final doc = users[index];
//                         final userData = doc.data() as Map<String, dynamic>;
//                         final gameStats =
//                             userData['gameStats'] as Map<String, dynamic>?;
//                         final numberSequenceStats =
//                             gameStats?['numberSequence'] as Map<String, dynamic>?;
//                         final isCurrentUser = doc.id == _currentUserId;

//                         final highScore = numberSequenceStats?['highScore'] ?? 0;
//                         final level = numberSequenceStats?['highestLevel'] ?? 1; // Get highestLevel
//                         final username = userData['username'] ?? 'Anonymous';
//                         final profileImageUrl =
//                             userData['profileImageUrl'] ?? '';

//                         // Special rendering for top 3
//                         if (index < 3) {
//                           return _buildTopPlayerCard(
//                             context,
//                             index,
//                             username,
//                             highScore,
//                             level, // Pass level
//                             profileImageUrl,
//                             isCurrentUser,
//                             isDark,
//                             currentUserDark,
//                             accentColorDark,
//                           ).animate().fadeIn(duration: 500.ms, delay: (100 * index).ms).slideY(begin: 0.2, end: 0);
//                         }

//                         // Normal list item for others
//                         return _buildLeaderboardItem(
//                           context,
//                           index,
//                           username,
//                           highScore,
//                           level, // Pass level
//                           profileImageUrl,
//                           isCurrentUser,
//                           isDark,
//                           currentUserLight,
//                           currentUserDark,
//                           accentColorLight,
//                           accentColorDark,
//                         ).animate().fadeIn(duration: 300.ms, delay: (200 + 50 * index).ms).slideY(begin: 0.1, end: 0);
//                       },
//                       childCount: users.length,
//                     ),
//                   ),
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildHeroSection(BuildContext context, bool isDark, Color darkPrimary, Color lightPrimary) {
//     return Container(
//       height: 180,
//       width: double.infinity,
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: isDark
//               ? [darkPrimary.withOpacity(0.9), Colors.blue.shade900.withOpacity(0.9)]
//               : [lightPrimary.withOpacity(0.9), Colors.blue.shade100.withOpacity(0.9)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
//         boxShadow: [
//           BoxShadow(
//             color: (isDark ? Colors.black : Colors.blue).withOpacity(0.3),
//             blurRadius: 10,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 Icons.numbers, // Changed icon for Number Sequence
//                 size: 60,
//                 color: isDark ? Colors.cyanAccent : Colors.blue.shade700,
//               ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
//               const SizedBox(height: 8),
//               Text(
//                 'Number Sequence Leaders',
//                 style: TextStyle(
//                   fontSize: 28,
//                   fontWeight: FontWeight.bold,
//                   color: isDark ? Colors.white : Colors.blue[900],
//                   shadows: [
//                     Shadow(
//                       color: (isDark ? Colors.black : Colors.white).withOpacity(0.5),
//                       blurRadius: 4,
//                       offset: const Offset(2, 2),
//                     ),
//                   ],
//                 ),
//               ).animate().fadeIn(duration: 800.ms, delay: 200.ms).slideY(begin: 0.2, end: 0),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTopPlayerCard(
//     BuildContext context,
//     int index,
//     String username,
//     int highScore,
//     int level, // Added level
//     String profileImageUrl,
//     bool isCurrentUser,
//     bool isDark,
//     Color currentUserDark,
//     Color accentColorDark,
//   ) {
//     Color medalColor;
//     IconData medalIcon;
//     switch (index) {
//       case 0:
//         medalColor = Colors.amber.shade600;
//         medalIcon = Icons.star; // Star for 1st place
//         break;
//       case 1:
//         medalColor = Colors.grey.shade400;
//         medalIcon = Icons.star_half; // Half star for 2nd place
//         break;
//       case 2:
//         medalColor = Colors.brown.shade400;
//         medalIcon = Icons.star_border; // Outlined star for 3rd place
//         break;
//       default:
//         medalColor = Colors.transparent;
//         medalIcon = Icons.circle; // Should not be reached
//     }

//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(15),
//         side: isCurrentUser
//             ? BorderSide(
//                 color: isDark ? accentColorDark : Colors.blue.shade700,
//                 width: 2.0)
//             : BorderSide.none,
//       ),
//       elevation: 8,
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(15),
//         child: BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
//           child: Container(
//             decoration: BoxDecoration(
//               color: (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
//               borderRadius: BorderRadius.circular(15),
//               border: Border.all(
//                 color: (isDark ? Colors.white30 : Colors.black12),
//               ),
//             ),
//             padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
//             child: Stack(
//               alignment: Alignment.center,
//               children: [
//                 Positioned(
//                   top: 0,
//                   right: 0,
//                   child: Icon(
//                     medalIcon,
//                     size: 80,
//                     color: medalColor.withOpacity(0.3),
//                   ),
//                 ),
//                 Row(
//                   children: [
//                     CircleAvatar(
//                       radius: 30,
//                       backgroundColor: isDark ? currentUserDark : Colors.blue[100],
//                       child: profileImageUrl.isNotEmpty
//                           ? ClipOval(
//                               child: CachedNetworkImage(
//                                 imageUrl: profileImageUrl,
//                                 width: 60,
//                                 height: 60,
//                                 fit: BoxFit.cover,
//                                 placeholder: (context, url) => Container(
//                                   color: Colors.grey[300],
//                                   child: Icon(Icons.person, color: Colors.grey[600]),
//                                 ),
//                                 errorWidget: (context, url, error) =>
//                                     const Icon(Icons.person, color: Colors.grey),
//                               ),
//                             )
//                           : Text(
//                               '${index + 1}',
//                               style: TextStyle(
//                                 color: isDark ? Colors.white : Colors.blue,
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 22,
//                               ),
//                             ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             username,
//                             style: TextStyle(
//                               fontSize: 22,
//                               fontWeight: FontWeight.bold,
//                               color: isDark ? Colors.white : Colors.black87,
//                             ),
//                           ),
//                           Text(
//                             'Score: $highScore | Level: $level', // Display Level
//                             style: TextStyle(
//                               fontSize: 18,
//                               color: isDark ? Colors.white70 : Colors.black54,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     Icon(
//                       medalIcon,
//                       size: 40,
//                       color: medalColor,
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildLeaderboardItem(
//     BuildContext context,
//     int index,
//     String username,
//     int highScore,
//     int level, // Added level
//     String profileImageUrl,
//     bool isCurrentUser,
//     bool isDark,
//     Color currentUserLight,
//     Color currentUserDark,
//     Color accentColorLight,
//     Color accentColorDark,
//   ) {
//     return Card(
//       color: isCurrentUser
//           ? (isDark ? currentUserDark : currentUserLight)
//           : (isDark ? const Color(0xFF1E2E43) : Colors.white),
//       elevation: 4,
//       margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//         side: isCurrentUser
//             ? BorderSide(
//                 color: isDark ? accentColorDark : accentColorLight,
//                 width: 1.5)
//             : BorderSide.none,
//       ),
//       child: ListTile(
//         leading: CircleAvatar(
//           radius: 24,
//           backgroundColor: isDark ? currentUserDark.withOpacity(0.6) : Colors.blue[100],
//           child: profileImageUrl.isNotEmpty
//               ? ClipOval(
//                   child: CachedNetworkImage(
//                     imageUrl: profileImageUrl,
//                     width: 48,
//                     height: 48,
//                     fit: BoxFit.cover,
//                     placeholder: (context, url) => Container(
//                       color: Colors.grey[300],
//                       child: const Icon(Icons.person, color: Colors.white),
//                     ),
//                     errorWidget: (context, url, error) =>
//                         const Icon(Icons.person),
//                   ),
//                 )
//               : Text(
//                   '${index + 1}',
//                   style: TextStyle(
//                     color: isDark ? Colors.white : Colors.blue.shade700,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//         ),
//         title: Text(
//           username,
//           style: TextStyle(
//             fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
//             color: isDark ? Colors.white : Colors.black,
//             fontSize: 16,
//           ),
//         ),
//         subtitle: Text(
//           'Score: $highScore | Level: $level', // Display Level
//           style: TextStyle(
//             color: isDark ? Colors.white70 : Colors.black54,
//             fontSize: 14,
//           ),
//         ),
//         trailing: isCurrentUser
//             ? Icon(
//                 Icons.star,
//                 color: isDark ? Colors.cyanAccent : Colors.blue.shade700,
//                 size: 20,
//               )
//             : null,
//       ),
//     );
//   }

//   Widget _buildShimmerLoading(bool isDark, Color darkPrimary, Color darkSecondary, Color lightPrimary, Color lightSecondary) {
//     return Shimmer.fromColors(
//       baseColor: isDark ? darkSecondary.withOpacity(0.7) : Colors.grey.shade300,
//       highlightColor: isDark ? darkPrimary.withOpacity(0.7) : Colors.grey.shade100,
//       child: ListView.builder(
//         padding: const EdgeInsets.all(16),
//         itemCount: 10, // Show 10 shimmer items
//         itemBuilder: (context, index) {
//           return Card(
//             margin: const EdgeInsets.symmetric(vertical: 8),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: const ListTile(
//               leading: CircleAvatar(
//                 radius: 24,
//                 backgroundColor: Colors.white,
//               ),
//               title: SizedBox(
//                 height: 16,
//                 width: 150,
//                 child: DecoratedBox(
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.all(Radius.circular(4)),
//                   ),
//                 ),
//               ),
//               subtitle: SizedBox(
//                 height: 14,
//                 width: 100,
//                 child: DecoratedBox(
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.all(Radius.circular(4)),
//                   ),
//                 ),
//               ),
//               trailing: SizedBox(
//                 height: 24,
//                 width: 24,
//                 child: DecoratedBox(
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     shape: BoxShape.circle,
//                   ),
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }


// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter_animate/flutter_animate.dart';

// class LeaderboardScreen2 extends StatefulWidget {
//   const LeaderboardScreen2({super.key});

//   @override
//   State<LeaderboardScreen2> createState() => _LeaderboardScreen2State();
// }

// class _LeaderboardScreen2State extends State<LeaderboardScreen2> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   String? _currentUserId;

//   @override
//   void initState() {
//     super.initState();
//     _currentUserId = _auth.currentUser?.uid;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
    
//     // Color scheme for light mode
//     const lightPrimary = Color(0xFF1976D2);  // Material Blue 700
//     const lightBackground = Color(0xFFE3F2FD);  // Blue 50
//     const lightCard = Colors.white;
//     const lightText = Color(0xFF212121);  // Grey 900
//     const lightSubtext = Color(0xFF757575);  // Grey 600
//     const lightHighlight = Color(0xFFBBDEFB);  // Blue 100
    
//     // Color scheme for dark mode
//     const darkPrimary = Color.fromARGB(255, 48, 68, 83);  // Blue 200
//     const darkBackground = Color(0xFF0D1B2A);  // Deep blue-black
//     const darkCard = Color(0xFF1B263B);  // Slightly lighter navy
//     const darkText = Colors.white;
//     const darkSubtext = Color(0xFFE0E0E0);  // Grey 300
//     const darkHighlight = Color(0xFF1E88E5);  // Blue 600

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Number Sequence',
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             letterSpacing: 0.8,
//           ),
//         ),
//         centerTitle: true,
//         backgroundColor: isDark ? darkPrimary : lightPrimary,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: Container(
//         color: isDark ? darkBackground : lightBackground,
//         child: StreamBuilder<QuerySnapshot>(
//           stream: _firestore
//               .collection('users')
//               .where('gameStats.numberSequence.highLevel', isGreaterThan: 0)
//               .orderBy('gameStats.numberSequence.highLevel', descending: true)
//               .limit(100)
//               .snapshots(),
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return _buildFastShimmerLoading(isDark);
//             }

//             if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//               return Center(
//                 child: Text(
//                   'No leaderboard data yet. Play a game to see your score!',
//                   style: TextStyle(
//                     color: isDark ? darkSubtext : lightSubtext,
//                     fontSize: 16,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               );
//             }

//             final users = snapshot.data!.docs;

//             return CustomScrollView(
//               slivers: [
//                 SliverToBoxAdapter(
//                   child: _buildHeroSection(
//                     context, 
//                     isDark, 
//                     primary: isDark ? darkPrimary : lightPrimary,
//                     textColor: isDark ? darkText : lightText,
//                   ),
//                 ),
//                 SliverPadding(
//                   padding: const EdgeInsets.all(16.0),
//                   sliver: SliverList(
//                     delegate: SliverChildBuilderDelegate(
//                       (context, index) {
//                         final doc = users[index];
//                         final userData = doc.data() as Map<String, dynamic>;
//                         final gameStats =
//                             userData['gameStats'] as Map<String, dynamic>?;
//                         final numberSequenceStats =
//                             gameStats?['numberSequence'] as Map<String, dynamic>?;
//                         final isCurrentUser = doc.id == _currentUserId;

//                         final highScore = numberSequenceStats?['highScore'] ?? 0;
//                         final level = numberSequenceStats?['highestLevel'] ?? 1;
//                         final username = userData['username'] ?? 'Anonymous';
//                         final profileImageUrl =
//                             userData['profileImageUrl'] ?? '';

//                         if (index < 3) {
//                           return _buildTopPlayerCard(
//                             context,
//                             index,
//                             username,
//                             highScore,
//                             level,
//                             profileImageUrl,
//                             isCurrentUser,
//                             isDark,
//                             cardColor: isDark ? darkCard : lightCard,
//                             textColor: isDark ? darkText : lightText,
//                             subtextColor: isDark ? darkSubtext : lightSubtext,
//                             highlightColor: isDark ? darkHighlight : lightHighlight,
//                           ).animate().fadeIn(duration: 150.ms, delay: (50 * index).ms);
//                         }

//                         return _buildLeaderboardItem(
//                           context,
//                           index,
//                           username,
//                           highScore,
//                           level,
//                           profileImageUrl,
//                           isCurrentUser,
//                           isDark,
//                           cardColor: isDark ? darkCard : lightCard,
//                           textColor: isDark ? darkText : lightText,
//                           subtextColor: isDark ? darkSubtext : lightSubtext,
//                           highlightColor: isDark ? darkHighlight : lightHighlight,
//                         ).animate().fadeIn(duration: 100.ms, delay: (100 + 20 * index).ms);
//                       },
//                       childCount: users.length,
//                     ),
//                   ),
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildHeroSection(
//     BuildContext context, 
//     bool isDark, {
//     required Color primary,
//     required Color textColor,
//   }) {
//     return Container(
//       height: 180,
//       width: double.infinity,
//       color: primary,
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.numbers,
//             size: 60,
//             color: Colors.white,
//           ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
//           const SizedBox(height: 8),
//           Text(
//             'Number Sequence Leaders',
//             style: TextStyle(
//               fontSize: 28,
//               fontWeight: FontWeight.bold,
//               color: textColor,
//             ),
//           ).animate().fadeIn(duration: 300.ms),
//         ],
//       ),
//     );
//   }

//   Widget _buildTopPlayerCard(
//     BuildContext context,
//     int index,
//     String username,
//     int highScore,
//     int level,
//     String profileImageUrl,
//     bool isCurrentUser,
//     bool isDark, {
//     required Color cardColor,
//     required Color textColor,
//     required Color subtextColor,
//     required Color highlightColor,
//   }) {
//     final medalColor = switch (index) {
//       0 => const Color(0xFFFFD700), // Gold
//       1 => const Color(0xFFC0C0C0), // Silver
//       2 => const Color(0xFFCD7F32), // Bronze
//       _ => Colors.transparent,
//     };
    
//     final medalIcon = switch (index) {
//       0 => Icons.star,
//       1 => Icons.star_half,
//       2 => Icons.star_border,
//       _ => Icons.circle,
//     };

//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
//       color: isCurrentUser ? highlightColor.withOpacity(0.2) : cardColor,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(15),
//         side: BorderSide(
//           color: isCurrentUser ? highlightColor : Colors.transparent,
//           width: 2.0,
//         ),
//       ),
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
//         child: Row(
//           children: [
//             CircleAvatar(
//               radius: 30,
//               backgroundColor: highlightColor.withOpacity(0.2),
//               child: profileImageUrl.isNotEmpty
//                   ? ClipOval(
//                       child: CachedNetworkImage(
//                         imageUrl: profileImageUrl,
//                         width: 60,
//                         height: 60,
//                         fit: BoxFit.cover,
//                         placeholder: (context, url) => Container(
//                           color: Colors.grey[300],
//                           child: Icon(Icons.person, color: Colors.grey[600]),
//                         ),
//                         errorWidget: (context, url, error) =>
//                             const Icon(Icons.person, color: Colors.grey),
//                       ),
//                     )
//                   : Text(
//                       '${index + 1}',
//                       style: TextStyle(
//                         color: textColor,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 22,
//                       ),
//                     ),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     username,
//                     style: TextStyle(
//                       fontSize: 22,
//                       fontWeight: FontWeight.bold,
//                       color: textColor,
//                     ),
//                   ),
//                   Text(
//                     'Score: $highScore | Level: $level',
//                     style: TextStyle(
//                       fontSize: 18,
//                       color: subtextColor,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Icon(
//               medalIcon,
//               size: 40,
//               color: medalColor,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildLeaderboardItem(
//     BuildContext context,
//     int index,
//     String username,
//     int highScore,
//     int level,
//     String profileImageUrl,
//     bool isCurrentUser,
//     bool isDark, {
//     required Color cardColor,
//     required Color textColor,
//     required Color subtextColor,
//     required Color highlightColor,
//   }) {
//     return Card(
//       color: isCurrentUser
//           ? highlightColor.withOpacity(0.15)
//           : cardColor,
//       elevation: 2,
//       margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//         side: BorderSide(
//           color: isCurrentUser ? highlightColor : Colors.transparent,
//           width: 1.5,
//         ),
//       ),
//       child: ListTile(
//         leading: CircleAvatar(
//           radius: 24,
//           backgroundColor: highlightColor.withOpacity(0.2),
//           child: profileImageUrl.isNotEmpty
//               ? ClipOval(
//                   child: CachedNetworkImage(
//                     imageUrl: profileImageUrl,
//                     width: 48,
//                     height: 48,
//                     fit: BoxFit.cover,
//                     placeholder: (context, url) => Container(
//                       color: Colors.grey[300],
//                       child: const Icon(Icons.person, color: Colors.white),
//                     ),
//                     errorWidget: (context, url, error) =>
//                         const Icon(Icons.person),
//                   ),
//                 )
//               : Text(
//                   '${index + 1}',
//                   style: TextStyle(
//                     color: textColor,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//         ),
//         title: Text(
//           username,
//           style: TextStyle(
//             fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
//             color: textColor,
//             fontSize: 16,
//           ),
//         ),
//         subtitle: Text(
//           'Score: $highScore | Level: $level',
//           style: TextStyle(
//             color: subtextColor,
//             fontSize: 14,
//           ),
//         ),
//         trailing: isCurrentUser
//             ? Icon(
//                 Icons.star,
//                 color: highlightColor,
//                 size: 20,
//               )
//             : null,
//       ),
//     );
//   }

//   Widget _buildFastShimmerLoading(bool isDark) {
//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: 10,
//       itemBuilder: (context, index) {
//         return Card(
//           margin: const EdgeInsets.symmetric(vertical: 8),
//           color: isDark ? const Color(0xFF1B263B) : Colors.white,
//           child: const ListTile(
//             leading: CircleAvatar(
//               radius: 24,
//               backgroundColor: Colors.grey,
//             ),
//             title: SizedBox(
//               height: 16,
//               width: 150,
//               child: DecoratedBox(
//                 decoration: BoxDecoration(
//                   color: Colors.grey,
//                   borderRadius: BorderRadius.all(Radius.circular(4)),
//                 ),
//               ),
//             ),
//             subtitle: SizedBox(
//               height: 14,
//               width: 100,
//               child: DecoratedBox(
//                 decoration: BoxDecoration(
//                   color: Colors.grey,
//                   borderRadius: BorderRadius.all(Radius.circular(4)),
//                 ),
//               ),
//             ),
//           ),
//         ).animate().fadeIn(duration: 100.ms, delay: (20 * index).ms);
//       },
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LeaderboardScreen2 extends StatefulWidget {
  const LeaderboardScreen2({super.key});

  @override
  State<LeaderboardScreen2> createState() => _LeaderboardScreen2State();
}

class _LeaderboardScreen2State extends State<LeaderboardScreen2> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Color scheme for light mode
    const lightPrimary = Color(0xFF1976D2);  // Material Blue 700
    const lightBackground = Color(0xFFE3F2FD);  // Blue 50
    const lightCard = Colors.white;
    const lightText = Color(0xFF212121);  // Grey 900
    const lightSubtext = Color(0xFF757575);  // Grey 600
    const lightHighlight = Color(0xFFBBDEFB);  // Blue 100
    
    // Color scheme for dark mode
    const darkPrimary = Color.fromARGB(255, 48, 68, 83);  // Blue 200
    const darkBackground = Color(0xFF0D1B2A);  // Deep blue-black
    const darkCard = Color(0xFF1B263B);  // Slightly lighter navy
    const darkText = Colors.white;
    const darkSubtext = Color(0xFFE0E0E0);  // Grey 300
    const darkHighlight = Color(0xFF1E88E5);  // Blue 600

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Number Sequence',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDark ? darkPrimary : lightPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: isDark ? darkBackground : lightBackground,
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('users')
              .where('gameStats.numberSequence.highestLevel', isGreaterThan: 0)
              .orderBy('gameStats.numberSequence.highestLevel', descending: true)
              .limit(100)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildFastShimmerLoading(isDark);
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  'No leaderboard data yet. Play a game to see your score!',
                  style: TextStyle(
                    color: isDark ? darkSubtext : lightSubtext,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }

            final users = snapshot.data!.docs;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHeroSection(
                    context, 
                    isDark, 
                    primary: isDark ? darkPrimary : lightPrimary,
                    textColor: isDark ? darkText : lightText,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final doc = users[index];
                        final userData = doc.data() as Map<String, dynamic>;
                        final gameStats =
                            userData['gameStats'] as Map<String, dynamic>?;
                        final numberSequenceStats =
                            gameStats?['numberSequence'] as Map<String, dynamic>?;
                        final isCurrentUser = doc.id == _currentUserId;

                        final level = numberSequenceStats?['highestLevel'] ?? 0;
                        final lastPlayed = numberSequenceStats?['lastPlayed']?.toDate() ?? DateTime.now();
                        final username = userData['username'] ?? 'Anonymous';
                        final profileImageUrl =
                            userData['profileImageUrl'] ?? '';

                        if (index < 3) {
                          return _buildTopPlayerCard(
                            context,
                            index,
                            username,
                            level,
                            lastPlayed,
                            profileImageUrl,
                            isCurrentUser,
                            isDark,
                            cardColor: isDark ? darkCard : lightCard,
                            textColor: isDark ? darkText : lightText,
                            subtextColor: isDark ? darkSubtext : lightSubtext,
                            highlightColor: isDark ? darkHighlight : lightHighlight,
                          ).animate().fadeIn(duration: 150.ms, delay: (50 * index).ms);
                        }

                        return _buildLeaderboardItem(
                          context,
                          index,
                          username,
                          level,
                          lastPlayed,
                          profileImageUrl,
                          isCurrentUser,
                          isDark,
                          cardColor: isDark ? darkCard : lightCard,
                          textColor: isDark ? darkText : lightText,
                          subtextColor: isDark ? darkSubtext : lightSubtext,
                          highlightColor: isDark ? darkHighlight : lightHighlight,
                        ).animate().fadeIn(duration: 100.ms, delay: (100 + 20 * index).ms);
                      },
                      childCount: users.length,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroSection(
    BuildContext context, 
    bool isDark, {
    required Color primary,
    required Color textColor,
  }) {
    return Container(
      height: 180,
      width: double.infinity,
      color: primary,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.numbers,
            size: 60,
            color: Colors.white,
          ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 8),
          Text(
            'Number Sequence Leaders',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ).animate().fadeIn(duration: 300.ms),
        ],
      ),
    );
  }

  Widget _buildTopPlayerCard(
    BuildContext context,
    int index,
    String username,
    int level,
    DateTime lastPlayed,
    String profileImageUrl,
    bool isCurrentUser,
    bool isDark, {
    required Color cardColor,
    required Color textColor,
    required Color subtextColor,
    required Color highlightColor,
  }) {
    final medalColor = switch (index) {
      0 => const Color(0xFFFFD700), // Gold
      1 => const Color(0xFFC0C0C0), // Silver
      2 => const Color(0xFFCD7F32), // Bronze
      _ => Colors.transparent,
    };
    
    final medalIcon = switch (index) {
      0 => Icons.star,
      1 => Icons.star_half,
      2 => Icons.star_border,
      _ => Icons.circle,
    };

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      color: isCurrentUser ? highlightColor.withOpacity(0.2) : cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: isCurrentUser ? highlightColor : Colors.transparent,
          width: 2.0,
        ),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: highlightColor.withOpacity(0.2),
              child: profileImageUrl.isNotEmpty
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: profileImageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[300],
                          child: Icon(Icons.person, color: Colors.grey[600]),
                        ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.person, color: Colors.grey),
                      ),
                    )
                  : Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Text(
                    'Level: $level',
                    style: TextStyle(
                      fontSize: 18,
                      color: subtextColor,
                    ),
                  ),
                  Text(
                    'Last played: ${_formatDate(lastPlayed)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: subtextColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              medalIcon,
              size: 40,
              color: medalColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardItem(
    BuildContext context,
    int index,
    String username,
    int level,
    DateTime lastPlayed,
    String profileImageUrl,
    bool isCurrentUser,
    bool isDark, {
    required Color cardColor,
    required Color textColor,
    required Color subtextColor,
    required Color highlightColor,
  }) {
    return Card(
      color: isCurrentUser
          ? highlightColor.withOpacity(0.15)
          : cardColor,
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCurrentUser ? highlightColor : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: highlightColor.withOpacity(0.2),
          child: profileImageUrl.isNotEmpty
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: profileImageUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.person),
                  ),
                )
              : Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        title: Text(
          username,
          style: TextStyle(
            fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
            color: textColor,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Level: $level',
              style: TextStyle(
                color: subtextColor,
                fontSize: 14,
              ),
            ),
            Text(
              'Last played: ${_formatDate(lastPlayed)}',
              style: TextStyle(
                color: subtextColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: isCurrentUser
            ? Icon(
                Icons.star,
                color: highlightColor,
                size: 20,
              )
            : null,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildFastShimmerLoading(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          color: isDark ? const Color(0xFF1B263B) : Colors.white,
          child: const ListTile(
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey,
            ),
            title: SizedBox(
              height: 16,
              width: 150,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
              ),
            ),
            subtitle: SizedBox(
              height: 14,
              width: 100,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
              ),
            ),
          ),
        ).animate().fadeIn(duration: 100.ms, delay: (20 * index).ms);
      },
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cached_network_image/cached_network_image.dart';

// class LeaderboardScreen2 extends StatefulWidget {
//   const LeaderboardScreen2({super.key});

//   @override
//   State<LeaderboardScreen2> createState() => _LeaderboardScreen2State();
// }

// class _LeaderboardScreen2State extends State<LeaderboardScreen2> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   String? _currentUserId;

//   @override
//   void initState() {
//     super.initState();
//     _currentUserId = _auth.currentUser?.uid;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Number Sequence Leaderboard'),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: isDark
//                 ? [const Color(0xFF0D1B2A), const Color(0xFF071B2B)]
//                 : [const Color(0xFFFFF8E1), const Color(0xFFE1F5FE)],
//           ),
//         ),
//         child: StreamBuilder<QuerySnapshot>(
//           stream: _firestore
//               .collection('users')
//               .where('gameStats.numberSequence.highScore', isGreaterThan: 0)
//               .orderBy('gameStats.numberSequence.highScore', descending: true)
//               .limit(100)
//               .snapshots(),
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(child: CircularProgressIndicator());
//             }

//             if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//               return const Center(child: Text('No leaderboard data yet'));
//             }

//             final users = snapshot.data!.docs;

//             return ListView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: users.length,
//               itemBuilder: (context, index) {
//                 final doc = users[index];
//                 final userData = doc.data() as Map<String, dynamic>;
//                 final gameStats = userData['gameStats'] as Map<String, dynamic>?;
//                 final numberSequenceStats = gameStats?['numberSequence'] as Map<String, dynamic>?;
//                 final isCurrentUser = doc.id == _currentUserId;

//                 final highScore = numberSequenceStats?['highScore'] ?? 0;
//                 final level = numberSequenceStats?['highestLevel'] ?? 1;
//                 final username = userData['username'] ?? 'Anonymous';
//                 final profileImageUrl = userData['profileImageUrl'] ?? '';

//                 return Card(
//                   color: isCurrentUser
//                       ? (isDark ? Colors.blue[900] : Colors.blue[100])
//                       : (isDark ? const Color(0xFF1E2E43) : Colors.white),
//                   elevation: 2,
//                   margin: const EdgeInsets.symmetric(vertical: 4),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                     side: isCurrentUser
//                         ? BorderSide(
//                             color: isDark ? Colors.blueAccent : Colors.blue,
//                             width: 1.5)
//                         : BorderSide.none,
//                   ),
//                   child: ListTile(
//                     leading: CircleAvatar(
//                       radius: 24,
//                       backgroundColor: isDark ? Colors.blue[800] : Colors.blue[100],
//                       child: profileImageUrl.isNotEmpty
//                           ? ClipOval(
//                               child: CachedNetworkImage(
//                                 imageUrl: profileImageUrl,
//                                 width: 48,
//                                 height: 48,
//                                 fit: BoxFit.cover,
//                                 placeholder: (context, url) => Container(
//                                   color: Colors.grey[300],
//                                   child: const Icon(Icons.person, color: Colors.white),
//                                 ),
//                                 errorWidget: (context, url, error) => const Icon(Icons.person),
//                               ),
//                             )
//                           : Text(
//                               '${index + 1}',
//                               style: TextStyle(
//                                 color: isDark ? Colors.white : Colors.blue,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                     ),
//                     title: Text(
//                       username,
//                       style: TextStyle(
//                         fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
//                         color: isDark ? Colors.white : Colors.black,
//                       ),
//                     ),
//                     subtitle: Text(
//                       'Score: $highScore | Level: $level',
//                       style: TextStyle(
//                         color: isDark ? Colors.white70 : Colors.black54,
//                       ),
//                     ),
//                     trailing: index < 3
//                         ? Icon(
//                             index == 0
//                                 ? Icons.emoji_events
//                                 : index == 1
//                                     ? Icons.workspace_premium
//                                     : Icons.military_tech,
//                             color: index == 0
//                                 ? Colors.amber
//                                 : index == 1
//                                     ? Colors.grey[400]
//                                     : Colors.brown[400],
//                             size: 30,
//                           )
//                         : null,
//                   ),
//                 );
//               },
//             );
//           },
//         ),
//       ),
//     );
//   }
// }






// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cached_network_image/cached_network_image.dart';

// class LeaderboardScreen2 extends StatefulWidget {
//   const LeaderboardScreen2({super.key});

//   @override
//   State<LeaderboardScreen2> createState() => _LeaderboardScreen2State();
// }

// class _LeaderboardScreen2State extends State<LeaderboardScreen2> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   String? _currentUserId;

//   @override
//   void initState() {
//     super.initState();
//     _currentUserId = _auth.currentUser?.uid;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Leaderboard'),
//         centerTitle: true,
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: isDark
//                 ? [const Color(0xFF0D1B2A), const Color(0xFF071B2B)]
//                 : [const Color(0xFFFFF8E1), const Color(0xFFE1F5FE)],
//           ),
//         ),
//         child: StreamBuilder<QuerySnapshot>(
//           stream: _firestore
//               .collection('users')
//               .where('gameStats.numberSequence.highScore', isGreaterThan: 0)
//               .orderBy('gameStats.numberSequence.highScore', descending: true)
//               .limit(100)
//               .snapshots(),
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(child: CircularProgressIndicator());
//             }

//             if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//               return const Center(child: Text('No leaderboard data yet'));
//             }

//             return ListView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: snapshot.data!.docs.length,
//               itemBuilder: (context, index) {
//                 final doc = snapshot.data!.docs[index];
//                 final userData = doc.data() as Map<String, dynamic>;
//                 final gameStats = userData['gameStats'] as Map<String, dynamic>?;
//                 final numberSequenceStats = gameStats?['numberSequence'] as Map<String, dynamic>?;
//                 final isCurrentUser = doc.id == _currentUserId;

//                 final highScore = numberSequenceStats?['highScore'] ?? 0;
//                 final level = numberSequenceStats?['highestLevel'] ?? 1;
//                 final username = userData['username'] ?? 'Anonymous';
//                 final profileImageUrl = userData['profileImageUrl'] ?? '';

//                 return Card(
//                   color: isCurrentUser
//                       ? (isDark ? Colors.blue[900] : Colors.blue[100])
//                       : (isDark ? const Color(0xFF1E2E43) : Colors.white),
//                   child: ListTile(
//                     leading: CircleAvatar(
//                       backgroundImage: profileImageUrl.isNotEmpty 
//                           ? NetworkImage(profileImageUrl) 
//                           : null,
//                       child: profileImageUrl.isEmpty 
//                           ? Text('${index + 1}') 
//                           : null,
//                     ),
//                     title: Text(username),
//                     subtitle: Text('Score: $highScore | Level: $level'),
//                     trailing: index < 3 ? _getMedalIcon(index) : null,
//                   ),
//                 );
//               },
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Widget _getMedalIcon(int index) {
//     switch (index) {
//       case 0:
//         return const Icon(Icons.emoji_events, color: Colors.amber, size: 30);
//       case 1:
//         return const Icon(Icons.workspace_premium, color: Colors.grey, size: 30);
//       case 2:
//         return const Icon(Icons.military_tech, color: Colors.brown, size: 30);
//       default:
//         return const SizedBox();
//     }
//   }
// }