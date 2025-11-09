import 'package:flutter/material.dart';
import 'auth/login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App Logo/Icon
              const Icon(Icons.psychology, size: 120, color: Colors.teal),
              const SizedBox(height: 32),

              // App Name
              const Text(
                'FocusMate',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 16),

              // Tagline
              const Text(
                'Stay focused, achieve more',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 48),

              // Features List
              _buildFeature(Icons.timer, 'Pomodoro Timer'),
              const SizedBox(height: 16),
              _buildFeature(Icons.analytics, 'Track Your Progress'),
              const SizedBox(height: 16),
              _buildFeature(Icons.task_alt, 'Manage Tasks'),
              const SizedBox(height: 16),
              _buildFeature(Icons.chat_bubble, 'AI Coach Support'),
              const SizedBox(height: 48),

              // Get Started Button
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Get Started',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 16),

              // Optional: Skip to explore without login
              TextButton(
                onPressed: () {
                  // Optional: Navigate to a demo/preview screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please sign in to use all features'),
                    ),
                  );
                },
                child: const Text('Learn More'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.teal, size: 28),
        const SizedBox(width: 16),
        Text(text, style: const TextStyle(fontSize: 16)),
      ],
    );
  }
}
