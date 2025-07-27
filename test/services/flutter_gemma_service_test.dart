import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor/models/gemma_config.dart';
import 'package:noor/models/gemma_status.dart';
import 'package:noor/models/gemma_exceptions.dart';
import 'package:noor/services/flutter_gemma_service.dart';

void main() {
  group('FlutterGemmaService', () {
    late FlutterGemmaService service;

    setUpAll(() {
      // Initialize Flutter binding for tests
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      // Reset singleton for each test
      FlutterGemmaService.disposeInstance();
      service = FlutterGemmaService.instance;
    });

    tearDown(() async {
      await service.dispose();
      FlutterGemmaService.disposeInstance();
    });

    group('Singleton Pattern', () {
      test('should return the same instance', () {
        final instance1 = FlutterGemmaService.instance;
        final instance2 = FlutterGemmaService.instance;
        
        expect(instance1, same(instance2));
      });

      test('should create new instance after disposal', () {
        final instance1 = FlutterGemmaService.instance;
        FlutterGemmaService.disposeInstance();
        final instance2 = FlutterGemmaService.instance;
        
        expect(instance1, isNot(same(instance2)));
      });
    });

    group('Initialization', () {
      test('should start with not initialized state', () {
        expect(service.isInitialized, isFalse);
        expect(service.isInitializing, isFalse);
        expect(service.currentStatus.status, equals(ModelStatus.notDownloaded));
      });

      test('should use default configuration when none provided', () {
        final config = service.config;
        
        expect(config.modelType, equals('gemmaIt'));
        expect(config.backend, equals('gpu'));
        expect(config.maxTokens, equals(4096));
        expect(config.supportImage, isFalse);
        expect(config.maxNumImages, equals(1));
        expect(config.tools, isNull);
      });

      test('should accept custom configuration', () async {
        const customConfig = GemmaModelConfig(
          modelType: 'gemmaIt',
          backend: 'cpu',
          maxTokens: 2048,
          supportImage: true,
          maxNumImages: 2,
        );

        // This will fail in test environment due to missing model file
        // but we can test that the config is accepted
        try {
          await service.initialize(customConfig);
        } catch (e) {
          // Expected to fail in test environment
        }

        expect(service.config.backend, equals('cpu'));
        expect(service.config.maxTokens, equals(2048));
        expect(service.config.supportImage, isTrue);
        expect(service.config.maxNumImages, equals(2));
      });

      test('should return false when model is not ready', () async {
        final result = await service.initialize();
        expect(result, isFalse);
        expect(service.isInitialized, isFalse);
      });

      test('should handle initialization errors gracefully', () async {
        // This should fail gracefully since model file doesn't exist
        final result = await service.initialize();
        
        expect(result, isFalse);
        expect(service.currentStatus.status, equals(ModelStatus.error));
        expect(service.currentStatus.error, isNotNull);
      });

      test('should prevent multiple simultaneous initializations', () async {
        // Start two initializations simultaneously
        final future1 = service.initialize();
        final future2 = service.initialize();

        final results = await Future.wait([future1, future2]);
        
        // Both should return the same result
        expect(results[0], equals(results[1]));
      });
    });

    group('Model Management', () {
      test('should check model readiness correctly', () async {
        final isReady = await service.isModelReady();
        expect(isReady, isFalse); // No model file in test environment
      });

      test('should provide detailed model information', () async {
        final modelInfo = await service.getModelInfo();
        expect(modelInfo, isA<ModelInfo>());
        expect(modelInfo.status, equals(ModelStatus.notDownloaded));
      });

      test('should handle download progress', () async {
        final progressValues = <double>[];
        
        try {
          await for (final progress in service.downloadModel()) {
            progressValues.add(progress);
          }
        } catch (e) {
          // Expected in test environment
        }

        expect(progressValues, isNotEmpty);
        expect(progressValues.first, equals(0.0));
        expect(progressValues.last, equals(1.0));
      });

      test('should handle download with retry mechanism', () async {
        final progressValues = <double>[];
        
        try {
          await for (final progress in service.downloadModelWithRetry()) {
            progressValues.add(progress);
          }
        } catch (e) {
          // Expected in test environment
        }

        expect(progressValues, isNotEmpty);
      });

      test('should prevent multiple simultaneous downloads', () async {
        // Force redownload to ensure we actually download
        final stream1 = service.downloadModel(forceRedownload: true);
        
        // Start consuming to trigger the download
        final subscription = stream1.listen((_) {});
        
        // Small delay to ensure first download has started
        await Future.delayed(const Duration(milliseconds: 50));
        
        // Try to start second download - should throw
        bool exceptionThrown = false;
        try {
          final stream2 = service.downloadModel(forceRedownload: true);
          await stream2.first;
        } catch (e) {
          exceptionThrown = true;
          expect(e, isA<GemmaException>());
          expect((e as GemmaException).type, equals(GemmaErrorType.configurationError));
        }
        
        expect(exceptionThrown, isTrue, reason: 'Expected GemmaException to be thrown');
        
        subscription.cancel();
      });

      test('should handle model deletion', () async {
        await service.deleteModel();
        expect(service.currentStatus.status, equals(ModelStatus.notDownloaded));
      });

      test('should handle model deletion with cache cleanup', () async {
        await service.deleteModel(cleanupCache: true);
        expect(service.currentStatus.status, equals(ModelStatus.notDownloaded));
      });

      test('should check storage space requirements', () async {
        final availableSpace = await service.getAvailableStorageSpace();
        final requiredSpace = await service.getRequiredStorageSpace();
        final hasEnoughSpace = await service.hasEnoughStorageSpace();
        
        expect(availableSpace, isA<int>());
        expect(requiredSpace, isA<int>());
        expect(hasEnoughSpace, isA<bool>());
      });

      test('should check network availability', () async {
        final isNetworkAvailable = await service.isNetworkAvailable();
        expect(isNetworkAvailable, isA<bool>());
      });

      test('should update retry configuration', () {
        const customConfig = DownloadRetryConfig(
          maxRetries: 5,
          initialDelay: Duration(seconds: 2),
        );
        
        expect(() => service.updateRetryConfig(customConfig), returnsNormally);
      });
    });

    group('Session Management', () {
      test('should throw exception when creating chat without initialization', () async {
        expect(
          () async => await service.createChat(),
          throwsA(isA<GemmaException>()),
        );
      });

      test('should throw exception when creating session without initialization', () async {
        expect(
          () async => await service.createSession(),
          throwsA(isA<GemmaException>()),
        );
      });

      test('should accept chat configuration parameters', () async {
        // This will throw since service is not initialized, but we can test parameter acceptance
        try {
          await service.createChat(
            temperature: 0.5,
            randomSeed: 42,
            topK: 5,
            supportImage: true,
          );
        } catch (e) {
          expect(e, isA<GemmaException>());
          expect((e as GemmaException).type, equals(GemmaErrorType.initializationError));
        }
      });

      test('should accept session configuration parameters', () async {
        // This will throw since service is not initialized, but we can test parameter acceptance
        try {
          await service.createSession(
            temperature: 0.7,
            randomSeed: 123,
            topK: 3,
          );
        } catch (e) {
          expect(e, isA<GemmaException>());
          expect((e as GemmaException).type, equals(GemmaErrorType.initializationError));
        }
      });
    });

    group('Configuration Updates', () {
      test('should update configuration without reinitialization for non-critical changes', () async {
        const newConfig = GemmaModelConfig(
          modelType: 'gemmaIt', // Same as default
          backend: 'gpu', // Same as default
          maxTokens: 4096, // Same as default
          supportImage: false, // Same as default
          maxNumImages: 1, // Same as default
        );

        await service.updateConfig(newConfig);
        expect(service.config.modelType, equals(newConfig.modelType));
        expect(service.config.backend, equals(newConfig.backend));
      });

      test('should identify when reinitialization is required', () async {
        const newConfig = GemmaModelConfig(
          modelType: 'gemmaIt',
          backend: 'cpu', // Different from default
          maxTokens: 2048, // Different from default
        );

        // This will attempt reinitialization but fail due to missing model
        try {
          await service.updateConfig(newConfig);
        } catch (e) {
          // Expected in test environment
        }

        expect(service.config.backend, equals('cpu'));
        expect(service.config.maxTokens, equals(2048));
      });
    });

    group('Status Tracking', () {
      test('should emit status updates through stream', () async {
        final statusUpdates = <ModelStatus>[];
        
        final subscription = service.statusStream.listen((status) {
          statusUpdates.add(status.status);
        });

        // Trigger some status changes
        try {
          await service.initialize();
        } catch (e) {
          // Expected to fail in test environment
        }

        await Future.delayed(const Duration(milliseconds: 100));
        subscription.cancel();

        expect(statusUpdates, contains(ModelStatus.initializing));
        expect(statusUpdates, contains(ModelStatus.error));
      });

      test('should maintain current status correctly', () {
        expect(service.currentStatus.status, equals(ModelStatus.notDownloaded));
        expect(service.currentStatus.downloadProgress, isNull);
        expect(service.currentStatus.error, isNull);
      });
    });

    group('Error Handling', () {
      test('should handle initialization errors gracefully', () async {
        final result = await service.initialize();
        
        expect(result, isFalse);
        expect(service.currentStatus.status, equals(ModelStatus.error));
        expect(service.currentStatus.error, isNotNull);
      });

      test('should handle disposal errors gracefully', () async {
        // Should not throw even if there's nothing to dispose
        await service.dispose();
        expect(service.isInitialized, isFalse);
      });

      test('should handle multiple disposal calls', () async {
        await service.dispose();
        await service.dispose(); // Should not throw
        expect(service.isInitialized, isFalse);
      });
    });

    group('Resource Management', () {
      test('should clean up resources on disposal', () async {
        await service.dispose();
        
        expect(service.isInitialized, isFalse);
        expect(service.isInitializing, isFalse);
        expect(service.currentStatus.status, equals(ModelStatus.notDownloaded));
      });

      test('should handle disposal of uninitialized service', () async {
        // Should not throw
        await service.dispose();
        expect(service.isInitialized, isFalse);
      });

      test('should provide memory information', () async {
        final memoryInfo = await service.getMemoryInfo();
        
        expect(memoryInfo, isA<Map<String, dynamic>>());
        expect(memoryInfo.containsKey('isInitialized'), isTrue);
        expect(memoryInfo.containsKey('modelLoaded'), isTrue);
        expect(memoryInfo.containsKey('status'), isTrue);
      });

      test('should check GPU acceleration availability', () async {
        final isGpuAvailable = await service.isGpuAccelerationAvailable();
        
        expect(isGpuAvailable, isA<bool>());
        // Should return true for default GPU backend
        expect(isGpuAvailable, isTrue);
      });

      test('should handle resource optimization', () async {
        // Should not throw even if service is not initialized
        await service.optimizeResources();
        
        // No specific assertions as this is a placeholder implementation
        expect(service.isInitialized, isFalse);
      });
    });
  });

  group('GemmaModelConfig', () {
    test('should create with default values', () {
      const config = GemmaModelConfig();
      
      expect(config.modelType, equals('gemmaIt'));
      expect(config.backend, equals('gpu'));
      expect(config.maxTokens, equals(4096));
      expect(config.supportImage, isFalse);
      expect(config.maxNumImages, equals(1));
      expect(config.tools, isNull);
    });

    test('should create copy with modified values', () {
      const original = GemmaModelConfig();
      final copy = original.copyWith(
        backend: 'cpu',
        maxTokens: 2048,
        supportImage: true,
      );
      
      expect(copy.backend, equals('cpu'));
      expect(copy.maxTokens, equals(2048));
      expect(copy.supportImage, isTrue);
      expect(copy.modelType, equals(original.modelType)); // Unchanged
    });

    test('should have meaningful toString', () {
      const config = GemmaModelConfig();
      final string = config.toString();
      
      expect(string, contains('GemmaModelConfig'));
      expect(string, contains('modelType'));
      expect(string, contains('backend'));
    });
  });

  group('GemmaChatConfig', () {
    test('should create with default values', () {
      const config = GemmaChatConfig();
      
      expect(config.temperature, equals(0.8));
      expect(config.randomSeed, equals(1));
      expect(config.topK, equals(1));
      expect(config.supportImage, isFalse);
      expect(config.tools, isNull);
      expect(config.supportsFunctionCalls, isFalse);
    });

    test('should create copy with modified values', () {
      const original = GemmaChatConfig();
      final copy = original.copyWith(
        temperature: 0.5,
        topK: 5,
        supportImage: true,
        supportsFunctionCalls: true,
      );
      
      expect(copy.temperature, equals(0.5));
      expect(copy.topK, equals(5));
      expect(copy.supportImage, isTrue);
      expect(copy.supportsFunctionCalls, isTrue);
      expect(copy.randomSeed, equals(original.randomSeed)); // Unchanged
    });

    test('should have meaningful toString', () {
      const config = GemmaChatConfig();
      final string = config.toString();
      
      expect(string, contains('GemmaChatConfig'));
      expect(string, contains('temperature'));
      expect(string, contains('supportImage'));
    });
  });
}