import 'package:flutter/material.dart';
import '../../services/biometric_service.dart';
import '../../services/auth_service.dart';
import '../../services/secure_storage_service.dart';
import '../home_screen.dart';
import 'login_screen.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _bio = BiometricService();
  final _auth = AuthService();
  final _secureStorage = SecureStorageService();

  bool _checking = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tryUnlock();
  }

  Future<void> _tryUnlock() async {
    setState(() {
      _checking = true;
      _error = null;
    });

    final supported = await _bio.isSupported();
    final enrolled = await _bio.hasEnrolledBiometrics();

    if (!supported || !enrolled) {
      setState(() {
        _checking = false;
        _error = 'Biometric not available. Use password instead.';
      });
      return;
    }

    final ok = await _bio.authenticate(reason: 'Unlock FocusMate');

    if (!mounted) return;

    if (!ok) {
      setState(() {
        _checking = false;
        _error = 'Authentication failed. Try again or use password.';
      });
      return;
    }

    // Try Google silent sign-in first
    try {
      final user = await _auth.signInWithGoogleSilently();
      if (user != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        return;
      }
    } catch (e) {
      // Google silent sign-in failed, try email/password
    }

    // Fall back to stored email & password
    final creds = await _secureStorage.getCredentials();
    final email = creds['email'];
    final password = creds['password'];

    if (email == null || password == null) {
      setState(() {
        _checking = false;
        _error = 'No saved credentials found. Login with password.';
      });
      return;
    }

    // Sign into Firebase using stored credentials
    try {
      await _auth.signInWithEmail(email, password);

      if (!mounted) return;

      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } catch (e) {
      setState(() {
        _checking = false;
        _error = 'Login failed. Use password instead.';
      });
    }
  }

  Future<void> _usePassword() async {
    await _auth.signOut();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: Colors.teal),
              const SizedBox(height: 16),
              const Text(
                'Unlock with Face ID / Touch ID',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              if (_checking)
                const CircularProgressIndicator()
              else if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _checking ? null : _tryUnlock,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text("Try Again"),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _checking ? null : _usePassword,
                    child: const Text("Use Password"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
