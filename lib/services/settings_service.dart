import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../config/firebase_config.dart';
import 'api_service.dart';

class SettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _settingsCollection => 
      _firestore.collection(FirebaseConfig.settingsCollection);

  // Initialize user settings in Firebase
  Future<void> initializeUserSettings(String userId) async {
    try {
      // Check if user settings already exist
      DocumentSnapshot doc = await _settingsCollection.doc(userId).get();
      
      if (!doc.exists) {
        // Create default settings for new user
        Map<String, dynamic> defaultSettings = _getDefaultSettings();
        await _settingsCollection.doc(userId).set(defaultSettings);
        print('Default settings initialized for user: $userId');
      }
    } catch (e) {
      print('Error initializing user settings: $e');
      rethrow;
    }
  }

  // Get user settings stream for real-time updates
  Stream<Map<String, dynamic>?> getUserSettingsStream(String userId) {
    return _settingsCollection.doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    });
  }

  // Get user settings once
  Future<Map<String, dynamic>?> getUserSettings(String userId) async {
    try {
      DocumentSnapshot doc = await _settingsCollection.doc(userId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting user settings: $e');
      return null;
    }
  }

  // Update a single setting
  Future<void> updateSetting(String userId, String category, String key, dynamic value) async {
    try {
      await _settingsCollection.doc(userId).update({
        '$category.$key': value,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      print('Setting updated: $category.$key = $value');
    } catch (e) {
      print('Error updating setting: $e');
      rethrow;
    }
  }

  // Update notification settings
  Future<void> updateNotificationSettings(String userId, Map<String, dynamic> settings) async {
    try {
      await _settingsCollection.doc(userId).update({
        'notifications': settings,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      print('Notification settings updated for user: $userId');
    } catch (e) {
      print('Error updating notification settings: $e');
      rethrow;
    }
  }

  // Reset settings to defaults
  Future<void> resetToDefaults(String userId) async {
    try {
      Map<String, dynamic> defaultSettings = _getDefaultSettings();
      await _settingsCollection.doc(userId).set(defaultSettings);
      print('Settings reset to defaults for user: $userId');
    } catch (e) {
      print('Error resetting settings: $e');
      rethrow;
    }
  }

  // Export settings
  Future<Map<String, dynamic>> exportSettings(String userId) async {
    try {
      Map<String, dynamic>? settings = await getUserSettings(userId);
      if (settings != null) {
        return {
          'version': '1.0.0',
          'exported_at': DateTime.now().toIso8601String(),
          'user_id': userId,
          'settings': settings,
        };
      }
      throw Exception('No settings found for user');
    } catch (e) {
      print('Error exporting settings: $e');
      rethrow;
    }
  }

  // Import settings
  Future<bool> importSettings(String userId, Map<String, dynamic> data) async {
    try {
      if (data['version'] != '1.0.0') {
        throw Exception('Unsupported settings version');
      }

      Map<String, dynamic> settings = data['settings'] as Map<String, dynamic>;
      await _settingsCollection.doc(userId).set(settings);
      print('Settings imported successfully for user: $userId');
      return true;
    } catch (e) {
      print('Error importing settings: $e');
      return false;
    }
  }

  // Sync settings with backend API
  Future<void> syncSettings(String userId) async {
    try {
      // This method can be used for additional sync logic
      // Try to sync with backend API first
      try {
        final settings = await getUserSettings(userId);
        if (settings != null) {
          await ApiService.updateSettings(userId, settings);
          print('Settings synced with backend API for user: $userId');
        }
      } catch (e) {
        print('Failed to sync with backend API, using Firebase only: $e');
      }
      // For now, just ensure settings are up to date
      DocumentSnapshot doc = await _settingsCollection.doc(userId).get();
      if (!doc.exists) {
        await initializeUserSettings(userId);
      }
      print('Settings synced for user: $userId');
    } catch (e) {
      print('Error syncing settings: $e');
      rethrow;
    }
  }

  // Health check for backend API
  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final result = await ApiService.healthCheck();
      return {
        'status': 'success',
        'backend': result,
        'firebase': 'connected',
      };
    } catch (e) {
      return {
        'status': 'error',
        'backend': 'disconnected',
        'firebase': 'connected',
        'error': e.toString(),
      };
    }
  }

  // Get default settings
  Map<String, dynamic> _getDefaultSettings() {
    return {
      'notifications': {
        'pushNotificationsEnabled': true,
        'orderNotificationsEnabled': true,
        'ecoTipsEnabled': true,
        'promotionalNotificationsEnabled': true,
        'carbonTrackingEnabled': true,
      },
      'privacy': {
        'locationEnabled': true,
        'dataCollectionEnabled': true,
        'biometricEnabled': false,
      },
      'preferences': {
        'darkModeEnabled': false,
        'autoSaveEnabled': true,
        'hapticFeedbackEnabled': true,
        'language': 'en',
        'currency': 'INR',
        'timezone': 'Asia/Kolkata',
      },
      'app': {
        'theme': 'system',
        'fontSize': 'medium',
      },
      'sync': {
        'autoSync': true,
        'offlineMode': false,
      },
      'createdAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }
}




