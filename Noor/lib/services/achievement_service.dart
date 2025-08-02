import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/achievement.dart';

/// Service for managing user achievements and progress
class AchievementService {
  static AchievementService? _instance;
  static AchievementService get instance => _instance ??= AchievementService._();
  
  AchievementService._();
  
  /// Create a new instance for testing
  static AchievementService createForTesting() => AchievementService._();

  static const String _achievementsKey = 'user_achievements';
  static const String _progressKey = 'achievement_progress';
  static const String _notificationsKey = 'achievement_notifications';

  final Map<String, Achievement> _availableAchievements = {};
  final Map<String, UserAchievement> _userAchievements = {};
  final Map<String, AchievementProgress> _achievementProgress = {};
  final List<String> _pendingNotifications = [];

  final StreamController<UserAchievement> _achievementEarnedController = 
      StreamController<UserAchievement>.broadcast();
  final StreamController<AchievementProgress> _progressUpdatedController = 
      StreamController<AchievementProgress>.broadcast();

  bool _isInitialized = false;

  /// Stream of newly earned achievements
  Stream<UserAchievement> get achievementEarned => _achievementEarnedController.stream;

  /// Stream of achievement progress updates
  Stream<AchievementProgress> get progressUpdated => _progressUpdatedController.stream;

  /// Initialize the achievement service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load predefined achievements
      _loadPredefinedAchievements();
      
      // Load user data from storage
      await _loadUserData();
      
      _isInitialized = true;
      
