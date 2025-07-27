import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/models/gemma_config.dart';
import '../../lib/models/gemma_message.dart';
import '../../lib/models/gemma_response.dart';
import '../../lib/models/gemma_exceptions.dart';

void main() {
  group('GemmaChat Basic Tests', () {
    group('Configuration', () {
      test('should create GemmaChatConfig with default values', () {
        const config = GemmaChatConfig();
        
        expect(config.temperature, equals(0.8));
        expect(config.randomSeed, equals(1));
        expect(config.topK, equals(1));
        expect(config.supportImage, isFalse);
        expect(config.supportsFunctionCalls, isFalse);
        expect(config.tools, isNull);
      });

      test('should create GemmaChatConfig with custom values', () {
        const config = GemmaChatConfig(
          temperature: 0.5,
          randomSeed: 42,
          topK: 5,
          supportImage: true,
          supportsFunctionCalls: true,
        );
        
        expect(config.temperature, equals(0.5));
        expect(config.randomSeed, equals(42));
        expect(config.topK, equals(5));
        expect(config.supportImage, isTrue);
        expect(config.supportsFunctionCalls, isTrue);
      });

      test('should copy GemmaChatConfig with modified values', () {
        const originalConfig = GemmaChatConfig(temperature: 0.8);
        final newConfig = originalConfig.copyWith(temperature: 0.5, supportImage: true);
        
        expect(newConfig.temperature, equals(0.5));
        expect(newConfig.supportImage, isTrue);
        expect(newConfig.randomSeed, equals(originalConfig.randomSeed)); // Should keep original value
      });
    });

    group('Message Types', () {
      test('should create TextMessage correctly', () {
        final message = TextMessage(
          text: 'Hello, world!',
          isUser: true,
        );

        expect(message.text, equals('Hello, world!'));
        expect(message.isUser, isTrue);
        expect(message.messageType, equals('text'));
        expect(message.timestamp, isA<DateTime>());
      });

      test('should create ImageMessage correctly', () {
        final imageBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
        final message = ImageMessage(
          text: 'What is this?',
          imageBytes: imageBytes,
          isUser: true,
          imageDescription: 'Test image',
        );

        expect(message.text, equals('What is this?'));
        expect(message.imageBytes, equals(imageBytes));
        expect(message.isUser, isTrue);
        expect(message.messageType, equals('image'));
        expect(message.imageDescription, equals('Test image'));
      });

      test('should create FunctionCallMessage correctly', () {
        final message = FunctionCallMessage(
          functionName: 'test_function',
          arguments: {'param1': 'value1', 'param2': 42},
          isUser: false,
        );

        expect(message.functionName, equals('test_function'));
        expect(message.arguments, containsPair('param1', 'value1'));
        expect(message.arguments, containsPair('param2', 42));
        expect(message.isUser, isFalse);
        expect(message.messageType, equals('function_call'));
        expect(message.text, contains('Function call: test_function'));
      });

      test('should serialize and deserialize TextMessage', () {
        final originalMessage = TextMessage(
          text: 'Test message',
          isUser: true,
          id: 'test_id',
        );

        final json = originalMessage.toJson();
        final deserializedMessage = GemmaMessage.fromJson(json) as TextMessage;

        expect(deserializedMessage.text, equals(originalMessage.text));
        expect(deserializedMessage.isUser, equals(originalMessage.isUser));
        expect(deserializedMessage.id, equals(originalMessage.id));
        expect(deserializedMessage.messageType, equals(originalMessage.messageType));
      });

      test('should serialize and deserialize ImageMessage', () {
        final imageBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
        final originalMessage = ImageMessage(
          text: 'Image test',
          imageBytes: imageBytes,
          isUser: true,
          imageDescription: 'Test description',
          id: 'image_id',
        );

        final json = originalMessage.toJson();
        final deserializedMessage = GemmaMessage.fromJson(json) as ImageMessage;

        expect(deserializedMessage.text, equals(originalMessage.text));
        expect(deserializedMessage.imageBytes, equals(originalMessage.imageBytes));
        expect(deserializedMessage.isUser, equals(originalMessage.isUser));
        expect(deserializedMessage.imageDescription, equals(originalMessage.imageDescription));
        expect(deserializedMessage.id, equals(originalMessage.id));
      });

      test('should serialize and deserialize FunctionCallMessage', () {
        final originalMessage = FunctionCallMessage(
          functionName: 'test_func',
          arguments: {'key': 'value'},
          response: {'result': 'success'},
          isUser: false,
          id: 'func_id',
        );

        final json = originalMessage.toJson();
        final deserializedMessage = GemmaMessage.fromJson(json) as FunctionCallMessage;

        expect(deserializedMessage.functionName, equals(originalMessage.functionName));
        expect(deserializedMessage.arguments, equals(originalMessage.arguments));
        expect(deserializedMessage.response, equals(originalMessage.response));
        expect(deserializedMessage.isUser, equals(originalMessage.isUser));
        expect(deserializedMessage.id, equals(originalMessage.id));
      });
    });

    group('Response Types', () {
      test('should create TextResponse correctly', () {
        const response = TextResponse('Hello', isComplete: false);

        expect(response.token, equals('Hello'));
        expect(response.isComplete, isFalse);
        expect(response.responseType, equals('text'));
      });

      test('should create FunctionCallResponse correctly', () {
        const response = FunctionCallResponse(
          'test_function',
          {'param': 'value'},
          callId: 'call_123',
        );

        expect(response.name, equals('test_function'));
        expect(response.args, containsPair('param', 'value'));
        expect(response.callId, equals('call_123'));
        expect(response.responseType, equals('function_call'));
      });

      test('should create ErrorResponse correctly', () {
        const response = ErrorResponse(
          'Something went wrong',
          errorCode: 'ERR_001',
          details: {'context': 'test'},
        );

        expect(response.error, equals('Something went wrong'));
        expect(response.errorCode, equals('ERR_001'));
        expect(response.details, containsPair('context', 'test'));
        expect(response.responseType, equals('error'));
      });

      test('should serialize and deserialize TextResponse', () {
        const originalResponse = TextResponse('Token', isComplete: true);

        final json = originalResponse.toJson();
        final deserializedResponse = GemmaResponse.fromJson(json) as TextResponse;

        expect(deserializedResponse.token, equals(originalResponse.token));
        expect(deserializedResponse.isComplete, equals(originalResponse.isComplete));
        expect(deserializedResponse.responseType, equals(originalResponse.responseType));
      });

      test('should serialize and deserialize FunctionCallResponse', () {
        const originalResponse = FunctionCallResponse(
          'func_name',
          {'arg': 'val'},
          callId: 'id_123',
        );

        final json = originalResponse.toJson();
        final deserializedResponse = GemmaResponse.fromJson(json) as FunctionCallResponse;

        expect(deserializedResponse.name, equals(originalResponse.name));
        expect(deserializedResponse.args, equals(originalResponse.args));
        expect(deserializedResponse.callId, equals(originalResponse.callId));
      });

      test('should serialize and deserialize ErrorResponse', () {
        const originalResponse = ErrorResponse(
          'Error message',
          errorCode: 'CODE',
          details: {'info': 'data'},
        );

        final json = originalResponse.toJson();
        final deserializedResponse = GemmaResponse.fromJson(json) as ErrorResponse;

        expect(deserializedResponse.error, equals(originalResponse.error));
        expect(deserializedResponse.errorCode, equals(originalResponse.errorCode));
        expect(deserializedResponse.details, equals(originalResponse.details));
      });
    });

    group('StreamingResponseHandler', () {
      test('should handle streaming tokens correctly', () {
        final handler = StreamingResponseHandler();

        expect(handler.completeText, isEmpty);
        expect(handler.tokens, isEmpty);
        expect(handler.isComplete, isFalse);

        handler.addToken(const TextResponse('Hello', isComplete: false));
        handler.addToken(const TextResponse(' world', isComplete: false));
        handler.addToken(const TextResponse('!', isComplete: true));

        expect(handler.completeText, equals('Hello world!'));
        expect(handler.tokens, hasLength(3));
        expect(handler.isComplete, isTrue);
      });

      test('should convert to complete response', () {
        final handler = StreamingResponseHandler();
        handler.addToken(const TextResponse('Test', isComplete: false));
        handler.addToken(const TextResponse(' message', isComplete: true));

        final completeResponse = handler.toCompleteResponse();

        expect(completeResponse.token, equals('Test message'));
        expect(completeResponse.isComplete, isTrue);
      });

      test('should clear handler correctly', () {
        final handler = StreamingResponseHandler();
        handler.addToken(const TextResponse('Test', isComplete: false));

        expect(handler.completeText, isNotEmpty);
        expect(handler.tokens, isNotEmpty);

        handler.clear();

        expect(handler.completeText, isEmpty);
        expect(handler.tokens, isEmpty);
        expect(handler.isComplete, isFalse);
      });
    });

    group('Exception Types', () {
      test('should create GemmaException with correct properties', () {
        const exception = GemmaException(
          GemmaErrorType.invalidInput,
          'Invalid input provided',
        );

        expect(exception.type, equals(GemmaErrorType.invalidInput));
        expect(exception.message, equals('Invalid input provided'));
        expect(exception.originalError, isNull);
      });

      test('should create GemmaException with original error', () {
        final originalError = Exception('Original error');
        final exception = GemmaException(
          GemmaErrorType.inferenceError,
          'Inference failed',
          originalError,
        );

        expect(exception.type, equals(GemmaErrorType.inferenceError));
        expect(exception.message, equals('Inference failed'));
        expect(exception.originalError, equals(originalError));
      });

      test('should create factory exceptions correctly', () {
        final modelNotFound = GemmaException.modelNotFound('Model file missing');
        expect(modelNotFound.type, equals(GemmaErrorType.modelNotFound));
        expect(modelNotFound.message, contains('Model not found'));
        expect(modelNotFound.message, contains('Model file missing'));

        final modelLoadFailed = GemmaException.modelLoadFailed('Load error');
        expect(modelLoadFailed.type, equals(GemmaErrorType.modelLoadFailed));
        expect(modelLoadFailed.message, contains('Failed to load model'));

        final inferenceError = GemmaException.inferenceError('Inference error');
        expect(inferenceError.type, equals(GemmaErrorType.inferenceError));
        expect(inferenceError.message, contains('Inference failed'));

        final networkError = GemmaException.networkError('Network issue');
        expect(networkError.type, equals(GemmaErrorType.networkError));
        expect(networkError.message, contains('Network error'));

        final memoryError = GemmaException.memoryError('Out of memory');
        expect(memoryError.type, equals(GemmaErrorType.memoryError));
        expect(memoryError.message, contains('Memory error'));

        final initError = GemmaException.initializationError('Init failed');
        expect(initError.type, equals(GemmaErrorType.initializationError));
        expect(initError.message, contains('Initialization failed'));
      });

      test('should have meaningful toString representation', () {
        const exception = GemmaException(
          GemmaErrorType.configurationError,
          'Config is invalid',
        );

        final stringRep = exception.toString();
        expect(stringRep, contains('GemmaException'));
        expect(stringRep, contains('configurationError'));
        expect(stringRep, contains('Config is invalid'));
      });
    });

    group('Message Equality', () {
      test('should compare TextMessages correctly', () {
        final message1 = TextMessage(
          text: 'Hello',
          isUser: true,
          timestamp: DateTime(2024, 1, 1),
          id: 'id1',
        );

        final message2 = TextMessage(
          text: 'Hello',
          isUser: true,
          timestamp: DateTime(2024, 1, 1),
          id: 'id1',
        );

        final message3 = TextMessage(
          text: 'Hi',
          isUser: true,
          timestamp: DateTime(2024, 1, 1),
          id: 'id1',
        );

        expect(message1, equals(message2));
        expect(message1, isNot(equals(message3)));
        expect(message1.hashCode, equals(message2.hashCode));
      });

      test('should compare ImageMessages correctly', () {
        final imageBytes1 = Uint8List.fromList([1, 2, 3]);
        final imageBytes2 = Uint8List.fromList([1, 2, 3]);
        final imageBytes3 = Uint8List.fromList([4, 5, 6]);

        final message1 = ImageMessage(
          text: 'Image',
          imageBytes: imageBytes1,
          isUser: true,
          timestamp: DateTime(2024, 1, 1),
        );

        final message2 = ImageMessage(
          text: 'Image',
          imageBytes: imageBytes2,
          isUser: true,
          timestamp: DateTime(2024, 1, 1),
        );

        final message3 = ImageMessage(
          text: 'Image',
          imageBytes: imageBytes3,
          isUser: true,
          timestamp: DateTime(2024, 1, 1),
        );

        expect(message1, equals(message2));
        expect(message1, isNot(equals(message3)));
      });

      test('should compare FunctionCallMessages correctly', () {
        final message1 = FunctionCallMessage(
          functionName: 'func',
          arguments: {'key': 'value'},
          response: {'result': 'ok'},
          isUser: false,
          timestamp: DateTime(2024, 1, 1),
        );

        final message2 = FunctionCallMessage(
          functionName: 'func',
          arguments: {'key': 'value'},
          response: {'result': 'ok'},
          isUser: false,
          timestamp: DateTime(2024, 1, 1),
        );

        final message3 = FunctionCallMessage(
          functionName: 'func',
          arguments: {'key': 'different'},
          response: {'result': 'ok'},
          isUser: false,
          timestamp: DateTime(2024, 1, 1),
        );

        expect(message1, equals(message2));
        expect(message1, isNot(equals(message3)));
      });
    });
  });
}