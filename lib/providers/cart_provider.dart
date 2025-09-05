import 'package:flutter/material.dart';

class CartItem {
  final String id;
  final String name;
  final String description;
  final double price;
  int quantity;
  final IconData icon;
  final Color color;
  final String category; // Add category for carbon calculation
  final double carbonFootprint; // Add carbon footprint per unit

  CartItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    required this.icon,
    required this.color,
    required this.category,
    required this.carbonFootprint,
  });

  double get totalPrice => price * quantity;
  double get totalCarbonFootprint => carbonFootprint * quantity;
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _cartItems = {};

  Map<String, CartItem> get cartItems => {..._cartItems};

  List<CartItem> get cartItemsList => _cartItems.values.toList();

  int get itemCount => _cartItems.length;

  double get totalAmount {
    double total = 0.0;
    _cartItems.forEach((key, cartItem) {
      total += cartItem.totalPrice;
    });
    return total;
  }

  int get totalQuantity {
    int total = 0;
    _cartItems.forEach((key, cartItem) {
      total += cartItem.quantity;
    });
    return total;
  }

  // Calculate total carbon footprint saved
  double get totalCarbonFootprintSaved {
    double total = 0.0;
    _cartItems.forEach((key, cartItem) {
      total += cartItem.totalCarbonFootprint;
    });
    return total;
  }

  // Get carbon footprint by category
  Map<String, double> get carbonFootprintByCategory {
    Map<String, double> categoryCarbon = {};
    _cartItems.forEach((key, cartItem) {
      if (categoryCarbon.containsKey(cartItem.category)) {
        categoryCarbon[cartItem.category] = categoryCarbon[cartItem.category]! + cartItem.totalCarbonFootprint;
      } else {
        categoryCarbon[cartItem.category] = cartItem.totalCarbonFootprint;
      }
    });
    return categoryCarbon;
  }

  void addItem({
    required String productId,
    required String name,
    required String description,
    required double price,
    required IconData icon,
    required Color color,
    required String category,
    required double carbonFootprint,
  }) {
    if (_cartItems.containsKey(productId)) {
      // If item already exists, increase quantity
      _cartItems.update(
        productId,
        (existingCartItem) => CartItem(
          id: existingCartItem.id,
          name: existingCartItem.name,
          description: existingCartItem.description,
          price: existingCartItem.price,
          quantity: existingCartItem.quantity + 1,
          icon: existingCartItem.icon,
          color: existingCartItem.color,
          category: existingCartItem.category,
          carbonFootprint: existingCartItem.carbonFootprint,
        ),
      );
    } else {
      // Add new item to cart
      _cartItems.putIfAbsent(
        productId,
        () => CartItem(
          id: productId,
          name: name,
          description: description,
          price: price,
          quantity: 1,
          icon: icon,
          color: color,
          category: category,
          carbonFootprint: carbonFootprint,
        ),
      );
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _cartItems.remove(productId);
    notifyListeners();
  }

  void removeSingleItem(String productId) {
    if (!_cartItems.containsKey(productId)) {
      return;
    }

    if (_cartItems[productId]!.quantity > 1) {
      _cartItems.update(
        productId,
        (existingCartItem) => CartItem(
          id: existingCartItem.id,
          name: existingCartItem.name,
          description: existingCartItem.description,
          price: existingCartItem.price,
          quantity: existingCartItem.quantity - 1,
          icon: existingCartItem.icon,
          color: existingCartItem.color,
          category: existingCartItem.category,
          carbonFootprint: existingCartItem.carbonFootprint,
        ),
      );
    } else {
      _cartItems.remove(productId);
    }
    notifyListeners();
  }

  void updateQuantity(String productId, int newQuantity) {
    if (!_cartItems.containsKey(productId) || newQuantity <= 0) {
      return;
    }

    _cartItems.update(
      productId,
      (existingCartItem) => CartItem(
        id: existingCartItem.id,
        name: existingCartItem.name,
        description: existingCartItem.description,
        price: existingCartItem.price,
        quantity: newQuantity,
        icon: existingCartItem.icon,
        color: existingCartItem.color,
        category: existingCartItem.category,
        carbonFootprint: existingCartItem.carbonFootprint,
      ),
    );
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  bool isInCart(String productId) {
    return _cartItems.containsKey(productId);
  }

  int getQuantity(String productId) {
    if (_cartItems.containsKey(productId)) {
      return _cartItems[productId]!.quantity;
    }
    return 0;
  }

  // Get purchase summary for carbon tracking
  Map<String, dynamic> getPurchaseSummary() {
    return {
      'totalAmount': totalAmount,
      'totalQuantity': totalQuantity,
      'totalCarbonSaved': totalCarbonFootprintSaved,
      'carbonByCategory': carbonFootprintByCategory,
      'items': cartItemsList.map((item) => {
        'id': item.id,
        'name': item.name,
        'quantity': item.quantity,
        'price': item.price,
        'totalPrice': item.totalPrice,
        'category': item.category,
        'carbonFootprint': item.carbonFootprint,
        'totalCarbonSaved': item.totalCarbonFootprint,
      }).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}