import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../models/user_model.dart';
import '../models/session_model.dart';
import '../models/task_model.dart';

/// Example: How to use Firebase Backend Services in FocusMate
///
/// This file demonstrates how to integrate the Firebase backend
/// into your Flutter app screens and widgets.

class FirebaseUsageExamples {
  final AuthService _authService = AuthService();
  final FirebaseService _firebaseService = FirebaseService();

  // ============ AUTHENTICATION EXAMPLES ============

  /// Example 1: User Registration
  Future<void> registerUser(String email, String password) async {
    try {
      // Register with Firebase Auth
      final user = await _authService.registerWithEmail(email, password);

      if (user != null) {
        // Create user profile in Firestore
        final userProfile = UserModel(
          uid: user.uid,
          email: user.email!,
          createdAt: DateTime.now(),
        );
        await _firebaseService.createUserProfile(userProfile);

        debugPrint('User registered successfully!');
      }
    } catch (e) {
      debugPrint('Registration error: $e');
      // Show error to user
    }
  }

  /// Example 2: User Sign In
  Future<void> signIn(String email, String password) async {
    try {
      final user = await _authService.signInWithEmail(email, password);
      if (user != null) {
        debugPrint('User signed in: ${user.email}');
      }
    } catch (e) {
      debugPrint('Sign in error: $e');
    }
  }

  /// Example 3: Check Auth State (in main.dart)
  Widget buildAuthWrapper() {
    return StreamBuilder(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // User is signed in - show home screen
          return const Text('Home Screen');
        } else {
          // User is not signed in - show login screen
          return const Text('Login Screen');
        }
      },
    );
  }

  // ============ SESSION EXAMPLES ============

  /// Example 4: Save a Focus Session
  Future<void> saveFocusSession(int durationMinutes) async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) return;

      final session = SessionModel(
        id: '',
        userId: userId,
        durationMinutes: durationMinutes,
        startedAt: DateTime.now(),
        isCompleted: true,
        completedAt: DateTime.now(),
      );

      await _firebaseService.addSession(session);
      debugPrint('Session saved!');
    } catch (e) {
      debugPrint('Error saving session: $e');
    }
  }

  /// Example 5: Display User Sessions (in analytics screen)
  Widget buildSessionsList(BuildContext context) {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return const Text('Not logged in');

    return StreamBuilder(
      stream: _firebaseService.getUserSessions(userId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final sessions = snapshot.data!;
          return ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              return ListTile(
                title: Text('${session.durationMinutes} minutes'),
                subtitle: Text(session.startedAt.toString()),
              );
            },
          );
        }
        return const CircularProgressIndicator();
      },
    );
  }

  // ============ TASK EXAMPLES ============

  /// Example 6: Add a New Task
  Future<void> addNewTask(
    String title, {
    String? description,
    int priority = 2,
  }) async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) return;

      final task = TaskModel(
        id: '',
        userId: userId,
        title: title,
        description: description,
        createdAt: DateTime.now(),
        priority: priority,
      );

      await _firebaseService.addTask(task);
      debugPrint('Task added!');
    } catch (e) {
      debugPrint('Error adding task: $e');
    }
  }

  /// Example 7: Display Tasks (in todo screen)
  Widget buildTasksList(BuildContext context) {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return const Text('Not logged in');

    return StreamBuilder(
      stream: _firebaseService.getIncompleteTasks(userId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final tasks = snapshot.data!;
          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return CheckboxListTile(
                title: Text(task.title),
                subtitle: Text(task.description ?? ''),
                value: task.isCompleted,
                onChanged: (value) {
                  _firebaseService.toggleTaskCompletion(
                    task.id,
                    value ?? false,
                  );
                },
              );
            },
          );
        }
        return const CircularProgressIndicator();
      },
    );
  }

  /// Example 8: Display User Stats
  Widget buildUserStatsWidget(BuildContext context) {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return const Text('Not logged in');

    return StreamBuilder(
      stream: _firebaseService.streamUserProfile(userId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final user = snapshot.data!;
          return Column(
            children: [
              Text('Total Focus Time: ${user.totalFocusMinutes} minutes'),
              Text('Total Sessions: ${user.totalSessions}'),
            ],
          );
        }
        return const CircularProgressIndicator();
      },
    );
  }
}
