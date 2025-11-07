# Firestore Security Rules for FocusMate App

## Setup Instructions:
1. Go to Firebase Console: https://console.firebase.google.com
2. Select your project: focusmate-9e315
3. Navigate to: Firestore Database > Rules
4. Copy and paste the rules below
5. Click "Publish"

## Security Rules:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Helper function to check if user owns the document
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // Users collection
    match /users/{userId} {
      // Users can read and write only their own profile
      allow read: if isOwner(userId);
      allow create: if isOwner(userId);
      allow update: if isOwner(userId);
      allow delete: if false; // Prevent deletion
    }
    
    // Sessions collection
    match /sessions/{sessionId} {
      // Users can only read and create their own sessions
      allow read: if isAuthenticated() && resource.data.userId == request.auth.uid;
      allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
      allow update: if isAuthenticated() && resource.data.userId == request.auth.uid;
      allow delete: if false; // Prevent deletion for analytics purposes
    }
    
    // Tasks collection
    match /tasks/{taskId} {
      // Users can manage only their own tasks
      allow read: if isAuthenticated() && resource.data.userId == request.auth.uid;
      allow create: if isAuthenticated() && request.resource.data.userId == request.auth.uid;
      allow update: if isAuthenticated() && resource.data.userId == request.auth.uid;
      allow delete: if isAuthenticated() && resource.data.userId == request.auth.uid;
    }
  }
}
```

## Firestore Indexes:

Create these composite indexes in Firebase Console > Firestore Database > Indexes:

### Sessions Collection:
1. **Index 1:**
   - Collection: `sessions`
   - Fields: `userId` (Ascending), `startedAt` (Descending)
   - Query scope: Collection

2. **Index 2:**
   - Collection: `sessions`
   - Fields: `userId` (Ascending), `startedAt` (Ascending)
   - Query scope: Collection

### Tasks Collection:
1. **Index 1:**
   - Collection: `tasks`
   - Fields: `userId` (Ascending), `isCompleted` (Ascending), `priority` (Ascending), `createdAt` (Ascending)
   - Query scope: Collection

2. **Index 2:**
   - Collection: `tasks`
   - Fields: `userId` (Ascending), `isCompleted` (Ascending), `completedAt` (Descending)
   - Query scope: Collection

## Firebase Authentication Setup:

1. Go to Firebase Console > Authentication
2. Click "Get Started"
3. Enable "Email/Password" sign-in method
4. (Optional) Enable "Google" sign-in for future use

## Test Your Setup:

After deploying rules, test in Firebase Console > Firestore Database > Rules Playground
