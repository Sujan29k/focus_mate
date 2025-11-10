import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import '../models/task_model.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final TextEditingController _controller = TextEditingController();
  final AuthService _authService = AuthService();
  final FirebaseService _firebaseService = FirebaseService();
  int _selectedPriority = 2; // Default: Medium
  DateTime? _selectedDueDate;

  void _addTask() async {
    if (_controller.text.trim().isEmpty) return;

    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to add tasks')),
      );
      return;
    }

    try {
      final task = TaskModel(
        id: '', // Will be set by Firestore
        userId: user.uid,
        title: _controller.text.trim(),
        createdAt: DateTime.now(),
        priority: _selectedPriority,
        dueDate: _selectedDueDate,
      );

      // Add to Firebase and get the task ID
      final taskId = await _firebaseService.addTask(task);

      // Schedule notification if due date/time is set
      if (_selectedDueDate != null && task.hasTimeSet) {
        // Create a new task instance with the actual ID from Firestore
        final notifiableTask = TaskModel(
          id: taskId,
          userId: task.userId,
          title: task.title,
          description: task.description,
          isCompleted: task.isCompleted,
          createdAt: task.createdAt,
          completedAt: task.completedAt,
          dueDate: task.dueDate,
          priority: task.priority,
        );
        await NotificationService.scheduleTaskNotification(notifiableTask);
      }

      _controller.clear();
      setState(() {
        _selectedPriority = 2; // Reset to medium
        _selectedDueDate = null; // Reset due date
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedDueDate != null && task.hasTimeSet
                  ? 'Task added with reminder!'
                  : 'Task added successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding task: $e')));
      }
    }
  }

  Future<void> _selectDueDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select Due Date',
    );

    if (pickedDate != null) {
      // After selecting date, ask for time
      if (!mounted) return;

      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: _selectedDueDate != null
            ? TimeOfDay.fromDateTime(_selectedDueDate!)
            : TimeOfDay.now(),
        helpText: 'Select Due Time (Optional)',
      );

      // Combine date and time
      if (pickedTime != null) {
        setState(() {
          _selectedDueDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      } else {
        // User skipped time, use date only (midnight)
        setState(() {
          _selectedDueDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
          );
        });
      }
    }
  }

  void _toggleTaskCompletion(TaskModel task) async {
    try {
      await _firebaseService.toggleTaskCompletion(task.id, !task.isCompleted);

      // Cancel notification if completing the task
      if (!task.isCompleted) {
        await NotificationService.cancelTaskNotification(task.id);
      } else if (task.dueDate != null && task.hasTimeSet) {
        // Re-schedule notification if uncompleting and has due time
        await NotificationService.scheduleTaskNotification(task);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating task: $e')));
      }
    }
  }

  void _deleteTask(String taskId) async {
    try {
      await _firebaseService.deleteTask(taskId);

      // Cancel scheduled notification
      await NotificationService.cancelTaskNotification(taskId);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Task deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting task: $e')));
      }
    }
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final date = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    // Only show time if it's not midnight
    if (dateTime.hour == 0 && dateTime.minute == 0) {
      return date;
    }
    return '$date at $displayHour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Tasks')),
        body: const Center(child: Text('Please login to view your tasks')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () async {
              // Test notification
              await NotificationService.showImmediateNotification(
                'Test Notification 🔔',
                'This is how task reminders will look!',
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Test notification sent!')),
                );
              }
            },
            tooltip: 'Test Notification',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Priority Levels'),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.circle, color: Colors.red, size: 12),
                          SizedBox(width: 8),
                          Text('High Priority'),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.circle, color: Colors.orange, size: 12),
                          SizedBox(width: 8),
                          Text('Medium Priority'),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.circle, color: Colors.green, size: 12),
                          SizedBox(width: 8),
                          Text('Low Priority'),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Add Task Input
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          labelText: 'New task',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _addTask(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle),
                      iconSize: 40,
                      color: Theme.of(context).primaryColor,
                      onPressed: _addTask,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Priority Selector
                Row(
                  children: [
                    const Text('Priority: '),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('High'),
                      selected: _selectedPriority == 1,
                      onSelected: (selected) {
                        setState(() => _selectedPriority = 1);
                      },
                      selectedColor: Colors.red.shade100,
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Medium'),
                      selected: _selectedPriority == 2,
                      onSelected: (selected) {
                        setState(() => _selectedPriority = 2);
                      },
                      selectedColor: Colors.orange.shade100,
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Low'),
                      selected: _selectedPriority == 3,
                      onSelected: (selected) {
                        setState(() => _selectedPriority = 3);
                      },
                      selectedColor: Colors.green.shade100,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Due Date Selector
                Row(
                  children: [
                    const Text('Due: '),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectDueDate,
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          _selectedDueDate == null
                              ? 'Select date & time'
                              : _formatDateTime(_selectedDueDate!),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (_selectedDueDate != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () =>
                            setState(() => _selectedDueDate = null),
                        tooltip: 'Clear due date',
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          // Task List with Tabs
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Active'),
                      Tab(text: 'Completed'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Active Tasks
                        _buildTaskList(
                          _firebaseService.getIncompleteTasks(user.uid),
                          false,
                        ),
                        // Completed Tasks
                        _buildTaskList(
                          _firebaseService.getCompletedTasks(user.uid),
                          true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(Stream<List<TaskModel>> stream, bool isCompleted) {
    return StreamBuilder<List<TaskModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          final errorMessage = snapshot.error.toString();
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Index Required',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    errorMessage.contains('index')
                        ? 'Firebase needs an index for this query'
                        : 'Error loading tasks',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  if (errorMessage.contains('https://'))
                    ElevatedButton.icon(
                      onPressed: () {
                        // Extract URL from error message
                        final urlMatch = RegExp(
                          r'https://[^\s]+',
                        ).firstMatch(errorMessage);
                        if (urlMatch != null) {
                          // Copy to clipboard or show instruction
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Check the console for the index creation link',
                              ),
                              duration: const Duration(seconds: 5),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Create Index'),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    errorMessage,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final tasks = snapshot.data ?? [];

        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isCompleted ? Icons.check_circle_outline : Icons.task_alt,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  isCompleted ? 'No completed tasks yet' : 'No active tasks',
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return Dismissible(
              key: Key(task.id),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (direction) => _deleteTask(task.id),
              child: ListTile(
                leading: Icon(
                  Icons.circle,
                  color: _getPriorityColor(task.priority),
                  size: 12,
                ),
                title: Text(
                  task.title,
                  style: TextStyle(
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    color: task.isCompleted ? Colors.grey : null,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (task.description != null) ...[
                      Text(task.description!),
                      const SizedBox(height: 4),
                    ],
                    if (task.dueDate != null)
                      Row(
                        children: [
                          Icon(
                            task.isOverdue
                                ? Icons.warning_amber_rounded
                                : Icons.calendar_today,
                            size: 14,
                            color: task.isOverdue
                                ? Colors.red
                                : task.isCompleted
                                ? Colors.grey
                                : Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            task.dueDateFormatted,
                            style: TextStyle(
                              fontSize: 12,
                              color: task.isOverdue
                                  ? Colors.red
                                  : task.isCompleted
                                  ? Colors.grey
                                  : Colors.blue,
                              fontWeight: task.isOverdue
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                trailing: Checkbox(
                  value: task.isCompleted,
                  onChanged: (_) => _toggleTaskCompletion(task),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
