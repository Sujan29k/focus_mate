# Task Due Date & Time Feature ⏰📅

## Overview
Enhanced task management with both date AND time selection for precise deadline tracking.

## What's New

### Time Picker Integration
- **Date Picker** → **Time Picker** (sequential selection)
- Users can now set specific times for tasks (e.g., "Meeting at 2:30 PM")
- Time selection is optional - can skip to set date-only deadline
- Smart display: Shows time only when set, hides when it's midnight (00:00)

## User Experience Flow

### Adding a Task with Date & Time:

1. **Enter Task Title** → Type your task
2. **Select Priority** → Choose High/Medium/Low
3. **Click "Select date & time"** button
4. **Pick Date** → Calendar appears → Select date
5. **Pick Time** → Clock appears → Select time (or skip for date-only)
6. **Click "+" to Add** → Task saved with deadline

### Example Flow:
```
User: "Team meeting"
Priority: High
Due: 11/15/2025 at 2:30 PM
         ↓
Task saved: "Team meeting"
Display: "In 6 days at 2:30 PM"
```

## Display Formats

### In Task Input Area:
- **No selection**: `"Select date & time"`
- **Date only**: `"15/11/2025"`
- **Date + Time**: `"15/11/2025 at 2:30 PM"`

### In Task List (Smart Formatting):
- **Today with time**: `"Today at 2:30 PM"` 📅
- **Today without time**: `"Today"` 📅
- **Tomorrow with time**: `"Tomorrow at 9:00 AM"` 📅
- **Future with time**: `"In 5 days at 3:45 PM"` 📅
- **Future without time**: `"In 5 days"` 📅
- **Overdue with time**: `"2 days ago at 1:00 PM"` ⚠️
- **Overdue without time**: `"2 days ago"` ⚠️

## Visual Indicators

### Color Coding:
| Status | Icon | Color | Weight | Example |
|--------|------|-------|--------|---------|
| **Overdue** | ⚠️ Warning | 🔴 Red | Bold | "2 days ago at 3:00 PM" |
| **Upcoming** | 📅 Calendar | 🔵 Blue | Normal | "Tomorrow at 2:30 PM" |
| **Completed** | 📅 Calendar | ⚪ Gray | Normal | "Today at 10:00 AM" |

### Priority Dots:
- 🔴 **Red** = High Priority
- 🟠 **Orange** = Medium Priority  
- 🟢 **Green** = Low Priority

## Technical Details

### TaskModel Updates (`task_model.dart`)

#### New Getters:
```dart
String get timeFormatted
// Returns: "2:30 PM", "9:00 AM", "11:45 PM"

bool get hasTimeSet
// Returns: true if time is set (not midnight)

String get dueDateFormatted
// Returns: "Today at 2:30 PM", "Tomorrow", "In 5 days at 9:00 AM"
```

#### Time Formatting Logic:
- **12-hour format** with AM/PM
- **Padded minutes** (2:05 PM not 2:5 PM)
- **Midnight detection** (00:00 means no time set)
- **Smart display** (shows time only when relevant)

### TodoScreen Updates (`todo_screen.dart`)

#### New Method:
```dart
Future<void> _selectDueDate() async
```
**Flow:**
1. Shows `DatePicker` → User selects date
2. Shows `TimePicker` → User selects time (optional)
3. Combines both → Updates `_selectedDueDate`
4. If time skipped → Uses midnight (00:00)

#### Helper Method:
```dart
String _formatDateTime(DateTime dateTime)
```
**Purpose:** Format date/time for button display
**Output:** "15/11/2025" or "15/11/2025 at 2:30 PM"

## Database Storage

### Firestore Document:
```json
{
  "title": "Team meeting",
  "dueDate": "2025-11-15T14:30:00.000Z",  // Full DateTime with time
  "priority": 1,
  "isCompleted": false
}
```

**Format:** ISO8601 string with full date and time
**Timezone:** Stored in UTC, displayed in local time
**Midnight:** "2025-11-15T00:00:00.000Z" means date-only

## Use Cases

### 1. Time-Specific Tasks
```
Task: "Doctor appointment"
Due: Today at 3:30 PM
Display: "Today at 3:30 PM" (Blue, with calendar icon)
Use: Specific appointment times
```

### 2. Date-Only Deadlines
```
Task: "Submit report"
Due: November 20
Display: "In 11 days" (Blue, with calendar icon)
Use: End-of-day deadlines
```

### 3. Urgent Time-Sensitive
```
Task: "Call client"
Due: Today at 11:00 AM (if it's 2 PM now)
Display: "3 hours ago at 11:00 AM" (Red, bold, warning icon)
Use: Missed deadlines with specific time
```

### 4. Recurring Daily Tasks
```
Task: "Daily standup"
Due: Tomorrow at 9:00 AM
Display: "Tomorrow at 9:00 AM" (Blue, calendar icon)
Use: Regular scheduled tasks
```

## Time Selection UX

### Time Picker Features:
- **12-hour format** (not 24-hour)
- **Hour and minute** selection
- **AM/PM toggle**
- **Current time** as default
- **Skip button** to set date-only

### Smart Defaults:
- First time: Uses current time
- Subsequent: Remembers last selected time
- After adding: Resets to current time

