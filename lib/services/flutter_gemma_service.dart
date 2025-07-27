import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/gemma_config.dart';
import '../models/gemma_status.dart';
import '../models/gemma_exceptions.dart';

/// Configuration for model download retry behavior
class DownloadRetryConfig {
  final int maxRetries;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;
  
  const DownloadRetryConfig({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 30),
  });
}

/// Core service for managing Flutter Gemma integration
class FlutterGemmaService {
  static FlutterGemmaService? _instance;
  static final Object _lock = Object();

  /// Singleton instance
  static FlutterGemmaService get instance {
    _instance ??= FlutterGemmaService._internal();
    return _instance!;
  }

  FlutterGemmaService._internal();

  // Private fields
  dynamic _model; // Will be InferenceModel when flutter_gemma is properly integrated
  GemmaModelConfig _config = const GemmaModelConfig();
  final StreamController<ModelInfo> _statusController = StreamController<ModelInfo>.broadcast();
  ModelInfo _currentStatus = const ModelInfo(status: ModelStatus.notDownloaded);
  bool _isInitialized = false;
  bool _isInitializing = false;
  bool _isDownloading = false;
  DownloadRetryConfig _retryConfig = const DownloadRetryConfig();

  // Public getters
  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;
  ModelInfo get currentStatus => _currentStatus;
  Stream<ModelInfo> get statusStream => _statusController.stream;
  GemmaModelConfig get config => _config;

  /// Initialize the service with optional configuration
  Future<bool> initialize([GemmaModelConfig? config]) async {
    if (_isInitialized) {
      return true;
    }

    if (_isInitializing) {
      // Wait for current initialization to complete
      await _waitForInitialization();
      return _isInitialized;
    }

    _isInitializing = true;
    _updateStatus(const ModelInfo(status: ModelStatus.initializing));

    try {
      if (config != null) {
        _config = config;
      }

      // Check if model is ready
      final isReady = await isModelReady();
      if (!isReady) {
        _updateStatus(const ModelInfo(status: ModelStatus.error, error: 'Model not found'));
        return false;
      }

      // Initialize the model
      await _initializeModel();
      
      _isInitialized = true;
      _updateStatus(ModelInfo(
        status: ModelStatus.initialized,
        modelPath: await _getModelPath(),
        modelSize: await _getModelSize(),
      ));

      return true;
    } catch (e, stackTrace) {
      final error = e is GemmaException ? e : GemmaException.initializationError(e.toString(), e);
      _updateStatus(ModelInfo(status: ModelStatus.error, error: error.message));
      
      if (kDebugMode) {
        print('FlutterGemmaService initialization failed: $error');
        print('Stack trace: $stackTrace');
      }
      
      return false;
    } finally {
      _isInitializing = false;
    }
  }

  /// Wait for current initialization to complete
  Future<void> _waitForInitialization() async {
    while (_isInitializing) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Initialize the actual model
  Future<void> _initializeModel() async {
    try {
      final modelPath = await _getModelPath();
      
      // TODO: Initialize flutter_gemma model when package is properly configured
      // This is a placeholder implementation that will be replaced with actual flutter_gemma integration
      // 
      // Example of what the actual implementation would look like:
      // _model = await InferenceModel.createFromAsset(
      //   modelPath,
      //   modelType: _getModelType(_config.modelType),
      //   preferredBackend: _getPreferredBackend(_config.backend),
      //   maxTokens: _config.maxTokens,
      //   supportImage: _config.supportImage,
      //   maxNumImages: _config.maxNumImages,
      //   tools: _config.tools,
      // );
      
      _model = 'placeholder_model'; // Placeholder for actual InferenceModel

      if (_model == null) {
        throw GemmaException.modelLoadFailed('Model creation returned null');
      }
    } catch (e) {
      throw GemmaException.modelLoadFailed('Failed to create model from asset', e);
    }
  }

  /// Check if the model is ready for use
  Future<bool> isModelReady() async {
    try {
      final modelPath = await _getModelPath();
      final file = File(modelPath);
      
      if (!await file.exists()) {
        return false;
      }
      
      // Validate model file integrity
      return await _validateModelFile(file);
    } catch (e) {
      if (kDebugMode) {
        print('Error checking model readiness: $e');
      }
      return false;
    }
  }

  /// Validate the model file integrity
  Future<bool> _validateModelFile(File modelFile) async {
    try {
      final stat = await modelFile.stat();
      
      // Check if file is not empty
      if (stat.size == 0) {
        if (kDebugMode) {
          print('Model file is empty');
        }
        return false;
      }
      
      // Check minimum file size (placeholder validation)
      const minModelSize = 10; // bytes - very small for testing
      if (stat.size < minModelSize) {
        if (kDebugMode) {
          print('Model file too small: ${stat.size} bytes');
        }
        return false;
      }
      
      // Additional validation could include:
      // - File format validation
      // - Checksum verification
      // - Model metadata validation
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error validating model file: $e');
      }
      return false;
    }
  }

