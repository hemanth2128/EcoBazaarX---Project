import 'package:flutter/foundation.dart';
import '../services/store_service.dart';

class StoreProvider with ChangeNotifier {
  final StoreService _storeService = StoreService();
  
  List<Map<String, dynamic>> _allStores = [];
  List<Map<String, dynamic>> _filteredStores = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _selectedStore;

  // Getters
  List<Map<String, dynamic>> get allStores => _allStores;
  List<Map<String, dynamic>> get filteredStores => _filteredStores;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get selectedStore => _selectedStore;

  // Available store categories for dropdowns
  List<String> get availableCategories => [
    'General Store',
    'Specialty Store',
    'Local Store',
    'Premium Store',
    'Organic Store',
    'Electronics Store',
    'Fashion Store',
    'Home & Garden Store',
    'Food & Beverages Store',
    'Personal Care Store',
  ];

  // Available locations for dropdowns
  List<String> get availableLocations => [
    'Mumbai, Maharashtra',
    'Delhi, NCR',
    'Bangalore, Karnataka',
    'Chennai, Tamil Nadu',
    'Pune, Maharashtra',
    'Hyderabad, Telangana',
    'Kolkata, West Bengal',
    'Ahmedabad, Gujarat',
    'Jaipur, Rajasthan',
    'Lucknow, Uttar Pradesh',
  ];

  // Initialize stores
  Future<void> initializeStores() async {
    try {
      _setLoading(true);
      _error = null;
      
      // First try to load from Firebase
      List<Map<String, dynamic>> stores = await _storeService.getAllStores();
      
      if (stores.isNotEmpty) {
        _allStores = stores;
        _filteredStores = stores;
        print('Stores loaded from Firebase: ${stores.length} stores');
      } else {
        // If Firebase is empty, initialize with sample data
        await _storeService.initializeSampleStores();
        stores = await _storeService.getAllStores();
        _allStores = stores;
        _filteredStores = stores;
        print('Sample stores initialized and loaded: ${stores.length} stores');
      }
    } catch (e) {
      print('Error initializing stores: $e');
      _error = 'Failed to load stores: ${e.toString()}';
      // Fallback to static data
      _allStores = _storeService.getStaticStores();
      _filteredStores = _allStores;
    } finally {
      _setLoading(false);
    }
  }