## Comparison: Before vs After

### Before (Date Only):
```
[Select date]
    ↓
15/11/2025
    ↓
Task shows: "In 6 days"
```

### After (Date + Time):
```
[Select date & time]
    ↓
15/11/2025 + 2:30 PM
    ↓
Task shows: "In 6 days at 2:30 PM"
```

## Backwards Compatibility

✅ **Old tasks work perfectly**
- Existing tasks without time show date only
- No migration needed
- Time defaults to midnight (00:00)
- Display shows "Today" not "Today at 12:00 AM"

## Benefits

### For Users:
1. ⏰ **Precise scheduling** - Know exact deadline time
2. 🔔 **Better planning** - "Meeting at 2 PM" vs "Meeting today"
3. ⚠️ **Clear alerts** - See how long overdue (with time)
4. 📊 **Time tracking** - Understand task timing patterns
5. 🎯 **Flexibility** - Can use date-only OR date+time

### For Workflow:
- **Appointments**: Specify exact time
- **Deadlines**: Use date-only for end-of-day
- **Meetings**: Set precise start times
- **Calls**: Schedule specific call times
- **Events**: Track event start times

## Future Enhancements

### Possible Additions:
1. **Smart Notifications** 📲
   - "Meeting in 15 minutes"
   - "Task due in 1 hour"
   - Configurable reminder times

2. **Time Zones** 🌍
   - Store UTC with timezone
   - Display in user's local time
   - Handle daylight saving

3. **Duration Tracking** ⏱️
   - Add "estimated duration" field
   - Calculate end time
   - Show time blocks

4. **Calendar Integration** 📆
   - Export to Google Calendar
   - Import from calendar apps
   - Show in calendar view

5. **Quick Time Selection** ⚡
   - "In 1 hour" button
   - "Tomorrow 9 AM" preset
   - "End of day" shortcut

6. **Time-based Sorting** 🔢
   - Sort by due time (not just date)
   - "Next up" section
   - Chronological order

7. **Recurring Tasks** 🔄
   - "Every day at 9 AM"
   - "Weekly on Monday 2 PM"
   - Auto-reschedule on completion

8. **Time Analytics** 📊
   - Average completion time
   - On-time completion rate
   - Peak productivity hours

## Testing Scenarios

### Must Test:
- [x] Add task with date and time
- [x] Add task with date only (skip time picker)
- [x] View task due today with time
- [x] View overdue task with time
- [x] Complete task with time (turns gray)
- [x] Clear selected date/time before adding
- [x] Add task at 11:59 PM (edge case)
- [x] Add task at 12:00 AM (midnight)
- [x] Change system time to test overdue
- [x] Multiple tasks at different times

### Edge Cases:
- Task due in 1 minute
- Task due at midnight (00:00)
- Task due at noon (12:00 PM)
- Task past midnight (next day)
- Timezone changes (travel)

## Code Examples

### Check if Task is Time-Sensitive:
```dart
if (task.hasTimeSet) {
  // Show exact time
  print(task.timeFormatted); // "2:30 PM"
} else {
  // Date-only task
  print("End of day deadline");
}
```

### Create Task with Specific Time:
```dart
final task = TaskModel(
  id: '',
  userId: user.uid,
  title: 'Team standup',
  dueDate: DateTime(2025, 11, 15, 9, 30), // 9:30 AM
  priority: 2,
  createdAt: DateTime.now(),
);
```

### Format for Notification:
```dart
String getNotificationText(TaskModel task) {
  if (task.isOverdue) {
    return 'OVERDUE: ${task.title} - ${task.dueDateFormatted}';
  } else if (task.daysUntilDue == 0 && task.hasTimeSet) {
    return 'DUE SOON: ${task.title} at ${task.timeFormatted}';
  }
  return '${task.title} - ${task.dueDateFormatted}';
}
```

## Known Limitations

1. **No Timezone Storage** - Assumes local timezone
2. **No Duration** - Can't set "2 hours long"
3. **No Reminders** - Must manually check
4. **No Recurring** - Can't auto-repeat tasks
5. **No Quick Presets** - Must use full picker
6. **12-hour Only** - No 24-hour format option

## Performance Notes

- **No Impact** - DateTime still stored as single field
- **No Extra Queries** - Same Firestore reads
- **Instant Display** - Formatting done in Dart (fast)
- **No Index Changes** - Works with existing setup

## Accessibility

- **Clear Labels** - "Select date & time"
- **Standard Pickers** - Native iOS/Android dialogs
- **Visual + Text** - Icons + text descriptions
- **Color + Shape** - Red icon + red text for overdue
- **Skip Option** - Can dismiss time picker

## Summary

🎯 **What Changed:**
- Date picker → Now followed by time picker
- Button text: "Select date & time"
- Display format includes time when set
- Smart hiding of midnight (00:00)

✅ **What Stayed Same:**
- Can still use date-only (skip time)
- Existing tasks work perfectly
- Same Firestore structure
- Same query performance

🚀 **What's Better:**
- Precise deadline tracking
- Better for appointments/meetings
- Clearer overdue indicators
- More professional task management

Perfect for tasks that need exact timing! ⏰✨
