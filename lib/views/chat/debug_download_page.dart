// lib/pages/debug_download_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/gemma_native_service.dart';
import 'dart:io';

import '../../services/model_download_service.dart';

class DebugDownloadPage extends StatefulWidget {
  const DebugDownloadPage({Key? key}) : super(key: key);

  @override
  State<DebugDownloadPage> createState() => _DebugDownloadPageState();
}

class _DebugDownloadPageState extends State<DebugDownloadPage> {
  final TextEditingController _urlController = TextEditingController();
  final GemmaNativeService _gemmaService = GemmaNativeService();

  String _status = 'Checking model...';
  bool _isDownloading = false;
  double _progress = 0.0;
  String? _modelPath;
  bool _modelExists = false;
  int? _modelSize;

  @override
  void initState() {
    super.initState();
    _checkModel();

    // Pre-fill with common Gemma model URLs
    _urlController.text = 'https://storage.googleapis.com/noormodel/gemma-3n-E2B-it-int4.task';
  }

  Future<void> _checkModel() async {
    try {
      _modelPath = await ModelDownloadService.getModelPath();
      final file = File(_modelPath!);
      _modelExists = await file.exists();

      if (_modelExists) {
        _modelSize = await file.length();
        final sizeMB = (_modelSize! / 1024 / 1024).toStringAsFixed(1);
        setState(() {
          _status = 'Model found at: $_modelPath\nSize: $sizeMB MB';
        });
      } else {
        setState(() {
          _status = 'No model found. Please enter a URL and download.';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error checking model: $e';
      });
    }
  }

  Future<void> _downloadModel() async {
    final url = _urlController.text.trim();
    if (url.isEmpty || url == 'YOUR_MODEL_DOWNLOAD_URL_HERE') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid model URL')),
      );
      return;
    }

    // Save the URL
    await ModelDownloadService.setModelUrl(url);

    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _status = 'Starting download...';
    });

    await ModelDownloadService.downloadModel(
      onProgress: (progress, status) {
        setState(() {
          _progress = progress;
          _status = status;
        });
      },
      onComplete: () {
        setState(() {
          _isDownloading = false;
          _status = 'Download complete! Checking model...';
        });
        _checkModel();
      },
      onError: (error) {
        setState(() {
          _isDownloading = false;
          _status = 'Download error: $error';
        });
      },
    );
  }

  Future<void> _testModel() async {
    setState(() {
      _status = 'Initializing model...';
    });

    try {
      final success = await _gemmaService.initializeModel();
      if (success) {
        setState(() {
          _status = 'Model initialized successfully! Testing generation...';
        });

        final response = await _gemmaService.generateText('Hello, how are you?');
        setState(() {
          _status = 'Success! Response: $response';
        });
      } else {
        setState(() {
          _status = 'Failed to initialize model';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _deleteModel() async {
    await ModelDownloadService.deleteModel();
    _checkModel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Model Download Debug'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // URL Input
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Model URL:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _urlController,
                      decoration: const InputDecoration(
                        hintText: 'Enter model download URL',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Try these URLs:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SelectableText(
                      '• GitHub: https://github.com/yourusername/yourrepo/releases/download/v1.0/gemma-3n-E2B-it-int4.task\n'
                          '• Google Drive: https://drive.google.com/uc?export=download&id=YOUR_FILE_ID\n'
                          '• Dropbox: https://www.dropbox.com/s/YOUR_ID/gemma-3n-E2B-it-int4.task?dl=1',
                      style: TextStyle(fontSize: 11, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Progress
            if (_isDownloading) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      LinearProgressIndicator(value: _progress),
                      const SizedBox(height: 8),
                      Text('${(_progress * 100).toStringAsFixed(0)}%'),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Actions
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isDownloading ? null : _downloadModel,
                  icon: const Icon(Icons.download),
                  label: const Text('Download'),
                ),
                ElevatedButton.icon(
                  onPressed: _modelExists && !_isDownloading ? _testModel : null,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Test Model'),
                ),
                ElevatedButton.icon(
                  onPressed: _modelExists && !_isDownloading ? _deleteModel : null,
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // File info
            if (_modelPath != null) ...[
              Card(
                color: Colors.grey.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'File Info:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        'Path: $_modelPath\n'
                            'Exists: $_modelExists\n'
                            'Size: ${_modelSize != null ? "${(_modelSize! / 1024 / 1024).toStringAsFixed(1)} MB" : "N/A"}',
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _gemmaService.dispose();
    super.dispose();
  }
}
