// import 'package:flutter/material.dart';

// class SettingsController extends ChangeNotifier {
//   bool _soundEffects = true;
//   bool _backgroundMusic = false;
//   bool _isDarkMode = false;

//     int highestUnlockedLevel = 1;

//   bool get soundEffects => _soundEffects;
//   bool get backgroundMusic => _backgroundMusic;
//   bool get isDarkMode => _isDarkMode;

//   void toggleDarkMode(bool value) {
//     _isDarkMode = value;
//     notifyListeners();
//   }

//     void unlockNextLevel(int level) {
//     if (level >= highestUnlockedLevel) {
//       highestUnlockedLevel = level + 1;
//       notifyListeners();
//     }
//   }

//   void toggleSoundEffects(bool value) {
//     _soundEffects = value;
//     notifyListeners();
//   }

//   void toggleBackgroundMusic(bool value) {
//     _backgroundMusic = value;
//     notifyListeners();
//   }
  
// }


// import 'package:flutter/material.dart';
// import 'package:audioplayers/audioplayers.dart';

// class SettingsController extends ChangeNotifier {
//   bool _soundEffects = true;
//   bool _backgroundMusic = false;
//   bool _isDarkMode = false;

//   int highestUnlockedLevel = 1;

//   final AudioPlayer _audioPlayer = AudioPlayer();

//   SettingsController() {
//     _initMusic();
//   }

//   bool get soundEffects => _soundEffects;
//   bool get backgroundMusic => _backgroundMusic;
//   bool get isDarkMode => _isDarkMode;


  

//   void toggleDarkMode(bool value) {
//     _isDarkMode = value;
//     notifyListeners();
//   }



//   void unlockNextLevel(int level) {
//     if (level >= highestUnlockedLevel) {
//       highestUnlockedLevel = level + 1;
//       notifyListeners();
//     }
//   }

// void resetProgress() {
//     highestUnlockedLevel = 1;
//     notifyListeners();
//   }

//   void toggleSoundEffects(bool value) {
//     _soundEffects = value;
//     notifyListeners();
//   }

//   void toggleBackgroundMusic(bool value) {
//     _backgroundMusic = value;
//     if (value) {
//       _playMusic();
//     } else {
//       _pauseMusic();
//     }
//     notifyListeners();
//   }

//   Future<void> _initMusic() async {
//     await _audioPlayer.setReleaseMode(ReleaseMode.loop);
//     if (_backgroundMusic) {
//       _playMusic();
//     }
//   }



//   Future<void> _playMusic() async {
//     print('Playing music...');
//     await _audioPlayer.play(AssetSource('audio/background_music.mp3'));
//   }

//   Future<void> _pauseMusic() async {
//     print('Pausing music...');
//     await _audioPlayer.pause();
//   }

