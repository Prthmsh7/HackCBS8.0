import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shopping_item.dart';
import 'firestore_service.dart';

class ShoppingService {
  static final CollectionReference _shoppingCollection =
      FirestoreService.firestore.collection('shopping_items');

  /// Get all shopping items for current user
  static Stream<List<ShoppingItem>> getUserShoppingItems(String userId) {
    return _shoppingCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return ShoppingItem.fromJson({
                'id': doc.id,
                ...data,
              });
            })
            .toList());
  }

  /// Get shopping items by completion status
  static Stream<List<ShoppingItem>> getShoppingItemsByStatus(
      String userId, bool isCompleted) {
    return _shoppingCollection
        .where('userId', isEqualTo: userId)
        .where('isCompleted', isEqualTo: isCompleted)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return ShoppingItem.fromJson({
                'id': doc.id,
                ...data,
              });
            })
            .toList());
  }

  /// Get shopping items by category
  static Stream<List<ShoppingItem>> getShoppingItemsByCategory(
      String userId, String category) {
    return _shoppingCollection
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: category)
        .where('isCompleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return ShoppingItem.fromJson({
                'id': doc.id,
                ...data,
              });
            })
            .toList());
  }

  /// Create a new shopping item
  static Future<String> createShoppingItem(
      ShoppingItem item, String userId) async {
    final itemData = item.toJson();
    itemData['userId'] = userId;
    itemData['createdAt'] = FieldValue.serverTimestamp();
    
    final docRef = await _shoppingCollection.add(itemData);
    return docRef.id;
  }

  /// Update an existing shopping item
  static Future<void> updateShoppingItem(
      String itemId, ShoppingItem item) async {
    final itemData = item.toJson();
    itemData['updatedAt'] = FieldValue.serverTimestamp();
    
    await _shoppingCollection.doc(itemId).update(itemData);
  }

  /// Toggle completion status of a shopping item
  static Future<void> toggleShoppingItemStatus(
      String itemId, bool isCompleted) async {
    await _shoppingCollection.doc(itemId).update({
      'isCompleted': isCompleted,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a shopping item
  static Future<void> deleteShoppingItem(String itemId) async {
    await _shoppingCollection.doc(itemId).delete();
  }
}




