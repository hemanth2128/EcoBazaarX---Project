import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'services/settings_service.dart';

class BackendConnectionTest {
  static Future<void> testConnection() async {
    print('🔍 Testing Backend Connection...');
    
    try {
      // Test 1: Health Check
      print('\n1. Testing Health Check...');
      final healthResult = await ApiService.healthCheck();
      print('✅ Health Check Result: $healthResult');
      
      // Test 2: Settings Service Health Check
      print('\n2. Testing Settings Service Health Check...');
      final settingsService = SettingsService();
      final settingsHealthResult = await settingsService.healthCheck();
      print('✅ Settings Health Check Result: $settingsHealthResult');
      
      // Test 3: Test API Endpoints (if available)
      print('\n3. Testing API Endpoints...');
      
      // Test stores endpoint
      try {
        final storesResult = await ApiService.getStores();
        print('✅ Stores API: $storesResult');
      } catch (e) {
        print('⚠️ Stores API Error: $e');
      }
      
      // Test products endpoint
      try {
        final productsResult = await ApiService.getProducts();
        print('✅ Products API: $productsResult');
      } catch (e) {
        print('⚠️ Products API Error: $e');
      }
      
      print('\n🎉 Backend Connection Test Completed!');
      
    } catch (e) {
      print('❌ Backend Connection Test Failed: $e');
    }
  }
  
  static void showTestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backend Connection Test'),
        content: const Text('Testing connection to backend API...'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await testConnection();
            },
            child: const Text('Run Test'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
