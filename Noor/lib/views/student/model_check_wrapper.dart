import 'package:flutter/material.dart';
import '../../services/model_download_service.dart';
import 'student_dashboard_screen.dart';
import 'model_download_screen.dart';

class ModelCheckWrapper extends StatefulWidget {
  const ModelCheckWrapper({Key? key}) : super(key: key);

  @override
  State<ModelCheckWrapper> createState() => _ModelCheckWrapperState();
}

class _ModelCheckWrapperState extends State<ModelCheckWrapper> {
  bool _isCheckingModel = true;
  bool _modelReady = false;

  @override
  void initState() {
    super.initState();
    _checkModel();
  }

  Future<void> _checkModel() async {
    final isReady = await ModelDownloadService.isModelReady();

    if (mounted) {
      setState(() {
        _modelReady = isReady;
        _isCheckingModel = false;
      });
    }
  }

  void _onDownloadComplete() {
    setState(() {
      _modelReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingModel) {
      // Show loading screen while checking
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Checking AI model...'),
            ],
          ),
        ),
      );
    }

    if (_modelReady) {
      // Model is ready, show main dashboard
      return const StudentDashboardScreen();
    } else {
      // Model not ready, show download screen
      return ModelDownloadScreen(
        onDownloadComplete: _onDownloadComplete,
      );
    }
  }
}