import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class WishlistService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _wishlistCollection = _firestore.collection('wishlists');
  static final CollectionReference _wishlistItemsCollection = _firestore.collection('wishlist_items');

  // Generate unique wishlist item ID
  static String _generateWishlistItemId() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    final random = Random().nextInt(1000);
    return 'WISH_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_$random';
  }

  // Helper method to convert Firestore Timestamp to DateTime
  static DateTime? _convertToDateTime(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is DateTime) return timestamp;
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Add product to user's wishlist
  static Future<Map<String, dynamic>> addToWishlist({
    required String userId,
    required String productId,
    required String productName,
    required String productDescription,
    required double productPrice,
    required String productCategory,
    required String productColor,
    required String productIcon,
    required double carbonFootprint,
    String? productImage,
    double? waterSaved,
    double? energySaved,
    double? wasteReduced,
    double? treesEquivalent,
    String? material,
    double? rating,
    double? quantity,
  }) async {
    try {
      // Check if product already exists in user's wishlist
      final existingItem = await _wishlistItemsCollection
          .where('userId', isEqualTo: userId)
          .where('productId', isEqualTo: productId)
          .get();

      if (existingItem.docs.isNotEmpty) {
        return {
          'success': false,
          'message': 'Product already exists in your wishlist!',
        };
      }

      final wishlistItemId = _generateWishlistItemId();
      final now = DateTime.now();

      final wishlistItemData = {
        'id': wishlistItemId,
        'userId': userId,
        'productId': productId,
        'productName': productName,
        'productDescription': productDescription,
        'productPrice': productPrice,
        'productCategory': productCategory,
        'productColor': productColor,
        'productIcon': productIcon,
        'carbonFootprint': carbonFootprint,
        'productImage': productImage,
        'waterSaved': waterSaved ?? 0.0,
        'energySaved': energySaved ?? 0.0,
        'wasteReduced': wasteReduced ?? 0.0,
        'treesEquivalent': treesEquivalent ?? 0.0,
        'material': material ?? 'Eco-friendly material',
        'rating': rating ?? 4.5,
        'quantity': quantity ?? 10.0,
        'addedAt': now,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _wishlistItemsCollection.doc(wishlistItemId).set(wishlistItemData);

      // Update user's wishlist stats
      await _updateUserWishlistStats(userId, 1);

      return {
        'success': true,
        'wishlistItemId': wishlistItemId,
        'message': 'Product added to wishlist successfully!',
        'wishlistItemData': wishlistItemData,
      };
    } catch (e) {
      print('Error adding to wishlist: $e');
      return {
        'success': false,
        'message': 'Failed to add to wishlist: ${e.toString()}',
      };
    }
  }

  // Remove product from user's wishlist
  static Future<Map<String, dynamic>> removeFromWishlist({
    required String userId,
    required String productId,
  }) async {
    try {
      final wishlistItem = await _wishlistItemsCollection
          .where('userId', isEqualTo: userId)
          .where('productId', isEqualTo: productId)
          .get();

      if (wishlistItem.docs.isEmpty) {
        return {
          'success': false,
          'message': 'Product not found in wishlist!',
        };
      }

      await wishlistItem.docs.first.reference.delete();

      // Update user's wishlist stats
      await _updateUserWishlistStats(userId, -1);

      return {
        'success': true,
        'message': 'Product removed from wishlist successfully!',
      };
    } catch (e) {
      print('Error removing from wishlist: $e');
      return {
        'success': false,
        'message': 'Failed to remove from wishlist: ${e.toString()}',
      };
    }
  }

  // Get user's wishlist items
  static Future<List<Map<String, dynamic>>> getUserWishlist(String userId) async {
    try {
      final snapshot = await _wishlistItemsCollection
          .where('userId', isEqualTo: userId)
          .get();

      final wishlistItems = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          ...data,
          'id': doc.id,
        };
      }).toList();

      // Sort in memory instead of using Firestore orderBy
      wishlistItems.sort((a, b) {
        final aAddedAt = _convertToDateTime(a['addedAt']) ?? DateTime.now();
        final bAddedAt = _convertToDateTime(b['addedAt']) ?? DateTime.now();
        return bAddedAt.compareTo(aAddedAt); // Descending order
      });

      return wishlistItems;
    } catch (e) {
      print('Error getting user wishlist: $e');
      return [];
    }
  }

  // Check if product is in user's wishlist
  static Future<bool> isProductInWishlist(String userId, String productId) async {
    try {
      final snapshot = await _wishlistItemsCollection
          .where('userId', isEqualTo: userId)
          .where('productId', isEqualTo: productId)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking wishlist status: $e');
      return false;
    }
  }

  // Get wishlist items by category
  static Future<List<Map<String, dynamic>>> getWishlistByCategory(String userId, String category) async {
    try {
      final snapshot = await _wishlistItemsCollection
          .where('userId', isEqualTo: userId)
          .where('productCategory', isEqualTo: category)
          .get();

      final wishlistItems = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          ...data,
          'id': doc.id,
        };
      }).toList();

      // Sort in memory instead of using Firestore orderBy
      wishlistItems.sort((a, b) {
        final aAddedAt = _convertToDateTime(a['addedAt']) ?? DateTime.now();
        final bAddedAt = _convertToDateTime(b['addedAt']) ?? DateTime.now();
        return bAddedAt.compareTo(aAddedAt); // Descending order
      });

      return wishlistItems;
    } catch (e) {
      print('Error getting wishlist by category: $e');
      return [];
    }
  }

  // Get wishlist statistics
  static Future<Map<String, dynamic>> getWishlistStats(String userId) async {
    try {
      final snapshot = await _wishlistItemsCollection
          .where('userId', isEqualTo: userId)
          .get();

      final wishlistItems = snapshot.docs;
      
      int totalItems = wishlistItems.length;
      double totalValue = 0.0;
      Map<String, int> categoryBreakdown = {};

      for (var doc in wishlistItems) {
        final data = doc.data() as Map<String, dynamic>;
        final price = (data['productPrice'] ?? 0.0) as double;
        final category = data['productCategory'];
        String categoryString;
        if (category == null) {
          categoryString = 'Other';
        } else if (category is String) {
          categoryString = category;
        } else {
          categoryString = category.toString();
        }

        totalValue += price;

        if (categoryBreakdown.containsKey(categoryString)) {
          categoryBreakdown[categoryString] = categoryBreakdown[categoryString]! + 1;
        } else {
          categoryBreakdown[categoryString] = 1;
        }
      }

      return {
        'totalItems': totalItems,
        'totalValue': totalValue,
        'categoryBreakdown': categoryBreakdown,
      };
    } catch (e) {
      print('Error getting wishlist stats: $e');
      return {
        'totalItems': 0,
        'totalValue': 0.0,
        'categoryBreakdown': {},
      };
    }
  }

  // Clear user's entire wishlist
  static Future<Map<String, dynamic>> clearWishlist(String userId) async {
    try {
      final snapshot = await _wishlistItemsCollection
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Reset user's wishlist stats
      await _resetUserWishlistStats(userId);

      return {
        'success': true,
        'message': 'Wishlist cleared successfully!',
      };
    } catch (e) {
      print('Error clearing wishlist: $e');
      return {
        'success': false,
        'message': 'Failed to clear wishlist: ${e.toString()}',
      };
    }
  }

  // Move wishlist item to cart (remove from wishlist and add to cart)
  static Future<Map<String, dynamic>> moveToCart({
    required String userId,
    required String productId,
    required Function addToCartCallback,
  }) async {
    try {
      // Get wishlist item details
      final wishlistItem = await _wishlistItemsCollection
          .where('userId', isEqualTo: userId)
          .where('productId', isEqualTo: productId)
          .get();

      if (wishlistItem.docs.isEmpty) {
        return {
          'success': false,
          'message': 'Product not found in wishlist!',
        };
      }

      final itemData = wishlistItem.docs.first.data() as Map<String, dynamic>;

      // Add to cart using the provided callback
      await addToCartCallback(itemData);

      // Remove from wishlist
      await wishlistItem.docs.first.reference.delete();

      // Update user's wishlist stats
      await _updateUserWishlistStats(userId, -1);

      return {
        'success': true,
        'message': 'Product moved to cart successfully!',
      };
    } catch (e) {
      print('Error moving to cart: $e');
      return {
        'success': false,
        'message': 'Failed to move to cart: ${e.toString()}',
      };
    }
  }

  // Update user's wishlist statistics
  static Future<void> _updateUserWishlistStats(String userId, int change) async {
    try {
      final userWishlistDoc = _wishlistCollection.doc(userId);
      final docSnapshot = await userWishlistDoc.get();

      if (docSnapshot.exists) {
        final currentData = docSnapshot.data() as Map<String, dynamic>;
        final currentCount = (currentData['totalItems'] ?? 0) as int;
        final newCount = currentCount + change;

        await userWishlistDoc.update({
          'totalItems': newCount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new user wishlist stats
        await userWishlistDoc.set({
          'userId': userId,
          'totalItems': change > 0 ? 1 : 0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating user wishlist stats: $e');
    }
  }

  // Reset user's wishlist statistics
  static Future<void> _resetUserWishlistStats(String userId) async {
    try {
      final userWishlistDoc = _wishlistCollection.doc(userId);
      await userWishlistDoc.update({
        'totalItems': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error resetting user wishlist stats: $e');
    }
  }

  // Get wishlist recommendations based on user's wishlist
  static Future<List<Map<String, dynamic>>> getWishlistRecommendations(String userId) async {
    try {
      // Get user's wishlist categories
      final userWishlist = await getUserWishlist(userId);
      final userCategories = userWishlist
          .map((item) {
            final category = item['productCategory'];
            if (category == null) return 'Other';
            if (category is String) return category;
            return category.toString();
          })
          .toSet()
          .toList();

      if (userCategories.isEmpty) {
        return [];
      }

      // Get products from similar categories (this would typically come from a products collection)
      // For now, return some sample recommendations
      return [
        {
          'id': 'rec_1',
          'name': 'Eco-Friendly Water Bottle',
          'description': 'Sustainable alternative to plastic bottles',
          'price': 299.0,
          'category': 'Plastic Reduction',
          'color': '#D6EAF8',
          'icon': 'local_drink_rounded',
          'carbonFootprint': 0.5,
          'rating': 4.8,
        },
        {
          'id': 'rec_2',
          'name': 'Organic Cotton Tote Bag',
          'description': 'Reusable shopping bag made from organic cotton',
          'price': 199.0,
          'category': 'Plastic Reduction',
          'color': '#E8D5C4',
          'icon': 'shopping_bag_rounded',
          'carbonFootprint': 0.3,
          'rating': 4.6,
        },
        {
          'id': 'rec_3',
          'name': 'Bamboo Toothbrush',
          'description': 'Biodegradable toothbrush with bamboo handle',
          'price': 99.0,
          'category': 'Plastic Reduction',
          'color': '#F9E79F',
          'icon': 'brush_rounded',
          'carbonFootprint': 0.2,
          'rating': 4.7,
        },
      ];
    } catch (e) {
      print('Error getting wishlist recommendations: $e');
      return [];
    }
  }

  // Get wishlist analytics
  static Future<Map<String, dynamic>> getWishlistAnalytics(String userId) async {
    try {
      final wishlistItems = await getUserWishlist(userId);
      
      if (wishlistItems.isEmpty) {
        return {
          'totalItems': 0,
          'totalValue': 0.0,
          'averagePrice': 0.0,
          'mostExpensiveItem': null,
          'categoryDistribution': {},
          'recentAdditions': [],
        };
      }

      double totalValue = 0.0;
      Map<String, int> categoryDistribution = {};
      Map<String, dynamic>? mostExpensiveItem;
      double maxPrice = 0.0;

      for (var item in wishlistItems) {
        final price = (item['productPrice'] ?? 0.0) as double;
        final category = item['productCategory'];
        String categoryString;
        if (category == null) {
          categoryString = 'Other';
        } else if (category is String) {
          categoryString = category;
        } else {
          categoryString = category.toString();
        }

        totalValue += price;

        if (price > maxPrice) {
          maxPrice = price;
          mostExpensiveItem = item;
        }

        if (categoryDistribution.containsKey(categoryString)) {
          categoryDistribution[categoryString] = categoryDistribution[categoryString]! + 1;
        } else {
          categoryDistribution[categoryString] = 1;
        }
      }

      final averagePrice = totalValue / wishlistItems.length;
      final recentAdditions = wishlistItems.take(5).toList();

      return {
        'totalItems': wishlistItems.length,
        'totalValue': totalValue,
        'averagePrice': averagePrice,
        'mostExpensiveItem': mostExpensiveItem,
        'categoryDistribution': categoryDistribution,
        'recentAdditions': recentAdditions,
      };
    } catch (e) {
      print('Error getting wishlist analytics: $e');
      return {
        'totalItems': 0,
        'totalValue': 0.0,
        'averagePrice': 0.0,
        'mostExpensiveItem': null,
        'categoryDistribution': {},
        'recentAdditions': [],
      };
    }
  }

  // Initialize sample wishlist items (for demo purposes)
  static Future<void> initializeSampleWishlistItems(String userId) async {
    try {
      final snapshot = await _wishlistItemsCollection
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        print('Wishlist items already exist for user, skipping initialization');
        return;
      }

      final sampleItems = [
        {
          'productId': 'bamboo-water-bottle',
          'productName': 'Bamboo Water Bottle',
          'productDescription': 'Eco-friendly water bottle made from sustainable bamboo',
          'productPrice': 599.0,
          'productCategory': 'Plastic Reduction',
          'productColor': '#D6EAF8',
          'productIcon': 'local_drink_rounded',
          'carbonFootprint': 0.5,
          'waterSaved': 100.0,
          'energySaved': 2.5,
          'wasteReduced': 0.8,
          'treesEquivalent': 1.2,
          'material': 'Bamboo',
          'rating': 4.8,
          'quantity': 15,
        },
        {
          'productId': 'organic-cotton-tshirt',
          'productName': 'Organic Cotton T-Shirt',
          'productDescription': 'Comfortable t-shirt made from 100% organic cotton',
          'productPrice': 899.0,
          'productCategory': 'Clothing',
          'productColor': '#B5C7F7',
          'productIcon': 'checkroom_rounded',
          'carbonFootprint': 1.2,
          'waterSaved': 250.0,
          'energySaved': 5.0,
          'wasteReduced': 1.5,
          'treesEquivalent': 2.0,
          'material': 'Organic Cotton',
          'rating': 4.6,
          'quantity': 20,
        },
        {
          'productId': 'solar-phone-charger',
          'productName': 'Solar Phone Charger',
          'productDescription': 'Portable solar charger for your devices',
          'productPrice': 1299.0,
          'productCategory': 'Energy',
          'productColor': '#F9E79F',
          'productIcon': 'solar_power_rounded',
          'carbonFootprint': 2.0,
          'waterSaved': 50.0,
          'energySaved': 8.0,
          'wasteReduced': 2.0,
          'treesEquivalent': 3.0,
          'material': 'Solar Panels + Plastic',
          'rating': 4.7,
          'quantity': 8,
        },
      ];

      for (var item in sampleItems) {
        await addToWishlist(
          userId: userId,
          productId: item['productId'] as String,
          productName: item['productName'] as String,
          productDescription: item['productDescription'] as String,
          productPrice: item['productPrice'] as double,
          productCategory: item['productCategory'] as String,
          productColor: item['productColor'] as String,
          productIcon: item['productIcon'] as String,
          carbonFootprint: item['carbonFootprint'] as double,
          waterSaved: item['waterSaved'] as double?,
          energySaved: item['energySaved'] as double?,
          wasteReduced: item['wasteReduced'] as double?,
          treesEquivalent: item['treesEquivalent'] as double?,
          material: item['material'] as String?,
          rating: item['rating'] as double?,
          quantity: item['quantity'] as double?,
        );
      }

      print('Sample wishlist items initialized successfully');
    } catch (e) {
      print('Error initializing sample wishlist items: $e');
    }
  }
}
