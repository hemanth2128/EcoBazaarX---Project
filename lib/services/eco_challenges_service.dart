import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class EcoChallengeData {
  final String id;
  final String title;
  final String description;
  final String reward;
  final String colorHex;
  final String iconName;
  final int targetValue;
  final String targetUnit;
  final DateTime startDate;
  final DateTime endDate;
  final String category;
  final bool isActive;
  final bool isCompleted;
  final int currentProgress;
  final double progressPercentage;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  EcoChallengeData({
    required this.id,
    required this.title,
    required this.description,
    required this.reward,
    required this.colorHex,
    required this.iconName,
    required this.targetValue,
    required this.targetUnit,
    required this.startDate,
    required this.endDate,
    required this.category,
    this.isActive = true,
    this.isCompleted = false,
    this.currentProgress = 0,
    this.progressPercentage = 0.0,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'reward': reward,
      'colorHex': colorHex,
      'iconName': iconName,
      'targetValue': targetValue,
      'targetUnit': targetUnit,
      'startDate': startDate,
      'endDate': endDate,
      'category': category,
      'isActive': isActive,
      'isCompleted': isCompleted,
      'currentProgress': currentProgress,
      'progressPercentage': progressPercentage,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? DateTime.now(),
    };
  }

  factory EcoChallengeData.fromMap(Map<String, dynamic> map) {
    return EcoChallengeData(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      reward: map['reward'] ?? '',
      colorHex: map['colorHex'] ?? '#B5C7F7',
      iconName: map['iconName'] ?? 'eco_rounded',
      targetValue: map['targetValue'] ?? 0,
      targetUnit: map['targetUnit'] ?? '',
      startDate: _parseDateTime(map['startDate']),
      endDate: _parseDateTime(map['endDate']),
      category: map['category'] ?? '',
      isActive: map['isActive'] ?? true,
      isCompleted: map['isCompleted'] ?? false,
      currentProgress: map['currentProgress'] ?? 0,
      progressPercentage: (map['progressPercentage'] ?? 0.0).toDouble(),
      createdBy: map['createdBy'] ?? '',
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }
}

class UserChallengeProgress {
  final String userId;
  final String challengeId;
  final int currentProgress;
  final double progressPercentage;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime lastUpdated;

  UserChallengeProgress({
    required this.userId,
    required this.challengeId,
    this.currentProgress = 0,
    this.progressPercentage = 0.0,
    this.isCompleted = false,
    this.completedAt,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'challengeId': challengeId,
      'currentProgress': currentProgress,
      'progressPercentage': progressPercentage,
      'isCompleted': isCompleted,
      'completedAt': completedAt,
      'lastUpdated': lastUpdated,
    };
  }

  factory UserChallengeProgress.fromMap(Map<String, dynamic> map) {
    return UserChallengeProgress(
      userId: map['userId'] ?? '',
      challengeId: map['challengeId'] ?? '',
      currentProgress: map['currentProgress'] ?? 0,
      progressPercentage: (map['progressPercentage'] ?? 0.0).toDouble(),
      isCompleted: map['isCompleted'] ?? false,
      completedAt: EcoChallengeData._parseDateTime(map['completedAt']),
      lastUpdated: EcoChallengeData._parseDateTime(map['lastUpdated']),
    );
  }
}

class EcoChallengesService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _challengesCollection = _firestore.collection('eco_challenges');
  static final CollectionReference _userProgressCollection = _firestore.collection('user_challenge_progress');
  static final CollectionReference _userStatsCollection = _firestore.collection('user_challenge_stats');

  // Generate unique challenge ID
  static String _generateChallengeId() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    final random = Random().nextInt(1000);
    return 'CHALLENGE_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_$random';
  }

  // Create a new challenge
  static Future<Map<String, dynamic>> createChallenge({
    required String userId,
    required String title,
    required String description,
    required String reward,
    required Color color,
    required IconData icon,
    required int targetValue,
    required String targetUnit,
    required String category,
    required int durationDays,
  }) async {
    try {
      final challengeId = _generateChallengeId();
      final now = DateTime.now();
      final endDate = now.add(Duration(days: durationDays));

      final challengeData = EcoChallengeData(
        id: challengeId,
        title: title,
        description: description,
        reward: reward,
        colorHex: '#${color.value.toRadixString(16).substring(2)}',
        iconName: _iconToString(icon),
        targetValue: targetValue,
        targetUnit: targetUnit,
        startDate: now,
        endDate: endDate,
        category: category,
        createdBy: userId,
        createdAt: now,
      );

      await _challengesCollection.doc(challengeId).set(challengeData.toMap());

      return {
        'success': true,
        'challengeId': challengeId,
        'message': 'Challenge created successfully!',
        'challengeData': challengeData.toMap(),
      };
    } catch (e) {
      print('Error creating challenge: $e');
      return {
        'success': false,
        'message': 'Failed to create challenge: ${e.toString()}',
      };
    }
  }

  // Get all challenges
  static Future<List<EcoChallengeData>> getAllChallenges() async {
    try {
      final snapshot = await _challengesCollection
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return EcoChallengeData.fromMap(data);
      }).toList();
    } catch (e) {
      print('Error getting challenges: $e');
      return [];
    }
  }

  // Get challenges by category
  static Future<List<EcoChallengeData>> getChallengesByCategory(String category) async {
    try {
      final snapshot = await _challengesCollection
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return EcoChallengeData.fromMap(data);
      }).toList();
    } catch (e) {
      print('Error getting challenges by category: $e');
      return [];
    }
  }

  // Get user's challenges
  static Future<List<EcoChallengeData>> getUserChallenges(String userId) async {
    try {
      final snapshot = await _challengesCollection
          .where('createdBy', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return EcoChallengeData.fromMap(data);
      }).toList();
    } catch (e) {
      print('Error getting user challenges: $e');
      return [];
    }
  }

  // Update challenge progress
  static Future<Map<String, dynamic>> updateChallengeProgress({
    required String userId,
    required String challengeId,
    required int progress,
  }) async {
    try {
      // Get current progress
      final progressDoc = await _userProgressCollection
          .where('userId', isEqualTo: userId)
          .where('challengeId', isEqualTo: challengeId)
          .get();

      final now = DateTime.now();
      int currentProgress = 0;
      double progressPercentage = 0.0;
      bool isCompleted = false;
      DateTime? completedAt;

      if (progressDoc.docs.isNotEmpty) {
        final existingProgress = UserChallengeProgress.fromMap(
          progressDoc.docs.first.data() as Map<String, dynamic>
        );
        currentProgress = existingProgress.currentProgress;
        progressPercentage = existingProgress.progressPercentage;
        isCompleted = existingProgress.isCompleted;
        completedAt = existingProgress.completedAt;
      }

      // Get challenge details
      final challengeDoc = await _challengesCollection.doc(challengeId).get();
      if (!challengeDoc.exists) {
        return {
          'success': false,
          'message': 'Challenge not found!',
        };
      }

      final challengeData = EcoChallengeData.fromMap(
        challengeDoc.data() as Map<String, dynamic>
      );

      // Update progress
      final newProgress = currentProgress + progress;
      final newProgressPercentage = (newProgress / challengeData.targetValue).clamp(0.0, 1.0);
      final newIsCompleted = newProgress >= challengeData.targetValue;
      final newCompletedAt = newIsCompleted && !isCompleted ? now : completedAt;

      final updatedProgress = UserChallengeProgress(
        userId: userId,
        challengeId: challengeId,
        currentProgress: newProgress,
        progressPercentage: newProgressPercentage,
        isCompleted: newIsCompleted,
        completedAt: newCompletedAt,
        lastUpdated: now,
      );

      // Save progress
      final progressId = '${userId}_$challengeId';
      await _userProgressCollection.doc(progressId).set(updatedProgress.toMap());

      // Update user stats if completed
      if (newIsCompleted && !isCompleted) {
        await _updateUserStats(userId, challengeData);
      }

      return {
        'success': true,
        'message': 'Progress updated successfully!',
        'progress': updatedProgress.toMap(),
        'isCompleted': newIsCompleted,
        'pointsEarned': newIsCompleted && !isCompleted ? _extractPoints(challengeData.reward) : 0,
      };
    } catch (e) {
      print('Error updating challenge progress: $e');
      return {
        'success': false,
        'message': 'Failed to update progress: ${e.toString()}',
      };
    }
  }

  // Get user's challenge progress
  static Future<List<UserChallengeProgress>> getUserProgress(String userId) async {
    try {
      final snapshot = await _userProgressCollection
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return UserChallengeProgress.fromMap(data);
      }).toList();
    } catch (e) {
      print('Error getting user progress: $e');
      return [];
    }
  }

  // Get user's completed challenges
  static Future<List<UserChallengeProgress>> getUserCompletedChallenges(String userId) async {
    try {
      final snapshot = await _userProgressCollection
          .where('userId', isEqualTo: userId)
          .where('isCompleted', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return UserChallengeProgress.fromMap(data);
      }).toList();
    } catch (e) {
      print('Error getting completed challenges: $e');
      return [];
    }
  }

  // Get user challenge statistics
  static Future<Map<String, dynamic>> getUserChallengeStats(String userId) async {
    try {
      final progressList = await getUserProgress(userId);
      final completedChallenges = await getUserCompletedChallenges(userId);
      
      int totalPoints = 0;
      int totalChallenges = progressList.length;
      int completedCount = completedChallenges.length;
      double averageProgress = 0.0;

      if (progressList.isNotEmpty) {
        averageProgress = progressList.fold(0.0, (sum, progress) => sum + progress.progressPercentage) / progressList.length;
      }

      // Calculate total points from completed challenges
      for (final progress in completedChallenges) {
        final challengeDoc = await _challengesCollection.doc(progress.challengeId).get();
        if (challengeDoc.exists) {
          final challengeData = EcoChallengeData.fromMap(
            challengeDoc.data() as Map<String, dynamic>
          );
          totalPoints += _extractPoints(challengeData.reward);
        }
      }

      return {
        'totalChallenges': totalChallenges,
        'completedChallenges': completedCount,
        'totalPoints': totalPoints,
        'averageProgress': averageProgress,
        'completionRate': totalChallenges > 0 ? (completedCount / totalChallenges) : 0.0,
      };
    } catch (e) {
      print('Error getting user stats: $e');
      return {
        'totalChallenges': 0,
        'completedChallenges': 0,
        'totalPoints': 0,
        'averageProgress': 0.0,
        'completionRate': 0.0,
      };
    }
  }

  // Delete a challenge
  static Future<Map<String, dynamic>> deleteChallenge({
    required String challengeId,
    required String userId,
  }) async {
    try {
      // Check if user owns the challenge
      final challengeDoc = await _challengesCollection.doc(challengeId).get();
      if (!challengeDoc.exists) {
        return {
          'success': false,
          'message': 'Challenge not found!',
        };
      }

      final challengeData = EcoChallengeData.fromMap(
        challengeDoc.data() as Map<String, dynamic>
      );

      if (challengeData.createdBy != userId) {
        return {
          'success': false,
          'message': 'You can only delete your own challenges!',
        };
      }

      await _challengesCollection.doc(challengeId).delete();

      return {
        'success': true,
        'message': 'Challenge deleted successfully!',
      };
    } catch (e) {
      print('Error deleting challenge: $e');
      return {
        'success': false,
        'message': 'Failed to delete challenge: ${e.toString()}',
      };
    }
  }

  // Initialize sample challenges
  static Future<void> initializeSampleChallenges() async {
    try {
      final snapshot = await _challengesCollection.limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        print('Sample challenges already exist, skipping initialization');
        return;
      }

      final now = DateTime.now();
      final sampleChallenges = [
        {
          'title': 'Zero Waste Week',
          'description': 'Go 7 days without producing any waste. Use reusable containers, avoid single-use plastics, and compost organic waste.',
          'reward': '500 Eco Points',
          'colorHex': '#B5C7F7',
          'iconName': 'recycling_rounded',
          'targetValue': 7,
          'targetUnit': 'days',
          'category': 'Waste Reduction',
          'durationDays': 7,
        },
        {
          'title': 'Carbon Footprint Reduction',
          'description': 'Reduce your daily carbon footprint by 20%. Walk or cycle instead of driving, use public transport, and choose eco-friendly products.',
          'reward': '300 Eco Points',
          'colorHex': '#F9E79F',
          'iconName': 'eco_rounded',
          'targetValue': 20,
          'targetUnit': '% reduction',
          'category': 'Carbon Reduction',
          'durationDays': 30,
        },
        {
          'title': 'Local Shopping Spree',
          'description': 'Buy from 5 local eco-friendly stores. Support local businesses and reduce transportation emissions.',
          'reward': '200 Eco Points',
          'colorHex': '#E8D5C4',
          'iconName': 'store_rounded',
          'targetValue': 5,
          'targetUnit': 'stores',
          'category': 'Local Support',
          'durationDays': 14,
        },
        {
          'title': 'Water Conservation',
          'description': 'Save 1000 liters of water this month. Take shorter showers, fix leaks, and use water-efficient appliances.',
          'reward': '400 Eco Points',
          'colorHex': '#00BCD4',
          'iconName': 'water_drop_rounded',
          'targetValue': 1000,
          'targetUnit': 'liters',
          'category': 'Water Conservation',
          'durationDays': 30,
        },
        {
          'title': 'Energy Saving Champion',
          'description': 'Reduce energy consumption by 15%. Switch to LED bulbs, unplug devices, and use natural light.',
          'reward': '350 Eco Points',
          'colorHex': '#FF9800',
          'iconName': 'electric_bolt_rounded',
          'targetValue': 15,
          'targetUnit': '% reduction',
          'category': 'Energy Conservation',
          'durationDays': 21,
        },
      ];

      for (final challenge in sampleChallenges) {
        await createChallenge(
          userId: 'system',
          title: challenge['title'] as String,
          description: challenge['description'] as String,
          reward: challenge['reward'] as String,
          color: _parseColor(challenge['colorHex'] as String),
          icon: _parseIcon(challenge['iconName'] as String),
          targetValue: challenge['targetValue'] as int,
          targetUnit: challenge['targetUnit'] as String,
          category: challenge['category'] as String,
          durationDays: challenge['durationDays'] as int,
        );
      }

      print('Sample challenges initialized successfully');
    } catch (e) {
      print('Error initializing sample challenges: $e');
    }
  }

  // Helper methods
  static String _iconToString(IconData icon) {
    final iconMap = {
      Icons.recycling_rounded: 'recycling_rounded',
      Icons.eco_rounded: 'eco_rounded',
      Icons.store_rounded: 'store_rounded',
      Icons.water_drop_rounded: 'water_drop_rounded',
      Icons.electric_bolt_rounded: 'electric_bolt_rounded',
      Icons.restaurant_rounded: 'restaurant_rounded',
      Icons.no_drinks_rounded: 'no_drinks_rounded',
      Icons.directions_bike_rounded: 'directions_bike_rounded',
      Icons.local_florist_rounded: 'local_florist_rounded',
      Icons.park_rounded: 'park_rounded',
      Icons.forest_rounded: 'forest_rounded',
      Icons.local_drink_rounded: 'local_drink_rounded',
      Icons.directions_bus_rounded: 'directions_bus_rounded',
      Icons.directions_walk_rounded: 'directions_walk_rounded',
      Icons.lightbulb_rounded: 'lightbulb_rounded',
      Icons.solar_power_rounded: 'solar_power_rounded',
      Icons.brush_rounded: 'brush_rounded',
      Icons.spa_rounded: 'spa_rounded',
      Icons.book_rounded: 'book_rounded',
      Icons.face_rounded: 'face_rounded',
      Icons.fitness_center_rounded: 'fitness_center_rounded',
      Icons.local_cafe_rounded: 'local_cafe_rounded',
    };
    
    return iconMap[icon] ?? 'eco_rounded';
  }

  static IconData _parseIcon(String iconName) {
    final iconMap = {
      'recycling_rounded': Icons.recycling_rounded,
      'eco_rounded': Icons.eco_rounded,
      'store_rounded': Icons.store_rounded,
      'water_drop_rounded': Icons.water_drop_rounded,
      'electric_bolt_rounded': Icons.electric_bolt_rounded,
      'restaurant_rounded': Icons.restaurant_rounded,
      'no_drinks_rounded': Icons.no_drinks_rounded,
      'directions_bike_rounded': Icons.directions_bike_rounded,
      'local_florist_rounded': Icons.local_florist_rounded,
      'park_rounded': Icons.park_rounded,
      'forest_rounded': Icons.forest_rounded,
      'local_drink_rounded': Icons.local_drink_rounded,
      'directions_bus_rounded': Icons.directions_bus_rounded,
      'directions_walk_rounded': Icons.directions_walk_rounded,
      'lightbulb_rounded': Icons.lightbulb_rounded,
      'solar_power_rounded': Icons.solar_power_rounded,
      'brush_rounded': Icons.brush_rounded,
      'spa_rounded': Icons.spa_rounded,
      'book_rounded': Icons.book_rounded,
      'face_rounded': Icons.face_rounded,
      'fitness_center_rounded': Icons.fitness_center_rounded,
      'local_cafe_rounded': Icons.local_cafe_rounded,
    };
    
    return iconMap[iconName] ?? Icons.eco_rounded;
  }

  static Color _parseColor(String colorHex) {
    try {
      String hex = colorHex.startsWith('#') ? colorHex.substring(1) : colorHex;
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (e) {
      print('Error parsing color: $colorHex - $e');
    }
    return const Color(0xFFB5C7F7);
  }

  static int _extractPoints(String reward) {
    try {
      final match = RegExp(r'(\d+)').firstMatch(reward);
      if (match != null) {
        return int.parse(match.group(1)!);
      }
    } catch (e) {
      print('Error extracting points from reward: $reward - $e');
    }
    return 0;
  }

  static Future<void> _updateUserStats(String userId, EcoChallengeData challenge) async {
    try {
      final statsDoc = await _userStatsCollection.doc(userId).get();
      final points = _extractPoints(challenge.reward);
      
      if (statsDoc.exists) {
        final currentData = statsDoc.data() as Map<String, dynamic>;
        final currentPoints = (currentData['totalPoints'] ?? 0) as int;
        final completedCount = (currentData['completedChallenges'] ?? 0) as int;
        
        await _userStatsCollection.doc(userId).update({
          'totalPoints': currentPoints + points,
          'completedChallenges': completedCount + 1,
          'lastUpdated': DateTime.now(),
        });
      } else {
        await _userStatsCollection.doc(userId).set({
          'userId': userId,
          'totalPoints': points,
          'completedChallenges': 1,
          'createdAt': DateTime.now(),
          'lastUpdated': DateTime.now(),
        });
      }
    } catch (e) {
      print('Error updating user stats: $e');
    }
  }
}
