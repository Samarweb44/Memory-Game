// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter_animate/flutter_animate.dart'; // Add this to your pubspec.yaml
// import 'package:shimmer/shimmer.dart'; // Add this to your pubspec.yaml
// import 'dart:ui'; // For ImageFilter.blur
// // import 'package:shimmer_animation/shimmer_animation.dart';

// class LeaderboardScreen extends StatefulWidget {
//   const LeaderboardScreen({super.key});

//   @override
//   State<LeaderboardScreen> createState() => _LeaderboardScreenState();
// }

// class _LeaderboardScreenState extends State<LeaderboardScreen> {
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
//       extendBodyBehindAppBar: true, // Allows content to go behind the app bar
//       appBar: AppBar(
//         title: const Text(
//           'Memory Tile Leaderboard',
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             letterSpacing: 0.8,
//           ),
//         ),
//         centerTitle: true,
//         backgroundColor: Colors.transparent, // Make app bar transparent
//         elevation: 0, // Remove app bar shadow
//         flexibleSpace: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: isDark
//                   ? [Colors.deepPurple.shade900, Colors.indigo.shade900]
//                   : [Colors.deepPurple.shade300, Colors.indigo.shade300],
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
//                 ? [Colors.deepPurple.shade900, Colors.indigo.shade900]
//                 : [Colors.deepPurple.shade50, Colors.indigo.shade50],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: StreamBuilder<QuerySnapshot>(
//           stream: _firestore
//               .collection('users')
//               .where('gameStats.memoryTile.highScore', isGreaterThan: 0)
//               .orderBy('gameStats.memoryTile.highScore', descending: true)
//               .limit(100)
//               .snapshots(),
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return _buildShimmerLoading(isDark);
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
//                   child: _buildHeroSection(context, isDark),
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
//                         final memoryTileStats =
//                             gameStats?['memoryTile'] as Map<String, dynamic>?;
//                         final isCurrentUser = doc.id == _currentUserId;

//                         final highScore = memoryTileStats?['highScore'] ?? 0;
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
//                             profileImageUrl,
//                             isCurrentUser,
//                             isDark,
//                           ).animate().fadeIn(duration: 500.ms, delay: (100 * index).ms).slideY(begin: 0.2, end: 0);
//                         }

//                         // Normal list item for others
//                         return _buildLeaderboardItem(
//                           context,
//                           index,
//                           username,
//                           highScore,
//                           profileImageUrl,
//                           isCurrentUser,
//                           isDark,
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

//   Widget _buildHeroSection(BuildContext context, bool isDark) {
//     return Container(
//       height: 180,
//       width: double.infinity,
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: isDark
//               ? [Colors.deepPurple.shade800, Colors.indigo.shade800]
//               : [Colors.deepPurple.shade200, Colors.indigo.shade200],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
//         boxShadow: [
//           BoxShadow(
//             color: (isDark ? Colors.black : Colors.deepPurple).withOpacity(0.3),
//             blurRadius: 10,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           // This is where you could add an image or illustration
//           // Example: Image.asset('assets/leaderboard_hero.png', fit: BoxFit.cover, opacity: const AlwaysStoppedAnimation(0.5)),
//           Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 Icons.emoji_events,
//                 size: 60,
//                 color: isDark ? Colors.amberAccent : Colors.amber,
//               ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
//               const SizedBox(height: 8),
//               Text(
//                 'Top Players',
//                 style: TextStyle(
//                   fontSize: 28,
//                   fontWeight: FontWeight.bold,
//                   color: isDark ? Colors.white : Colors.deepPurple[900],
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
//     String profileImageUrl,
//     bool isCurrentUser,
//     bool isDark,
//   ) {
//     Color medalColor;
//     IconData medalIcon;
//     switch (index) {
//       case 0:
//         medalColor = Colors.amber.shade600;
//         medalIcon = Icons.emoji_events;
//         break;
//       case 1:
//         medalColor = Colors.grey.shade400;
//         medalIcon = Icons.military_tech;
//         break;
//       case 2:
//         medalColor = Colors.brown.shade400;
//         medalIcon = Icons.workspace_premium;
//         break;
//       default:
//         medalColor = Colors.transparent;
//         medalIcon = Icons.star; // Should not be reached
//     }

