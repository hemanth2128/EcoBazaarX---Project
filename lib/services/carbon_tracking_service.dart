import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class CarbonTrackingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _carbonActivitiesCollection = _firestore.collection('carbon_activities');
  static final CollectionReference _userCarbonStatsCollection = _firestore.collection('user_carbon_stats');
  static final CollectionReference _carbonGoalsCollection = _firestore.collection('carbon_goals');

  // Generate unique activity ID
  static String _generateActivityId() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    final random = Random().nextInt(1000);
    return 'CARB_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_$random';
  }

  // Record carbon saving activity
  static Future<Map<String, dynamic>> recordCarbonActivity({
    required String userId,
    required String activityType,
    required double carbonSaved,
    required String description,
    required String category,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final activityId = _generateActivityId();
      final now = DateTime.now();

      final activityData = {
        'id': activityId,
        'userId': userId,
        'activityType': activityType,
        'carbonSaved': carbonSaved,
        'description': description,
        'category': category,
        'additionalData': additionalData ?? {},
        'timestamp': now,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _carbonActivitiesCollection.doc(activityId).set(activityData);

      // Update user's total carbon stats
      await _updateUserCarbonStats(userId, carbonSaved);

      return {
        'success': true,
        'activityId': activityId,
        'message': 'Carbon activity recorded successfully!',
        'activityData': activityData,
      };
    } catch (e) {
      print('Error recording carbon activity: $e');
      return {
        'success': false,
        'message': 'Failed to record carbon activity: ${e.toString()}',
      };
    }
  }

  // Update user's total carbon statistics
  static Future<void> _updateUserCarbonStats(String userId, double carbonSaved) async {
    try {
      final userStatsDoc = _userCarbonStatsCollection.doc(userId);
      final doc = await userStatsDoc.get();

      if (doc.exists) {
        final currentData = doc.data() as Map<String, dynamic>;
        final currentTotal = (currentData['totalCarbonSaved'] ?? 0.0) as double;
        final currentActivities = (currentData['totalActivities'] ?? 0) as int;
        final currentStreak = (currentData['currentStreak'] ?? 0) as int;
        final lastActivityDate = currentData['lastActivityDate'] as Timestamp?;

        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        
        int newStreak = currentStreak;
        if (lastActivityDate != null) {
          final lastDate = lastActivityDate.toDate();
          if (lastDate.year == yesterday.year && 
              lastDate.month == yesterday.month && 
              lastDate.day == yesterday.day) {
            newStreak = currentStreak + 1;
          } else if (lastDate.year != today.year || 
                     lastDate.month != today.month || 
                     lastDate.day != today.day) {
            newStreak = 1;
          }
        } else {
          newStreak = 1;
        }

        await userStatsDoc.update({
          'totalCarbonSaved': currentTotal + carbonSaved,
          'totalActivities': currentActivities + 1,
          'currentStreak': newStreak,
          'lastActivityDate': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new user stats
        await userStatsDoc.set({
          'userId': userId,
          'totalCarbonSaved': carbonSaved,
          'totalActivities': 1,
          'currentStreak': 1,
          'lastActivityDate': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating user carbon stats: $e');
    }
  }

  // Get user's carbon statistics
  static Future<Map<String, dynamic>> getUserCarbonStats(String userId) async {
    try {
      final doc = await _userCarbonStatsCollection.doc(userId).get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'totalCarbonSaved': data['totalCarbonSaved'] ?? 0.0,
          'totalActivities': data['totalActivities'] ?? 0,
          'currentStreak': data['currentStreak'] ?? 0,
          'lastActivityDate': data['lastActivityDate'],
        };
      } else {
        return {
          'totalCarbonSaved': 0.0,
          'totalActivities': 0,
          'currentStreak': 0,
          'lastActivityDate': null,
        };
      }
    } catch (e) {
      print('Error getting user carbon stats: $e');
      return {
        'totalCarbonSaved': 0.0,
        'totalActivities': 0,
        'currentStreak': 0,
        'lastActivityDate': null,
      };
    }
  }

  // Get user's carbon activities
  static Future<List<Map<String, dynamic>>> getUserCarbonActivities(String userId, {int limit = 50}) async {
    try {
      final snapshot = await _carbonActivitiesCollection
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      final activities = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          ...data,
          'id': doc.id,
        };
      }).toList();

      return activities;
    } catch (e) {
      print('Error getting user carbon activities: $e');
      return [];
    }
  }

  // Get carbon activities by category
  static Future<List<Map<String, dynamic>>> getCarbonActivitiesByCategory(String userId, String category) async {
    try {
      final snapshot = await _carbonActivitiesCollection
          .where('userId', isEqualTo: userId)
          .where('category', isEqualTo: category)
          .orderBy('timestamp', descending: true)
          .get();

      final activities = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          ...data,
          'id': doc.id,
        };
      }).toList();

      return activities;
    } catch (e) {
      print('Error getting carbon activities by category: $e');
      return [];
    }
  }

  // Get carbon savings by time period
  static Future<Map<String, dynamic>> getCarbonSavingsByPeriod(String userId, String period) async {
    try {
      final now = DateTime.now();
      DateTime startDate;

      switch (period) {
        case 'today':
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case 'week':
          startDate = now.subtract(Duration(days: now.weekday - 1));
          startDate = DateTime(startDate.year, startDate.month, startDate.day);
          break;
        case 'month':
          startDate = DateTime(now.year, now.month, 1);
          break;
        case 'year':
          startDate = DateTime(now.year, 1, 1);
          break;
        default:
          startDate = now.subtract(const Duration(days: 30));
      }

      final snapshot = await _carbonActivitiesCollection
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .get();

      double totalCarbonSaved = 0.0;
      int totalActivities = 0;
      Map<String, double> categoryBreakdown = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final carbonSaved = (data['carbonSaved'] ?? 0.0) as double;
        final category = data['category'] as String? ?? 'Other';

        totalCarbonSaved += carbonSaved;
        totalActivities++;

        if (categoryBreakdown.containsKey(category)) {
          categoryBreakdown[category] = categoryBreakdown[category]! + carbonSaved;
        } else {
          categoryBreakdown[category] = carbonSaved;
        }
      }

      return {
        'totalCarbonSaved': totalCarbonSaved,
        'totalActivities': totalActivities,
        'categoryBreakdown': categoryBreakdown,
        'period': period,
      };
    } catch (e) {
      print('Error getting carbon savings by period: $e');
      return {
        'totalCarbonSaved': 0.0,
        'totalActivities': 0,
        'categoryBreakdown': {},
        'period': period,
      };
    }
  }

  // Set carbon saving goal
  static Future<Map<String, dynamic>> setCarbonGoal({
    required String userId,
    required double targetCarbonSaved,
    required String goalPeriod,
    String? description,
  }) async {
    try {
      final goalData = {
        'userId': userId,
        'targetCarbonSaved': targetCarbonSaved,
        'goalPeriod': goalPeriod,
        'description': description ?? 'Carbon saving goal',
        'currentProgress': 0.0,
        'isActive': true,
        'startDate': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _carbonGoalsCollection.doc(userId).set(goalData);

      return {
        'success': true,
        'message': 'Carbon goal set successfully!',
        'goalData': goalData,
      };
    } catch (e) {
      print('Error setting carbon goal: $e');
      return {
        'success': false,
        'message': 'Failed to set carbon goal: ${e.toString()}',
      };
    }
  }

  // Get user's carbon goal
  static Future<Map<String, dynamic>?> getUserCarbonGoal(String userId) async {
    try {
      final doc = await _carbonGoalsCollection.doc(userId).get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          ...data,
          'id': doc.id,
        };
      }
      return null;
    } catch (e) {
      print('Error getting user carbon goal: $e');
      return null;
    }
  }

  // Update carbon goal progress
  static Future<Map<String, dynamic>> updateCarbonGoalProgress(String userId, double carbonSaved) async {
    try {
      final goalDoc = await _carbonGoalsCollection.doc(userId).get();
      
      if (!goalDoc.exists) {
        return {
          'success': false,
          'message': 'No carbon goal found for user!',
        };
      }

      final goalData = goalDoc.data() as Map<String, dynamic>;
      final currentProgress = (goalData['currentProgress'] ?? 0.0) as double;
      final targetCarbonSaved = (goalData['targetCarbonSaved'] ?? 0.0) as double;
      final newProgress = currentProgress + carbonSaved;
      final isCompleted = newProgress >= targetCarbonSaved;

      await _carbonGoalsCollection.doc(userId).update({
        'currentProgress': newProgress,
        'isCompleted': isCompleted,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': isCompleted 
            ? 'Congratulations! You\'ve achieved your carbon saving goal!' 
            : 'Goal progress updated!',
        'newProgress': newProgress,
        'isCompleted': isCompleted,
        'progressPercentage': (newProgress / targetCarbonSaved) * 100,
      };
    } catch (e) {
      print('Error updating carbon goal progress: $e');
      return {
        'success': false,
        'message': 'Failed to update goal progress: ${e.toString()}',
      };
    }
  }

  // Get carbon saving suggestions
  static Future<List<Map<String, dynamic>>> getCarbonSavingSuggestions() async {
    try {
      // Return predefined carbon saving suggestions
      return [
        {
          'title': 'Use Public Transport',
          'description': 'Take bus or train instead of driving',
          'carbonSaved': 2.5,
          'category': 'Transportation',
          'icon': 'directions_bus_rounded',
          'color': '#B5C7F7',
        },
        {
          'title': 'Walk or Cycle',
          'description': 'Short trips can be done on foot or bicycle',
          'carbonSaved': 1.8,
          'category': 'Transportation',
          'icon': 'directions_walk_rounded',
          'color': '#D6EAF8',
        },
        {
          'title': 'Use Reusable Water Bottle',
          'description': 'Avoid single-use plastic bottles',
          'carbonSaved': 0.5,
          'category': 'Plastic Reduction',
          'icon': 'local_drink_rounded',
          'color': '#F9E79F',
        },
        {
          'title': 'Eat Plant-Based Meal',
          'description': 'Choose vegetarian or vegan options',
          'carbonSaved': 2.0,
          'category': 'Diet',
          'icon': 'restaurant_rounded',
          'color': '#E8D5C4',
        },
        {
          'title': 'Use Energy-Efficient Appliances',
          'description': 'Turn off lights and unplug devices',
          'carbonSaved': 1.2,
          'category': 'Energy',
          'icon': 'lightbulb_rounded',
          'color': '#B5C7F7',
        },
        {
          'title': 'Buy Local Produce',
          'description': 'Support local farmers and reduce transport',
          'carbonSaved': 1.5,
          'category': 'Shopping',
          'icon': 'store_rounded',
          'color': '#D6EAF8',
        },
      ];
    } catch (e) {
      print('Error getting carbon saving suggestions: $e');
      return [];
    }
  }

  // Get carbon impact statistics
  static Future<Map<String, dynamic>> getCarbonImpactStats(String userId) async {
    try {
      final stats = await getUserCarbonStats(userId);
      final totalCarbonSaved = stats['totalCarbonSaved'] ?? 0.0;

      // Calculate environmental impact
      final treesEquivalent = totalCarbonSaved / 22.0; // 1 tree absorbs ~22kg CO2/year
      final carMilesSaved = totalCarbonSaved * 2.3; // 1kg CO2 = ~2.3 miles of driving
      final electricitySaved = totalCarbonSaved * 0.85; // 1kg CO2 = ~0.85 kWh

      return {
        'totalCarbonSaved': totalCarbonSaved,
        'treesEquivalent': treesEquivalent,
        'carMilesSaved': carMilesSaved,
        'electricitySaved': electricitySaved,
        'totalActivities': stats['totalActivities'] ?? 0,
        'currentStreak': stats['currentStreak'] ?? 0,
      };
    } catch (e) {
      print('Error getting carbon impact stats: $e');
      return {
        'totalCarbonSaved': 0.0,
        'treesEquivalent': 0.0,
        'carMilesSaved': 0.0,
        'electricitySaved': 0.0,
        'totalActivities': 0,
        'currentStreak': 0,
      };
    }
  }

  // Initialize sample carbon activities (for demo purposes)
  static Future<void> initializeSampleCarbonActivities(String userId) async {
    try {
      final snapshot = await _carbonActivitiesCollection
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        print('Carbon activities already exist for user, skipping initialization');
        return;
      }

      final sampleActivities = [
        {
          'activityType': 'public_transport',
          'carbonSaved': 2.5,
          'description': 'Used public transport instead of driving',
          'category': 'Transportation',
        },
        {
          'activityType': 'walking',
          'carbonSaved': 1.8,
          'description': 'Walked to nearby store',
          'category': 'Transportation',
        },
        {
          'activityType': 'reusable_bottle',
          'carbonSaved': 0.5,
          'description': 'Used reusable water bottle',
          'category': 'Plastic Reduction',
        },
        {
          'activityType': 'plant_based_meal',
          'carbonSaved': 2.0,
          'description': 'Ate vegetarian meal',
          'category': 'Diet',
        },
        {
          'activityType': 'energy_saving',
          'carbonSaved': 1.2,
          'description': 'Turned off unnecessary lights',
          'category': 'Energy',
        },
      ];

      for (var activity in sampleActivities) {
        await recordCarbonActivity(
          userId: userId,
          activityType: activity['activityType'] as String,
          carbonSaved: activity['carbonSaved'] as double,
          description: activity['description'] as String,
          category: activity['category'] as String,
        );
      }

      print('Sample carbon activities initialized successfully');
    } catch (e) {
      print('Error initializing sample carbon activities: $e');
    }
  }
}
