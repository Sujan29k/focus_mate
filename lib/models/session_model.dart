import 'package:cloud_firestore/cloud_firestore.dart';

class SessionModel {
  final String id;
  final String userId;
  final int durationMinutes;
  final DateTime startedAt;
  final DateTime? completedAt;
  final bool isCompleted;
  final String? notes;

  SessionModel({
    required this.id,
    required this.userId,
    required this.durationMinutes,
    required this.startedAt,
    this.completedAt,
    this.isCompleted = false,
    this.notes,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'durationMinutes': durationMinutes,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'isCompleted': isCompleted,
      'notes': notes,
    };
  }

  // Create from Firestore document
  factory SessionModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SessionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      durationMinutes: data['durationMinutes'] ?? 0,
      startedAt: DateTime.parse(
        data['startedAt'] ?? DateTime.now().toIso8601String(),
      ),
      completedAt: data['completedAt'] != null
          ? DateTime.parse(data['completedAt'])
          : null,
      isCompleted: data['isCompleted'] ?? false,
      notes: data['notes'],
    );
  }

  // Create copy with updated values
  SessionModel copyWith({
    int? durationMinutes,
    DateTime? completedAt,
    bool? isCompleted,
    String? notes,
  }) {
    return SessionModel(
      id: id,
      userId: userId,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      startedAt: startedAt,
      completedAt: completedAt ?? this.completedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
    );
  }
}
