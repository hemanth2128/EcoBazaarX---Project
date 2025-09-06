import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';
import '../config/firebase_config.dart';

class OrdersService {
  static const String _baseUrl = FirebaseConfig.baseApiUrl;
  static const String _ordersEndpoint = '/orders';

  // Create order
  static Future<Map<String, dynamic>> createOrder({
    required String userId,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required String deliveryAddress,
    String? paymentMethod,
    String? notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$_ordersEndpoint'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': userId,
          'items': items,
          'totalAmount': totalAmount,
          'deliveryAddress': deliveryAddress,
          'paymentMethod': paymentMethod ?? 'CASH',
          'notes': notes ?? '',
          'orderStatus': 'PENDING',
          'paymentStatus': 'PENDING',
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to create order: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error creating order: $e',
      };
    }
  }

  // Get user orders
  static Future<List<Map<String, dynamic>>> getUserOrders(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$_ordersEndpoint/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } catch (e) {
      print('Error getting user orders: $e');
      return [];
    }
  }

  // Get order by ID
  static Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$_ordersEndpoint/$orderId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      print('Error getting order by ID: $e');
      return null;
    }
  }

  // Update order status
  static Future<Map<String, dynamic>> updateOrderStatus({
    required String orderId,
    required String status,
    String? notes,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl$_ordersEndpoint/$orderId/status'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'status': status,
          'notes': notes ?? '',
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to update order status: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error updating order status: $e',
      };
    }
  }

  // Cancel order
  static Future<Map<String, dynamic>> cancelOrder(String orderId) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl$_ordersEndpoint/$orderId/cancel'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to cancel order: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error cancelling order: $e',
      };
    }
  }

  // Get orders by status
  static Future<List<Map<String, dynamic>>> getOrdersByStatus(String status) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$_ordersEndpoint/status/$status'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } catch (e) {
      print('Error getting orders by status: $e');
      return [];
    }
  }

  // Get shopkeeper orders
  static Future<List<Map<String, dynamic>>> getShopkeeperOrders(String shopkeeperId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$_ordersEndpoint/shopkeeper/$shopkeeperId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } catch (e) {
      print('Error getting shopkeeper orders: $e');
      return [];
    }
  }

  // Get order statistics
  static Future<Map<String, dynamic>> getOrderStatistics(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$_ordersEndpoint/stats/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'totalOrders': 0,
          'pendingOrders': 0,
          'completedOrders': 0,
          'cancelledOrders': 0,
          'totalSpent': 0.0,
        };
      }
    } catch (e) {
      print('Error getting order statistics: $e');
      return {
        'totalOrders': 0,
        'pendingOrders': 0,
        'completedOrders': 0,
        'cancelledOrders': 0,
        'totalSpent': 0.0,
      };
    }
  }

  // Get order items
  static Future<List<Map<String, dynamic>>> getOrderItems(String orderId) async {
    // TODO: Implement with Spring Boot API
    return [];
  }

  // Add order item
  static Future<Map<String, dynamic>> addOrderItem({
    required String orderId,
    required String productId,
    required int quantity,
    required double price,
  }) async {
    // TODO: Implement with Spring Boot API
    return {
      'success': false,
      'message': 'Order item addition will be implemented with Spring Boot backend',
    };
  }

  // Remove order item
  static Future<Map<String, dynamic>> removeOrderItem(String orderItemId) async {
    // TODO: Implement with Spring Boot API
    return {
      'success': false,
      'message': 'Order item removal will be implemented with Spring Boot backend',
    };
  }

  // Update order item quantity
  static Future<Map<String, dynamic>> updateOrderItemQuantity({
    required String orderItemId,
    required int quantity,
  }) async {
    // TODO: Implement with Spring Boot API
    return {
      'success': false,
      'message': 'Order item quantity update will be implemented with Spring Boot backend',
    };
  }

  // Get order history
  static Future<List<Map<String, dynamic>>> getOrderHistory(String userId, {int limit = 50}) async {
    // TODO: Implement with Spring Boot API
    return [];
  }

  // Get recent orders
  static Future<List<Map<String, dynamic>>> getRecentOrders(String userId, {int limit = 10}) async {
    // TODO: Implement with Spring Boot API
    return [];
  }

  // Calculate order total
  static double calculateOrderTotal(List<Map<String, dynamic>> items) {
    double total = 0.0;
    for (var item in items) {
      final quantity = item['quantity'] as int? ?? 0;
      final price = (item['price'] as num?)?.toDouble() ?? 0.0;
      total += quantity * price;
    }
    return total;
  }

  // Generate order number
  static String generateOrderNumber() {
    final now = DateTime.now();
    final random = Random().nextInt(1000);
    return 'ORD_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_$random';
  }
}