import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? dueDate;
  final int priority; // 1-High, 2-Medium, 3-Low

  TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
    this.dueDate,
    this.priority = 2,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'priority': priority,
    };
  }

  // Create from Firestore document
  factory TaskModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      isCompleted: data['isCompleted'] ?? false,
      createdAt: DateTime.parse(
        data['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      completedAt: data['completedAt'] != null
          ? DateTime.parse(data['completedAt'])
          : null,
      dueDate: data['dueDate'] != null ? DateTime.parse(data['dueDate']) : null,
      priority: data['priority'] ?? 2,
    );
  }

  // Create copy with updated values
  TaskModel copyWith({
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? dueDate,
    int? priority,
  }) {
    return TaskModel(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
    );
  }

  String get priorityLabel {
    switch (priority) {
      case 1:
        return 'High';
      case 2:
        return 'Medium';
      case 3:
        return 'Low';
      default:
        return 'Medium';
    }
  }

  // Check if task is overdue
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  // Get days until due date
  int? get daysUntilDue {
    if (dueDate == null) return null;
    final difference = dueDate!.difference(DateTime.now()).inDays;
    return difference;
  }

  // Format due date for display
  String get dueDateFormatted {
    if (dueDate == null) return 'No due date';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dueDay = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);

    // Format time
    final hour = dueDate!.hour;
    final minute = dueDate!.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final timeStr = '$displayHour:$minute $period';

    // Check if time is set (not midnight)
    final hasTime = dueDate!.hour != 0 || dueDate!.minute != 0;

    if (dueDay == today) {
      return hasTime ? 'Today at $timeStr' : 'Today';
    } else if (dueDay == tomorrow) {
      return hasTime ? 'Tomorrow at $timeStr' : 'Tomorrow';
    } else if (dueDay.isBefore(today)) {
      final daysAgo = today.difference(dueDay).inDays;
      final dayText = '$daysAgo day${daysAgo == 1 ? '' : 's'} ago';
      return hasTime ? '$dayText at $timeStr' : dayText;
    } else {
      final daysUntil = dueDay.difference(today).inDays;
      final dayText = 'In $daysUntil day${daysUntil == 1 ? '' : 's'}';
      return hasTime ? '$dayText at $timeStr' : dayText;
    }
  }

  // Get formatted time only (e.g., "2:30 PM")
  String get timeFormatted {
    if (dueDate == null) return '';
    final hour = dueDate!.hour;
    final minute = dueDate!.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  // Check if time is set (not just date)
  bool get hasTimeSet {
    if (dueDate == null) return false;
    return dueDate!.hour != 0 || dueDate!.minute != 0;
  }
}