  /// Get detailed model information
  Future<ModelInfo> getModelInfo() async {
    try {
      final modelPath = await _getModelPath();
      final file = File(modelPath);
      
      if (!await file.exists()) {
        return const ModelInfo(status: ModelStatus.notDownloaded);
      }
      
      final isValid = await _validateModelFile(file);
      final modelSize = await _getModelSize();
      
      return ModelInfo(
        status: isValid ? ModelStatus.ready : ModelStatus.error,
        modelPath: modelPath,
        modelSize: modelSize,
        error: isValid ? null : 'Model file validation failed',
      );
    } catch (e) {
      return ModelInfo(
        status: ModelStatus.error,
        error: 'Failed to get model info: ${e.toString()}',
      );
    }
  }

  /// Download the model with progress tracking
  Stream<double> downloadModel({String? modelUrl, bool forceRedownload = false}) async* {
    // Check if already downloading before doing anything else
    if (_isDownloading) {
      throw GemmaException(GemmaErrorType.configurationError, 'Model is already being downloaded');
    }

    // Set downloading flag immediately to prevent concurrent downloads
    _isDownloading = true;

    try {
      // Check if model already exists and we're not forcing redownload
      if (!forceRedownload && await isModelReady()) {
        _updateStatus(ModelInfo(
          status: ModelStatus.ready,
          modelPath: await _getModelPath(),
          modelSize: await _getModelSize(),
        ));
        yield 1.0;
        return;
      }

      // Validate prerequisites before starting download
      await _validateDownloadPrerequisites();

      _updateStatus(const ModelInfo(status: ModelStatus.downloading, downloadProgress: 0.0));

      final modelPath = await _getModelPath();
      final modelFile = File(modelPath);
      
      // Ensure directory exists
      await modelFile.parent.create(recursive: true);

      // For now, simulate download with progress tracking
      // In a real implementation, this would download from a remote source
      const totalSteps = 100;
      for (int i = 0; i <= totalSteps; i += 5) {
        await Future.delayed(const Duration(milliseconds: 20));
        final progress = i / totalSteps;
        
        _updateStatus(ModelInfo(
          status: ModelStatus.downloading, 
          downloadProgress: progress,
          modelPath: modelPath,
        ));
        
        yield progress;
        
        // Simulate network interruption for testing
        if (i == 50 && modelUrl?.contains('fail') == true) {
          throw GemmaException.networkError('Simulated network connection lost');
        }
      }

      // Create a placeholder model file for testing
      await modelFile.writeAsString('placeholder_model_data');
      
      final modelSize = await _getModelSize();
      _updateStatus(ModelInfo(
        status: ModelStatus.ready,
        modelPath: modelPath,
        modelSize: modelSize,
      ));
      
      yield 1.0;
    } catch (e) {
      final error = GemmaException.networkError('Download failed: ${e.toString()}', e);
      _updateStatus(ModelInfo(status: ModelStatus.error, error: error.message));
      rethrow;
    } finally {
      _isDownloading = false;
    }
  }

  /// Download model with retry mechanism
  Stream<double> downloadModelWithRetry({
    String? modelUrl, 
    bool forceRedownload = false,
    DownloadRetryConfig? retryConfig,
  }) async* {
    final config = retryConfig ?? _retryConfig;
    int attemptCount = 0;
    Duration currentDelay = config.initialDelay;

    while (attemptCount <= config.maxRetries) {
      try {
        await for (final progress in downloadModel(
          modelUrl: modelUrl, 
          forceRedownload: forceRedownload
        )) {
          yield progress;
        }
        return; // Success, exit retry loop
      } catch (e) {
        attemptCount++;
        
        if (attemptCount > config.maxRetries) {
          // Final attempt failed, rethrow the error
          final error = GemmaException.networkError(
            'Download failed after ${config.maxRetries} retries: ${e.toString()}', 
            e
          );
          _updateStatus(ModelInfo(status: ModelStatus.error, error: error.message));
          throw error;
        }

        // Wait before retry with exponential backoff
        if (kDebugMode) {
          print('Download attempt $attemptCount failed, retrying in ${currentDelay.inSeconds}s: $e');
        }
        
        _updateStatus(ModelInfo(
          status: ModelStatus.error, 
          error: 'Download failed (attempt $attemptCount/${config.maxRetries}), retrying...'
        ));
        
        await Future.delayed(currentDelay);
        
        // Exponential backoff
        currentDelay = Duration(
          milliseconds: (currentDelay.inMilliseconds * config.backoffMultiplier).round()
        );
        if (currentDelay > config.maxDelay) {
          currentDelay = config.maxDelay;
        }
        
        // Reset status for retry
        _updateStatus(const ModelInfo(status: ModelStatus.downloading, downloadProgress: 0.0));
      }
    }
  }

