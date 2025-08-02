import 'package:flutter/material.dart';
import 'services/gemma_ai_service.dart';
import 'views/student/student_dashboard_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Noor - Educational AI Platform',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({Key? key}) : super(key: key);

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitialized = false;
  String _status = 'Initializing Noor...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      setState(() {
        _status = 'Starting educational platform...';
      });

      // Initialize the Gemma AI service
      final service = GemmaAiService.instance;
      await service.initialize();

      setState(() {
        _status = 'Ready!';
        _isInitialized = true;
      });

      // Navigate to main app after a brief delay
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const StudentDashboardScreen(),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo.shade100, Colors.white],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.school,
                size: 80,
                color: Colors.indigo.shade700,
              ),
              const SizedBox(height: 24),
              Text(
                'Noor',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Educational Platform for Afghan Women',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.indigo.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              if (!_isInitialized) ...[
                CircularProgressIndicator(
                  color: Colors.indigo.shade600,
                ),
                const SizedBox(height: 16),
              ],
              Text(
                _status,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.indigo.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


