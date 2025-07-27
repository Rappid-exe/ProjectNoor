import 'package:flutter_test/flutter_test.dart';
import 'package:noor/models/gemma_exceptions.dart';

void main() {
  group('GemmaErrorType', () {
    test('should have all expected error types', () {
      expect(GemmaErrorType.values, contains(GemmaErrorType.modelNotFound));
      expect(GemmaErrorType.values, contains(GemmaErrorType.modelLoadFailed));
      expect(GemmaErrorType.values, contains(GemmaErrorType.inferenceError));
      expect(GemmaErrorType.values, contains(GemmaErrorType.networkError));
      expect(GemmaErrorType.values, contains(GemmaErrorType.memoryError));
      expect(GemmaErrorType.values, contains(GemmaErrorType.platformNotSupported));
      expect(GemmaErrorType.values, contains(GemmaErrorType.functionCallError));
      expect(GemmaErrorType.values, contains(GemmaErrorType.imageProcessingError));
      expect(GemmaErrorType.values, contains(GemmaErrorType.initializationError));
      expect(GemmaErrorType.values, contains(GemmaErrorType.configurationError));
    });
  });

  group('GemmaException', () {
    test('should create basic exception', () {
      const exception = GemmaException(
        GemmaErrorType.modelNotFound,
        'Model file not found',
      );
      
      expect(exception.type, equals(GemmaErrorType.modelNotFound));
      expect(exception.message, equals('Model file not found'));
      expect(exception.originalError, isNull);
      expect(exception.stackTrace, isNull);
    });

    test('should create exception with original error', () {
      final originalError = Exception('Original error');
      final stackTrace = StackTrace.current;
      
      final exception = GemmaException(
        GemmaErrorType.inferenceError,
        'Inference failed',
        originalError,
        stackTrace,
      );
      
      expect(exception.type, equals(GemmaErrorType.inferenceError));
      expect(exception.message, equals('Inference failed'));
      expect(exception.originalError, equals(originalError));
      expect(exception.stackTrace, equals(stackTrace));
    });

    test('should have meaningful toString', () {
      const exception = GemmaException(
        GemmaErrorType.modelNotFound,
        'Model file not found',
      );
      
      final string = exception.toString();
      expect(string, contains('GemmaException'));
      expect(string, contains('modelNotFound'));
      expect(string, contains('Model file not found'));
    });

    test('should include original error in toString', () {
      final originalError = Exception('Original error');
      final exception = GemmaException(
        GemmaErrorType.inferenceError,
        'Inference failed',
        originalError,
      );
      
      final string = exception.toString();
      expect(string, contains('Original: Exception: Original error'));
    });

    group('Factory constructors', () {
      test('modelNotFound should create correct exception', () {
        final exception = GemmaException.modelNotFound();
        
        expect(exception.type, equals(GemmaErrorType.modelNotFound));
        expect(exception.message, equals('Model not found'));
        expect(exception.originalError, isNull);
      });

      test('modelNotFound with details should include details', () {
        final exception = GemmaException.modelNotFound('File missing');
        
        expect(exception.type, equals(GemmaErrorType.modelNotFound));
        expect(exception.message, equals('Model not found: File missing'));
      });

      test('modelLoadFailed should create correct exception', () {
        final exception = GemmaException.modelLoadFailed();
        
        expect(exception.type, equals(GemmaErrorType.modelLoadFailed));
        expect(exception.message, equals('Failed to load model'));
        expect(exception.originalError, isNull);
      });

      test('modelLoadFailed with details and original error', () {
        final originalError = Exception('Load error');
        final exception = GemmaException.modelLoadFailed('Corrupt file', originalError);
        
        expect(exception.type, equals(GemmaErrorType.modelLoadFailed));
        expect(exception.message, equals('Failed to load model: Corrupt file'));
        expect(exception.originalError, equals(originalError));
      });

      test('inferenceError should create correct exception', () {
        final exception = GemmaException.inferenceError();
        
        expect(exception.type, equals(GemmaErrorType.inferenceError));
        expect(exception.message, equals('Inference failed'));
        expect(exception.originalError, isNull);
      });

      test('inferenceError with details and original error', () {
        final originalError = Exception('GPU error');
        final exception = GemmaException.inferenceError('GPU failure', originalError);
        
        expect(exception.type, equals(GemmaErrorType.inferenceError));
        expect(exception.message, equals('Inference failed: GPU failure'));
        expect(exception.originalError, equals(originalError));
      });

      test('networkError should create correct exception', () {
        final exception = GemmaException.networkError();
        
        expect(exception.type, equals(GemmaErrorType.networkError));
        expect(exception.message, equals('Network error'));
        expect(exception.originalError, isNull);
      });

      test('networkError with details and original error', () {
        final originalError = Exception('Connection timeout');
        final exception = GemmaException.networkError('Timeout', originalError);
        
        expect(exception.type, equals(GemmaErrorType.networkError));
        expect(exception.message, equals('Network error: Timeout'));
        expect(exception.originalError, equals(originalError));
      });

      test('memoryError should create correct exception', () {
        final exception = GemmaException.memoryError();
        
        expect(exception.type, equals(GemmaErrorType.memoryError));
        expect(exception.message, equals('Memory error'));
        expect(exception.originalError, isNull);
      });

      test('memoryError with details', () {
        final exception = GemmaException.memoryError('Out of memory');
        
        expect(exception.type, equals(GemmaErrorType.memoryError));
        expect(exception.message, equals('Memory error: Out of memory'));
      });

      test('initializationError should create correct exception', () {
        final exception = GemmaException.initializationError();
        
        expect(exception.type, equals(GemmaErrorType.initializationError));
        expect(exception.message, equals('Initialization failed'));
        expect(exception.originalError, isNull);
      });

      test('initializationError with details and original error', () {
        final originalError = Exception('Config error');
        final exception = GemmaException.initializationError('Bad config', originalError);
        
        expect(exception.type, equals(GemmaErrorType.initializationError));
        expect(exception.message, equals('Initialization failed: Bad config'));
        expect(exception.originalError, equals(originalError));
      });
    });

    test('should implement Exception interface', () {
      const exception = GemmaException(
        GemmaErrorType.modelNotFound,
        'Test message',
      );
      
      expect(exception, isA<Exception>());
    });
  });
}