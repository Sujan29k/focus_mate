import 'package:flutter/material.dart';

/// Task category definitions
class TaskCategory {
  final String name;
  final IconData icon;
  final Color color;

  const TaskCategory({
    required this.name,
    required this.icon,
    required this.color,
  });

  static const TaskCategory work = TaskCategory(
    name: 'Work',
    icon: Icons.work_outline,
    color: Colors.blue,
  );

  static const TaskCategory personal = TaskCategory(
    name: 'Personal',
    icon: Icons.person_outline,
    color: Colors.purple,
  );

  static const TaskCategory study = TaskCategory(
    name: 'Study',
    icon: Icons.school_outlined,
    color: Colors.orange,
  );

  static const TaskCategory health = TaskCategory(
    name: 'Health',
    icon: Icons.favorite_outline,
    color: Colors.red,
  );

  static const TaskCategory shopping = TaskCategory(
    name: 'Shopping',
    icon: Icons.shopping_cart_outlined,
    color: Colors.green,
  );

  static const TaskCategory home = TaskCategory(
    name: 'Home',
    icon: Icons.home_outlined,
    color: Colors.brown,
  );

  static const TaskCategory other = TaskCategory(
    name: 'Other',
    icon: Icons.more_horiz,
    color: Colors.grey,
  );

  /// List of all available categories
  static const List<TaskCategory> all = [
    work,
    personal,
    study,
    health,
    shopping,
    home,
    other,
  ];

  /// Get category by name
  static TaskCategory fromName(String name) {
    return all.firstWhere(
      (category) => category.name == name,
      orElse: () => personal, // Default to Personal
    );
  }

  /// Get all category names
  static List<String> get allNames => all.map((c) => c.name).toList();
}