  // Load stores from Firebase
  Future<void> loadStores() async {
    try {
      _setLoading(true);
      _error = null;
      
      List<Map<String, dynamic>> stores = await _storeService.getAllStores();
      _allStores = stores;
      _filteredStores = stores;
    } catch (e) {
      print('Error loading stores: $e');
      _error = 'Failed to load stores: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  // Add a new store
  Future<Map<String, dynamic>> addStore(Map<String, dynamic> storeData) async {
    try {
      _setLoading(true);
      _error = null;
      
      final result = await _storeService.addStore(storeData);
      
      if (result['success']) {
        // Reload stores from Firebase
        await loadStores();
      }
      
      return result;
    } catch (e) {
      _error = 'Failed to add store: ${e.toString()}';
      return {
        'success': false,
        'message': _error!,
      };
    } finally {
      _setLoading(false);
    }
  }

  // Update store
  Future<Map<String, dynamic>> updateStore(String storeId, Map<String, dynamic> updateData) async {
    try {
      _setLoading(true);
      _error = null;
      
      final result = await _storeService.updateStore(storeId, updateData);
      
      if (result['success']) {
        // Reload stores from Firebase
        await loadStores();
      }
      
      return result;
    } catch (e) {
      _error = 'Failed to update store: ${e.toString()}';
      return {
        'success': false,
        'message': _error!,
      };
    } finally {
      _setLoading(false);
    }
  }

  // Delete store
  Future<Map<String, dynamic>> deleteStore(String storeId) async {
    try {
      _setLoading(true);
      _error = null;
      
      final result = await _storeService.deleteStore(storeId);
      
      if (result['success']) {
        // Reload stores from Firebase
        await loadStores();
      }
      
      return result;
    } catch (e) {
      _error = 'Failed to delete store: ${e.toString()}';
      return {
        'success': false,
        'message': _error!,
      };
    } finally {
      _setLoading(false);
    }
  }

  // Toggle store status
  Future<Map<String, dynamic>> toggleStoreStatus(String storeId) async {
    try {
      // Get current store status
      final store = _allStores.firstWhere((s) => s['id'] == storeId);
      final currentStatus = store['isActive'] ?? true;
      final newStatus = !currentStatus;
      
      final result = await _storeService.toggleStoreStatus(storeId, newStatus);
      
      if (result['success']) {
        // Reload stores from Firebase
        await loadStores();
      }
      
      return result;
    } catch (e) {
      _error = 'Failed to toggle store status: ${e.toString()}';
      return {
        'success': false,
        'message': _error!,
      };
    }
  }

  // Get store by ID
  Map<String, dynamic>? getStoreById(String storeId) {
    try {
      return _allStores.firstWhere((store) => store['id'] == storeId);
    } catch (e) {
      return null;
    }
  }

  // Get stores by category
  List<Map<String, dynamic>> getStoresByCategory(String category) {
    return _allStores.where((store) => store['category'] == category).toList();
  }

  // Get stores by location
  List<Map<String, dynamic>> getStoresByLocation(String location) {
    return _allStores.where((store) => store['location'] == location).toList();
  }

  // Get stores by status
  List<Map<String, dynamic>> getStoresByStatus(bool isActive) {
    return _allStores.where((store) => store['isActive'] == isActive).toList();
  }

  // Get stores by owner
  List<Map<String, dynamic>> getStoresByOwner(String ownerId) {
    return _allStores.where((store) => store['ownerId'] == ownerId).toList();
  }

  // Search stores
  List<Map<String, dynamic>> searchStores(String query) {
    if (query.isEmpty) {
      _filteredStores = _allStores;
    } else {
      _filteredStores = _allStores.where((store) {
        final name = store['name']?.toString().toLowerCase() ?? '';
        final description = store['description']?.toString().toLowerCase() ?? '';
        final category = store['category']?.toString().toLowerCase() ?? '';
        final location = store['location']?.toString().toLowerCase() ?? '';
        final ownerName = store['ownerName']?.toString().toLowerCase() ?? '';
        
        final searchQuery = query.toLowerCase();
        
        return name.contains(searchQuery) ||
               description.contains(searchQuery) ||
               category.contains(searchQuery) ||
               location.contains(searchQuery) ||
               ownerName.contains(searchQuery);
      }).toList();
    }
    notifyListeners();
    return _filteredStores;
  }

  // Search stores in Firebase
  Future<List<Map<String, dynamic>>> searchStoresFirebase(String query) async {
    try {
      return await _storeService.searchStores(query);
    } catch (e) {
      print('Error searching stores in Firebase: $e');
      return searchStores(query);
    }
  }

  // Filter stores
  void filterStores({
    String? category,
    String? location,
    bool? isActive,
    String? sortBy,
    bool ascending = true,
  }) {
    _filteredStores = _allStores.where((store) {
      bool matchesCategory = category == null || store['category'] == category;
      bool matchesLocation = location == null || store['location'] == location;
      bool matchesStatus = isActive == null || store['isActive'] == isActive;
      
      return matchesCategory && matchesLocation && matchesStatus;
    }).toList();

    // Sort stores
    if (sortBy != null) {
      _filteredStores.sort((a, b) {
        dynamic aValue = a[sortBy];
        dynamic bValue = b[sortBy];
        
        aValue ??= ascending ? double.negativeInfinity : double.infinity;
        bValue ??= ascending ? double.negativeInfinity : double.infinity;
        
        int comparison = ascending ? 1 : -1;
        
        if (aValue is String && bValue is String) {
          return ascending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
        } else if (aValue is num && bValue is num) {
          return ascending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
        }
        
        return 0;
      });
    }

    notifyListeners();
  }

  // Clear filters
  void clearFilters() {
    _filteredStores = _allStores;
    notifyListeners();
  }

  // Set selected store
  void setSelectedStore(Map<String, dynamic>? store) {
    _selectedStore = store;
    notifyListeners();
  }

  // Get store statistics
  Future<Map<String, dynamic>> getStoreStats() async {
    try {
      return await _storeService.getStoreStats();
    } catch (e) {
      print('Error getting store stats: $e');
      return {
        'totalStores': _allStores.length,
        'activeStores': _allStores.where((store) => store['isActive'] == true).length,
        'totalProducts': _allStores.fold(0, (sum, store) => sum + ((store['totalProducts'] ?? 0) as int)),
        'totalRevenue': _allStores.fold(0.0, (sum, store) => sum + (store['totalRevenue'] ?? 0.0)),
        'categories': _allStores.map((store) => store['category'] ?? '').toSet().toList(),
        'averageProductsPerStore': _allStores.isNotEmpty 
            ? _allStores.fold(0, (sum, store) => sum + ((store['totalProducts'] ?? 0) as int)) / _allStores.length 
            : 0.0,
      };
    }
  }

  // Helper method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

