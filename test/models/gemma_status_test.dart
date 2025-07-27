import 'package:flutter_test/flutter_test.dart';
import 'package:noor/models/gemma_status.dart';

void main() {
  group('ModelStatus', () {
    test('should have all expected values', () {
      expect(ModelStatus.values, contains(ModelStatus.notDownloaded));
      expect(ModelStatus.values, contains(ModelStatus.downloading));
      expect(ModelStatus.values, contains(ModelStatus.ready));
      expect(ModelStatus.values, contains(ModelStatus.error));
      expect(ModelStatus.values, contains(ModelStatus.initializing));
      expect(ModelStatus.values, contains(ModelStatus.initialized));
    });
  });

  group('ModelInfo', () {
    test('should create with required status', () {
      const info = ModelInfo(status: ModelStatus.ready);
      
      expect(info.status, equals(ModelStatus.ready));
      expect(info.downloadProgress, isNull);
      expect(info.error, isNull);
      expect(info.modelSize, isNull);
      expect(info.modelPath, isNull);
    });

    test('should create with all parameters', () {
      const info = ModelInfo(
        status: ModelStatus.downloading,
        downloadProgress: 0.5,
        error: 'Test error',
        modelSize: 1024,
        modelPath: '/path/to/model',
      );
      
      expect(info.status, equals(ModelStatus.downloading));
      expect(info.downloadProgress, equals(0.5));
      expect(info.error, equals('Test error'));
      expect(info.modelSize, equals(1024));
      expect(info.modelPath, equals('/path/to/model'));
    });

    test('should create copy with modified values', () {
      const original = ModelInfo(
        status: ModelStatus.downloading,
        downloadProgress: 0.3,
      );
      
      final copy = original.copyWith(
        status: ModelStatus.ready,
        downloadProgress: 1.0,
        modelSize: 2048,
      );
      
      expect(copy.status, equals(ModelStatus.ready));
      expect(copy.downloadProgress, equals(1.0));
      expect(copy.modelSize, equals(2048));
      expect(copy.error, isNull); // Unchanged from original
    });

    test('should have meaningful toString', () {
      const info = ModelInfo(
        status: ModelStatus.ready,
        modelSize: 1024,
      );
      
      final string = info.toString();
      expect(string, contains('ModelInfo'));
      expect(string, contains('ready'));
      expect(string, contains('1024'));
    });

    test('should implement equality correctly', () {
      const info1 = ModelInfo(
        status: ModelStatus.ready,
        downloadProgress: 0.5,
        modelSize: 1024,
      );
      
      const info2 = ModelInfo(
        status: ModelStatus.ready,
        downloadProgress: 0.5,
        modelSize: 1024,
      );
      
      const info3 = ModelInfo(
        status: ModelStatus.error,
        downloadProgress: 0.5,
        modelSize: 1024,
      );
      
      expect(info1, equals(info2));
      expect(info1, isNot(equals(info3)));
      expect(info1.hashCode, equals(info2.hashCode));
      expect(info1.hashCode, isNot(equals(info3.hashCode)));
    });

    test('should handle null values in equality', () {
      const info1 = ModelInfo(status: ModelStatus.ready);
      const info2 = ModelInfo(status: ModelStatus.ready);
      const info3 = ModelInfo(
        status: ModelStatus.ready,
        downloadProgress: 0.5,
      );
      
      expect(info1, equals(info2));
      expect(info1, isNot(equals(info3)));
    });

    test('should be identical to itself', () {
      const info = ModelInfo(status: ModelStatus.ready);
      expect(info, same(info));
    });
  });
}