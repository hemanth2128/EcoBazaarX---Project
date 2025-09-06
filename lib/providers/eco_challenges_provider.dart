import 'package:flutter/material.dart';
import 'dart:math';
import '../services/eco_challenges_service.dart';

class EcoChallenge {
  final String id;
  final String title;
  final String description;
  final String reward;
  final Color color;
  final IconData icon;
  final int targetValue;
  final String targetUnit;
  final DateTime startDate;
  final DateTime endDate;
  final String category;
  final bool isActive;
  final bool isCompleted;
  final int currentProgress;
  final double progressPercentage;

  EcoChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.reward,
    required this.color,
    required this.icon,
    required this.targetValue,
    required this.targetUnit,
    required this.startDate,
    required this.endDate,
    required this.category,
    this.isActive = true,
    this.isCompleted = false,
    this.currentProgress = 0,
    this.progressPercentage = 0.0,
  });

  EcoChallenge copyWith({
    String? id,
    String? title,
    String? description,
    String? reward,
    Color? color,
    IconData? icon,
    int? targetValue,
    String? targetUnit,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    bool? isActive,
    bool? isCompleted,
    int? currentProgress,
    double? progressPercentage,
  }) {
    return EcoChallenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      reward: reward ?? this.reward,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      targetValue: targetValue ?? this.targetValue,
      targetUnit: targetUnit ?? this.targetUnit,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      isCompleted: isCompleted ?? this.isCompleted,
      currentProgress: currentProgress ?? this.currentProgress,
      progressPercentage: progressPercentage ?? this.progressPercentage,
    );
  }
}

class EcoChallengesProvider extends ChangeNotifier {
  static EcoChallengesProvider? _instance;
  
  factory EcoChallengesProvider() {
    _instance ??= EcoChallengesProvider._internal();
    return _instance!;
  }
  
  EcoChallengesProvider._internal() {
    print('EcoChallengesProvider initialized');
  }

  final List<EcoChallenge> _challenges = [];
  int _totalEcoPoints = 0;
  bool _isLoading = false;
  String? _error;

