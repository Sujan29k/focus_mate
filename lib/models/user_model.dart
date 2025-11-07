import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final DateTime createdAt;
  final int totalFocusMinutes;
  final int totalSessions;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    required this.createdAt,
    this.totalFocusMinutes = 0,
    this.totalSessions = 0,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'createdAt': createdAt.toIso8601String(),
      'totalFocusMinutes': totalFocusMinutes,
      'totalSessions': totalSessions,
    };
  }

  // Create from Firestore document
  factory UserModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      createdAt: DateTime.parse(
        data['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      totalFocusMinutes: data['totalFocusMinutes'] ?? 0,
      totalSessions: data['totalSessions'] ?? 0,
    );
  }

  // Create copy with updated values
  UserModel copyWith({
    String? displayName,
    int? totalFocusMinutes,
    int? totalSessions,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt,
      totalFocusMinutes: totalFocusMinutes ?? this.totalFocusMinutes,
      totalSessions: totalSessions ?? this.totalSessions,
    );
  }
}