//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(15),
//         side: isCurrentUser
//             ? BorderSide(
//                 color: isDark ? Colors.amberAccent : Colors.deepPurple,
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
//                       backgroundColor: isDark ? Colors.deepPurple : Colors.deepPurple[100],
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
//                                 color: isDark ? Colors.white : Colors.deepPurple,
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
//                             'Score: $highScore',
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
//     String profileImageUrl,
//     bool isCurrentUser,
//     bool isDark,
//   ) {
//     return Card(
//       color: isCurrentUser
//           ? (isDark ? Colors.deepPurple[800] : Colors.deepPurple[100])
//           : (isDark ? Colors.grey[900] : Colors.white),
//       elevation: 4,
//       margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//         side: isCurrentUser
//             ? BorderSide(
//                 color: isDark ? Colors.deepPurpleAccent : Colors.deepPurple,
//                 width: 1.5)
//             : BorderSide.none,
//       ),
//       child: ListTile(
//         leading: CircleAvatar(
//           radius: 24,
//           backgroundColor: isDark ? Colors.deepPurple[600] : Colors.deepPurple[100],
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
//                     color: isDark ? Colors.white : Colors.deepPurple,
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
//           'Score: $highScore',
//           style: TextStyle(
//             color: isDark ? Colors.white70 : Colors.black54,
//             fontSize: 14,
//           ),
//         ),
//         trailing: isCurrentUser
//             ? Icon(
//                 Icons.star,
//                 color: isDark ? Colors.amberAccent : Colors.deepPurple,
//                 size: 20,
//               )
//             : null,
//       ),
//     );
//   }