  List<EcoChallenge> get activeChallenges => _challenges.where((c) => c.isActive && !c.isCompleted).toList();
  List<EcoChallenge> get completedChallenges => _challenges.where((c) => c.isCompleted).toList();
  List<EcoChallenge> get allChallenges => List.from(_challenges);
  int get totalEcoPoints => _totalEcoPoints;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load challenges from Firestore
  Future<void> loadChallenges() async {
    _setLoading(true);
    _clearError();
    
    try {
      final challengesData = await EcoChallengesService.getAllChallenges();
      _challenges.clear();
      
      for (final challengeData in challengesData) {
        final challenge = EcoChallenge(
          id: challengeData.id,
          title: challengeData.title,
          description: challengeData.description,
          reward: challengeData.rewards.isNotEmpty ? challengeData.rewards.first : 'Eco Points',
          color: challengeData.color,
          icon: _parseIcon(challengeData.icon),
          targetValue: challengeData.targetValue,
          targetUnit: challengeData.unit,
          startDate: challengeData.startDate,
          endDate: challengeData.endDate,
          category: challengeData.category,
          isActive: !challengeData.isCompleted,
          isCompleted: challengeData.isCompleted,
          currentProgress: challengeData.currentValue,
          progressPercentage: challengeData.progress,
        );
        _challenges.add(challenge);
      }
      
      print('Challenges loaded from Firestore: ${_challenges.length}');
      notifyListeners();
    } catch (e) {
      _setError('Failed to load challenges: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Initialize challenges (load from Firestore or create sample data)
  Future<void> initializeChallenges() async {
    await loadChallenges();
    
    // If no challenges exist, initialize sample data
    if (_challenges.isEmpty) {
      await EcoChallengesService.initializeSampleChallenges();
      await loadChallenges();
    }
  }

  // Load user progress from Firestore
  Future<void> loadUserProgress(String userId) async {
    try {
      final progressList = await EcoChallengesService.getUserProgress(userId);
      
      for (final progress in progressList) {
        final challengeIndex = _challenges.indexWhere((c) => c.id == progress['challengeId']);
        if (challengeIndex != -1) {
          final challenge = _challenges[challengeIndex];
          _challenges[challengeIndex] = challenge.copyWith(
            currentProgress: progress['currentProgress'] ?? 0,
            progressPercentage: (progress['progressPercentage'] ?? 0.0).toDouble(),
            isCompleted: progress['isCompleted'] ?? false,
          );
        }
      }
      
      // Load user stats
      final stats = await EcoChallengesService.getUserChallengeStats(userId);
      _totalEcoPoints = stats['totalPoints'] ?? 0;
      
      notifyListeners();
    } catch (e) {
      print('Error loading user progress: $e');
    }
  }

  void resetChallenge(String challengeId) {
    final challengeIndex = _challenges.indexWhere((c) => c.id == challengeId);
    if (challengeIndex != -1) {
      _challenges[challengeIndex] = _challenges[challengeIndex].copyWith(
        currentProgress: 0,
        progressPercentage: 0.0,
        isCompleted: false,
      );
      notifyListeners();
    }
  }

  void addCustomChallenge(EcoChallenge challenge) {
    print('Adding custom challenge: ${challenge.title}');
    _challenges.add(challenge);
    print('Total challenges now: ${_challenges.length}');
    print('Active challenges: ${activeChallenges.length}');
    notifyListeners();
  }

  List<EcoChallenge> getChallengesByCategory(String category) {
    return _challenges.where((c) => c.category == category).toList();
  }

  List<String> get categories {
    return _challenges.map((c) => c.category).toSet().toList();
  }

  int getCompletedChallengesCount() {
    return completedChallenges.length;
  }

  int getActiveChallengesCount() {
    return activeChallenges.length;
  }

  double getOverallProgress() {
    if (_challenges.isEmpty) return 0.0;
    final totalProgress = _challenges.fold(0.0, (sum, challenge) => sum + challenge.progressPercentage);
    return totalProgress / _challenges.length;
  }

  // Simulate daily progress updates
  void simulateDailyProgress(String userId) {
    for (final challenge in activeChallenges) {
      if (Random().nextDouble() < 0.3) { // 30% chance of progress
        final progress = Random().nextInt(3) + 1; // 1-3 progress points
        updateProgress(challenge.id, progress, userId);
      }
    }
  }

  // Load sample progress for demonstration
  void loadSampleProgress(String userId) {
    updateProgress('zero_waste_week', 4, userId);
    updateProgress('carbon_footprint_reduction', 12, userId);
    updateProgress('local_shopping', 2, userId);
    updateProgress('water_conservation', 350, userId);
    updateProgress('energy_saving', 8, userId);
    updateProgress('plant_based_meals', 6, userId);
    updateProgress('plastic_free_living', 8, userId);
    updateProgress('eco_transport', 12, userId);
  }

  // Force initialize challenges (for debugging)
  void forceInitialize() {
    if (_challenges.isEmpty) {
      print('Force initializing challenges...');
      initializeChallenges();
      print('Challenges initialized: ${_challenges.length}');
    }
  }

  // Create a new challenge
  Future<bool> createChallenge({
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
    _setLoading(true);
    _clearError();
    
    try {
      final result = await EcoChallengesService.createChallenge(
        userId: userId,
        title: title,
        description: description,
        reward: reward,
        color: color,
        icon: icon,
        targetValue: targetValue,
        targetUnit: targetUnit,
        category: category,
        durationDays: durationDays,
      );
      
      if (result['success']) {
        await loadChallenges();
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Failed to create challenge: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update challenge progress
  Future<bool> updateProgress(String challengeId, int progress, String userId) async {
    try {
      final result = await EcoChallengesService.updateChallengeProgress(
        userId: userId,
        challengeId: challengeId,
        progressValue: progress,
      );
      
      if (result['success']) {
        await loadUserProgress(userId);
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Failed to update progress: ${e.toString()}');
      return false;
    }
  }

  // Delete a challenge
  Future<bool> deleteChallenge(String challengeId, String userId) async {
    _setLoading(true);
    _clearError();
    
    try {
      final result = await EcoChallengesService.deleteChallenge(
        challengeId: challengeId,
        userId: userId,
      );
      
      if (result['success']) {
        await loadChallenges();
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Failed to delete challenge: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }


  IconData _parseIcon(String iconName) {
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
}
