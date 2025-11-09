# Firestore Indexes Guide

## Current Status: ✅ No Indexes Required

The app is currently configured to work **without custom indexes** by doing sorting in the app instead of in Firestore queries.

## What Was the Problem?

The original queries used multiple `where()` and `orderBy()` clauses together, which requires composite indexes in Firestore:

```dart
// ❌ This requires an index:
.where('userId', isEqualTo: userId)
.where('isCompleted', isEqualTo: false)
.orderBy('priority')
.orderBy('createdAt')
```

## Current Solution

We simplified the queries and moved sorting to the app:

```dart
// ✅ This works without an index:
.where('userId', isEqualTo: userId)
.where('isCompleted', isEqualTo: false)
// Then sort the results in Dart code
```

## Performance Considerations

- **Good for**: Small to medium datasets (< 1000 tasks per user)
- **Pros**: No index setup needed, works immediately
- **Cons**: Slightly more data transfer, sorting happens on device

## If You Need Better Performance (Future)

If your users have thousands of tasks and you need better performance, create these indexes:

### Index 1: Incomplete Tasks
- **Collection**: `tasks`
- **Fields**:
  1. `userId` - Ascending
  2. `isCompleted` - Ascending
  3. `priority` - Ascending
  4. `createdAt` - Ascending

### Index 2: Completed Tasks
- **Collection**: `tasks`
- **Fields**:
  1. `userId` - Ascending
  2. `isCompleted` - Ascending
  3. `completedAt` - Descending

### How to Create Indexes

1. **Automatic Method** (Easiest):
   - Run the app and trigger the query
   - Check the console/debug output for the error message
   - Click the link in the error message
   - It will take you directly to Firebase Console with pre-filled values
   - Click "Create Index"

2. **Manual Method**:
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Select your project: `focusmate-9e315`
   - Navigate to: **Firestore Database** → **Indexes** tab
   - Click **Create Index**
   - Fill in the fields as shown above
   - Click **Create**

3. **Using firebase.json** (Advanced):
   ```json
   {
     "firestore": {
       "rules": "firestore.rules",
       "indexes": "firestore.indexes.json"
     }
   }
   ```

   Create `firestore.indexes.json`:
   ```json
   {
     "indexes": [
       {
         "collectionGroup": "tasks",
         "queryScope": "COLLECTION",
         "fields": [
           { "fieldPath": "userId", "order": "ASCENDING" },
           { "fieldPath": "isCompleted", "order": "ASCENDING" },
           { "fieldPath": "priority", "order": "ASCENDING" },
           { "fieldPath": "createdAt", "order": "ASCENDING" }
         ]
       },
       {
         "collectionGroup": "tasks",
         "queryScope": "COLLECTION",
         "fields": [
           { "fieldPath": "userId", "order": "ASCENDING" },
           { "fieldPath": "isCompleted", "order": "ASCENDING" },
           { "fieldPath": "completedAt", "order": "DESCENDING" }
         ]
       }
     ]
   }
   ```

   Then deploy:
   ```bash
   firebase deploy --only firestore:indexes
   ```

## Index Creation Time

- Indexes typically take **1-5 minutes** to build for small datasets
- Can take **longer** if you already have lots of data
- The Firebase Console will show build progress

## Monitoring Index Usage

Check which indexes are being used:
1. Go to Firebase Console → Firestore → **Indexes** tab
2. You'll see all indexes and their status
3. Delete unused indexes to save quota

## Best Practices

1. ✅ Start without indexes (current approach)
2. ✅ Add indexes only when needed for performance
3. ✅ Test queries in small scale first
4. ❌ Don't create indexes for every possible query
5. ❌ Don't over-optimize prematurely

## Current Query Performance

With the simplified approach:
- **Incomplete tasks query**: Fast (1-2 filters only)
- **Completed tasks query**: Fast (1-2 filters only)
- **Sorting overhead**: Negligible for < 1000 items
- **Network transfer**: Same as with indexes

## Need Help?

If you see index errors in the future:
1. Check the error message for the index creation link
2. Follow the link and create the index
3. Wait 1-5 minutes for it to build
4. Retry your query

The error will look like:
```
cloud_firestore/failed-precondition: The query requires an index. 
You can create it here: https://console.firebase.google.com/...
```
