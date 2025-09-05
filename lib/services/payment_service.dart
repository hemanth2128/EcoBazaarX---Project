import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class PaymentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _ordersCollection = _firestore.collection('orders');
  static final CollectionReference _paymentTransactionsCollection = _firestore.collection('payment_transactions');
  static final CollectionReference _userOrdersCollection = _firestore.collection('user_orders');

  // Generate unique order ID
  static String _generateOrderId() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    final random = Random().nextInt(1000);
    return 'ORD_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_$random';
  }

  // Generate unique transaction ID
  static String _generateTransactionId() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch;
    final random = Random().nextInt(1000);
    return 'TXN_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_$random';
  }

  // Create order in Firestore
  static Future<Map<String, dynamic>> createOrder({
    required String userId,
    required String userEmail,
    required String userName,
    required String userPhone,
    required List<Map<String, dynamic>> cartItems,
    required Map<String, dynamic> shippingAddress,
    required Map<String, dynamic> billingAddress,
    required double totalAmount,
    required double taxAmount,
    required double shippingAmount,
    required double discountAmount,
    required double finalAmount,
    required String paymentMethod,
    String? deliveryNotes,
  }) async {
    try {
      final orderId = _generateOrderId();
      final now = DateTime.now();
      final estimatedDelivery = now.add(const Duration(days: 4));

      // Calculate carbon footprint and eco points
      double totalCarbonFootprint = 0.0;
      int totalEcoPoints = 0;

      for (var item in cartItems) {
        final quantity = (item['quantity'] ?? 1) as int;
        final carbonFootprint = (item['carbonFootprint'] ?? 0.0) as double;
        final ecoPoints = (item['ecoPoints'] ?? 0) as int;
        
        totalCarbonFootprint += carbonFootprint * quantity;
        totalEcoPoints += ecoPoints * quantity;
      }

      final orderData = {
        'orderId': orderId,
        'userId': userId,
        'userEmail': userEmail,
        'userName': userName,
        'userPhone': userPhone,
        'orderDate': now,
        'orderStatus': 'pending',
        'paymentStatus': 'pending',
        'paymentMethod': paymentMethod,
        'paymentId': null,
        'totalAmount': totalAmount,
        'taxAmount': taxAmount,
        'shippingAmount': shippingAmount,
        'discountAmount': discountAmount,
        'finalAmount': finalAmount,
        'currency': 'INR',
        'items': cartItems,
        'shippingAddress': shippingAddress,
        'billingAddress': billingAddress,
        'deliveryNotes': deliveryNotes,
        'estimatedDelivery': estimatedDelivery,
        'trackingNumber': null,
        'carbonFootprint': totalCarbonFootprint,
        'ecoPointsEarned': totalEcoPoints,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Save order to Firestore
      await _ordersCollection.doc(orderId).set(orderData);

      // Update product stock for each item
      for (var item in cartItems) {
        final productId = item['productId'] as String?;
        final quantity = (item['quantity'] ?? 1) as int;
        
        if (productId != null) {
          await _updateProductStock(productId, quantity);
        }
      }

      // Create user order reference
      await _userOrdersCollection.add({
        'userId': userId,
        'orderId': orderId,
        'orderDate': now,
        'orderStatus': 'pending',
        'totalAmount': finalAmount,
        'itemCount': cartItems.length,
        'createdAt': FieldValue.serverTimestamp(),
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

  // Update product stock after order
  static Future<void> _updateProductStock(String productId, int orderedQuantity) async {
    try {
      final productDoc = await _firestore.collection('products').doc(productId).get();
      
      if (productDoc.exists) {
        final productData = productDoc.data() as Map<String, dynamic>;
        final currentStock = (productData['quantity'] ?? 0) as int;
        final newStock = currentStock - orderedQuantity;
        
        // Ensure stock doesn't go below 0
        final finalStock = newStock < 0 ? 0 : newStock;
        
        await _firestore.collection('products').doc(productId).update({
          'quantity': finalStock,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        print('✅ Stock updated for product $productId: $currentStock -> $finalStock (ordered: $orderedQuantity)');
      } else {
        print('❌ Product not found: $productId');
      }
    } catch (e) {
      print('❌ Error updating stock for product $productId: $e');
    }
  }

  // Process payment and update order
  static Future<Map<String, dynamic>> processPayment({
    required String orderId,
    required String userId,
    required String paymentMethod,
    required String paymentGateway,
    required double amount,
    required Map<String, dynamic> gatewayResponse,
    String? failureReason,
  }) async {
    try {
      final transactionId = _generateTransactionId();
      final now = DateTime.now();

      // Create payment transaction record
      final transactionData = {
        'transactionId': transactionId,
        'orderId': orderId,
        'userId': userId,
        'paymentMethod': paymentMethod,
        'paymentGateway': paymentGateway,
        'gatewayTransactionId': gatewayResponse['razorpay_payment_id'],
        'amount': amount,
        'currency': 'INR',
        'status': failureReason == null ? 'success' : 'failed',
        'gatewayResponse': gatewayResponse,
        'failureReason': failureReason,
        'refundAmount': 0.00,
        'refundReason': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Save transaction to Firestore
      await _paymentTransactionsCollection.doc(transactionId).set(transactionData);

      // Update order status
      final orderUpdateData = {
        'paymentStatus': failureReason == null ? 'paid' : 'failed',
        'paymentId': gatewayResponse['razorpay_payment_id'],
        'orderStatus': failureReason == null ? 'confirmed' : 'pending',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _ordersCollection.doc(orderId).update(orderUpdateData);

      // Update user order status
      await _userOrdersCollection
          .where('orderId', isEqualTo: orderId)
          .get()
          .then((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          snapshot.docs.first.reference.update({
            'orderStatus': failureReason == null ? 'confirmed' : 'pending',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      return {
        'success': failureReason == null,
        'transactionId': transactionId,
        'message': failureReason == null 
            ? 'Payment processed successfully!' 
            : 'Payment failed: $failureReason',
        'transactionData': transactionData,
      };
    } catch (e) {
      print('Error processing payment: $e');
      return {
        'success': false,
        'message': 'Failed to process payment: ${e.toString()}',
      };
    }
  }

  // Get user orders
  static Future<List<Map<String, dynamic>>> getUserOrders(String userId) async {
    try {
      final snapshot = await _userOrdersCollection
          .where('userId', isEqualTo: userId)
          .orderBy('orderDate', descending: true)
          .get();

      final userOrders = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          ...data,
          'id': doc.id,
        };
      }).toList();

      // Get detailed order information
      final detailedOrders = <Map<String, dynamic>>[];
      for (var userOrder in userOrders) {
        final orderDoc = await _ordersCollection.doc(userOrder['orderId']).get();
        if (orderDoc.exists) {
          final orderData = orderDoc.data() as Map<String, dynamic>;
          detailedOrders.add({
            ...userOrder,
            'orderDetails': orderData,
          });
        }
      }

      return detailedOrders;
    } catch (e) {
      print('Error getting user orders: $e');
      return [];
    }
  }

  // Get order details
  static Future<Map<String, dynamic>?> getOrderDetails(String orderId) async {
    try {
      final doc = await _ordersCollection.doc(orderId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting order details: $e');
      return null;
    }
  }

  // Update order status
  static Future<Map<String, dynamic>> updateOrderStatus({
    required String orderId,
    required String status,
    String? trackingNumber,
  }) async {
    try {
      final updateData = {
        'orderStatus': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (trackingNumber != null) {
        updateData['trackingNumber'] = trackingNumber;
      }

      await _ordersCollection.doc(orderId).update(updateData);

      // Update user order status
      await _userOrdersCollection
          .where('orderId', isEqualTo: orderId)
          .get()
          .then((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          snapshot.docs.first.reference.update({
            'orderStatus': status,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
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

  // Get payment statistics
  static Future<Map<String, dynamic>> getPaymentStats() async {
    try {
      final ordersSnapshot = await _ordersCollection.get();
      final transactionsSnapshot = await _paymentTransactionsCollection.get();

      final orders = ordersSnapshot.docs;
      final transactions = transactionsSnapshot.docs;

      double totalRevenue = 0.0;
      int totalOrders = orders.length;
      int successfulPayments = 0;
      int failedPayments = 0;

      for (var transaction in transactions) {
        final data = transaction.data() as Map<String, dynamic>;
        if (data['status'] == 'success') {
          totalRevenue += (data['amount'] ?? 0.0);
          successfulPayments++;
        } else if (data['status'] == 'failed') {
          failedPayments++;
        }
      }

      return {
        'totalRevenue': totalRevenue,
        'totalOrders': totalOrders,
        'successfulPayments': successfulPayments,
        'failedPayments': failedPayments,
        'successRate': totalOrders > 0 ? (successfulPayments / totalOrders) * 100 : 0.0,
      };
    } catch (e) {
      print('Error getting payment stats: $e');
      return {
        'totalRevenue': 0.0,
        'totalOrders': 0,
        'successfulPayments': 0,
        'failedPayments': 0,
        'successRate': 0.0,
      };
    }
  }

  // Simulate Razorpay payment (for demo purposes)
  static Future<Map<String, dynamic>> simulateRazorpayPayment({
    required double amount,
    required String currency,
    required String orderId,
  }) async {
    try {
      // Simulate payment processing delay
      await Future.delayed(const Duration(seconds: 2));

      // Simulate success/failure (90% success rate for demo)
      final isSuccess = Random().nextDouble() > 0.1;

      if (isSuccess) {
        return {
          'success': true,
          'razorpay_payment_id': 'pay_${DateTime.now().millisecondsSinceEpoch}',
          'razorpay_order_id': 'order_${DateTime.now().millisecondsSinceEpoch}',
          'razorpay_signature': 'signature_${DateTime.now().millisecondsSinceEpoch}',
          'message': 'Payment successful!',
        };
      } else {
        return {
          'success': false,
          'failureReason': 'Payment gateway error',
          'message': 'Payment failed due to gateway error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'failureReason': 'Network error',
        'message': 'Payment failed due to network error',
      };
    }
  }
}
