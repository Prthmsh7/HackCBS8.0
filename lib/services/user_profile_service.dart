import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';

class UserProfileService {
  static final CollectionReference _usersCollection =
      FirestoreService.firestore.collection('users');

  /// Get user profile
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final doc = await _usersCollection.doc(userId).get();
    if (doc.exists) {
      return doc.data() as Map<String, dynamic>?;
    }
    return null;
  }

  /// Get user profile stream
  static Stream<Map<String, dynamic>?> getUserProfileStream(String userId) {
    return _usersCollection.doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    });
  }

  /// Create or update user profile
  static Future<void> saveUserProfile(String userId, {
    String? name,
    int? age,
    double? weight,
    double? height,
    String? gender,
    String? goal,
    List<String>? dietaryPreferences,
  }) async {
    final profileData = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (name != null) profileData['name'] = name;
    if (age != null) profileData['age'] = age;
    if (weight != null) profileData['weight'] = weight;
    if (height != null) profileData['height'] = height;
    if (gender != null) profileData['gender'] = gender;
    if (goal != null) profileData['goal'] = goal;
    if (dietaryPreferences != null) {
      profileData['dietaryPreferences'] = dietaryPreferences;
    }

    final docRef = _usersCollection.doc(userId);
    final doc = await docRef.get();
    
    if (!doc.exists) {
      profileData['createdAt'] = FieldValue.serverTimestamp();
    }

    await docRef.set(profileData, SetOptions(merge: true));
  }

  /// Update user profile
  static Future<void> updateUserProfile(
      String userId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _usersCollection.doc(userId).update(updates);
  }

  /// Delete user profile
  static Future<void> deleteUserProfile(String userId) async {
    await _usersCollection.doc(userId).delete();
  }
}

