import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Handles reading and writing user profile data to Firestore.
class UserService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  UserService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  String? get _uid => _auth.currentUser?.uid;

  /// Returns the Firestore-stored display name for the current user.
  /// Falls back to [FirebaseAuth.currentUser.displayName] then [email].
  Future<String?> getDisplayName() async {
    final uid = _uid;
    if (uid == null) return null;
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        final name = data?['displayName'] as String?;
        if (name != null && name.trim().isNotEmpty) return name.trim();
      }
    } catch (_) {}
    final authName = _auth.currentUser?.displayName;
    if (authName != null && authName.trim().isNotEmpty) return authName.trim();
    return _auth.currentUser?.email;
  }

  /// Persists [displayName] to Firestore for the current user (merge so we
  /// never overwrite other fields).
  Future<void> updateDisplayName(String displayName) async {
    final uid = _uid;
    if (uid == null) return;
    await _usersCollection.doc(uid).set(
      {'displayName': displayName.trim()},
      SetOptions(merge: true),
    );
  }
}
