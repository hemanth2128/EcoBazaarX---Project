import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class OrdersService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _ordersCollection = _firestore.collection('orders');
  static final CollectionReference _userOrdersCollection = _firestore.collection('user_orders');

  // Generate unique order ID
  static String _generateOrderId() {
    final now = DateTime.now();
    final random = Random().nextInt(1000);
    return 'ORD_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_$random';
  }

  // Create a new order
  static Future<Map<String, dynamic>> createOrder({
    required String userId,
    required String userEmail,
    required String userName,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required String status,
    String? deliveryAddress,
    String? paymentMethod,
  }) async {
    try {
      final orderId = _generateOrderId();
      final now = DateTime.now();

      final orderData = {
        'orderId': orderId,
        'userId': userId,
        'userEmail': userEmail,
        'userName': userName,
        'items': items,
        'totalAmount': totalAmount,
        'status': status,
        'deliveryAddress': deliveryAddress,
        'paymentMethod': paymentMethod,
        'createdAt': now,
        'updatedAt': now,
        'estimatedDelivery': now.add(const Duration(days: 4)),
      };

      // Add to orders collection
      await _ordersCollection.doc(orderId).set(orderData);

      // Add to user orders collection for easy querying
      await _userOrdersCollection.doc(orderId).set({
        ...orderData,
        'orderId': orderId,
      });

      return {
        'success': true,
        'orderId': orderId,
        'message': 'Order created successfully!',
        'orderData': orderData,
      };
    } catch (e) {
      print('Error creating order: $e');
      return {
        'success': false,
        'message': 'Failed to create order: ${e.toString()}',
      };
    }
  }

  // Get all orders for a user
  static Future<List<Map<String, dynamic>>> getUserOrders(String userId) async {
    try {
      final snapshot = await _userOrdersCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          ...data,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      print('Error getting user orders: $e');
      return [];
    }
  }

  // Get all orders (for admin/shopkeeper)
  static Future<List<Map<String, dynamic>>> getAllOrders() async {
    try {
      final snapshot = await _ordersCollection
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          ...data,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      print('Error getting all orders: $e');
      return [];
    }
  }

  // Get orders by status
  static Future<List<Map<String, dynamic>>> getOrdersByStatus(String status) async {
    try {
      final snapshot = await _ordersCollection
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          ...data,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      print('Error getting orders by status: $e');
      return [];
    }
  }

  // Update order status
  static Future<Map<String, dynamic>> updateOrderStatus(String orderId, String newStatus) async {
    try {
      final now = DateTime.now();
      
      await _ordersCollection.doc(orderId).update({
        'status': newStatus,
        'updatedAt': now,
      });

      await _userOrdersCollection.doc(orderId).update({
        'status': newStatus,
        'updatedAt': now,
      });

      return {
        'success': true,
        'message': 'Order status updated successfully!',
      };
    } catch (e) {
      print('Error updating order status: $e');
      return {
        'success': false,
        'message': 'Failed to update order status: ${e.toString()}',
      };
    }
  }

  // Get order by ID
  static Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    try {
      final doc = await _ordersCollection.doc(orderId).get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          ...data,
          'id': doc.id,
        };
      }
      
      return null;
    } catch (e) {
      print('Error getting order by ID: $e');
      return null;
    }
  }

  // Get order statistics
  static Future<Map<String, dynamic>> getOrderStatistics() async {
    try {
      final snapshot = await _ordersCollection.get();
      final orders = snapshot.docs;

      int totalOrders = orders.length;
      double totalRevenue = 0.0;
      Map<String, int> statusCounts = {};
      Map<String, double> monthlyRevenue = {};

      for (var doc in orders) {
        final data = doc.data() as Map<String, dynamic>;
        final amount = (data['totalAmount'] ?? 0.0) as double;
        final status = data['status'] ?? 'Unknown';
        final createdAt = data['createdAt'] as Timestamp?;
        
        totalRevenue += amount;
        
        // Count by status
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
        
        // Monthly revenue
        if (createdAt != null) {
          final month = '${createdAt.toDate().year}-${createdAt.toDate().month.toString().padLeft(2, '0')}';
          monthlyRevenue[month] = (monthlyRevenue[month] ?? 0.0) + amount;
        }
      }

      return {
        'totalOrders': totalOrders,
        'totalRevenue': totalRevenue,
        'statusCounts': statusCounts,
        'monthlyRevenue': monthlyRevenue,
        'averageOrderValue': totalOrders > 0 ? totalRevenue / totalOrders : 0.0,
      };
    } catch (e) {
      print('Error getting order statistics: $e');
      return {
        'totalOrders': 0,
        'totalRevenue': 0.0,
        'statusCounts': {},
        'monthlyRevenue': {},
        'averageOrderValue': 0.0,
      };
    }
  }

  // Initialize sample orders (for demo purposes)
  static Future<void> initializeSampleOrders() async {
    try {
      // Check if orders already exist
      final existingOrders = await _ordersCollection.limit(1).get();
      
      if (existingOrders.docs.isNotEmpty) {
        print('Orders already exist in Firestore');
        return;
      }

      final sampleOrders = [
        {
          'orderId': 'ORD_20240115_001',
          'userId': 'user_1',
          'userEmail': 'customer1@example.com',
          'userName': 'Priya Sharma',
          'items': [
            {
              'id': '1',
              'name': 'Bamboo Water Bottle',
              'price': 599.0,
              'quantity': 1,
              'color': '#D6EAF8',
              'icon': 'water_drop_rounded',
            }
          ],
          'totalAmount': 599.0,
          'status': 'Delivered',
          'deliveryAddress': '123 Eco Street, Mumbai',
          'paymentMethod': 'Credit Card',
          'createdAt': DateTime.now().subtract(const Duration(days: 1)),
          'updatedAt': DateTime.now().subtract(const Duration(days: 1)),
          'estimatedDelivery': DateTime.now().subtract(const Duration(days: 1)).add(const Duration(days: 4)),
        },
        {
          'orderId': 'ORD_20240114_002',
          'userId': 'user_2',
          'userEmail': 'customer2@example.com',
          'userName': 'Rahul Kumar',
          'items': [
            {
              'id': '2',
              'name': 'Organic Cotton T-Shirt',
              'price': 899.0,
              'quantity': 1,
              'color': '#B5C7F7',
              'icon': 'checkroom_rounded',
            }
          ],
          'totalAmount': 899.0,
          'status': 'In Transit',
          'deliveryAddress': '456 Green Avenue, Delhi',
          'paymentMethod': 'UPI',
          'createdAt': DateTime.now().subtract(const Duration(days: 2)),
          'updatedAt': DateTime.now().subtract(const Duration(days: 2)),
          'estimatedDelivery': DateTime.now().subtract(const Duration(days: 2)).add(const Duration(days: 4)),
        },
        {
          'orderId': 'ORD_20240113_003',
          'userId': 'user_3',
          'userEmail': 'customer3@example.com',
          'userName': 'Anjali Patel',
          'items': [
            {
              'id': '3',
              'name': 'Eco-Friendly Soap',
              'price': 199.0,
              'quantity': 2,
              'color': '#F9E79F',
              'icon': 'spa_rounded',
            }
          ],
          'totalAmount': 398.0,
          'status': 'Processing',
          'deliveryAddress': '789 Sustainable Road, Bangalore',
          'paymentMethod': 'Debit Card',
          'createdAt': DateTime.now().subtract(const Duration(days: 3)),
          'updatedAt': DateTime.now().subtract(const Duration(days: 3)),
          'estimatedDelivery': DateTime.now().subtract(const Duration(days: 3)).add(const Duration(days: 4)),
        },
        {
          'orderId': 'ORD_20240112_004',
          'userId': 'user_4',
          'userEmail': 'customer4@example.com',
          'userName': 'Vikram Singh',
          'items': [
            {
              'id': '4',
              'name': 'Solar Phone Charger',
              'price': 1299.0,
              'quantity': 1,
              'color': '#E8D5C4',
              'icon': 'solar_power_rounded',
            }
          ],
          'totalAmount': 1299.0,
          'status': 'Delivered',
          'deliveryAddress': '321 Eco Lane, Chennai',
          'paymentMethod': 'Net Banking',
          'createdAt': DateTime.now().subtract(const Duration(days: 4)),
          'updatedAt': DateTime.now().subtract(const Duration(days: 4)),
          'estimatedDelivery': DateTime.now().subtract(const Duration(days: 4)).add(const Duration(days: 4)),
        },
        {
          'orderId': 'ORD_20240111_005',
          'userId': 'user_5',
          'userEmail': 'customer5@example.com',
          'userName': 'Meera Reddy',
          'items': [
            {
              'id': '5',
              'name': 'Reusable Shopping Bag',
              'price': 299.0,
              'quantity': 1,
              'color': '#B5C7F7',
              'icon': 'shopping_bag_rounded',
            }
          ],
          'totalAmount': 299.0,
          'status': 'In Transit',
          'deliveryAddress': '654 Green Street, Hyderabad',
          'paymentMethod': 'Wallet',
          'createdAt': DateTime.now().subtract(const Duration(days: 5)),
          'updatedAt': DateTime.now().subtract(const Duration(days: 5)),
          'estimatedDelivery': DateTime.now().subtract(const Duration(days: 5)).add(const Duration(days: 4)),
        },
      ];

      // Add sample orders to Firestore
      for (var order in sampleOrders) {
        final orderId = order['orderId'] as String;
        await _ordersCollection.doc(orderId).set(order);
        await _userOrdersCollection.doc(orderId).set(order);
      }

      print('Sample orders initialized successfully!');
    } catch (e) {
      print('Error initializing sample orders: $e');
    }
  }

  // Helper method to format order status for display
  static String getStatusDisplayName(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'processing':
        return 'Processing';
      case 'in_transit':
      case 'in transit':
        return 'In Transit';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      case 'refunded':
        return 'Refunded';
      default:
        return status;
    }
  }

  // Helper method to get status color
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFFB74D);
      case 'processing':
        return const Color(0xFFF9E79F);
      case 'in_transit':
      case 'in transit':
        return const Color(0xFF64B5F6);
      case 'delivered':
        return const Color(0xFF81C784);
      case 'cancelled':
        return const Color(0xFFE57373);
      case 'refunded':
        return const Color(0xFFBA68C8);
      default:
        return const Color(0xFFB5C7F7);
    }
  }
}
