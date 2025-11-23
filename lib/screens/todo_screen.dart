import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import '../models/task_model.dart';
import '../utils/task_categories.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final TextEditingController _controller = TextEditingController();
  final AuthService _authService = AuthService();
  final FirebaseService _firebaseService = FirebaseService();
  int _selectedPriority = 2;
  DateTime? _selectedDueDate;
  String _selectedCategory = 'Personal';
  String? _filterCategory;

  void _showAddTaskBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add New Task',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Enter task title',
                      prefixIcon: const Icon(Icons.edit),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSubmitted: (_) {
                      _addTask();
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Priority',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _priorityPill('High', 1, Colors.red),
                      const SizedBox(width: 8),
                      _priorityPill('Medium', 2, Colors.orange),
                      const SizedBox(width: 8),
                      _priorityPill('Low', 3, Colors.green),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Category',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: TaskCategory.all.map((category) {
                      return DropdownMenuItem<String>(
                        value: category.name,
                        child: Row(
                          children: [
                            Icon(
                              category.icon,
                              size: 20,
                              color: category.color,
                            ),
                            const SizedBox(width: 8),
                            Text(category.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCategory = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Due Date (Optional)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selectDueDate,
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: Text(
                            _selectedDueDate == null
                                ? 'Select date & time'
                                : _formatDateTime(_selectedDueDate!),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      if (_selectedDueDate != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () =>
                              setState(() => _selectedDueDate = null),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _addTask();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Add Task',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

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
        id: '',
        userId: user.uid,
        title: _controller.text.trim(),
        createdAt: DateTime.now(),
        priority: _selectedPriority,
        dueDate: _selectedDueDate,
        category: _selectedCategory,
      );

      final taskId = await _firebaseService.addTask(task);

      if (_selectedDueDate != null && task.hasTimeSet) {
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
        _selectedPriority = 2;
        _selectedDueDate = null;
        _selectedCategory = 'Personal';
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
      if (!mounted) return;

      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: _selectedDueDate != null
            ? TimeOfDay.fromDateTime(_selectedDueDate!)
            : TimeOfDay.now(),
        helpText: 'Select Due Time (Optional)',
      );

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

      if (!task.isCompleted) {
        await NotificationService.cancelTaskNotification(task.id);
      } else if (task.dueDate != null && task.hasTimeSet) {
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
      await _firebase_service_delete_wrapper(taskId);
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

  // small wrapper to keep code tidy and preserve original call
  Future<void> _firebase_service_delete_wrapper(String taskId) async {
    await _firebase_service_delete_and_cancel(taskId);
  }

  Future<void> _firebase_service_delete_and_cancel(String taskId) async {
    await _firebaseService.deleteTask(taskId);
    await NotificationService.cancelTaskNotification(taskId);
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black45 : Colors.black12,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Tasks',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, size: 28),
                  onPressed: () async {
                    await NotificationService.showImmediateNotification(
                      'Test Notification 🔔',
                      'This is how task reminders will look!',
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Test notification sent!'),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Category filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _filterCategory == null,
                  onSelected: (s) => setState(() => _filterCategory = null),
                ),
                const SizedBox(width: 8),
                ...TaskCategory.all.map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(category.icon, size: 16, color: category.color),
                          const SizedBox(width: 6),
                          Text(category.name),
                        ],
                      ),
                      selected: _filterCategory == category.name,
                      onSelected: (s) => setState(
                        () => _filterCategory = s ? category.name : null,
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Tabs + task list
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TabBar(
                      indicator: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: isDark
                          ? Colors.grey[400]
                          : Colors.grey[700],
                      labelStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(
                          height: 44,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.pending_actions, size: 18),
                              SizedBox(width: 6),
                              Text('Active'),
                            ],
                          ),
                        ),
                        Tab(
                          height: 44,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.task_alt, size: 18),
                              SizedBox(width: 6),
                              Text('Completed'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildTaskList(
                          _firebaseService.getIncompleteTasks(
                            _auth_service_userid(),
                          ),
                          false,
                          isDark,
                        ),
                        _buildTaskList(
                          _firebaseService.getCompletedTasks(
                            _auth_service_userid(),
                          ),
                          true,
                          isDark,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTaskBottomSheet,
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Task',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // wrapper to read user id safely (keeps original auth calls centralized)
  String _auth_service_userid() {
    final user = _authService.currentUser;
    if (user == null) return '';
    return user.uid;
  }

  Widget _priorityPill(String label, int value, Color color) {
    final selected = _selectedPriority == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => setState(() => _selectedPriority = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? color.withOpacity(0.5)
                : (isDark ? Colors.grey[700]! : Colors.grey.shade200),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? color
                    : (isDark ? Colors.grey[300] : Colors.grey[800]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList(
    Stream<List<TaskModel>> stream,
    bool isCompleted,
    bool isDark,
  ) {
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
                        final urlMatch = RegExp(
                          r'https://[^\s]+',
                        ).firstMatch(errorMessage);
                        if (urlMatch != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Check the console for the index creation link',
                              ),
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

        var tasks = snapshot.data ?? [];

        if (_filterCategory != null) {
          tasks = tasks.where((t) => t.category == _filterCategory).toList();
        }

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

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: tasks.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final task = tasks[index];
            return Dismissible(
              key: Key(task.id),
              direction: DismissDirection.endToStart,
              background: Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (direction) => _deleteTask(task.id),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black45 : Colors.black12,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: TaskCategory.fromName(
                        task.category,
                      ).color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      TaskCategory.fromName(task.category).icon,
                      color: TaskCategory.fromName(task.category).color,
                    ),
                  ),
                  title: Text(
                    task.title,
                    style: TextStyle(
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: task.isCompleted
                          ? Colors.grey
                          : Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            color: _getPriorityColor(task.priority),
                            size: 10,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            task.priorityLabel,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '\u2022',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            task.category,
                            style: TextStyle(
                              fontSize: 12,
                              color: TaskCategory.fromName(task.category).color,
                            ),
                          ),
                        ],
                      ),
                      if (task.description != null) ...[
                        const SizedBox(height: 6),
                        Text(task.description!),
                      ],
                      if (task.dueDate != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              task.isOverdue
                                  ? Icons.warning_amber_rounded
                                  : Icons.calendar_today,
                              size: 14,
                              color: task.isOverdue
                                  ? Colors.red
                                  : (task.isCompleted
                                        ? Colors.grey
                                        : Colors.blue),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              task.dueDateFormatted,
                              style: TextStyle(
                                fontSize: 12,
                                color: task.isOverdue
                                    ? Colors.red
                                    : (task.isCompleted
                                          ? Colors.grey
                                          : Colors.blue),
                                fontWeight: task.isOverdue
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  trailing: Checkbox(
                    value: task.isCompleted,
                    onChanged: (_) => _toggleTaskCompletion(task),
                  ),
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
