# Task Due Date Feature 📅

## Overview
Added due date functionality to tasks, allowing users to set deadlines and see overdue warnings.

## Changes Made

### 1. TaskModel Updates (`lib/models/task_model.dart`)

#### New Field
- `DateTime? dueDate` - Optional due date for tasks

#### New Methods
- `bool get isOverdue` - Returns true if task is past due date and not completed
- `int? get daysUntilDue` - Returns number of days until due (negative if overdue)
- `String get dueDateFormatted` - Returns human-readable due date:
  - "Today" - Due today
  - "Tomorrow" - Due tomorrow
  - "In X days" - Future dates
  - "X days ago" - Overdue dates

#### Updated Methods
- `toMap()` - Now includes dueDate
- `fromDoc()` - Parses dueDate from Firestore
- `copyWith()` - Supports updating dueDate

### 2. TodoScreen Updates (`lib/screens/todo_screen.dart`)

#### New State Variable
- `DateTime? _selectedDueDate` - Tracks selected due date for new tasks

#### New Method
- `_selectDueDate()` - Opens date picker dialog
  - Shows dates from today up to 1 year ahead
  - Updates _selectedDueDate when user selects a date

#### UI Changes

**Add Task Section:**
- Added "Due Date" row below priority selector
- Shows "Select date" button or formatted date (DD/MM/YYYY)
- Clear button (X) appears when date is selected
- Date picker opens on button click
- Due date resets after task is added

**Task List Items:**
- Due date shown in subtitle with calendar icon
- **Overdue tasks** display:
  - Red warning icon
  - Red text
  - Bold font
  - Text: "X days ago"
- **Upcoming tasks** display:
  - Blue calendar icon
  - Blue text
  - Text: "Today", "Tomorrow", or "In X days"
- **Completed tasks** with due dates:
  - Gray calendar icon
  - Gray text (maintaining completed look)

## Visual Indicators

### Priority Colors (Circle Icon)
- 🔴 Red = High Priority
- 🟠 Orange = Medium Priority
- 🟢 Green = Low Priority

### Due Date Colors
- 🔴 **Red** = Overdue (with warning icon ⚠️)
- 🔵 **Blue** = Upcoming (with calendar icon 📅)
- ⚪ **Gray** = Completed (with calendar icon 📅)

## User Experience

### Adding a Task with Due Date:
1. Enter task title
2. Select priority (High/Medium/Low)
3. Click "Select date" button
4. Choose date from calendar picker
5. Click "+" button to add task
6. Date automatically clears for next task

### Viewing Tasks:
- Tasks in **Active** tab show due date status
- Overdue tasks are visually prominent (red, bold)
- Today's tasks stand out with "Today" label
- Completed tasks maintain due date info but grayed out

### Clearing Due Date:
- Click X button next to selected date before adding task
- No way to remove due date from existing task (needs edit feature)

## Database Schema

### Firestore Task Document:
```json
{
  "userId": "string",
  "title": "string",
  "description": "string?",
  "isCompleted": "boolean",
  "createdAt": "ISO8601 string",
  "completedAt": "ISO8601 string?",
  "dueDate": "ISO8601 string?",  // ← NEW FIELD
  "priority": "integer (1-3)"
}
```

## Future Enhancements

### Possible Additions:
1. **Edit Due Date** - Long press task to edit due date
2. **Due Date Sorting** - Sort tasks by due date
3. **Notifications** - Remind user before due date
4. **Time Selection** - Add time picker (not just date)
5. **Recurring Tasks** - Tasks that repeat on schedule
6. **Calendar View** - See all tasks in calendar format
7. **Due Date Filters** - Filter by "Due Today", "Due This Week", etc.
8. **Overdue Tab** - Separate tab for overdue tasks
9. **Due Date Stats** - Track on-time completion rate

### Code Improvements:
1. Use `intl` package for better date formatting
2. Add localization for date display
3. Store timezone information with dates
4. Add date validation (prevent past dates)
5. Add "Due in 1 hour" for time-sensitive tasks

## Testing Checklist

- [x] Add task without due date (works as before)
- [x] Add task with future due date
- [x] View task due today
- [x] View task due tomorrow
- [x] View overdue task (change system date or wait)
- [x] Clear selected due date before adding
- [x] Complete task with due date (turns gray)
- [x] Delete task with due date
- [x] Multiple tasks with different due dates

## Known Limitations

1. **No Edit Feature** - Can't change due date after task is created
2. **No Time** - Only date, no specific time
3. **No Timezone** - Stored as ISO8601 string, interprets in local time
4. **No Notifications** - User must check app for due dates
5. **No Sorting by Due Date** - Tasks sorted by priority only
6. **Past Dates Allowed** - Can technically select past dates (if date picker is hacked)

## Migration Notes

**Existing Tasks:**
- Old tasks without `dueDate` field will work fine
- `dueDate` is optional (nullable)
- No data migration needed
- New field automatically added when tasks are created

**Firestore Queries:**
- Current queries don't filter by due date
- Queries will work with or without due date field
- No index changes required

## Code Examples

### Check if Task is Overdue:
```dart
if (task.isOverdue) {
  // Show warning, send notification, etc.
}
```

### Get Days Until Due:
```dart
final daysLeft = task.daysUntilDue;
if (daysLeft != null && daysLeft < 3) {
  // Task due soon!
}
```

### Display Due Date:
```dart
Text(task.dueDateFormatted) // "Today", "Tomorrow", "In 5 days", etc.
```

### Create Task with Due Date:
```dart
final task = TaskModel(
  id: '',
  userId: user.uid,
  title: 'Complete project',
  priority: 1,
  dueDate: DateTime(2025, 11, 15), // November 15, 2025
  createdAt: DateTime.now(),
);
```

## Screenshots Description

**Add Task Section:**
```
[New task field                    ] [+]
Priority: [High] [Medium✓] [Low]
Due Date: [📅 15/11/2025] [X]
```

**Task List Item (Overdue):**
```
🔴 Buy groceries
   ⚠️ 2 days ago                    [✓]
```

**Task List Item (Due Today):**
```
🟠 Submit report
   📅 Today                          [✓]
```

**Task List Item (Upcoming):**
```
🟢 Team meeting
   📅 In 5 days                      [✓]
```

## Support

If you encounter any issues:
1. Check that Firebase is connected
2. Verify TaskModel has dueDate field
3. Check console for errors
4. Ensure date picker appears on button click
