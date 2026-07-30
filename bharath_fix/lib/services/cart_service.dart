import 'package:flutter/foundation.dart';

class CartService {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final ValueNotifier<List<Map<String, dynamic>>> itemsNotifier =
      ValueNotifier<List<Map<String, dynamic>>>([]);

  List<Map<String, dynamic>> get items => itemsNotifier.value;

  int get itemCount => itemsNotifier.value.fold(0, (sum, item) => sum + (item['quantity'] as int? ?? 1));

  double get totalPrice {
    return itemsNotifier.value.fold(0.0, (sum, item) {
      final price = (item['price'] as num? ?? 0.0).toDouble();
      final qty = (item['quantity'] as int? ?? 1);
      return sum + (price * qty);
    });
  }

  void addItem(Map<String, dynamic> service) {
    final currentList = List<Map<String, dynamic>>.from(itemsNotifier.value);
    final id = service['id'] ?? service['title'];

    final existingIndex = currentList.indexWhere((item) => (item['id'] ?? item['title']) == id);
    if (existingIndex >= 0) {
      final existingItem = currentList[existingIndex];
      final currentQty = existingItem['quantity'] as int? ?? 1;
      currentList[existingIndex] = {
        ...existingItem,
        'quantity': currentQty + 1,
      };
    } else {
      currentList.add({
        ...service,
        'quantity': 1,
      });
    }

    itemsNotifier.value = currentList;
  }

  void removeItem(String id) {
    final currentList = List<Map<String, dynamic>>.from(itemsNotifier.value);
    currentList.removeWhere((item) => (item['id'] ?? item['title']) == id);
    itemsNotifier.value = currentList;
  }

  void updateQuantity(String id, int delta) {
    final currentList = List<Map<String, dynamic>>.from(itemsNotifier.value);
    final index = currentList.indexWhere((item) => (item['id'] ?? item['title']) == id);
    if (index >= 0) {
      final currentQty = currentList[index]['quantity'] as int? ?? 1;
      final newQty = currentQty + delta;
      if (newQty <= 0) {
        currentList.removeAt(index);
      } else {
        currentList[index] = {
          ...currentList[index],
          'quantity': newQty,
        };
      }
      itemsNotifier.value = currentList;
    }
  }

  void clearCart() {
    itemsNotifier.value = [];
  }
}
