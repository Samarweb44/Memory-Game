import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../controllers/settings_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;
  bool _isAdvancedSettingsExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    );
    
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.1), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 50),
    ]).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _colorAnimation = ColorTween(
      begin: Colors.amberAccent,
      end: Colors.deepPurpleAccent,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
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

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsController>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAppInfoDialog(context),
            tooltip: 'App Info',
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [Colors.black, Colors.indigo.shade900]
                : [const Color(0xFFFFA66B), const Color(0xFFC785FA)],
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
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: AnimatedBuilder(
                        animation: _scaleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Icon(
                              Icons.settings,
                              size: 60,
                              color: _colorAnimation.value,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildSettingCard(
                            context: context,
                            icon: Icons.volume_up,
                            title: 'Sound Effects',
                            value: settings.soundEffects,
                            onChanged: settings.toggleSoundEffects,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 10),
                          _buildVolumeSlider(
                            context: context,
                            isDark: isDark,
                            value: settings.volumeLevel,
                            onChanged: settings.setVolumeLevel,
                          ),
                          // const SizedBox(height: 10),
                          // _buildSettingCard(
                          //   context: context,
                          //   icon: Icons.vibration,
                          //   title: 'Haptic Feedback',
                          //   value: settings.isHapticFeedbackOn,
                          //   onChanged: (value) {
                          //     settings.setHapticFeedback(value);
                          //     if (value) {
                          //       HapticFeedback.lightImpact();
                          //     }
                          //   },
                          //   isDark: isDark,
                          // ),
                          const SizedBox(height: 20),
                          _buildThemeDropdown(
                            context: context,
                            isDark: isDark,
                            settings: settings,
                          ),
                          const SizedBox(height: 20),
                          _buildAdvancedSettingsSection(
                            context: context,
                            isDark: isDark,
                            settings: settings,
                          ),
                          const SizedBox(height: 20),
                          _buildResetButtonsRow(
                            context: context,
                            isDark: isDark,
                            settings: settings,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeSlider({
    required BuildContext context,
    required bool isDark,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black54 : Colors.amber.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.volume_down, color: isDark ? Colors.amber : Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: value,
                  onChanged: onChanged,
                  activeColor: Colors.amber,
                  inactiveColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  divisions: 10,
                  label: '${(value * 100).round()}%',
                ),
              ),
              Icon(Icons.volume_up, color: isDark ? Colors.amber : Colors.orange),
            ],
          ),
          Text(
            'Volume Level: ${(value * 100).round()}%',
            style: TextStyle(
              color: isDark ? Colors.amber.shade200 : Colors.orange.shade900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSettingsSection({
    required BuildContext context,
    required bool isDark,
    required SettingsController settings,
  }) {
    return ExpansionTile(
      leading: Icon(
        Icons.build,
        color: isDark ? Colors.amber : Colors.orange,
      ),
      title: Text(
        'Advanced Settings',
        style: TextStyle(
          color: isDark ? Colors.amber.shade200 : Colors.orange.shade900,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: isDark ? Colors.white10 : Colors.white.withOpacity(0.3),
      collapsedBackgroundColor: isDark ? Colors.white10 : Colors.white.withOpacity(0.3),
      onExpansionChanged: (expanded) {
        setState(() => _isAdvancedSettingsExpanded = expanded);
        if (expanded) HapticFeedback.lightImpact();
      },
      trailing: AnimatedRotation(
        turns: _isAdvancedSettingsExpanded ? 0.25 : 0,
        duration: const Duration(milliseconds: 300),
        child: Icon(
          Icons.arrow_forward_ios,
          color: isDark ? Colors.amber : Colors.orange,
          size: 16,
        ),
      ),
      children: [
        _buildSettingCard(
          context: context,
          icon: Icons.animation,
          title: 'Enable Animations',
          value: settings.enableAnimations,
          onChanged: settings.toggleAnimations,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildResetButtonsRow({
    required BuildContext context,
    required bool isDark,
    required SettingsController settings,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildResetButton(
            context: context,
            icon: Icons.delete_forever,
            label: 'Reset Scores',
            color: Colors.redAccent,
            onPressed: () => _confirmReset(context, settings.resetHighScores, 'High scores'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildResetButton(
            context: context,
            icon: Icons.settings_backup_restore,
            label: 'Reset All',
            color: Colors.deepOrange,
            onPressed: () => _confirmReset(context, settings.resetAllSettings, 'all settings'),
          ),
        ),
      ],
    );
  }

  Widget _buildResetButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
    );
  }

  Future<void> _confirmReset(BuildContext context, VoidCallback resetFunction, String what) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Reset'),
        content: Text('Are you sure you want to reset $what? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      resetFunction();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$what reset!'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _resetAllSettings() async {
    // Add your reset logic here
    final settings = Provider.of<SettingsController>(context, listen: false);
    await settings.resetHighScores();
    setState(() {
      settings.setVolumeLevel(0.7);
      settings.setHapticFeedback(true);
    });
  }

  void _showAppInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('App Info'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Game Settings', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Version: 2.0.0'),
            Text('Build: 2025.3.1'),
            SizedBox(height: 16),
            Text('Customize your gaming experience with these settings.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black54 : Colors.amber.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: SwitchListTile.adaptive(
        secondary: Icon(icon, color: isDark ? Colors.amber : Colors.orange),
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.amber.shade200 : Colors.orange.shade900,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.amberAccent,
      ),
    );
  }

  Widget _buildThemeDropdown({
    required BuildContext context,
    required bool isDark,
    required SettingsController settings,
  }) {
    final iconColor = isDark ? Colors.amber.shade200 : Colors.orange.shade900;
    final textColor = isDark ? Colors.amber.shade200 : Colors.orange.shade900;
    final currentIcon = settings.isDarkMode ? Icons.nights_stay : Icons.wb_sunny;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.amber.shade300 : Colors.deepOrange.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.amber.withOpacity(0.2) : Colors.deepOrange.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        initialValue: settings.isDarkMode ? 'Dark' : 'Light',
        icon: const Icon(Icons.arrow_drop_down),
        iconEnabledColor: iconColor,
        dropdownColor: isDark ? Colors.grey.shade900 : Colors.white,
        decoration: InputDecoration(
          border: InputBorder.none,
          icon: Icon(currentIcon, color: iconColor),
          labelText: 'App Theme',
          labelStyle: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        items: [
          DropdownMenuItem(
            value: 'Dark',
            child: Text(
              'Dark Theme',
              style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
            ),
          ),
          DropdownMenuItem(
            value: 'Light',
            child: Text(
              'Light Theme',
              style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
            ),
          ),
          if (MediaQuery.of(context).platformBrightness == Brightness.dark)
            DropdownMenuItem(
              value: 'System',
              child: Text(
                'System Default',
                style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
              ),
            ),
        ],
        onChanged: (value) {
          if (value != null) {
            settings.toggleDarkMode(value == 'Dark');
          }
        },
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
    final Paint cometPaint = Paint()
      ..color = isDark ? Colors.blueAccent.withOpacity(0.6) : Colors.orangeAccent.withOpacity(0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    
    final Random random = Random(42);
    
    // Draw stars
    for (int i = 0; i < 150; i++) {
      final double x = random.nextDouble() * size.width;
      final double y = (random.nextDouble() * size.height +
              animation.value * size.height) %
          size.height;
      final double radius = random.nextDouble() * 2 + 1;
      canvas.drawCircle(Offset(x, y), radius, starPaint);
    }
    
    // Draw a comet
    final double cometX = size.width * 0.2 + animation.value * size.width * 0.6;
    final double cometY = size.height * 0.3 + sin(animation.value * 2 * pi) * 50;
    canvas.drawCircle(Offset(cometX, cometY), 4, starPaint);
    
    // Comet tail
    final path = Path();
    path.moveTo(cometX - 30, cometY - 10);
    path.lineTo(cometX, cometY);
    path.lineTo(cometX - 30, cometY + 10);
    canvas.drawPath(path, cometPaint);
  }

  @override
  bool shouldRepaint(covariant _AnimatedSpacePainter oldDelegate) => true;
}







// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../controllers/settings_controller.dart';

// class SettingsScreen extends StatefulWidget {
//   const SettingsScreen({super.key});

//   @override
//   State<SettingsScreen> createState() => _SettingsScreenState();
// }

// class _SettingsScreenState extends State<SettingsScreen>
//     with SingleTickerProviderStateMixin {
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

//   @override
//   Widget build(BuildContext context) {
//     final settings = Provider.of<SettingsController>(context);
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Game Settings'),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         foregroundColor: isDark ? Colors.white : Colors.black,
//       ),
//       extendBodyBehindAppBar: true,
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: isDark
//                 ? [Colors.black, Colors.black]
//                 : [const Color.fromARGB(255, 255, 166, 107), const Color.fromARGB(255, 199, 133, 250)],
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
//             SafeArea(
//               child: Padding(
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Center(
//                       child: Icon(
//                         Icons.settings,
//                         size: 60,
//                         color: isDark ? Colors.white70 : Colors.black54,
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                     Expanded(
//                       child: ListView(
//                         physics: const BouncingScrollPhysics(),
//                         children: [
//                           _buildSettingCard(
//                             context: context,
//                             icon: Icons.volume_up,
//                             title: 'Sound Effects',
//                             value: settings.soundEffects,
//                             onChanged: settings.toggleSoundEffects,
//                             isDark: isDark,
//                           ),
//                           // const SizedBox(height: 20),
//                           // _buildSettingCard(
//                           //   context: context,
//                           //   icon: Icons.music_note,
//                           //   title: 'Background Music',
//                           //   value: settings.backgroundMusic,
//                           //   onChanged: settings.toggleBackgroundMusic,
//                           //   isDark: isDark,
//                           // ),
//                           const SizedBox(height: 20),
//                           _buildThemeDropdown(
//                             context: context,
//                             isDark: isDark,
//                             settings: settings,
//                           ),
//                           const SizedBox(height: 20),
//                           // Reset High Scores button (single, not duplicated)
//                           Padding(
//                             padding: const EdgeInsets.symmetric(vertical: 8.0),
//                             child: ElevatedButton.icon(
//                               icon: const Icon(Icons.delete_forever, color: Colors.white),
//                               label: const Text(
//                                 'Reset High Scores',
//                                 style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
//                               ),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.redAccent,
//                                 padding: const EdgeInsets.symmetric(vertical: 16),
//                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                               ),
//                               onPressed: () async {
//                                 await settings.resetHighScores();
//                                 if (context.mounted) {
//                                   ScaffoldMessenger.of(context).showSnackBar(
//                                     const SnackBar(
//                                       content: Text('High scores reset!'),
//                                       backgroundColor: Colors.redAccent,
//                                     ),
//                                   );
//                                 }
//                               },
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSettingCard({
//     required BuildContext context,
//     required IconData icon,
//     required String title,
//     required bool value,
//     required Function(bool) onChanged,
//     required bool isDark,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         color: isDark ? Colors.white10 : Colors.white.withOpacity(0.8),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.amber.shade300, width: 2),
//         boxShadow: [
//           BoxShadow(
//             color: isDark ? Colors.black54 : Colors.amber.withOpacity(0.3),
//             blurRadius: 10,
//             offset: const Offset(2, 2),
//           ),
//         ],
//       ),
//       child: SwitchListTile.adaptive(
//         secondary: Icon(icon, color: isDark ? Colors.amber : Colors.orange),
//         title: Text(
//           title,
//           style: TextStyle(
//             color: isDark ? Colors.amber.shade200 : Colors.orange.shade900,
//             fontWeight: FontWeight.bold,
//             fontSize: 18,
//           ),
//         ),
//         value: value,
//         onChanged: onChanged,
//         activeColor: Colors.amberAccent,
//       ),
//     );
//   }

//   Widget _buildThemeDropdown({
//   required BuildContext context,
//   required bool isDark,
//   required SettingsController settings,
// }) {
//   final iconColor = isDark ? Colors.amber.shade200 : Colors.orange.shade900;
//   final textColor = isDark ? Colors.amber.shade200 : Colors.orange.shade900;
//   final currentIcon = settings.isDarkMode ? Icons.nights_stay : Icons.wb_sunny;

//   return Container(
//     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//     decoration: BoxDecoration(
//       color: isDark ? Colors.black.withOpacity(0.4) : Colors.white.withOpacity(0.85),
//       borderRadius: BorderRadius.circular(16),
//       border: Border.all(
//         color: isDark ? Colors.amber.shade300 : Colors.deepOrange.shade300,
//         width: 2,
//       ),
//       boxShadow: [
//         BoxShadow(
//           color: isDark ? Colors.amber.withOpacity(0.2) : Colors.deepOrange.withOpacity(0.2),
//           blurRadius: 12,
//           offset: const Offset(0, 4),
//         ),
//       ],
//     ),
//     child: DropdownButtonFormField<String>(
//       value: settings.isDarkMode ? 'Dark' : 'Light',
//       icon: const Icon(Icons.arrow_drop_down),
//       iconEnabledColor: iconColor,
//       dropdownColor: isDark ? Colors.grey.shade900 : Colors.white,
//       decoration: InputDecoration(
//         border: InputBorder.none,
//         icon: Icon(currentIcon, color: iconColor),
//         labelText: 'App Theme',
//         labelStyle: TextStyle(
//           color: textColor,
//           fontWeight: FontWeight.w600,
//           fontSize: 18,
//         ),
//       ),
//       items: [
//         DropdownMenuItem(
//           value: 'Dark',
//           child: Text(
//             'Dark Theme',
//             style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
//           ),
//         ),
//         DropdownMenuItem(
//           value: 'Light',
//           child: Text(
//             'Light Theme',
//             style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
//           ),
//         ),
//       ],
//       onChanged: (value) {
//         if (value != null) {
//           settings.toggleDarkMode(value == 'Dark');
//         }
//       },
//     ),
//   );
// }

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