      if (kDebugMode) {
        print('AchievementService: Initialized with ${_availableAchievements.length} achievements');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AchievementService: Failed to initialize: $e');
      }
      rethrow;
    }
  }

  /// Check if the service is initialized
  bool get isInitialized => _isInitialized;

  /// Award an achievement to the user
  Future<bool> awardAchievement(String achievementId, String reason, {Map<String, dynamic>? context}) async {
    if (!_isInitialized) {
      throw StateError('AchievementService not initialized');
    }

    // Check if achievement exists
    final achievement = _availableAchievements[achievementId];
    if (achievement == null) {
      if (kDebugMode) {
        print('AchievementService: Achievement not found: $achievementId');
      }
      return false;
    }

    // Check if already earned
    if (_userAchievements.containsKey(achievementId)) {
      if (kDebugMode) {
        print('AchievementService: Achievement already earned: $achievementId');
      }
      return false;
    }

    try {
      // Create user achievement
      final userAchievement = UserAchievement(
        achievementId: achievementId,
        earnedAt: DateTime.now(),
        reason: reason,
        context: context,
        isNotified: false,
      );

      // Store the achievement
      _userAchievements[achievementId] = userAchievement;
      
      // Add to pending notifications
      _pendingNotifications.add(achievementId);

      // Save to storage
      await _saveUserData();

      // Notify listeners
      _achievementEarnedController.add(userAchievement);

      if (kDebugMode) {
        print('AchievementService: Awarded achievement: $achievementId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('AchievementService: Failed to award achievement $achievementId: $e');
      }
      return false;
    }
  }

  /// Update progress for an achievement
  Future<bool> updateProgress(String achievementId, int progress, {Map<String, dynamic>? metadata}) async {
    if (!_isInitialized) {
      throw StateError('AchievementService not initialized');
    }

    // Check if achievement exists
    final achievement = _availableAchievements[achievementId];
    if (achievement == null) {
      if (kDebugMode) {
        print('AchievementService: Achievement not found for progress update: $achievementId');
      }
      return false;
    }

    // Check if already earned
    if (_userAchievements.containsKey(achievementId)) {
      return true; // Already completed
    }

    try {
      // Get or create progress
      final currentProgress = _achievementProgress[achievementId];
      final targetProgress = _getTargetProgress(achievementId);
      
      final updatedProgress = AchievementProgress(
        achievementId: achievementId,
        currentProgress: progress,
        targetProgress: targetProgress,
        lastUpdated: DateTime.now(),
        metadata: metadata,
      );

      _achievementProgress[achievementId] = updatedProgress;

      // Check if achievement is now completed
      if (updatedProgress.isCompleted) {
        await awardAchievement(
          achievementId, 
          'Completed all requirements',
          context: {'progress': progress, 'target': targetProgress},
        );
      }

      // Save to storage
      await _saveUserData();

      // Notify listeners
      _progressUpdatedController.add(updatedProgress);

      if (kDebugMode) {
        print('AchievementService: Updated progress for $achievementId: $progress/$targetProgress');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('AchievementService: Failed to update progress for $achievementId: $e');
      }
      return false;
    }
  }

  /// Get all available achievements
  List<Achievement> getAvailableAchievements() {
    return _availableAchievements.values.toList();
  }

  /// Get user's earned achievements
  List<UserAchievement> getUserAchievements() {
    return _userAchievements.values.toList();
  }

  /// Get achievement progress
  List<AchievementProgress> getAchievementProgress() {
    return _achievementProgress.values.toList();
  }

  /// Get pending notifications
  List<String> getPendingNotifications() {
    return List.from(_pendingNotifications);
  }

  /// Mark achievement notification as seen
  Future<void> markNotificationSeen(String achievementId) async {
    _pendingNotifications.remove(achievementId);
    
    final userAchievement = _userAchievements[achievementId];
    if (userAchievement != null) {
      _userAchievements[achievementId] = userAchievement.copyWith(isNotified: true);
      await _saveUserData();
    }
  }

  /// Get achievement by ID
  Achievement? getAchievement(String achievementId) {
    return _availableAchievements[achievementId];
  }

  /// Check if user has earned an achievement
  bool hasEarnedAchievement(String achievementId) {
    return _userAchievements.containsKey(achievementId);
  }

  /// Get user's total achievement points
  int getTotalPoints() {
    int total = 0;
    for (final userAchievement in _userAchievements.values) {
      final achievement = _availableAchievements[userAchievement.achievementId];
      if (achievement != null) {
        total += (achievement.points * achievement.rarity.pointMultiplier).round();
      }
    }
    return total;
  }

  /// Get achievements by category
  List<Achievement> getAchievementsByCategory(AchievementCategory category) {
    return _availableAchievements.values
        .where((achievement) => achievement.category == category)
        .toList();
  }

  /// Load predefined achievements
  void _loadPredefinedAchievements() {
    final achievements = [
      // Learning achievements
      Achievement(
        id: 'first_question',
        title: 'Curious Mind',
        description: 'Asked your first question to the AI tutor',
        category: AchievementCategory.engagement,
        points: 5,
        iconName: 'help_outline',
        rarity: AchievementRarity.common,
      ),
      Achievement(
        id: 'first_chat',
        title: 'Getting Started',
        description: 'Started your first conversation with the AI tutor',
        category: AchievementCategory.engagement,
        points: 5,
        iconName: 'chat',
        rarity: AchievementRarity.common,
      ),
      Achievement(
        id: 'math_master',
        title: 'Math Master',
        description: 'Demonstrated excellent understanding in mathematics',
        category: AchievementCategory.mastery,
        points: 25,
        iconName: 'calculate',
        rarity: AchievementRarity.rare,
      ),
      Achievement(
        id: 'streak_7_days',
        title: 'Week Warrior',
        description: 'Maintained a 7-day learning streak',
        category: AchievementCategory.streak,
        points: 20,
        iconName: 'local_fire_department',
        rarity: AchievementRarity.uncommon,
      ),
      Achievement(
        id: 'streak_30_days',
        title: 'Monthly Master',
        description: 'Maintained a 30-day learning streak',
        category: AchievementCategory.streak,
        points: 50,
        iconName: 'whatshot',
        rarity: AchievementRarity.epic,
      ),
      Achievement(
        id: 'problem_solver',
        title: 'Problem Solver',
        description: 'Successfully solved 10 challenging problems',
        category: AchievementCategory.learning,
        points: 30,
        iconName: 'psychology',
        rarity: AchievementRarity.rare,
      ),
      Achievement(
        id: 'quick_learner',
        title: 'Quick Learner',
        description: 'Completed a lesson in record time',
        category: AchievementCategory.progress,
        points: 15,
        iconName: 'speed',
        rarity: AchievementRarity.uncommon,
      ),
      Achievement(
        id: 'vision_explorer',
        title: 'Vision Explorer',
        description: 'Used image-based learning for the first time',
        category: AchievementCategory.exploration,
        points: 10,
        iconName: 'camera_alt',
        rarity: AchievementRarity.common,
      ),
      Achievement(
        id: 'function_caller',
        title: 'Function Master',
        description: 'Triggered AI function calls successfully',
        category: AchievementCategory.exploration,
        points: 15,
        iconName: 'functions',
        rarity: AchievementRarity.uncommon,
      ),
      Achievement(
        id: 'course_complete',
        title: 'Course Conqueror',
        description: 'Completed your first course',
        category: AchievementCategory.progress,
        points: 40,
        iconName: 'school',
        rarity: AchievementRarity.rare,
      ),
      Achievement(
        id: 'helpful_ai',
        title: 'AI Assistant',
        description: 'Received helpful assistance from AI functions',
        category: AchievementCategory.engagement,
        points: 10,
        iconName: 'smart_toy',
        rarity: AchievementRarity.common,
      ),
      Achievement(
        id: 'progress_tracker',
        title: 'Progress Tracker',
        description: 'Consistently tracked learning progress',
        category: AchievementCategory.progress,
        points: 20,
        iconName: 'trending_up',
        rarity: AchievementRarity.uncommon,
      ),
    ];

    for (final achievement in achievements) {
      _availableAchievements[achievement.id] = achievement;
    }
  }

  /// Get target progress for progressive achievements
  int _getTargetProgress(String achievementId) {
    switch (achievementId) {
      case 'streak_7_days':
        return 7;
      case 'streak_30_days':
        return 30;
      case 'problem_solver':
        return 10;
      default:
        return 1;
    }
  }

  /// Load user data from storage
  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load user achievements
      final achievementsJson = prefs.getString(_achievementsKey);
      if (achievementsJson != null) {
        final achievementsData = jsonDecode(achievementsJson) as Map<String, dynamic>;
        for (final entry in achievementsData.entries) {
          _userAchievements[entry.key] = UserAchievement.fromJson(entry.value);
        }
      }

      // Load achievement progress
      final progressJson = prefs.getString(_progressKey);
      if (progressJson != null) {
        final progressData = jsonDecode(progressJson) as Map<String, dynamic>;
        for (final entry in progressData.entries) {
          _achievementProgress[entry.key] = AchievementProgress.fromJson(entry.value);
        }
      }

      // Load pending notifications
      final notificationsJson = prefs.getString(_notificationsKey);
      if (notificationsJson != null) {
        final notificationsList = jsonDecode(notificationsJson) as List<dynamic>;
        _pendingNotifications.clear();
        _pendingNotifications.addAll(notificationsList.cast<String>());
      }
    } catch (e) {
      if (kDebugMode) {
        print('AchievementService: Failed to load user data: $e');
      }
    }
  }

  /// Save user data to storage
  Future<void> _saveUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save user achievements
      final achievementsData = <String, dynamic>{};
      for (final entry in _userAchievements.entries) {
        achievementsData[entry.key] = entry.value.toJson();
      }
      await prefs.setString(_achievementsKey, jsonEncode(achievementsData));

      // Save achievement progress
      final progressData = <String, dynamic>{};
      for (final entry in _achievementProgress.entries) {
        progressData[entry.key] = entry.value.toJson();
      }
      await prefs.setString(_progressKey, jsonEncode(progressData));

      // Save pending notifications
      await prefs.setString(_notificationsKey, jsonEncode(_pendingNotifications));
    } catch (e) {
      if (kDebugMode) {
        print('AchievementService: Failed to save user data: $e');
      }
    }
  }

  /// Dispose of the service and clean up resources
  void dispose() {
    if (!_achievementEarnedController.isClosed) {
      _achievementEarnedController.close();
    }
    if (!_progressUpdatedController.isClosed) {
      _progressUpdatedController.close();
    }
    _availableAchievements.clear();
    _userAchievements.clear();
    _achievementProgress.clear();
    _pendingNotifications.clear();
    _isInitialized = false;
    
    if (kDebugMode) {
      print('AchievementService: Disposed');
    }
  }
}