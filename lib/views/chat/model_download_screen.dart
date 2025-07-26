import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/model_download_service.dart';

class ModelDownloadScreen extends StatefulWidget {
  final VoidCallback onDownloadComplete;

  const ModelDownloadScreen({
    Key? key,
    required this.onDownloadComplete,
  }) : super(key: key);

  @override
  State<ModelDownloadScreen> createState() => _ModelDownloadScreenState();
}

class _ModelDownloadScreenState extends State<ModelDownloadScreen>
    with WidgetsBindingObserver {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _statusMessage = '';
  String? _errorMessage;
  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkExistingModel();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelToken?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _isDownloading) {
      // Optionally cancel download when app goes to background
      // _cancelDownload();
    }
  }

  Future<void> _checkExistingModel() async {
    final isReady = await ModelDownloadService.isModelReady();
    if (isReady && mounted) {
      widget.onDownloadComplete();
    }
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _errorMessage = null;
      _downloadProgress = 0.0;
      _statusMessage = 'Starting download...';
      _cancelToken = CancelToken();
    });

    // Keep screen awake during download
    SystemChannels.platform.invokeMethod('SystemChrome.setPreferredOrientations');

    await ModelDownloadService.downloadModel(
      onProgress: (progress, status) {
        if (mounted) {
          setState(() {
            _downloadProgress = progress;
            _statusMessage = status;
          });
        }
      },
      onComplete: () {
        if (mounted) {
          widget.onDownloadComplete();
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isDownloading = false;
            _errorMessage = error;
            _cancelToken = null;
          });
        }
      },
      cancelToken: _cancelToken,
    );
  }

  void _cancelDownload() {
    _cancelToken?.cancel();
    setState(() {
      _isDownloading = false;
      _cancelToken = null;
      _statusMessage = 'Download cancelled';
    });
  }

  Future<void> _retryDownload() async {
    await ModelDownloadService.deleteModel();
    _startDownload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isDownloading ? Icons.downloading : Icons.download_rounded,
                  size: 64,
                  color: Colors.deepPurple,
                ),
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                'Gemma Model Setup',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              // Description
              Text(
                'The Gemma AI model needs to be downloaded for offline use.\nThis is a one-time download.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),

              const SizedBox(height: 48),

              // Progress section
              if (_isDownloading) ...[
                // Progress bar
                Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _downloadProgress > 0 ? _downloadProgress : null,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.deepPurple,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Progress text
                    Text(
                      _downloadProgress > 0
                          ? '${(_downloadProgress * 100).toStringAsFixed(0)}%'
                          : 'Preparing...',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),

                    const SizedBox(height: 8),

                    // Status message
                    Text(
                      _statusMessage,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Cancel button
                    TextButton.icon(
                      onPressed: _cancelDownload,
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancel Download'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Download button
                ElevatedButton.icon(
                  onPressed: _startDownload,
                  icon: const Icon(Icons.download),
                  label: const Text('Download Model'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],

              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Download Failed',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _retryDownload,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(),

              // Info text
              Text(
                'Model size: ~500MB\nRequires stable internet connection',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}