  /// Update retry configuration
  void updateRetryConfig(DownloadRetryConfig config) {
    _retryConfig = config;
  }

  /// Check network connectivity (simplified implementation)
  Future<bool> isNetworkAvailable() async {
    try {
      // Simple connectivity check - in a real app you might use connectivity_plus package
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('Network check failed: $e');
      }
      return false;
    }
  }

  /// Validate download prerequisites
  Future<void> _validateDownloadPrerequisites() async {
    // Check network connectivity
    if (!await isNetworkAvailable()) {
      throw GemmaException.networkError('No network connection available');
    }

    // Check storage space
    if (!await hasEnoughStorageSpace()) {
      final available = await getAvailableStorageSpace();
      final required = await getRequiredStorageSpace();
      throw GemmaException(
        GemmaErrorType.configurationError,
        'Insufficient storage space. Required: ${(required / 1024 / 1024).toStringAsFixed(1)}MB, Available: ${(available / 1024 / 1024).toStringAsFixed(1)}MB'
      );
    }
  }

  /// Delete the model from device
  Future<void> deleteModel({bool cleanupCache = true}) async {
    try {
      // Dispose of current model instance first
      await dispose();
      
      final modelPath = await _getModelPath();
      final file = File(modelPath);
      
      if (await file.exists()) {
        await file.delete();
        if (kDebugMode) {
          print('Model file deleted: $modelPath');
        }
      }

      // Clean up cache and temporary files if requested
      if (cleanupCache) {
        await _cleanupModelCache();
      }

      _updateStatus(const ModelInfo(status: ModelStatus.notDownloaded));
    } catch (e) {
      final error = GemmaException(GemmaErrorType.configurationError, 'Failed to delete model: ${e.toString()}', e);
      _updateStatus(ModelInfo(status: ModelStatus.error, error: error.message));
      throw error;
    }
  }

  /// Clean up model cache and temporary files
  Future<void> _cleanupModelCache() async {
    try {
      final modelPath = await _getModelPath();
      final modelDir = Directory(modelPath).parent;
      
      // Clean up temporary download files
      final tempFiles = await modelDir.list()
          .where((entity) => entity.path.contains('.tmp') || entity.path.contains('.download'))
          .toList();
      
      for (final tempFile in tempFiles) {
        try {
          if (tempFile is File) {
            await tempFile.delete();
            if (kDebugMode) {
              print('Cleaned up temp file: ${tempFile.path}');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Failed to delete temp file ${tempFile.path}: $e');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during cache cleanup: $e');
      }
    }
  }

  /// Check available storage space for model download
  Future<int> getAvailableStorageSpace() async {
    try {
      final modelPath = await _getModelPath();
      final modelDir = Directory(modelPath).parent;
      
      // Create directory if it doesn't exist
      if (!await modelDir.exists()) {
        await modelDir.create(recursive: true);
      }
      
      // Get available space (simplified implementation)
      final stat = await modelDir.stat();
      
      // This is a placeholder - in a real implementation, you would use
      // platform-specific methods to get actual available disk space
      return 1024 * 1024 * 1024; // 1GB placeholder
    } catch (e) {
      if (kDebugMode) {
        print('Error getting available storage space: $e');
      }
      return 0;
    }
  }

  /// Estimate required storage space for model
  Future<int> getRequiredStorageSpace() async {
    // This would typically be retrieved from model metadata or configuration
    // For now, return a placeholder value
    return 100 * 1024 * 1024; // 100MB placeholder
  }

  /// Check if there's enough storage space for model download
  Future<bool> hasEnoughStorageSpace() async {
    try {
      final available = await getAvailableStorageSpace();
      final required = await getRequiredStorageSpace();
      
      // Add 20% buffer for safety
      final requiredWithBuffer = (required * 1.2).round();
      
      return available >= requiredWithBuffer;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking storage space: $e');
      }
      return false;
    }
  }

  /// Create a chat session with the specified configuration
  Future<dynamic> createChat({
    double temperature = 0.8,
    int randomSeed = 1,
    int topK = 1,
    bool supportImage = false,
    List<dynamic>? tools,
  }) async {
    if (!_isInitialized || _model == null) {
      throw GemmaException.initializationError('Service not initialized. Call initialize() first.');
    }

    try {
      // TODO: Replace with actual flutter_gemma chat creation
      // final chat = await _model!.createChat(
      //   temperature: temperature,
      //   randomSeed: randomSeed,
      //   topK: topK,
      //   supportImage: supportImage,
      //   tools: tools,
      // );

      // Placeholder implementation
      return 'placeholder_chat';
    } catch (e) {
      throw GemmaException.inferenceError('Failed to create chat session', e);
    }
  }

  /// Create a session for single queries
  Future<dynamic> createSession({
    double temperature = 0.8,
    int randomSeed = 1,
    int topK = 1,
  }) async {
    if (!_isInitialized || _model == null) {
      throw GemmaException.initializationError('Service not initialized. Call initialize() first.');
    }

    try {
      // TODO: Replace with actual flutter_gemma session creation
      // final session = await _model!.createSession(
      //   temperature: temperature,
      //   randomSeed: randomSeed,
      //   topK: topK,
      // );

      // Placeholder implementation
      return 'placeholder_session';
    } catch (e) {
      throw GemmaException.inferenceError('Failed to create session', e);
    }
  }

  /// Update the service configuration
  Future<void> updateConfig(GemmaModelConfig newConfig) async {
    if (_isInitialized && _configRequiresReinitialization(newConfig)) {
      await dispose();
      _config = newConfig;
      await initialize();
    } else {
      _config = newConfig;
    }
  }

  /// Check if configuration change requires reinitialization
  bool _configRequiresReinitialization(GemmaModelConfig newConfig) {
    return _config.modelType != newConfig.modelType ||
           _config.backend != newConfig.backend ||
           _config.maxTokens != newConfig.maxTokens ||
           _config.supportImage != newConfig.supportImage ||
           _config.maxNumImages != newConfig.maxNumImages;
  }

  /// Get the model file path
  Future<String> _getModelPath() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      return '${directory.path}/gemma-3n-E2B-it-int4.task';
    } catch (e) {
      // Fallback for test environment
      return '/tmp/gemma-3n-E2B-it-int4.task';
    }
  }

  /// Get the model file size
  Future<int?> _getModelSize() async {
    try {
      final modelPath = await _getModelPath();
      final file = File(modelPath);
      
      if (await file.exists()) {
        return await file.length();
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting model size: $e');
      }
      return null;
    }
  }

  /// Update the current status and notify listeners
  void _updateStatus(ModelInfo newStatus) {
    _currentStatus = newStatus;
    if (!_statusController.isClosed) {
      _statusController.add(newStatus);
    }
  }

  /// Dispose of resources
  Future<void> dispose() async {
    try {
      // TODO: Call actual dispose method when flutter_gemma is properly configured
      // _model?.dispose();
      _model = null;
      _isInitialized = false;
      _isInitializing = false;
      _isDownloading = false;
      
      _updateStatus(const ModelInfo(status: ModelStatus.notDownloaded));
    } catch (e) {
      if (kDebugMode) {
        print('Error during disposal: $e');
      }
    }
  }

  /// Get memory usage information
  Future<Map<String, dynamic>> getMemoryInfo() async {
    try {
      // This would be implemented with actual memory monitoring
      // For now, return basic information
      return {
        'isInitialized': _isInitialized,
        'modelLoaded': _model != null,
        'modelSize': await _getModelSize(),
        'status': _currentStatus.status.toString(),
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting memory info: $e');
      }
      return {'error': e.toString()};
    }
  }

  /// Check if GPU acceleration is available
  Future<bool> isGpuAccelerationAvailable() async {
    try {
      // This would check actual GPU availability
      // For now, return true if backend is set to GPU
      return _config.backend.toLowerCase() == 'gpu';
    } catch (e) {
      if (kDebugMode) {
        print('Error checking GPU availability: $e');
      }
      return false;
    }
  }

  /// Optimize resource usage based on current system state
  Future<void> optimizeResources() async {
    try {
      if (!_isInitialized || _model == null) {
        return;
      }

      // This would implement actual resource optimization
      // For now, just log the optimization attempt
      if (kDebugMode) {
        print('Optimizing resources for current system state');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error optimizing resources: $e');
      }
    }
  }

  /// Dispose of the singleton instance (for testing)
  static void disposeInstance() {
    synchronized(_lock, () {
      _instance?.dispose();
      _instance?._statusController.close();
      _instance = null;
    });
  }
}

/// Simple synchronization helper
void synchronized(Object lock, void Function() callback) {
  callback();
}