//   Widget _buildShimmerLoading(bool isDark) {
//     return Shimmer.fromColors(
//       baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
//       highlightColor: isDark ? Colors.grey.shade600 : Colors.grey.shade100,
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
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
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
    const lightPrimary = Color.fromARGB(255, 187, 180, 239);  // Purple
    const lightSecondary = Color(0xFF00CEFF);  // Cyan
    const lightBackground = Color(0xFFF5F6FA);  // Very light gray
    const lightCard = Colors.white;
    const lightText = Color(0xFF2D3436);  // Dark gray
    const lightSubtext = Color(0xFF636E72);  // Gray
    
    // Color scheme for dark mode
    const darkPrimary = Color.fromARGB(255, 86, 63, 153);  // Light purple
    const darkSecondary = Color(0xFF67E8F9);  // Light cyan
    const darkBackground = Color(0xFF1E1E2E);  // Dark navy
    const darkCard = Color(0xFF2D2D3D);  // Slightly lighter navy
    const darkText = Colors.white;
    const darkSubtext = Color(0xFFA1A1AA);  // Light gray

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Memory Tile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDark ? darkPrimary : lightPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color.fromARGB(255, 0, 0, 0)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: isDark ? darkBackground : lightBackground,
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('users')
              .where('gameStats.memoryTile.highScore', isGreaterThan: 0)
              .orderBy('gameStats.memoryTile.highScore', descending: true)
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
                    secondary: isDark ? darkSecondary : lightSecondary,
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
                        final memoryTileStats =
                            gameStats?['memoryTile'] as Map<String, dynamic>?;
                        final isCurrentUser = doc.id == _currentUserId;

                        final highScore = memoryTileStats?['highScore'] ?? 0;
                        final username = userData['username'] ?? 'Anonymous';
                        final profileImageUrl =
                            userData['profileImageUrl'] ?? '';

                        if (index < 3) {
                          return _buildTopPlayerCard(
                            context,
                            index,
                            username,
                            highScore,
                            profileImageUrl,
                            isCurrentUser,
                            isDark,
                            cardColor: isDark ? darkCard : lightCard,
                            textColor: isDark ? darkText : lightText,
                            subtextColor: isDark ? darkSubtext : lightSubtext,
                            highlightColor: isDark ? darkPrimary : lightPrimary,
                          ).animate().fadeIn(duration: 150.ms, delay: (50 * index).ms);
                        }

                        return _buildLeaderboardItem(
                          context,
                          index,
                          username,
                          highScore,
                          profileImageUrl,
                          isCurrentUser,
                          isDark,
                          cardColor: isDark ? darkCard : lightCard,
                          textColor: isDark ? darkText : lightText,
                          subtextColor: isDark ? darkSubtext : lightSubtext,
                          highlightColor: isDark ? darkPrimary : lightPrimary,
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
    required Color secondary,
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
            Icons.emoji_events,
            size: 60,
            color: secondary,
          ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 8),
          Text(
            'Top Players',
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
    int highScore,
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
      0 => Icons.emoji_events,
      1 => Icons.military_tech,
      2 => Icons.workspace_premium,
      _ => Icons.star,
    };

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      color: cardColor,
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
                    'Score: $highScore',
                    style: TextStyle(
                      fontSize: 18,
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
    int highScore,
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
        subtitle: Text(
          'Score: $highScore',
          style: TextStyle(
            color: subtextColor,
            fontSize: 14,
          ),
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

  Widget _buildFastShimmerLoading(bool isDark) {
    final baseColor = isDark ? Colors.grey[800] : Colors.grey[300];
    final highlightColor = isDark ? Colors.grey[700] : Colors.grey[100];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          color: isDark ? const Color(0xFF2D2D3D) : Colors.white,
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


// class LeaderboardScreen extends StatefulWidget {
//   const LeaderboardScreen({super.key});

//   @override
//   State<LeaderboardScreen> createState() => _LeaderboardScreenState();
// }

// class _LeaderboardScreenState extends State<LeaderboardScreen> {
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
//         title: const Text('Memory Tile Leaderboard'),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: isDark
//                 ? [Colors.deepPurple.shade900, Colors.indigo.shade900]
//                 : [Colors.deepPurple.shade100, Colors.indigo.shade100],
//           ),
//         ),
//         child: StreamBuilder<QuerySnapshot>(
//           stream: _firestore
//               .collection('users')
//               .where('gameStats.memoryTile.highScore', isGreaterThan: 0)
//               .orderBy('gameStats.memoryTile.highScore', descending: true)
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
//                 final memoryTileStats = gameStats?['memoryTile'] as Map<String, dynamic>?;
//                 final isCurrentUser = doc.id == _currentUserId;

//                 final highScore = memoryTileStats?['highScore'] ?? 0;
//                 final username = userData['username'] ?? 'Anonymous';
//                 final profileImageUrl = userData['profileImageUrl'] ?? '';

//                 return Card(
//                   color: isCurrentUser
//                       ? (isDark ? Colors.deepPurple[800] : Colors.deepPurple[100])
//                       : (isDark ? Colors.grey[900] : Colors.white),
//                   elevation: 2,
//                   margin: const EdgeInsets.symmetric(vertical: 4),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                     side: isCurrentUser
//                         ? BorderSide(
//                             color: isDark ? Colors.deepPurpleAccent : Colors.deepPurple,
//                             width: 1.5)
//                         : BorderSide.none,
//                   ),
//                   child: ListTile(
//                     leading: CircleAvatar(
//                       radius: 24,
//                       backgroundColor: isDark ? Colors.deepPurple : Colors.deepPurple[100],
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
//                                 color: isDark ? Colors.white : Colors.deepPurple,
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
//                       'Score: $highScore',
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

// class LeaderboardScreen extends StatefulWidget {
//   const LeaderboardScreen({super.key});

//   @override
//   State<LeaderboardScreen> createState() => _LeaderboardScreenState();
// }

// class _LeaderboardScreenState extends State<LeaderboardScreen> {
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
//         child: StreamBuilder<QuerySnapshot>(
//           stream: _firestore
//               .collection('users')
//               .orderBy('highScore', descending: true)
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
//                 final userData = users[index].data() as Map<String, dynamic>;
//                 final isCurrentUser = users[index].id == _currentUserId;
//                 final profileImageUrl = userData['profileImageUrl'];

//                 return Card(
//                   color: isCurrentUser
//                       ? (isDark ? Colors.deepPurple[800] : Colors.deepPurple[100])
//                       : (isDark ? Colors.grey[900] : Colors.white),
//                   elevation: 2,
//                   margin: const EdgeInsets.symmetric(vertical: 4),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                     side: isCurrentUser
//                         ? BorderSide(
//                             color: isDark ? Colors.deepPurpleAccent : Colors.deepPurple,
//                             width: 1.5)
//                         : BorderSide.none,
//                   ),
//                   child: ListTile(
//                     leading: CircleAvatar(
//                       radius: 24,
//                       backgroundColor: isDark ? Colors.deepPurple : Colors.deepPurple[100],
//                       child: profileImageUrl != null && profileImageUrl.isNotEmpty
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
//                                 color: isDark ? Colors.white : Colors.deepPurple,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                     ),
//                     title: Text(
//                       userData['username'] ?? 'Anonymous',
//                       style: TextStyle(
//                         fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
//                         color: isDark ? Colors.white : Colors.black,
//                       ),
//                     ),
//                     subtitle: Text(
//                       'High Score: ${userData['highScore'] ?? 0}',
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