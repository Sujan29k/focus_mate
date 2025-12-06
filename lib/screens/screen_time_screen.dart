import 'package:flutter/material.dart';
import '../services/screen_time_service.dart';

class ScreenTimeScreen extends StatefulWidget {
  const ScreenTimeScreen({super.key});

  @override
  State<ScreenTimeScreen> createState() => _ScreenTimeScreenState();
}

class _ScreenTimeScreenState extends State<ScreenTimeScreen> {
  bool _isLoading = true;
  bool _isAuthorized = false;
  List<Map<String, dynamic>> _apps = [];
  int _totalUsageTime = 0;
  String? _errorMessage;
  bool _isMockData = false;

  @override
  void initState() {
    super.initState();
    _checkAuthorizationAndLoadData();
  }

  Future<void> _checkAuthorizationAndLoadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check authorization status
      final statusResult = await ScreenTimeService.checkAuthorizationStatus();
      _isAuthorized = statusResult['authorized'] == true;

      if (_isAuthorized) {
        // Load screen time data
        await _loadScreenTimeData();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error checking authorization: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadScreenTimeData() async {
    try {
      final result = await ScreenTimeService.getScreenTimeData();

      if (result['success'] == true || result['apps'] != null) {
        final apps = result['apps'] as List<dynamic>? ?? [];
        setState(() {
          _apps = ScreenTimeService.sortAppsByUsage(apps);
          _totalUsageTime = ScreenTimeService.getTotalUsageTime(apps);
          _isMockData = result['isMockData'] == true;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Failed to load data';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading screen time data: $e';
      });
    }
  }

  Future<void> _requestAuthorization() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ScreenTimeService.requestAuthorization();

      if (result['success'] == true) {
        setState(() {
          _isAuthorized = true;
        });
        await _loadScreenTimeData();
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Authorization request failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error requesting authorization: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Screen Time'),
        actions: [
          if (_isAuthorized)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadScreenTimeData,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_isAuthorized
          ? _buildAuthorizationRequired()
          : _buildScreenTimeData(isDark),
    );
  }

  Widget _buildAuthorizationRequired() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hourglass_empty,
              size: 80,
              color: Theme.of(context).primaryColor.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'Screen Time Access Required',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'To view your app usage statistics, FocusMate needs access to Screen Time data.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _requestAuthorization,
              icon: const Icon(Icons.check_circle),
              label: const Text('Grant Access'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScreenTimeData(bool isDark) {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadScreenTimeData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadScreenTimeData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Mock data warning
          if (_isMockData)
            Card(
              color: Colors.orange[100],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[900]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Showing demo data. Real Screen Time data requires additional iOS configuration.',
                        style: TextStyle(
                          color: Colors.orange[900],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Total usage card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Total Screen Time',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ScreenTimeService.formatTime(_totalUsageTime),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Today',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Apps list header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'App Usage',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                '${_apps.length} apps',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Apps list
          if (_apps.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.mobile_off, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No app usage data available',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...(_apps.map((app) => _buildAppCard(app, isDark))),
        ],
      ),
    );
  }

  Widget _buildAppCard(Map<String, dynamic> app, bool isDark) {
    final appName = app['appName'] as String? ?? 'Unknown App';
    final usageTime = app['usageTime'] as int? ?? 0;
    final category = app['category'] as String? ?? 'Other';

    final percentage = _totalUsageTime > 0
        ? (usageTime / _totalUsageTime * 100).toStringAsFixed(1)
        : '0.0';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // App icon placeholder
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getCategoryIcon(category),
                color: Theme.of(context).primaryColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),

            // App info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // Usage time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  ScreenTimeService.formatTime(usageTime),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$percentage%',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'social networking':
        return Icons.people;
      case 'entertainment':
        return Icons.movie;
      case 'productivity':
        return Icons.work;
      case 'utilities':
        return Icons.build;
      case 'games':
        return Icons.sports_esports;
      default:
        return Icons.phone_iphone;
    }
  }
}