//   @override
//   void dispose() {
//     _audioPlayer.dispose();
//     super.dispose();
//   }
// }

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends ChangeNotifier {
  bool _soundEffects = true;
  bool _isDarkMode = false;
  int _highestUnlockedLevel = 1;
  double _volumeLevel = 0.7;
  bool _isHapticFeedbackOn = true;

  // Advanced settings
  bool _enableAnimations = true;
  bool _enableNotifications = false;
  bool _enableCloudSync = false;

  final AudioPlayer _audioPlayer = AudioPlayer();

  // Keys for SharedPreferences
  static const String _soundEffectsKey = 'soundEffects';
  static const String _darkModeKey = 'isDarkMode';
  static const String _highestLevelKey = 'highestUnlockedLevel';
  static const String _volumeLevelKey = 'volumeLevel';
  static const String _hapticFeedbackKey = 'hapticFeedback';
  static const String _animationsKey = 'enableAnimations';
  static const String _notificationsKey = 'enableNotifications';
  static const String _cloudSyncKey = 'enableCloudSync';

  SettingsController() {
    _loadSettings();
  }

  // Getters
  bool get soundEffects => _soundEffects;
  bool get isDarkMode => _isDarkMode;
  int get highestUnlockedLevel => _highestUnlockedLevel;
  double get volumeLevel => _volumeLevel;
  bool get isHapticFeedbackOn => _isHapticFeedbackOn;
  bool get enableAnimations => _enableAnimations;
  bool get enableNotifications => _enableNotifications;
  bool get enableCloudSync => _enableCloudSync;

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEffects = prefs.getBool(_soundEffectsKey) ?? true;
    _isDarkMode = prefs.getBool(_darkModeKey) ?? false;
    _highestUnlockedLevel = prefs.getInt(_highestLevelKey) ?? 1;
    _volumeLevel = prefs.getDouble(_volumeLevelKey) ?? 0.7;
    _isHapticFeedbackOn = prefs.getBool(_hapticFeedbackKey) ?? true;
    _enableAnimations = prefs.getBool(_animationsKey) ?? true;
    _enableNotifications = prefs.getBool(_notificationsKey) ?? false;
    _enableCloudSync = prefs.getBool(_cloudSyncKey) ?? false;

    notifyListeners();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEffectsKey, _soundEffects);
    await prefs.setBool(_darkModeKey, _isDarkMode);
    await prefs.setInt(_highestLevelKey, _highestUnlockedLevel);
    await prefs.setDouble(_volumeLevelKey, _volumeLevel);
    await prefs.setBool(_hapticFeedbackKey, _isHapticFeedbackOn);
    await prefs.setBool(_animationsKey, _enableAnimations);
    await prefs.setBool(_notificationsKey, _enableNotifications);
    await prefs.setBool(_cloudSyncKey, _enableCloudSync);
  }

  // Volume control
  void setVolumeLevel(double value) {
    _volumeLevel = value;
    _saveSettings();
    notifyListeners();
  }

  // Haptic feedback
  void setHapticFeedback(bool value) {
    _isHapticFeedbackOn = value;
    _saveSettings();
    notifyListeners();
  }

  // Toggles
  void toggleSoundEffects(bool value) {
    _soundEffects = value;
    _saveSettings();
    notifyListeners();
  }

  void toggleDarkMode(bool value) {
    _isDarkMode = value;
    _saveSettings();
    notifyListeners();
  }

  void toggleAnimations(bool value) {
    _enableAnimations = value;
    _saveSettings();
    notifyListeners();
  }

  void toggleNotifications(bool value) {
    _enableNotifications = value;
    _saveSettings();
    notifyListeners();
  }

  void toggleCloudSync(bool value) {
    _enableCloudSync = value;
    _saveSettings();
    notifyListeners();
  }

  // Levels
  void unlockNextLevel(int currentLevel) {
    if (currentLevel + 1 > _highestUnlockedLevel) {
      _highestUnlockedLevel = currentLevel + 1;
      _saveSettings();
      notifyListeners();
    }
  }

  void resetProgress() {
    _highestUnlockedLevel = 1;
    _saveSettings();
    notifyListeners();
  }

  // High scores reset
  Future<void> resetHighScores() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('highScore', 0);
    await prefs.setInt('highestScore', 0);
    notifyListeners();
  }

  // Reset all settings
  Future<void> resetAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _soundEffects = true;
    _isDarkMode = false;
    _highestUnlockedLevel = 1;
    _volumeLevel = 0.7;
    _isHapticFeedbackOn = true;
    _enableAnimations = true;
    _enableNotifications = false;
    _enableCloudSync = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}


// import 'package:flutter/material.dart';////////////////////////////////////////
// import 'package:audioplayers/audioplayers.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class SettingsController extends ChangeNotifier {
//   bool _soundEffects = true;
//   bool _isDarkMode = false;
//   int _highestUnlockedLevel = 1;

//   // 🔹 New advanced settings
//   bool _enableAnimations = true;
//   bool _enableNotifications = false;
//   bool _enableCloudSync = false;

//   final AudioPlayer _audioPlayer = AudioPlayer();

//   // Keys for SharedPreferences
//   static const String _soundEffectsKey = 'soundEffects';
//   static const String _darkModeKey = 'isDarkMode';
//   static const String _highestLevelKey = 'highestUnlockedLevel';
//   static const String _animationsKey = 'enableAnimations';
//   static const String _notificationsKey = 'enableNotifications';
//   static const String _cloudSyncKey = 'enableCloudSync';

