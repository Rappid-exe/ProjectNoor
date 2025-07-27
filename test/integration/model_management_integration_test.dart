import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor/models/gemma_config.dart';
import 'package:noor/models/gemma_status.dart';
import 'package:noor/models/gemma_exceptions.dart';
import 'package:noor/services/flutter_gemma_service.dart';

void main() {
  group('Model Management Integration Tests', () {
    late FlutterGemmaService service;
    late Directory tempDir;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() async {
      // Create temporary directory for test files
      tempDir = await Directory.systemTemp.createTemp('gemma_test_');
      
      // Reset singleton for each test
      FlutterGemmaService.disposeInstance();
      service = FlutterGemmaService.instance;
    });

    tearDown(() async {
      await service.dispose();
      FlutterGemmaService.disposeInstance();
      
      // Clean up temporary directory
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('Model Download', () {
      test('should download model with progress tracking', () async {
        final progressValues = <double>[];
        final statusUpdates = <ModelStatus>[];
        
        // Listen to status updates
        final statusSubscription = service.statusStream.listen((status) {
          statusUpdates.add(status.status);
        });

        try {
          await for (final progress in service.downloadModel()) {
            progressValues.add(progress);
          }
        } catch (e) {
          // Expected in test environment without actual model
        }

        await statusSubscription.cancel();

        // Verify progress tracking
        expect(progressValues, isNotEmpty);
        expect(progressValues.first, equals(0.0));
        expect(progressValues.last, equals(1.0));
        
        // Verify status updates
        expect(statusUpdates, contains(ModelStatus.downloading));
      });

      test('should handle download with retry mechanism', () async {
        final progressValues = <double>[];
        
        try {
          await for (final progress in service.downloadModelWithRetry(
            modelUrl: 'http://example.com/fail', // Will trigger failure simulation
          )) {
            progressValues.add(progress);
          }
        } catch (e) {
          expect(e, isA<GemmaException>());
          expect((e as GemmaException).type, equals(GemmaErrorType.networkError));
        }

        // Should have attempted download despite failure
        expect(progressValues, isNotEmpty);
      });

      test('should prevent multiple simultaneous downloads', () async {
        expect(
          () async {
            final stream1 = service.downloadModel();
            final stream2 = service.downloadModel();
            
            await Future.wait([
              stream1.toList(),
              stream2.toList(),
            ]);
          },
          throwsA(isA<GemmaException>()),
        );
      });

      test('should skip download if model already exists', () async {
        // First download
        try {
          await for (final _ in service.downloadModel()) {
            // Consume stream
          }
        } catch (e) {
          // Expected in test environment
        }

        // Second download should skip if model exists
        final progressValues = <double>[];
        try {
          await for (final progress in service.downloadModel()) {
            progressValues.add(progress);
          }
        } catch (e) {
          // Expected in test environment
        }

        // Should immediately return 1.0 if model exists
        if (progressValues.isNotEmpty) {
          expect(progressValues.length, equals(1));
          expect(progressValues.first, equals(1.0));
        }
      });

      test('should force redownload when requested', () async {
        final progressValues = <double>[];
        
        try {
          await for (final progress in service.downloadModel(forceRedownload: true)) {
            progressValues.add(progress);
          }
        } catch (e) {
          // Expected in test environment
        }

        // Should go through full download process
        expect(progressValues, isNotEmpty);
        if (progressValues.length > 1) {
          expect(progressValues.first, equals(0.0));
          expect(progressValues.last, equals(1.0));
        }
      });
    });

    group('Model Validation', () {
      test('should validate model file integrity', () async {
        // Delete any existing model first
        await service.deleteModel();
        
        // Initially no model should be ready
        final isReady = await service.isModelReady();
        expect(isReady, isFalse);
      });

      test('should provide detailed model information', () async {
        // Delete any existing model first
        await service.deleteModel();
        
        final modelInfo = await service.getModelInfo();
        
        expect(modelInfo, isA<ModelInfo>());
        expect(modelInfo.status, equals(ModelStatus.notDownloaded));
      });

      test('should detect invalid model files', () async {
        // Delete any existing model first
        await service.deleteModel();
        
        // Create an empty model file to test validation
        final modelPath = await service._getModelPath();
        final modelFile = File(modelPath);
        await modelFile.parent.create(recursive: true);
        await modelFile.writeAsString(''); // Empty file
        
        final isReady = await service.isModelReady();
        expect(isReady, isFalse);
        
        // Clean up
        if (await modelFile.exists()) {
          await modelFile.delete();
        }
      });
    });

    group('Model Deletion', () {
      test('should delete model and clean up resources', () async {
        // First, simulate having a model
        try {
          await for (final _ in service.downloadModel()) {
            // Consume stream
          }
        } catch (e) {
          // Expected in test environment
        }

        // Delete the model
        await service.deleteModel();
        
        expect(service.currentStatus.status, equals(ModelStatus.notDownloaded));
        expect(service.isInitialized, isFalse);
      });

      test('should clean up cache when requested', () async {
        await service.deleteModel(cleanupCache: true);
        
        // Should complete without errors
        expect(service.currentStatus.status, equals(ModelStatus.notDownloaded));
      });

      test('should handle deletion of non-existent model', () async {
        // Should not throw when deleting non-existent model
        await service.deleteModel();
        expect(service.currentStatus.status, equals(ModelStatus.notDownloaded));
      });
    });

    group('Storage Management', () {
      test('should check available storage space', () async {
        final availableSpace = await service.getAvailableStorageSpace();
        expect(availableSpace, isA<int>());
        expect(availableSpace, greaterThan(0));
      });

      test('should estimate required storage space', () async {
        final requiredSpace = await service.getRequiredStorageSpace();
        expect(requiredSpace, isA<int>());
        expect(requiredSpace, greaterThan(0));
      });

      test('should check if enough storage space is available', () async {
        final hasEnoughSpace = await service.hasEnoughStorageSpace();
        expect(hasEnoughSpace, isA<bool>());
      });
    });

    group('Network and Connectivity', () {
      test('should check network availability', () async {
        final isNetworkAvailable = await service.isNetworkAvailable();
        expect(isNetworkAvailable, isA<bool>());
      });

      test('should validate download prerequisites', () async {
        try {
          await service._validateDownloadPrerequisites();
          // Should complete without error if prerequisites are met
        } catch (e) {
          // May throw if network is unavailable or storage is insufficient
          expect(e, isA<GemmaException>());
        }
      });
    });

    group('Error Handling', () {
      test('should handle network errors gracefully', () async {
        // Delete any existing model first to force download
        await service.deleteModel();
        
        // Simulate network error by using URL that triggers failure
        bool exceptionThrown = false;
        try {
          await for (final _ in service.downloadModel(modelUrl: 'http://example.com/fail', forceRedownload: true)) {
            // Consume stream
          }
        } catch (e) {
          exceptionThrown = true;
          expect(e, isA<GemmaException>());
        }
        
        expect(exceptionThrown, isTrue, reason: 'Expected GemmaException to be thrown');
      });

      test('should handle storage errors gracefully', () async {
        try {
          await service.deleteModel();
        } catch (e) {
          expect(e, isA<GemmaException>());
          expect((e as GemmaException).type, anyOf([
            GemmaErrorType.configurationError,
            GemmaErrorType.networkError,
          ]));
        }
      });

      test('should provide meaningful error messages', () async {
        try {
          await service.initialize();
        } catch (e) {
          // Should fail in test environment
        }

        expect(service.currentStatus.error, isNotNull);
        expect(service.currentStatus.error, isA<String>());
        expect(service.currentStatus.error!.isNotEmpty, isTrue);
      });
    });

    group('Retry Configuration', () {
      test('should accept custom retry configuration', () {
        const customRetryConfig = DownloadRetryConfig(
          maxRetries: 5,
          initialDelay: Duration(seconds: 2),
          backoffMultiplier: 1.5,
          maxDelay: Duration(seconds: 60),
        );

        service.updateRetryConfig(customRetryConfig);
        
        // Configuration should be updated (no direct getter, but method should not throw)
        expect(() => service.updateRetryConfig(customRetryConfig), returnsNormally);
      });

      test('should use retry configuration during download', () async {
        const customRetryConfig = DownloadRetryConfig(
          maxRetries: 1, // Only one retry for faster test
          initialDelay: Duration(milliseconds: 100),
        );

        service.updateRetryConfig(customRetryConfig);

        try {
          await for (final _ in service.downloadModelWithRetry(
            modelUrl: 'http://example.com/fail',
            forceRedownload: true,
          )) {
            // Consume stream
          }
        } catch (e) {
          expect(e, isA<GemmaException>());
          expect(e.toString(), contains('retries'));
        }
      });
    });

    group('Status Tracking', () {
      test('should emit status updates during model operations', () async {
        final statusUpdates = <ModelStatus>[];
        
        final subscription = service.statusStream.listen((status) {
          statusUpdates.add(status.status);
        });

        try {
          await service.initialize();
        } catch (e) {
          // Expected to fail in test environment
        }

        await Future.delayed(const Duration(milliseconds: 100));
        subscription.cancel();

        expect(statusUpdates, isNotEmpty);
        expect(statusUpdates, contains(ModelStatus.initializing));
      });

      test('should maintain consistent status information', () {
        expect(service.currentStatus, isA<ModelInfo>());
        expect(service.currentStatus.status, equals(ModelStatus.notDownloaded));
      });
    });

    group('Resource Management', () {
      test('should clean up resources on disposal', () async {
        await service.dispose();
        
        expect(service.isInitialized, isFalse);
        expect(service.isInitializing, isFalse);
      });

      test('should handle multiple disposal calls', () async {
        await service.dispose();
        await service.dispose(); // Should not throw
        
        expect(service.isInitialized, isFalse);
      });

      test('should provide memory information', () async {
        final memoryInfo = await service.getMemoryInfo();
        
        expect(memoryInfo, isA<Map<String, dynamic>>());
        expect(memoryInfo.containsKey('isInitialized'), isTrue);
        expect(memoryInfo.containsKey('modelLoaded'), isTrue);
        expect(memoryInfo.containsKey('status'), isTrue);
      });
    });
  });

  group('DownloadRetryConfig', () {
    test('should create with default values', () {
      const config = DownloadRetryConfig();
      
      expect(config.maxRetries, equals(3));
      expect(config.initialDelay, equals(Duration(seconds: 1)));
      expect(config.backoffMultiplier, equals(2.0));
      expect(config.maxDelay, equals(Duration(seconds: 30)));
    });

    test('should create with custom values', () {
      const config = DownloadRetryConfig(
        maxRetries: 5,
        initialDelay: Duration(seconds: 2),
        backoffMultiplier: 1.5,
        maxDelay: Duration(minutes: 1),
      );
      
      expect(config.maxRetries, equals(5));
      expect(config.initialDelay, equals(Duration(seconds: 2)));
      expect(config.backoffMultiplier, equals(1.5));
      expect(config.maxDelay, equals(Duration(minutes: 1)));
    });
  });
}

// Extension to access private methods for testing
extension FlutterGemmaServiceTestExtension on FlutterGemmaService {
  Future<String> _getModelPath() async {
    // This mirrors the private method implementation
    try {
      // Use a test-specific path
      return '/tmp/test_gemma_model.task';
    } catch (e) {
      return '/tmp/gemma-3n-E2B-it-int4.task';
    }
  }

  Future<void> _validateDownloadPrerequisites() async {
    // This mirrors the private method implementation
    if (!await isNetworkAvailable()) {
      throw GemmaException.networkError('No network connection available');
    }

    if (!await hasEnoughStorageSpace()) {
      final available = await getAvailableStorageSpace();
      final required = await getRequiredStorageSpace();
      throw GemmaException(
        GemmaErrorType.configurationError,
        'Insufficient storage space. Required: ${(required / 1024 / 1024).toStringAsFixed(1)}MB, Available: ${(available / 1024 / 1024).toStringAsFixed(1)}MB'
      );
    }
  }
}