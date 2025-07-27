import 'package:flutter/material.dart';
import '../services/flutter_gemma_service.dart';
import '../models/gemma_config.dart';
import '../models/gemma_status.dart';

/// Example usage of FlutterGemmaService
class FlutterGemmaExample extends StatefulWidget {
  const FlutterGemmaExample({super.key});

  @override
  State<FlutterGemmaExample> createState() => _FlutterGemmaExampleState();
}

class _FlutterGemmaExampleState extends State<FlutterGemmaExample> {
  final FlutterGemmaService _gemmaService = FlutterGemmaService.instance;
  ModelInfo _currentStatus = const ModelInfo(status: ModelStatus.notDownloaded);
  String _statusMessage = 'Not initialized';

  @override
  void initState() {
    super.initState();
    _initializeService();
    _listenToStatusUpdates();
  }

  void _initializeService() async {
    try {
      // Configure the service with custom settings
      const config = GemmaModelConfig(
        modelType: 'gemmaIt',
        backend: 'gpu',
        maxTokens: 2048,
        supportImage: true,
        maxNumImages: 1,
      );

      final success = await _gemmaService.initialize(config);
      
      if (success) {
        setState(() {
          _statusMessage = 'Service initialized successfully';
        });
      } else {
        setState(() {
          _statusMessage = 'Failed to initialize service';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    }
  }

  void _listenToStatusUpdates() {
    _gemmaService.statusStream.listen((status) {
      setState(() {
        _currentStatus = status;
      });
    });
  }

  Future<void> _downloadModel() async {
    try {
      await for (final progress in _gemmaService.downloadModel()) {
        setState(() {
          _statusMessage = 'Downloading: ${(progress * 100).toStringAsFixed(1)}%';
        });
      }
      setState(() {
        _statusMessage = 'Model downloaded successfully';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Download failed: $e';
      });
    }
  }

  Future<void> _createChatSession() async {
    try {
      final chat = await _gemmaService.createChat(
        temperature: 0.8,
        topK: 5,
        supportImage: false,
      );
      
      setState(() {
        _statusMessage = 'Chat session created: $chat';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to create chat: $e';
      });
    }
  }

  Future<void> _createSession() async {
    try {
      final session = await _gemmaService.createSession(
        temperature: 0.7,
        randomSeed: 42,
      );
      
      setState(() {
        _statusMessage = 'Session created: $session';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to create session: $e';
      });
    }
  }

  String _getStatusText() {
    switch (_currentStatus.status) {
      case ModelStatus.notDownloaded:
        return 'Model not downloaded';
      case ModelStatus.downloading:
        final progress = _currentStatus.downloadProgress ?? 0.0;
        return 'Downloading: ${(progress * 100).toStringAsFixed(1)}%';
      case ModelStatus.ready:
        return 'Model ready';
      case ModelStatus.error:
        return 'Error: ${_currentStatus.error ?? 'Unknown error'}';
      case ModelStatus.initializing:
        return 'Initializing...';
      case ModelStatus.initialized:
        return 'Initialized and ready';
    }
  }

  Color _getStatusColor() {
    switch (_currentStatus.status) {
      case ModelStatus.notDownloaded:
        return Colors.grey;
      case ModelStatus.downloading:
        return Colors.blue;
      case ModelStatus.ready:
      case ModelStatus.initialized:
        return Colors.green;
      case ModelStatus.error:
        return Colors.red;
      case ModelStatus.initializing:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Gemma Service Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Service Status',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          color: _getStatusColor(),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(_getStatusText()),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Message: $_statusMessage',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configuration',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Model Type: ${_gemmaService.config.modelType}'),
                    Text('Backend: ${_gemmaService.config.backend}'),
                    Text('Max Tokens: ${_gemmaService.config.maxTokens}'),
                    Text('Support Image: ${_gemmaService.config.supportImage}'),
                    Text('Max Images: ${_gemmaService.config.maxNumImages}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _currentStatus.status == ModelStatus.notDownloaded
                  ? _downloadModel
                  : null,
              child: const Text('Download Model'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _gemmaService.isInitialized ? _createChatSession : null,
              child: const Text('Create Chat Session'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _gemmaService.isInitialized ? _createSession : null,
              child: const Text('Create Session'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                await _gemmaService.deleteModel();
                setState(() {
                  _statusMessage = 'Model deleted';
                });
              },
              child: const Text('Delete Model'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Note: Don't dispose the service here as it's a singleton
    // The service will be disposed when the app closes
    super.dispose();
  }
}