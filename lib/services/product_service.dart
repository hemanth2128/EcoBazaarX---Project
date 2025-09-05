import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../config/firebase_config.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _productsCollection => 
      _firestore.collection(FirebaseConfig.productsCollection);

  // Helper method to convert Color object to hex string
  String _colorToHex(dynamic color) {
    if (color is String) {
      return color; // Already a string, return as is
    }
    
    if (color is Color) {
      // Convert Color to hex string
      return '#${color.value.toRadixString(16).padLeft(8, '0')}';
    }
    
    // Default color if conversion fails
    return '#B5C7F7';
  }

  // Helper method to convert IconData to string
  String _iconToString(dynamic icon) {
    if (icon is String) {
      return icon; // Already a string, return as is
    }
    
    if (icon is IconData) {
      // Convert IconData to string representation
      // This is a simplified approach - you might want to maintain a mapping
      return 'shopping_bag_rounded'; // Default icon
    }
    
    return 'shopping_bag_rounded'; // Default icon
  }

  // Add a new product
  Future<Map<String, dynamic>> addProduct(Map<String, dynamic> productData) async {
    try {
      print('Adding product to Firebase: ${productData['name']}');
      
      // Convert Color and IconData objects to strings for Firebase storage
      if (productData['color'] != null) {
        productData['color'] = _colorToHex(productData['color']);
      }
      
      if (productData['icon'] != null) {
        productData['icon'] = _iconToString(productData['icon']);
      }
      
      // Add timestamps
      productData['createdAt'] = FieldValue.serverTimestamp();
      productData['updatedAt'] = FieldValue.serverTimestamp();
      productData['isActive'] = true;

      // Add to Firestore
      DocumentReference docRef = await _productsCollection.add(productData);
      print('Product added to Firebase with ID: ${docRef.id}');
      
      // Get the created document
      DocumentSnapshot doc = await docRef.get();
      
      return {
        'success': true,
        'message': 'Product added successfully to Firebase!',
        'productId': docRef.id,
        'data': doc.data() as Map<String, dynamic>,
      };
    } catch (e) {
      print('Error adding product to Firebase: $e');
      return {
        'success': false,
        'message': 'Failed to add product to Firebase: ${e.toString()}',
      };
    }
  }

  // Get all products with fallback to static data
  Future<List<Map<String, dynamic>>> getAllProducts() async {
    try {
      // First try to get from Firestore
      QuerySnapshot querySnapshot = await _productsCollection
          .where('isActive', isEqualTo: true)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id; // Add document ID
          return data;
        }).toList();
      } else {
        // If no products in Firestore, return static data
        print('No products found in Firestore, using static data');
        return getStaticProducts();
      }
    } catch (e) {
      print('Error getting products from Firestore: $e');
      print('Falling back to static products data');
      return getStaticProducts();
    }
  }

  // Get products by category
  Future<List<Map<String, dynamic>>> getProductsByCategory(String category) async {
    try {
      QuerySnapshot querySnapshot = await _productsCollection
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
      } else {
        // Filter static data by category
        return getStaticProducts().where((product) => product['category'] == category).toList();
      }
    } catch (e) {
      print('Error getting products by category: $e');
      return getStaticProducts().where((product) => product['category'] == category).toList();
    }
  }

  // Get products by store
  Future<List<Map<String, dynamic>>> getProductsByStore(String storeId) async {
    try {
      QuerySnapshot querySnapshot = await _productsCollection
          .where('storeId', isEqualTo: storeId)
          .where('isActive', isEqualTo: true)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
      } else {
        // Filter static data by store
        return getStaticProducts().where((product) => product['storeId'] == storeId).toList();
      }
    } catch (e) {
      print('Error getting products by store: $e');
      return getStaticProducts().where((product) => product['storeId'] == storeId).toList();
    }
  }

  // Get product by ID
  Future<Map<String, dynamic>?> getProductById(String productId) async {
    try {
      DocumentSnapshot doc = await _productsCollection.doc(productId).get();
      
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }
      
      // Try to find in static data
      return getStaticProducts().firstWhere((product) => product['id'] == productId);
    } catch (e) {
      print('Error getting product by ID: $e');
      // Try to find in static data
      try {
        return getStaticProducts().firstWhere((product) => product['id'] == productId);
      } catch (e) {
        return null;
      }
    }
  }

  // Update product
  Future<Map<String, dynamic>> updateProduct(String productId, Map<String, dynamic> updateData) async {
    try {
      // Convert Color and IconData objects to strings for Firebase storage
      if (updateData['color'] != null) {
        updateData['color'] = _colorToHex(updateData['color']);
      }
      
      if (updateData['icon'] != null) {
        updateData['icon'] = _iconToString(updateData['icon']);
      }
      
      updateData['updatedAt'] = FieldValue.serverTimestamp();
      
      await _productsCollection.doc(productId).update(updateData);
      
      return {
        'success': true,
        'message': 'Product updated successfully!',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update product: ${e.toString()}',
      };
    }
  }

  // Delete product (hard delete - completely remove from Firestore)
  Future<Map<String, dynamic>> deleteProduct(String productId) async {
    try {
      print('Deleting product from Firebase: $productId');
      
      // First check if the document exists
      DocumentSnapshot doc = await _productsCollection.doc(productId).get();
      
      if (!doc.exists) {
        return {
          'success': false,
          'message': 'Product not found in database!',
        };
      }
      
      // Delete the document completely from Firestore
      await _productsCollection.doc(productId).delete();
      
      print('Product deleted from Firebase successfully: $productId');
      
      return {
        'success': true,
        'message': 'Product permanently deleted from database!',
      };
    } catch (e) {
      print('Error deleting product from Firebase: $e');
      return {
        'success': false,
        'message': 'Failed to delete product: ${e.toString()}',
      };
    }
  }

  // Soft delete product (set isActive to false)
  Future<Map<String, dynamic>> softDeleteProduct(String productId) async {
    try {
      await _productsCollection.doc(productId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return {
        'success': true,
        'message': 'Product deactivated successfully!',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to deactivate product: ${e.toString()}',
      };
    }
  }

  // Toggle product status
  Future<Map<String, dynamic>> toggleProductStatus(String productId, bool isActive) async {
    try {
      await _productsCollection.doc(productId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return {
        'success': true,
        'message': isActive ? 'Product activated successfully!' : 'Product deactivated successfully!',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to toggle product status: ${e.toString()}',
      };
    }
  }

  // Search products
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    try {
      // First try Firestore
      QuerySnapshot querySnapshot = await _productsCollection
          .where('isActive', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> products = [];
      
      if (querySnapshot.docs.isNotEmpty) {
        products = querySnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
      } else {
        products = getStaticProducts();
      }

      // Filter products based on search query
      return products.where((product) {
        final name = product['name']?.toString().toLowerCase() ?? '';
        final description = product['description']?.toString().toLowerCase() ?? '';
        final category = product['category']?.toString().toLowerCase() ?? '';
        final material = product['material']?.toString().toLowerCase() ?? '';
        final storeName = product['storeName']?.toString().toLowerCase() ?? '';
        
        final searchQuery = query.toLowerCase();
        
        return name.contains(searchQuery) ||
               description.contains(searchQuery) ||
               category.contains(searchQuery) ||
               material.contains(searchQuery) ||
               storeName.contains(searchQuery);
      }).toList();
    } catch (e) {
      print('Error searching products: $e');
      // Fallback to static data search
      return getStaticProducts().where((product) {
        final name = product['name']?.toString().toLowerCase() ?? '';
        final description = product['description']?.toString().toLowerCase() ?? '';
        final category = product['category']?.toString().toLowerCase() ?? '';
        final material = product['material']?.toString().toLowerCase() ?? '';
        final storeName = product['storeName']?.toString().toLowerCase() ?? '';
        
        final searchQuery = query.toLowerCase();
        
        return name.contains(searchQuery) ||
               description.contains(searchQuery) ||
               category.contains(searchQuery) ||
               material.contains(searchQuery) ||
               storeName.contains(searchQuery);
      }).toList();
    }
  }

  // Get featured products (products with high ratings or recent)
  Future<List<Map<String, dynamic>>> getFeaturedProducts({int limit = 6}) async {
    try {
      QuerySnapshot querySnapshot = await _productsCollection
          .where('isActive', isEqualTo: true)
          .limit(limit)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
      } else {
        return getStaticProducts().take(limit).toList();
      }
    } catch (e) {
      print('Error getting featured products: $e');
      return getStaticProducts().take(limit).toList();
    }
  }

  // Get products with low stock (for shopkeeper alerts)
  Future<List<Map<String, dynamic>>> getLowStockProducts({int threshold = 10}) async {
    try {
      QuerySnapshot querySnapshot = await _productsCollection
          .where('isActive', isEqualTo: true)
          .where('quantity', isLessThanOrEqualTo: threshold)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
      } else {
        return getStaticProducts().where((product) => (product['quantity'] ?? 0) <= threshold).toList();
      }
    } catch (e) {
      print('Error getting low stock products: $e');
      return getStaticProducts().where((product) => (product['quantity'] ?? 0) <= threshold).toList();
    }
  }

  // Get product statistics
  Future<Map<String, dynamic>> getProductStats() async {
    try {
      List<Map<String, dynamic>> products = await getAllProducts();

      // Calculate statistics
      int totalProducts = products.length;
      double totalValue = products.fold(0.0, (sum, product) => sum + (product['price'] ?? 0.0));
      int totalQuantity = products.fold(0, (sum, product) => sum + ((product['quantity'] ?? 0) as int));
      double totalCarbonSaved = products.fold(0.0, (sum, product) => sum + (product['carbonFootprint'] ?? 0.0));

      // Get categories
      Set<String> categories = products.map((product) => (product['category'] ?? '') as String).toSet();

      return {
        'totalProducts': totalProducts,
        'totalValue': totalValue,
        'totalQuantity': totalQuantity,
        'totalCarbonSaved': totalCarbonSaved,
        'categories': categories.toList(),
        'averagePrice': totalProducts > 0 ? totalValue / totalProducts : 0.0,
      };
    } catch (e) {
      print('Error getting product stats: $e');
      return {
        'totalProducts': 0,
        'totalValue': 0.0,
        'totalQuantity': 0,
        'totalCarbonSaved': 0.0,
        'categories': [],
        'averagePrice': 0.0,
      };
    }
  }

  // Initialize sample products in Firestore
  Future<void> initializeSampleProducts() async {
    try {
      // Check if products already exist
      QuerySnapshot existingProducts = await _productsCollection.limit(1).get();
      
      if (existingProducts.docs.isNotEmpty) {
        print('Products already exist in Firestore');
        return;
      }

      // Get static products and add to Firestore
      List<Map<String, dynamic>> sampleProducts = getStaticProducts();

      // Add products to Firestore
      for (Map<String, dynamic> product in sampleProducts) {
        await _productsCollection.add(product);
      }

      print('Sample products initialized successfully!');
    } catch (e) {
      print('Error initializing sample products: $e');
    }
  }

  // Static products data as fallback
  List<Map<String, dynamic>> getStaticProducts() {
    return [
      {
        'id': '1',
        'name': 'Men Grey Hoodie',
        'category': 'Clothing',
        'price': 49.90,
        'quantity': 96,
        'carbonFootprint': 5.2,
        'waterSaved': 2500,
        'energySaved': 45,
        'wasteReduced': 2.5,
        'treesEquivalent': 0.26,
        'image': 'hoodie',
        'description': 'Eco-friendly cotton hoodie made from sustainable materials. This product saves 2500L of water and 45kWh of energy compared to conventional cotton production.',
        'material': 'Organic Cotton',
        'color': '#B5C7F7',
        'icon': 'checkroom_rounded',
        'storeId': '1',
        'storeName': 'GreenMart',
        'isActive': true,
        'rating': 4.5,
        'reviews': 23,
      },
      {
        'id': '2',
        'name': 'Women Striped T-Shirt',
        'category': 'Clothing',
        'price': 34.90,
        'quantity': 56,
        'carbonFootprint': 3.1,
        'waterSaved': 1800,
        'energySaved': 32,
        'wasteReduced': 1.8,
        'treesEquivalent': 0.155,
        'image': 'tshirt',
        'description': 'Comfortable striped t-shirt made from recycled materials. Reduces water usage by 1800L and saves 32kWh of energy compared to virgin polyester.',
        'material': 'Recycled Polyester',
        'color': '#E8D5C4',
        'icon': 'checkroom_rounded',
        'storeId': '2',
        'storeName': 'EcoShop',
        'isActive': true,
        'rating': 4.2,
        'reviews': 18,
      },
      {
        'id': '3',
        'name': 'Bamboo Water Bottle',
        'category': 'Accessories',
        'price': 29.90,
        'quantity': 120,
        'carbonFootprint': 1.8,
        'waterSaved': 500,
        'energySaved': 15,
        'wasteReduced': 3.2,
        'treesEquivalent': 0.09,
        'image': 'bottle',
        'description': 'Sustainable bamboo water bottle, perfect for daily use. Replaces 500 plastic bottles and saves 15kWh of energy in production.',
        'material': 'Bamboo',
        'color': '#F9E79F',
        'icon': 'water_drop_rounded',
        'storeId': '1',
        'storeName': 'GreenMart',
        'isActive': true,
        'rating': 4.8,
        'reviews': 45,
      },
      {
        'id': '4',
        'name': 'Solar Phone Charger',
        'category': 'Electronics',
        'price': 89.90,
        'quantity': 45,
        'carbonFootprint': 2.5,
        'waterSaved': 800,
        'energySaved': 120,
        'wasteReduced': 1.5,
        'treesEquivalent': 0.125,
        'image': 'charger',
        'description': 'Portable solar charger for eco-friendly charging. Generates clean energy and saves 120kWh annually, equivalent to planting 0.125 trees.',
        'material': 'Recycled Plastic',
        'color': '#D6EAF8',
        'icon': 'solar_power_rounded',
        'storeId': '4',
        'storeName': 'Green Corner',
        'isActive': true,
        'rating': 4.6,
        'reviews': 32,
      },
      {
        'id': '5',
        'name': 'Organic Cotton Tote',
        'category': 'Accessories',
        'price': 24.90,
        'quantity': 200,
        'carbonFootprint': 1.2,
        'waterSaved': 600,
        'energySaved': 8,
        'wasteReduced': 4.0,
        'treesEquivalent': 0.06,
        'image': 'tote',
        'description': 'Reusable shopping bag made from organic cotton. Replaces 400 plastic bags and saves 600L of water in production.',
        'material': 'Organic Cotton',
        'color': '#E8D5C4',
        'icon': 'shopping_bag_rounded',
        'storeId': '2',
        'storeName': 'EcoShop',
        'isActive': true,
        'rating': 4.4,
        'reviews': 28,
      },
      {
        'id': '6',
        'name': 'Bamboo Toothbrush',
        'category': 'Personal Care',
        'price': 8.90,
        'quantity': 300,
        'carbonFootprint': 0.5,
        'waterSaved': 200,
        'energySaved': 3,
        'wasteReduced': 0.8,
        'treesEquivalent': 0.025,
        'image': 'toothbrush',
        'description': 'Biodegradable bamboo toothbrush with soft bristles. Replaces plastic toothbrushes and saves 200L of water in production.',
        'material': 'Bamboo',
        'color': '#F9E79F',
        'icon': 'brush_rounded',
        'storeId': '1',
        'storeName': 'GreenMart',
        'isActive': true,
        'rating': 4.7,
        'reviews': 67,
      },
      {
        'id': '7',
        'name': 'Organic Soap Bar',
        'category': 'Personal Care',
        'price': 12.90,
        'quantity': 150,
        'carbonFootprint': 0.8,
        'waterSaved': 300,
        'energySaved': 5,
        'wasteReduced': 1.2,
        'treesEquivalent': 0.04,
        'image': 'soap',
        'description': 'Natural organic soap made with essential oils. Saves 300L of water and reduces packaging waste by 1.2kg compared to liquid soaps.',
        'material': 'Organic Oils',
        'color': '#E8F5E8',
        'icon': 'spa_rounded',
        'storeId': '2',
        'storeName': 'EcoShop',
        'isActive': true,
        'rating': 4.3,
        'reviews': 41,
      },
      {
        'id': '8',
        'name': 'Recycled Notebook',
        'category': 'Accessories',
        'price': 15.90,
        'quantity': 80,
        'carbonFootprint': 1.2,
        'waterSaved': 400,
        'energySaved': 12,
        'wasteReduced': 2.0,
        'treesEquivalent': 0.06,
        'image': 'notebook',
        'description': 'Eco-friendly notebook made from recycled paper. Saves 400L of water and 12kWh of energy compared to virgin paper production.',
        'material': 'Recycled Paper',
        'color': '#F5F5E8',
        'icon': 'book_rounded',
        'storeId': '3',
        'storeName': 'Green Corner',
        'isActive': true,
        'rating': 4.1,
        'reviews': 19,
      },
      {
        'id': '9',
        'name': 'Hemp Face Mask',
        'category': 'Personal Care',
        'price': 18.90,
        'quantity': 120,
        'carbonFootprint': 1.5,
        'waterSaved': 350,
        'energySaved': 8,
        'wasteReduced': 1.8,
        'treesEquivalent': 0.075,
        'image': 'mask',
        'description': 'Reusable face mask made from sustainable hemp. Replaces 50 disposable masks and saves 350L of water in production.',
        'material': 'Hemp',
        'color': '#E8D5C4',
        'icon': 'face_rounded',
        'storeId': '1',
        'storeName': 'GreenMart',
        'isActive': true,
        'rating': 4.5,
        'reviews': 34,
      },
      {
        'id': '10',
        'name': 'Cork Yoga Mat',
        'category': 'Accessories',
        'price': 45.90,
        'quantity': 60,
        'carbonFootprint': 2.8,
        'waterSaved': 600,
        'energySaved': 25,
        'wasteReduced': 2.2,
        'treesEquivalent': 0.14,
        'image': 'yogamat',
        'description': 'Natural cork yoga mat for eco-conscious fitness. Sustainable cork harvesting saves 600L of water and 25kWh of energy.',
        'material': 'Cork',
        'color': '#D6EAF8',
        'icon': 'fitness_center_rounded',
        'storeId': '4',
        'storeName': 'Green Corner',
        'isActive': true,
        'rating': 4.6,
        'reviews': 23,
      },
      {
        'id': '11',
        'name': 'Jute Plant Pot',
        'category': 'Home & Garden',
        'price': 22.90,
        'quantity': 90,
        'carbonFootprint': 1.8,
        'waterSaved': 450,
        'energySaved': 10,
        'wasteReduced': 1.5,
        'treesEquivalent': 0.09,
        'image': 'plantpot',
        'description': 'Biodegradable plant pot made from natural jute. Replaces plastic pots and saves 450L of water in production.',
        'material': 'Jute',
        'color': '#F9E79F',
        'icon': 'local_florist_rounded',
        'storeId': '2',
        'storeName': 'EcoShop',
        'isActive': true,
        'rating': 4.2,
        'reviews': 16,
      },
      {
        'id': '12',
        'name': 'Organic Tea Set',
        'category': 'Food & Beverages',
        'price': 35.90,
        'quantity': 75,
        'carbonFootprint': 2.2,
        'waterSaved': 550,
        'energySaved': 18,
        'wasteReduced': 1.8,
        'treesEquivalent': 0.11,
        'image': 'teaset',
        'description': 'Ceramic tea set with organic tea leaves. Sustainable ceramic production saves 550L of water and 18kWh of energy.',
        'material': 'Ceramic',
        'color': '#E8F5E8',
        'icon': 'local_cafe_rounded',
        'storeId': '3',
        'storeName': 'Green Corner',
        'isActive': true,
        'rating': 4.4,
        'reviews': 29,
      },
    ];
  }
}
