// import 'package:cloud_firestore/cloud_firestore.dart'; // DISABLED - Using Spring Boot Backend
import 'package:flutter/material.dart';
import 'dart:math';

class EcoChallengeData {
  final String id;
  final String title;
  final String description;
  final String category;
  final int targetValue;
  final int currentValue;
  final String unit;
  final String icon;
  final Color color;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCompleted;
  final double progress;
  final List<String> rewards;

  EcoChallengeData({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.targetValue,
    required this.currentValue,
    required this.unit,
    required this.icon,
    required this.color,
    required this.startDate,
    required this.endDate,
    required this.isCompleted,
    required this.progress,
    required this.rewards,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'unit': unit,
      'icon': icon,
      'color': color.value,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isCompleted': isCompleted,
      'progress': progress,
      'rewards': rewards,
    };
  }

  factory EcoChallengeData.fromMap(Map<String, dynamic> map) {
    return EcoChallengeData(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      targetValue: map['targetValue'] ?? 0,
      currentValue: map['currentValue'] ?? 0,
      unit: map['unit'] ?? '',
      icon: map['icon'] ?? '',
      color: Color(map['color'] ?? 0xFF4CAF50),
      startDate: DateTime.parse(map['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(map['endDate'] ?? DateTime.now().toIso8601String()),
      isCompleted: map['isCompleted'] ?? false,
      progress: (map['progress'] ?? 0.0).toDouble(),
      rewards: List<String>.from(map['rewards'] ?? []),
    );
  }
}

class EcoChallengesService {
  // DISABLED - Using Spring Boot Backend
  // All Firestore functionality has been moved to Spring Boot backend
  // This service is kept for compatibility but will be replaced with API calls

  // static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // static final CollectionReference _challengesCollection = _firestore.collection('eco_challenges');
  // static final CollectionReference _userChallengesCollection = _firestore.collection('user_challenges');
  // static final CollectionReference _challengeProgressCollection = _firestore.collection('challenge_progress');

  // Get all challenges
  static Future<List<EcoChallengeData>> getAllChallenges() async {
    // TODO: Implement with Spring Boot API
    return [];
  }

  // Get available challenges
  static Future<List<EcoChallengeData>> getAvailableChallenges() async {
    // TODO: Implement with Spring Boot API
    return [];
  }

  // Get user challenges
  static Future<List<EcoChallengeData>> getUserChallenges(String userId) async {
    // TODO: Implement with Spring Boot API
    return [];
  }

  // Join challenge
  static Future<Map<String, dynamic>> joinChallenge({
    required String userId,
    required String challengeId,
  }) async {
    // TODO: Implement with Spring Boot API
    return {
      'success': false,
      'message': 'Challenge joining will be implemented with Spring Boot backend',
    };
  }

  // Update challenge progress
  static Future<Map<String, dynamic>> updateChallengeProgress({
    required String userId,
    required String challengeId,
    required int progressValue,
  }) async {
    // TODO: Implement with Spring Boot API
    return {
      'success': false,
      'message': 'Challenge progress update will be implemented with Spring Boot backend',
    };
  }

  // Complete challenge
  static Future<Map<String, dynamic>> completeChallenge({
    required String userId,
    required String challengeId,
  }) async {
    // TODO: Implement with Spring Boot API
    return {
      'success': false,
      'message': 'Challenge completion will be implemented with Spring Boot backend',
    };
  }

  // Get challenge progress
  static Future<Map<String, dynamic>?> getChallengeProgress(String userId, String challengeId) async {
    // TODO: Implement with Spring Boot API
    return null;
  }

  // Get user challenge statistics
  static Future<Map<String, dynamic>> getUserChallengeStatistics(String userId) async {
    // TODO: Implement with Spring Boot API
    return {
      'totalChallenges': 0,
      'completedChallenges': 0,
      'activeChallenges': 0,
      'totalPoints': 0,
      'currentStreak': 0,
    };
  }

  // Get challenge leaderboard
  static Future<List<Map<String, dynamic>>> getChallengeLeaderboard(String challengeId) async {
    // TODO: Implement with Spring Boot API
    return [];
  }

  // Get user achievements
  static Future<List<Map<String, dynamic>>> getUserAchievements(String userId) async {
    // TODO: Implement with Spring Boot API
    return [];
  }

  // Get challenge categories
  static Future<List<String>> getChallengeCategories() async {
    // TODO: Implement with Spring Boot API
    return [
      'Energy Saving',
      'Waste Reduction',
      'Transportation',
      'Water Conservation',
      'Sustainable Shopping',
      'Carbon Footprint',
    ];
  }

  // Get challenge rewards
  static Future<List<Map<String, dynamic>>> getChallengeRewards(String challengeId) async {
    // TODO: Implement with Spring Boot API
    return [];
  }

  // Claim challenge reward
  static Future<Map<String, dynamic>> claimChallengeReward({
    required String userId,
    required String challengeId,
    required String rewardId,
  }) async {
    // TODO: Implement with Spring Boot API
    return {
      'success': false,
      'message': 'Reward claiming will be implemented with Spring Boot backend',
    };
  }

  // Get challenge suggestions
  static Future<List<EcoChallengeData>> getChallengeSuggestions(String userId) async {
    // TODO: Implement with Spring Boot API
    return [];
  }

  // Create custom challenge
  static Future<Map<String, dynamic>> createCustomChallenge({
    required String userId,
    required String title,
    required String description,
    required String category,
    required int targetValue,
    required String unit,
    required DateTime endDate,
  }) async {
    // TODO: Implement with Spring Boot API
    return {
      'success': false,
      'message': 'Custom challenge creation will be implemented with Spring Boot backend',
    };
  }

  // Share challenge
  static Future<Map<String, dynamic>> shareChallenge(String challengeId) async {
    // TODO: Implement with Spring Boot API
    return {
      'success': false,
      'message': 'Challenge sharing will be implemented with Spring Boot backend',
    };
  }

  // Get challenge analytics
  static Future<Map<String, dynamic>> getChallengeAnalytics(String challengeId) async {
    // TODO: Implement with Spring Boot API
    return {
      'totalParticipants': 0,
      'completionRate': 0.0,
      'averageProgress': 0.0,
      'topPerformers': [],
    };
  }

  // Initialize sample challenges (for development/testing)
  static Future<void> initializeSampleChallenges() async {
    // TODO: Implement with Spring Boot API
    print('Sample challenges initialization will be implemented with Spring Boot backend');
  }

  // Get user progress for challenges
  static Future<List<Map<String, dynamic>>> getUserProgress(String userId) async {
    // TODO: Implement with Spring Boot API
    return [];
  }

  // Get user challenge statistics
  static Future<Map<String, dynamic>> getUserChallengeStats(String userId) async {
    // TODO: Implement with Spring Boot API
    return {
      'totalPoints': 0,
      'completedChallenges': 0,
      'activeChallenges': 0,
    };
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
    // TODO: Implement with Spring Boot API
    return {
      'success': false,
      'message': 'Challenge creation will be implemented with Spring Boot backend',
    };
  }

  // Delete a challenge
  static Future<Map<String, dynamic>> deleteChallenge({
    required String challengeId,
    required String userId,
  }) async {
    // TODO: Implement with Spring Boot API
    return {
      'success': false,
      'message': 'Challenge deletion will be implemented with Spring Boot backend',
    };
  }
}