//   SettingsController() {
//     _loadSettings();
//   }

//   // Getters
//   bool get soundEffects => _soundEffects;
//   bool get isDarkMode => _isDarkMode;
//   int get highestUnlockedLevel => _highestUnlockedLevel;
//   bool get enableAnimations => _enableAnimations;
//   bool get enableNotifications => _enableNotifications;
//   bool get enableCloudSync => _enableCloudSync;

//   Future<void> _loadSettings() async {
//     final prefs = await SharedPreferences.getInstance();
//     _soundEffects = prefs.getBool(_soundEffectsKey) ?? true;
//     _isDarkMode = prefs.getBool(_darkModeKey) ?? false;
//     _highestUnlockedLevel = prefs.getInt(_highestLevelKey) ?? 1;

//     // 🔹 Load advanced settings
//     _enableAnimations = prefs.getBool(_animationsKey) ?? true;
//     _enableNotifications = prefs.getBool(_notificationsKey) ?? false;
//     _enableCloudSync = prefs.getBool(_cloudSyncKey) ?? false;

//     print(
//         'Loaded settings: soundEffects=$_soundEffects, isDarkMode=$_isDarkMode, '
//         'highestUnlockedLevel=$_highestUnlockedLevel, animations=$_enableAnimations, '
//         'notifications=$_enableNotifications, cloudSync=$_enableCloudSync');
//     notifyListeners();
//   }

//   Future<void> _saveSettings() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool(_soundEffectsKey, _soundEffects);
//     await prefs.setBool(_darkModeKey, _isDarkMode);
//     await prefs.setInt(_highestLevelKey, _highestUnlockedLevel);

//     // 🔹 Save advanced settings
//     await prefs.setBool(_animationsKey, _enableAnimations);
//     await prefs.setBool(_notificationsKey, _enableNotifications);
//     await prefs.setBool(_cloudSyncKey, _enableCloudSync);

//     print('Settings saved.');
//   }

//   // Toggles
//   void toggleSoundEffects(bool value) {
//     _soundEffects = value;
//     _saveSettings();
//     notifyListeners();
//   }

//   void toggleDarkMode(bool value) {
//     _isDarkMode = value;
//     _saveSettings();
//     notifyListeners();
//   }

//   void toggleAnimations(bool value) {
//     _enableAnimations = value;
//     _saveSettings();
//     notifyListeners();
//   }

//   void toggleNotifications(bool value) {
//     _enableNotifications = value;
//     _saveSettings();
//     notifyListeners();
//   }

//   void toggleCloudSync(bool value) {
//     _enableCloudSync = value;
//     _saveSettings();
//     notifyListeners();
//   }

//   // Levels
//   void unlockNextLevel(int currentLevel) {
//     if (currentLevel + 1 > _highestUnlockedLevel) {
//       _highestUnlockedLevel = currentLevel + 1;
//       _saveSettings();
//       notifyListeners();
//       print('Level ${currentLevel + 1} unlocked and saved.');
//     }
//   }

//   void resetProgress() {
//     _highestUnlockedLevel = 1;
//     _saveSettings();
//     notifyListeners();
//     print('Progress reset to Level 1.');
//   }

//   // High scores reset
//   Future<void> resetHighScores() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setInt('highScore', 0);
//     await prefs.setInt('highestScore', 0);
//     notifyListeners();
//   }

//   @override
//   void dispose() {
//     _audioPlayer.dispose();
//     super.dispose();
//   }
// }


// import 'package:flutter/material.dart';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:shared_preferences/shared_preferences.dart'; // Import this

// class SettingsController extends ChangeNotifier {
//   bool _soundEffects = true;
  
//   // bool _backgroundMusic = false;
//   bool _isDarkMode = false;

//   int _highestUnlockedLevel = 1; // Make this private to control access

//   final AudioPlayer _audioPlayer = AudioPlayer();

