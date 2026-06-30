import 'package:cloud_firestore/cloud_firestore.dart';

class IssueModel {
  final String issueId;
  final String userId;
  final String userEmail;
  final String title;
  final String description;
  final String category;
  final String? mediaUrl;
  final String? mediaType;
  final double? latitude;
  final double? longitude;
  final String status;
  final String priority;
  final DateTime createdAt;

  IssueModel({
    required this.issueId,
    required this.userId,
    required this.userEmail,
    required this.title,
    required this.description,
    required this.category,
    this.mediaUrl,
    this.mediaType,
    this.latitude,
    this.longitude,
    required this.status,
    required this.priority,
    required this.createdAt,
  });

  IssueModel copyWith({
    String? issueId,
    String? userId,
    String? userEmail,
    String? title,
    String? description,
    String? category,
    String? mediaUrl,
    String? mediaType,
    double? latitude,
    double? longitude,
    String? status,
    String? priority,
    DateTime? createdAt,
  }) {
    return IssueModel(
      issueId: issueId ?? this.issueId,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'issueId': issueId,
      'userId': userId,
      'userEmail': userEmail,
      'title': title,
      'description': description,
      'category': category,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'priority': priority,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory IssueModel.fromMap(Map<String, dynamic> map, String id) {
    return IssueModel(
      issueId: id,
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      mediaUrl: map['mediaUrl'],
      mediaType: map['mediaType'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      status: map['status'] ?? 'pending',
      priority: map['priority'] ?? 'Medium',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
