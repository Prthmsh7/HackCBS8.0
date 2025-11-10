import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pantry_item.dart';
import 'firestore_service.dart';

class PantryService {
  static final CollectionReference _pantryCollection =
      FirestoreService.firestore.collection('pantry_items');

  /// Get all pantry items for current user
  static Stream<List<PantryItem>> getUserPantryItems(String userId) {
    return _pantryCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return PantryItem.fromJson({
                'id': doc.id,
                ...data,
                'expiryDate': data['expiryDate'] != null
                    ? (data['expiryDate'] as Timestamp).toDate().toIso8601String()
                    : null,
              });
            })
            .toList());
  }

  /// Get pantry items by category
  static Stream<List<PantryItem>> getPantryItemsByCategory(
      String userId, String category) {
    return _pantryCollection
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return PantryItem.fromJson({
                'id': doc.id,
                ...data,
                'expiryDate': data['expiryDate'] != null
                    ? (data['expiryDate'] as Timestamp).toDate().toIso8601String()
                    : null,
              });
            })
            .toList());
  }

  /// Get pantry items sorted by expiry date
  static Stream<List<PantryItem>> getPantryItemsByExpiry(String userId) {
    return _pantryCollection
        .where('userId', isEqualTo: userId)
        .where('expiryDate', isGreaterThan: Timestamp.now())
        .orderBy('expiryDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return PantryItem.fromJson({
                'id': doc.id,
                ...data,
                'expiryDate': data['expiryDate'] != null
                    ? (data['expiryDate'] as Timestamp).toDate().toIso8601String()
                    : null,
              });
            })
            .toList());
  }

  /// Create a new pantry item
  static Future<String> createPantryItem(
      PantryItem item, String userId) async {
    print('💾 [PANTRY SERVICE] Creating pantry item: ${item.name} for user: $userId');
    final itemData = item.toJson();
    itemData['userId'] = userId;
    if (item.expiryDate != null) {
      itemData['expiryDate'] = Timestamp.fromDate(item.expiryDate!);
    }
    itemData['createdAt'] = FieldValue.serverTimestamp();
    
    print('💾 [PANTRY SERVICE] Item data: $itemData');
    print('💾 [PANTRY SERVICE] Writing to Firestore collection: pantry_items');
    final docRef = await _pantryCollection.add(itemData);
    print('✅ [PANTRY SERVICE] Pantry item created with ID: ${docRef.id}');
    return docRef.id;
  }

  /// Update an existing pantry item
  static Future<void> updatePantryItem(String itemId, PantryItem item) async {
    print('💾 [PANTRY SERVICE] Updating pantry item: $itemId');
    final itemData = item.toJson();
    if (item.expiryDate != null) {
      itemData['expiryDate'] = Timestamp.fromDate(item.expiryDate!);
    }
    itemData['updatedAt'] = FieldValue.serverTimestamp();
    
    print('💾 [PANTRY SERVICE] Update data: $itemData');
    await _pantryCollection.doc(itemId).update(itemData);
    print('✅ [PANTRY SERVICE] Pantry item updated successfully');
  }

  /// Delete a pantry item
  static Future<void> deletePantryItem(String itemId) async {
    print('🗑️ [PANTRY SERVICE] Deleting pantry item: $itemId');
    await _pantryCollection.doc(itemId).delete();
    print('✅ [PANTRY SERVICE] Pantry item deleted successfully');
  }
}