//   // Keys for SharedPreferences
//   static const String _soundEffectsKey = 'soundEffects';
//   // static const String _backgroundMusicKey = 'backgroundMusic';
//   static const String _darkModeKey = 'isDarkMode';
//   static const String _highestLevelKey = 'highestUnlockedLevel'; // New key for level

//   SettingsController() {
//     _loadSettings(); // Load all settings when the controller is created
//     // _initMusic();
//   }

//   bool get soundEffects => _soundEffects;
//   // bool get backgroundMusic => _backgroundMusic;
//   bool get isDarkMode => _isDarkMode;
//   int get highestUnlockedLevel => _highestUnlockedLevel; // Public getter

//   Future<void> _loadSettings() async {
//     final prefs = await SharedPreferences.getInstance();
//     _soundEffects = prefs.getBool(_soundEffectsKey) ?? true;
//     // _backgroundMusic = prefs.getBool(_backgroundMusicKey) ?? false;
//     _isDarkMode = prefs.getBool(_darkModeKey) ?? false;
//     _highestUnlockedLevel = prefs.getInt(_highestLevelKey) ?? 1; // Load highest level

//     print('Loaded settings: soundEffects=$_soundEffects,isDarkMode=$_isDarkMode, highestUnlockedLevel=$_highestUnlockedLevel');
//     notifyListeners(); // Notify listeners once settings are loaded
//   }

//   Future<void> _saveSettings() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool(_soundEffectsKey, _soundEffects);
//     // await prefs.setBool(_backgroundMusicKey, _backgroundMusic);
//     await prefs.setBool(_darkModeKey, _isDarkMode);
//     await prefs.setInt(_highestLevelKey, _highestUnlockedLevel); // Save highest level
//     print('Settings saved: highestUnlockedLevel=$_highestUnlockedLevel');
//   }

//   void toggleDarkMode(bool value) {
//     _isDarkMode = value;
//     _saveSettings(); // Save changes
//     notifyListeners();
//   }

//   void unlockNextLevel(int currentLevel) {
//     // Only unlock if the current level is greater than or equal to the previously unlocked level
//     if (currentLevel + 1 > _highestUnlockedLevel) {
//       _highestUnlockedLevel = currentLevel + 1;
//       _saveSettings(); // Save the new highest level
//       notifyListeners();
//       print('Level ${currentLevel + 1} unlocked and saved.');
//     } else {
//       print('Level ${currentLevel + 1} is already unlocked or not a new highest.');
//     }
//   }

//   void resetProgress() {
//     _highestUnlockedLevel = 1; // Reset to 1
//     _saveSettings(); // Save the reset progress
//     notifyListeners();
//     print('Progress reset to Level 1.');
//   }

//   void toggleSoundEffects(bool value) {
//     _soundEffects = value;
//     _saveSettings(); // Save changes
//     notifyListeners();
//   }

//   // void toggleBackgroundMusic(bool value) {
//   //   _backgroundMusic = value;
//   //   if (value) {
//   //     _playMusic();
//   //   } else {
//   //     _pauseMusic();
//   //   }
//   //   _saveSettings(); // Save changes
//   //   notifyListeners();
//   // }

//   // Future<void> _initMusic() async {
//   //   await _audioPlayer.setReleaseMode(ReleaseMode.loop);
//   //   // Removed direct play here; it will be played via toggleBackgroundMusic if _backgroundMusic is true after loading.
//   // }

//   // Future<void> _playMusic() async {
//   //   print('Playing music...');
//   //   await _audioPlayer.play(AssetSource('sounds/background.mp3')); // Ensure correct path 'sounds/' not 'audio/'
//   // }

//   // Future<void> _pauseMusic() async {
//   //   print('Pausing music...');
//   //   await _audioPlayer.pause();
//   // }

//   // Add this method to reset high scores
//   Future<void> resetHighScores() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setInt('highScore', 0); // For number sequence game
//     await prefs.setInt('highestScore', 0); // For memory game (tile one)
//     notifyListeners();
//   }

//   @override
//   void dispose() {
//     _audioPlayer.dispose();
//     super.dispose();
//   }
// }