import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/firebase_config.dart';

class StoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _storesCollection => 
      _firestore.collection(FirebaseConfig.storesCollection);

  // Add a new store
  Future<Map<String, dynamic>> addStore(Map<String, dynamic> storeData) async {
    try {
      print('Adding store to Firebase: ${storeData['name']}');
      
      // Add timestamps
      storeData['createdAt'] = FieldValue.serverTimestamp();
      storeData['updatedAt'] = FieldValue.serverTimestamp();
      storeData['isActive'] = true;

      // Add to Firestore
      DocumentReference docRef = await _storesCollection.add(storeData);
      print('Store added to Firebase with ID: ${docRef.id}');
      
      // Get the created document
      DocumentSnapshot doc = await docRef.get();
      
      return {
        'success': true,
        'message': 'Store added successfully to Firebase!',
        'storeId': docRef.id,
        'data': doc.data() as Map<String, dynamic>,
      };
    } catch (e) {
      print('Error adding store to Firebase: $e');
      return {
        'success': false,
        'message': 'Failed to add store to Firebase: ${e.toString()}',
      };
    }
  }

  // Get all stores with fallback to static data
  Future<List<Map<String, dynamic>>> getAllStores() async {
    try {
      // First try to get from Firestore
      QuerySnapshot querySnapshot = await _storesCollection
          .where('isActive', isEqualTo: true)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id; // Add document ID
          return data;
        }).toList();
      } else {
        // If no stores in Firestore, return static data
        print('No stores found in Firestore, using static data');
        return getStaticStores();
      }
    } catch (e) {
      print('Error getting stores from Firestore: $e');
      print('Falling back to static stores data');
      return getStaticStores();
    }
  }

  // Get store by ID
  Future<Map<String, dynamic>?> getStoreById(String storeId) async {
    try {
      DocumentSnapshot doc = await _storesCollection.doc(storeId).get();
      
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }
      
      // Try to find in static data
      return getStaticStores().firstWhere((store) => store['id'] == storeId);
    } catch (e) {
      print('Error getting store by ID: $e');
      // Try to find in static data
      try {
        return getStaticStores().firstWhere((store) => store['id'] == storeId);
      } catch (e) {
        return null;
      }
    }
  }

  // Update store
  Future<Map<String, dynamic>> updateStore(String storeId, Map<String, dynamic> updateData) async {
    try {
      updateData['updatedAt'] = FieldValue.serverTimestamp();
      
      await _storesCollection.doc(storeId).update(updateData);
      
      return {
        'success': true,
        'message': 'Store updated successfully!',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update store: ${e.toString()}',
      };
    }
  }

  // Delete store (hard delete - completely remove from Firestore)
  Future<Map<String, dynamic>> deleteStore(String storeId) async {
    try {
      print('Deleting store from Firebase: $storeId');
      
      // First check if the document exists
      DocumentSnapshot doc = await _storesCollection.doc(storeId).get();
      
      if (!doc.exists) {
        return {
          'success': false,
          'message': 'Store not found in database!',
        };
      }
      
      // Delete the document completely from Firestore
      await _storesCollection.doc(storeId).delete();
      
      print('Store deleted from Firebase successfully: $storeId');
      
      return {
        'success': true,
        'message': 'Store permanently deleted from database!',
      };
    } catch (e) {
      print('Error deleting store from Firebase: $e');
      return {
        'success': false,
        'message': 'Failed to delete store: ${e.toString()}',
      };
    }
  }

  // Soft delete store (set isActive to false)
  Future<Map<String, dynamic>> softDeleteStore(String storeId) async {
    try {
      await _storesCollection.doc(storeId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return {
        'success': true,
        'message': 'Store deactivated successfully!',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to deactivate store: ${e.toString()}',
      };
    }
  }

  // Toggle store status
  Future<Map<String, dynamic>> toggleStoreStatus(String storeId, bool isActive) async {
    try {
      await _storesCollection.doc(storeId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return {
        'success': true,
        'message': isActive ? 'Store activated successfully!' : 'Store deactivated successfully!',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to toggle store status: ${e.toString()}',
      };
    }
  }

  // Search stores
  Future<List<Map<String, dynamic>>> searchStores(String query) async {
    try {
      // First try Firestore
      QuerySnapshot querySnapshot = await _storesCollection
          .where('isActive', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> stores = [];
      
      if (querySnapshot.docs.isNotEmpty) {
        stores = querySnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
      } else {
        stores = getStaticStores();
      }

      // Filter stores based on search query
      return stores.where((store) {
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
    } catch (e) {
      print('Error searching stores: $e');
      // Fallback to static data search
      return getStaticStores().where((store) {
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
  }

  // Get store statistics
  Future<Map<String, dynamic>> getStoreStats() async {
    try {
      List<Map<String, dynamic>> stores = await getAllStores();

      // Calculate statistics
      int totalStores = stores.length;
      int activeStores = stores.where((store) => store['isActive'] == true).length;
      int totalProducts = stores.fold(0, (sum, store) => sum + ((store['totalProducts'] ?? 0) as int));
      double totalRevenue = stores.fold(0.0, (sum, store) => sum + (store['totalRevenue'] ?? 0.0));

      // Get categories
      Set<String> categories = stores.map((store) => (store['category'] ?? '') as String).toSet();

      return {
        'totalStores': totalStores,
        'activeStores': activeStores,
        'totalProducts': totalProducts,
        'totalRevenue': totalRevenue,
        'categories': categories.toList(),
        'averageProductsPerStore': totalStores > 0 ? totalProducts / totalStores : 0.0,
      };
    } catch (e) {
      print('Error getting store stats: $e');
      return {
        'totalStores': 0,
        'activeStores': 0,
        'totalProducts': 0,
        'totalRevenue': 0.0,
        'categories': [],
        'averageProductsPerStore': 0.0,
      };
    }
  }

  // Initialize sample stores in Firestore
  Future<void> initializeSampleStores() async {
    try {
      // Check if stores already exist
      QuerySnapshot existingStores = await _storesCollection.limit(1).get();
      
      if (existingStores.docs.isNotEmpty) {
        print('Stores already exist in Firestore');
        return;
      }

      // Get static stores and add to Firestore
      List<Map<String, dynamic>> sampleStores = getStaticStores();

      // Add stores to Firestore
      for (Map<String, dynamic> store in sampleStores) {
        await _storesCollection.add(store);
      }

      print('Sample stores initialized successfully!');
    } catch (e) {
      print('Error initializing sample stores: $e');
    }
  }

  // Static stores data as fallback
  List<Map<String, dynamic>> getStaticStores() {
    return [
      {
        'id': '1',
        'name': 'GreenMart',
        'description': 'Your one-stop shop for eco-friendly products. We specialize in sustainable clothing, accessories, and personal care items.',
        'category': 'General Store',
        'location': 'Mumbai, Maharashtra',
        'ownerName': 'Priya Sharma',
        'ownerEmail': 'priya@greenmart.com',
        'ownerPhone': '+91 98765 43210',
        'address': '123 Eco Street, Bandra West, Mumbai - 400050',
        'totalProducts': 45,
        'totalRevenue': 125000.0,
        'rating': 4.5,
        'reviews': 156,
        'isActive': true,
        'image': 'greenmart',
        'banner': 'greenmart_banner',
        'openingHours': '9:00 AM - 9:00 PM',
        'deliveryAvailable': true,
        'pickupAvailable': true,
        'specialties': ['Organic Clothing', 'Bamboo Products', 'Natural Skincare'],
        'certifications': ['Organic Certified', 'Fair Trade', 'Carbon Neutral'],
      },
      {
        'id': '2',
        'name': 'EcoShop',
        'description': 'Dedicated to bringing you the finest eco-friendly products. From recycled materials to organic ingredients.',
        'category': 'Specialty Store',
        'location': 'Delhi, NCR',
        'ownerName': 'Rahul Verma',
        'ownerEmail': 'rahul@ecoshop.com',
        'ownerPhone': '+91 98765 43211',
        'address': '456 Green Avenue, Connaught Place, Delhi - 110001',
        'totalProducts': 32,
        'totalRevenue': 89000.0,
        'rating': 4.3,
        'reviews': 98,
        'isActive': true,
        'image': 'ecoshop',
        'banner': 'ecoshop_banner',
        'openingHours': '10:00 AM - 8:00 PM',
        'deliveryAvailable': true,
        'pickupAvailable': false,
        'specialties': ['Recycled Products', 'Zero Waste', 'Natural Cosmetics'],
        'certifications': ['Recycled Certified', 'Zero Waste', 'Cruelty Free'],
      },
      {
        'id': '3',
        'name': 'Green Corner',
        'description': 'Your neighborhood store for sustainable living. We focus on local, organic, and eco-friendly products.',
        'category': 'Local Store',
        'location': 'Bangalore, Karnataka',
        'ownerName': 'Anita Reddy',
        'ownerEmail': 'anita@greencorner.com',
        'ownerPhone': '+91 98765 43212',
        'address': '789 Nature Lane, Indiranagar, Bangalore - 560038',
        'totalProducts': 28,
        'totalRevenue': 67000.0,
        'rating': 4.7,
        'reviews': 134,
        'isActive': true,
        'image': 'greencorner',
        'banner': 'greencorner_banner',
        'openingHours': '8:00 AM - 10:00 PM',
        'deliveryAvailable': true,
        'pickupAvailable': true,
        'specialties': ['Local Products', 'Organic Food', 'Sustainable Home'],
        'certifications': ['Local Sourced', 'Organic Certified', 'Community Supported'],
      },
      {
        'id': '4',
        'name': 'Eco Essentials',
        'description': 'Premium eco-friendly products for conscious consumers. Quality meets sustainability.',
        'category': 'Premium Store',
        'location': 'Chennai, Tamil Nadu',
        'ownerName': 'Vikram Iyer',
        'ownerEmail': 'vikram@ecoessentials.com',
        'ownerPhone': '+91 98765 43213',
        'address': '321 Sustainable Road, T Nagar, Chennai - 600017',
        'totalProducts': 38,
        'totalRevenue': 145000.0,
        'rating': 4.6,
        'reviews': 89,
        'isActive': true,
        'image': 'ecoessentials',
        'banner': 'ecoessentials_banner',
        'openingHours': '9:30 AM - 8:30 PM',
        'deliveryAvailable': true,
        'pickupAvailable': true,
        'specialties': ['Premium Products', 'Luxury Eco', 'Gift Items'],
        'certifications': ['Premium Certified', 'Luxury Eco', 'Gift Wrapped'],
      },
      {
        'id': '5',
        'name': 'Nature\'s Basket',
        'description': 'Fresh from nature to your home. We offer the best organic and natural products.',
        'category': 'Organic Store',
        'location': 'Pune, Maharashtra',
        'ownerName': 'Meera Patel',
        'ownerEmail': 'meera@naturesbasket.com',
        'ownerPhone': '+91 98765 43214',
        'address': '654 Organic Street, Koregaon Park, Pune - 411001',
        'totalProducts': 52,
        'totalRevenue': 112000.0,
        'rating': 4.4,
        'reviews': 167,
        'isActive': true,
        'image': 'naturesbasket',
        'banner': 'naturesbasket_banner',
        'openingHours': '7:00 AM - 9:00 PM',
        'deliveryAvailable': true,
        'pickupAvailable': true,
        'specialties': ['Organic Food', 'Fresh Produce', 'Natural Remedies'],
        'certifications': ['Organic Certified', 'Fresh Daily', 'Natural Healing'],
      },
    ];
  }
}
