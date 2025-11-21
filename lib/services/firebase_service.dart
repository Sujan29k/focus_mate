import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/session_model.dart';
import '../models/task_model.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ============ USER OPERATIONS ============

  // Create user profile
  Future<void> createUserProfile(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  // Get user profile
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromDoc(doc);
    }
    return null;
  }

  // Update user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  // Stream user profile
  Stream<UserModel?> streamUserProfile(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromDoc(doc);
      }
      return null;
    });
  }

  // ============ SESSION OPERATIONS ============

  // Add focus session
  Future<String> addSession(SessionModel session) async {
    final docRef = await _db.collection('sessions').add(session.toMap());

    // Update user stats
    final userDoc = await _db.collection('users').doc(session.userId).get();
    if (userDoc.exists) {
      final currentStats = userDoc.data()!;
      await _db.collection('users').doc(session.userId).update({
        'totalFocusMinutes':
            (currentStats['totalFocusMinutes'] ?? 0) + session.durationMinutes,
        'totalSessions': (currentStats['totalSessions'] ?? 0) + 1,
      });
    }

    return docRef.id;
  }

  // Update session
  Future<void> updateSession(
    String sessionId,
    Map<String, dynamic> data,
  ) async {
    await _db.collection('sessions').doc(sessionId).update(data);
  }

  // Get user sessions
  Stream<List<SessionModel>> getUserSessions(String userId, {int limit = 20}) {
    return _db
        .collection('sessions')
        .where('userId', isEqualTo: userId)
        .orderBy('startedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => SessionModel.fromDoc(doc)).toList(),
        );
  }

  // Get sessions for a date range
  Stream<List<SessionModel>> getSessionsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _db
        .collection('sessions')
        .where('userId', isEqualTo: userId)
        .where('startedAt', isGreaterThanOrEqualTo: startDate.toIso8601String())
        .where('startedAt', isLessThanOrEqualTo: endDate.toIso8601String())
        .orderBy('startedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => SessionModel.fromDoc(doc)).toList(),
        );
  }

  // ============ TASK OPERATIONS ============

  // Add task
  Future<String> addTask(TaskModel task) async {
    final docRef = await _db.collection('tasks').add(task.toMap());
    return docRef.id;
  }

  // Update task
  Future<void> updateTask(String taskId, Map<String, dynamic> data) async {
    await _db.collection('tasks').doc(taskId).update(data);
  }

  // Delete task
  Future<void> deleteTask(String taskId) async {
    await _db.collection('tasks').doc(taskId).delete();
  }

  // Get user tasks
  Stream<List<TaskModel>> getUserTasks(String userId) {
    return _db
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => TaskModel.fromDoc(doc)).toList(),
        );
  }

  // Get incomplete tasks (simplified query - sorting done in app)
  Stream<List<TaskModel>> getIncompleteTasks(String userId) {
    return _db
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .where('isCompleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          final tasks = snapshot.docs
              .map((doc) => TaskModel.fromDoc(doc))
              .toList();
          // Sort in app: by priority first, then by created date
          tasks.sort((a, b) {
            final priorityCompare = a.priority.compareTo(b.priority);
            if (priorityCompare != 0) return priorityCompare;
            return a.createdAt.compareTo(b.createdAt);
          });
          return tasks;
        });
  }

  // Get completed tasks (simplified query - sorting done in app)
  Stream<List<TaskModel>> getCompletedTasks(String userId) {
    return _db
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .where('isCompleted', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final tasks = snapshot.docs
              .map((doc) => TaskModel.fromDoc(doc))
              .toList();
          // Sort by completion date (newest first)
          tasks.sort((a, b) {
            if (a.completedAt == null && b.completedAt == null) return 0;
            if (a.completedAt == null) return 1;
            if (b.completedAt == null) return -1;
            return b.completedAt!.compareTo(a.completedAt!);
          });
          return tasks;
        });
  }

  // Toggle task completion
  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) async {
    await _db.collection('tasks').doc(taskId).update({
      'isCompleted': isCompleted,
      'completedAt': isCompleted ? DateTime.now().toIso8601String() : null,
    });
  }

  // Get tasks by category
  Stream<List<TaskModel>> getTasksByCategory(String userId, String category) {
    return _db
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => TaskModel.fromDoc(doc)).toList(),
        );
  }

  // Get incomplete tasks by category
  Stream<List<TaskModel>> getIncompleteTasksByCategory(
    String userId,
    String category,
  ) {
    return _db
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .where('isCompleted', isEqualTo: false)
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) {
          final tasks = snapshot.docs
              .map((doc) => TaskModel.fromDoc(doc))
              .toList();
          // Sort in app: by priority first, then by created date
          tasks.sort((a, b) {
            final priorityCompare = a.priority.compareTo(b.priority);
            if (priorityCompare != 0) return priorityCompare;
            return a.createdAt.compareTo(b.createdAt);
          });
          return tasks;
        });
  }
}
