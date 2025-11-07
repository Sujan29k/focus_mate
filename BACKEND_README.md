# FocusMate Firebase Backend Documentation

## 🎯 Overview

Your FocusMate app now has a complete Firebase backend infrastructure with:
- ✅ User Authentication
- ✅ Cloud Firestore Database
- ✅ Real-time Data Synchronization
- ✅ Secure Data Access Rules

## 📁 Backend Structure

```
lib/
├── models/
│   ├── user_model.dart       # User profile data structure
│   ├── session_model.dart    # Focus session data structure
│   └── task_model.dart       # Task data structure
├── services/
│   ├── auth_service.dart           # Authentication operations
│   ├── firebase_service.dart       # Database CRUD operations
│   └── firebase_usage_examples.dart # Implementation examples
```

## 🚀 Quick Start Guide

### Step 1: Enable Firebase Authentication

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select project: **focusmate-9e315**
3. Click **Authentication** → **Get Started**
4. Enable **Email/Password** sign-in method
5. Click **Save**

### Step 2: Set Up Firestore Security Rules

1. Go to **Firestore Database** → **Rules** tab
2. Copy the rules from `FIREBASE_SETUP.md`
3. Click **Publish**

### Step 3: Create Firestore Indexes

The app will prompt you to create indexes when needed. Alternatively:
1. Go to **Firestore Database** → **Indexes** tab
2. Create indexes as documented in `FIREBASE_SETUP.md`

## 💾 Database Collections

### 1. **users** Collection
```
users/{userId}
├── uid: string
├── email: string
├── displayName: string (optional)
├── createdAt: timestamp
├── totalFocusMinutes: number
└── totalSessions: number
```

### 2. **sessions** Collection
```
sessions/{sessionId}
├── userId: string
├── durationMinutes: number
├── startedAt: timestamp
├── completedAt: timestamp (optional)
├── isCompleted: boolean
└── notes: string (optional)
```

### 3. **tasks** Collection
```
tasks/{taskId}
├── userId: string
├── title: string
├── description: string (optional)
├── isCompleted: boolean
├── createdAt: timestamp
├── completedAt: timestamp (optional)
└── priority: number (1=High, 2=Medium, 3=Low)
```

## 📝 How to Use the Backend

### Authentication

```dart
import 'services/auth_service.dart';

final authService = AuthService();

// Register new user
await authService.registerWithEmail('email@example.com', 'password123');

// Sign in
await authService.signInWithEmail('email@example.com', 'password123');

// Sign out
await authService.signOut();

// Get current user
final user = authService.currentUser;

// Listen to auth state
authService.authStateChanges.listen((user) {
  if (user != null) {
    print('User signed in: ${user.email}');
  } else {
    print('User signed out');
  }
});
```

### Database Operations

```dart
import 'services/firebase_service.dart';
import 'models/session_model.dart';

final firebaseService = FirebaseService();

// Save a focus session
final session = SessionModel(
  id: '',
  userId: currentUserId,
  durationMinutes: 25,
  startedAt: DateTime.now(),
  isCompleted: true,
);
await firebaseService.addSession(session);

// Get user sessions (Stream)
firebaseService.getUserSessions(currentUserId).listen((sessions) {
  print('Total sessions: ${sessions.length}');
});

// Add a task
final task = TaskModel(
  id: '',
  userId: currentUserId,
  title: 'Complete project',
  priority: 1,
  createdAt: DateTime.now(),
);
await firebaseService.addTask(task);

// Get incomplete tasks (Stream)
firebaseService.getIncompleteTasks(currentUserId).listen((tasks) {
  print('Pending tasks: ${tasks.length}');
});
```

## 🔐 Security Features

- ✅ Users can only access their own data
- ✅ Session deletion is disabled (for analytics)
- ✅ All operations require authentication
- ✅ Data validation on client and server side

## 📊 Real-time Updates

All data uses **Firestore Streams** for real-time synchronization:
- When a task is completed, all devices see the update instantly
- Focus sessions appear in analytics immediately
- User stats update in real-time

## 🎨 Next Steps for Integration

### 1. Add Login/Register Screens

Create `lib/screens/auth/login_screen.dart`:
```dart
// Use AuthService to handle sign in
// Show errors to users with SnackBars
// Navigate to home on success
```

### 2. Update Main App

Wrap your app with auth state:
```dart
StreamBuilder(
  stream: AuthService().authStateChanges,
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return HomeScreen(); // User logged in
    }
    return LoginScreen(); // Show login
  },
)
```

### 3. Integrate in Timer Screen

Save completed sessions:
```dart
await FirebaseService().addSession(SessionModel(...));
```

### 4. Update Analytics Screen

Show user sessions:
```dart
StreamBuilder(
  stream: FirebaseService().getUserSessions(userId),
  builder: (context, snapshot) {
    // Display sessions in charts/lists
  },
)
```

### 5. Update Todo Screen

Use real-time task streams:
```dart
StreamBuilder(
  stream: FirebaseService().getIncompleteTasks(userId),
  builder: (context, snapshot) {
    // Display tasks with checkboxes
  },
)
```

## 🛠️ Testing

### Test Authentication:
```bash
# Run app
flutter run

# Try to register a new user
# Verify user appears in Firebase Console > Authentication
```

### Test Database:
```bash
# Create a task or session
# Verify it appears in Firebase Console > Firestore Database
```

## 📚 Reference Files

- `FIREBASE_SETUP.md` - Detailed Firebase Console setup
- `lib/services/firebase_usage_examples.dart` - Code examples
- Firebase Documentation: https://firebase.google.com/docs/flutter

## 🔍 Troubleshooting

**Problem**: "Missing or insufficient permissions"
- **Solution**: Deploy security rules from `FIREBASE_SETUP.md`

**Problem**: "Index required" error
- **Solution**: Click the error link to create the index automatically

**Problem**: User not authenticated
- **Solution**: Check if user is signed in with `AuthService().currentUser`

## 🎉 You're Ready!

Your Firebase backend is fully set up! Start by:
1. ✅ Deploy security rules
2. ✅ Enable authentication
3. ✅ Create login/register screens
4. ✅ Integrate into existing screens

Need help? Check `firebase_usage_examples.dart` for implementation patterns!
