import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Base Firestore service with common functionality
class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static FirebaseFirestore get firestore => _firestore;
  static FirebaseAuth get auth => _auth;

  static String? get currentUserId => _auth.currentUser?.uid;

  /// Get current user document reference
  static DocumentReference? get currentUserRef {
    final userId = currentUserId;
    return userId != null ? _firestore.collection('users').doc(userId) : null;
  }
}




