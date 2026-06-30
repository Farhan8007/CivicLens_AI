import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/issue_model.dart';

class IssueService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'issues';

  /// Creates a new issue in the Firestore 'issues' collection.
  /// Returns the newly created document's ID.
  Future<String> createIssue(IssueModel issue) async {
    try {
      final docRef = _firestore.collection(_collectionName).doc();
      final issueWithId = issue.copyWith(issueId: docRef.id);
      
      await docRef.set(issueWithId.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create issue: $e');
    }
  }

  /// Retrieves all issues from the 'issues' collection.
  Future<List<IssueModel>> getAllIssues() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .orderBy('createdAt', descending: true)
          .get();
          
      return querySnapshot.docs
          .map((doc) => IssueModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all issues: $e');
    }
  }

  /// Retrieves issues reported by a specific user.
  Future<List<IssueModel>> getUserIssues(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
          
      return querySnapshot.docs
          .map((doc) => IssueModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user issues: $e');
    }
  }

  /// Updates the status of an existing issue.
  Future<void> updateIssueStatus(String issueId, String status) async {
    try {
      await _firestore.collection(_collectionName).doc(issueId).update({
        'status': status,
      });
    } catch (e) {
      throw Exception('Failed to update issue status: $e');
    }
  }

  /// Deletes an issue from the database.
  Future<void> deleteIssue(String issueId) async {
    try {
      await _firestore.collection(_collectionName).doc(issueId).delete();
    } catch (e) {
      throw Exception('Failed to delete issue: $e');
    }
  }

  /// Updates all fields of an existing issue.
  Future<void> updateIssue(IssueModel issue) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(issue.issueId)
          .update(issue.toMap());
    } catch (e) {
      throw Exception('Failed to update issue: $e');
    }
  }
}

