import 'package:flutter/material.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final List<Map<String, dynamic>> _tasks = [];
  final TextEditingController _controller = TextEditingController();

  void _addTask() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _tasks.add({'task': _controller.text, 'done': false});
      _controller.clear();
    });
  }

  void _toggleDone(int index) {
    setState(() => _tasks[index]['done'] = !_tasks[index]['done']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('To-Do List')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(controller: _controller, decoration: const InputDecoration(labelText: 'New task')),
                ),
                IconButton(icon: const Icon(Icons.add), onPressed: _addTask),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _tasks.length,
              itemBuilder: (context, i) {
                return ListTile(
                  title: Text(_tasks[i]['task'], style: TextStyle(decoration: _tasks[i]['done'] ? TextDecoration.lineThrough : null)),
                  trailing: Checkbox(value: _tasks[i]['done'], onChanged: (_) => _toggleDone(i)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
