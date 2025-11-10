import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meal.dart';
import 'firestore_service.dart';

class MealService {
  static final CollectionReference _mealsCollection =
      FirestoreService.firestore.collection('meals');

  /// Get all meals for current user
  static Stream<List<Meal>> getUserMeals(String userId) {
    return _mealsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Meal.fromJson({
                'id': doc.id,
                ...data,
                'dateTime': (data['dateTime'] as Timestamp).toDate().toIso8601String(),
              });
            })
            .toList());
  }

  /// Get meals by type for current user
  static Stream<List<Meal>> getUserMealsByType(String userId, String mealType) {
    return _mealsCollection
        .where('userId', isEqualTo: userId)
        .where('mealType', isEqualTo: mealType)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Meal.fromJson({
                'id': doc.id,
                ...data,
                'dateTime': (data['dateTime'] as Timestamp).toDate().toIso8601String(),
              });
            })
            .toList());
  }

  /// Get meals for a specific date range
  static Future<List<Meal>> getMealsByDateRange(
      String userId, DateTime startDate, DateTime endDate) async {
    final snapshot = await _mealsCollection
        .where('userId', isEqualTo: userId)
        .where('dateTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('dateTime', descending: true)
        .get();

    return snapshot.docs
        .map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Meal.fromJson({
            'id': doc.id,
            ...data,
            'dateTime': (data['dateTime'] as Timestamp).toDate().toIso8601String(),
          });
        })
        .toList();
  }

  /// Create a new meal
  static Future<String> createMeal(Meal meal, String userId) async {
    final mealData = meal.toJson();
    mealData['userId'] = userId;
    mealData['dateTime'] = Timestamp.fromDate(meal.dateTime);
    mealData['createdAt'] = FieldValue.serverTimestamp();
    
    final docRef = await _mealsCollection.add(mealData);
    return docRef.id;
  }

  /// Update an existing meal
  static Future<void> updateMeal(String mealId, Meal meal) async {
    final mealData = meal.toJson();
    mealData['dateTime'] = Timestamp.fromDate(meal.dateTime);
    mealData['updatedAt'] = FieldValue.serverTimestamp();
    
    await _mealsCollection.doc(mealId).update(mealData);
  }

  /// Delete a meal
  static Future<void> deleteMeal(String mealId) async {
    await _mealsCollection.doc(mealId).delete();
  }
}




