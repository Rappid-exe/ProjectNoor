import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/gemma_message.dart';

void main() {
  group('GemmaMessage', () {
    group('TextMessage', () {
      test('should create TextMessage with required parameters', () {
        final timestamp = DateTime.now();
        final message = TextMessage(
          text: 'Hello, world!',
          isUser: true,
          timestamp: timestamp,
          id: 'test-id',
        );

        expect(message.text, equals('Hello, world!'));
        expect(message.isUser, isTrue);
        expect(message.timestamp, equals(timestamp));
        expect(message.id, equals('test-id'));
        expect(message.messageType, equals('text'));
      });

      test('should create TextMessage with default timestamp when not provided', () {
        final beforeCreation = DateTime.now();
        final message = TextMessage(
          text: 'Hello, world!',
          isUser: true,
        );
        final afterCreation = DateTime.now();

        expect(message.timestamp.isAfter(beforeCreation.subtract(const Duration(seconds: 1))), isTrue);
        expect(message.timestamp.isBefore(afterCreation.add(const Duration(seconds: 1))), isTrue);
      });

      test('should serialize and deserialize correctly', () {
        final timestamp = DateTime.now();
        final original = TextMessage(
          text: 'Test message',
          isUser: false,
          timestamp: timestamp,
          id: 'msg-123',
        );

        final json = original.toJson();
        final deserialized = TextMessage.fromJson(json);

        expect(deserialized.text, equals(original.text));
        expect(deserialized.isUser, equals(original.isUser));
        expect(deserialized.timestamp, equals(original.timestamp));
        expect(deserialized.id, equals(original.id));
        expect(deserialized.messageType, equals(original.messageType));
      });

      test('should handle equality correctly', () {
        final timestamp = DateTime.now();
        final message1 = TextMessage(
          text: 'Same message',
          isUser: true,
          timestamp: timestamp,
          id: 'same-id',
        );
        final message2 = TextMessage(
          text: 'Same message',
          isUser: true,
          timestamp: timestamp,
          id: 'same-id',
        );
        final message3 = TextMessage(
          text: 'Different message',
          isUser: true,
          timestamp: timestamp,
          id: 'same-id',
        );

        expect(message1, equals(message2));
        expect(message1, isNot(equals(message3)));
        expect(message1.hashCode, equals(message2.hashCode));
      });

      test('should handle null id correctly', () {
        final message = TextMessage(
          text: 'No ID message',
          isUser: true,
        );

        expect(message.id, isNull);
        
        final json = message.toJson();
        final deserialized = TextMessage.fromJson(json);
        
        expect(deserialized.id, isNull);
      });
    });

    group('ImageMessage', () {
      late Uint8List testImageBytes;

      setUp(() {
        testImageBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      });

      test('should create ImageMessage with required parameters', () {
        final timestamp = DateTime.now();
        final message = ImageMessage(
          text: 'Look at this image',
          imageBytes: testImageBytes,
          isUser: true,
          imageDescription: 'A test image',
          timestamp: timestamp,
          id: 'img-123',
        );

        expect(message.text, equals('Look at this image'));
        expect(message.imageBytes, equals(testImageBytes));
        expect(message.isUser, isTrue);
        expect(message.imageDescription, equals('A test image'));
        expect(message.timestamp, equals(timestamp));
        expect(message.id, equals('img-123'));
        expect(message.messageType, equals('image'));
      });

      test('should serialize and deserialize correctly', () {
        final timestamp = DateTime.now();
        final original = ImageMessage(
          text: 'Image message',
          imageBytes: testImageBytes,
          isUser: false,
          imageDescription: 'Test description',
          timestamp: timestamp,
          id: 'img-456',
        );

        final json = original.toJson();
        final deserialized = ImageMessage.fromJson(json);

        expect(deserialized.text, equals(original.text));
        expect(deserialized.imageBytes, equals(original.imageBytes));
        expect(deserialized.isUser, equals(original.isUser));
        expect(deserialized.imageDescription, equals(original.imageDescription));
        expect(deserialized.timestamp, equals(original.timestamp));
        expect(deserialized.id, equals(original.id));
        expect(deserialized.messageType, equals(original.messageType));
      });

      test('should handle equality correctly with image bytes', () {
        final timestamp = DateTime.now();
        final message1 = ImageMessage(
          text: 'Same image',
          imageBytes: testImageBytes,
          isUser: true,
          timestamp: timestamp,
          id: 'same-id',
        );
        final message2 = ImageMessage(
          text: 'Same image',
          imageBytes: Uint8List.fromList([1, 2, 3, 4, 5]), // Same content
          isUser: true,
          timestamp: timestamp,
          id: 'same-id',
        );
        final message3 = ImageMessage(
          text: 'Same image',
          imageBytes: Uint8List.fromList([1, 2, 3, 4, 6]), // Different content
          isUser: true,
          timestamp: timestamp,
          id: 'same-id',
        );

        expect(message1, equals(message2));
        expect(message1, isNot(equals(message3)));
      });

      test('should handle null imageDescription correctly', () {
        final message = ImageMessage(
          text: 'Image without description',
          imageBytes: testImageBytes,
          isUser: true,
        );

        expect(message.imageDescription, isNull);
        
        final json = message.toJson();
        final deserialized = ImageMessage.fromJson(json);
        
        expect(deserialized.imageDescription, isNull);
      });

      test('should handle empty image bytes', () {
        final emptyBytes = Uint8List(0);
        final message = ImageMessage(
          text: 'Empty image',
          imageBytes: emptyBytes,
          isUser: true,
        );

        expect(message.imageBytes.length, equals(0));
        
        final json = message.toJson();
        final deserialized = ImageMessage.fromJson(json);
        
        expect(deserialized.imageBytes.length, equals(0));
      });
    });

    group('FunctionCallMessage', () {
      test('should create FunctionCallMessage with required parameters', () {
        final timestamp = DateTime.now();
        final arguments = {'param1': 'value1', 'param2': 42};
        final response = {'result': 'success', 'data': 'test'};
        
        final message = FunctionCallMessage(
          functionName: 'test_function',
          arguments: arguments,
          response: response,
          isUser: false,
          timestamp: timestamp,
          id: 'func-123',
        );

        expect(message.functionName, equals('test_function'));
        expect(message.arguments, equals(arguments));
        expect(message.response, equals(response));
        expect(message.isUser, isFalse);
        expect(message.timestamp, equals(timestamp));
        expect(message.id, equals('func-123'));
        expect(message.messageType, equals('function_call'));
        expect(message.text, equals('Function call: test_function'));
      });

      test('should serialize and deserialize correctly', () {
        final timestamp = DateTime.now();
        final arguments = {'param': 'value'};
        final response = {'status': 'ok'};
        
        final original = FunctionCallMessage(
          functionName: 'serialize_test',
          arguments: arguments,
          response: response,
          isUser: false,
          timestamp: timestamp,
          id: 'func-456',
        );

        final json = original.toJson();
        final deserialized = FunctionCallMessage.fromJson(json);

        expect(deserialized.functionName, equals(original.functionName));
        expect(deserialized.arguments, equals(original.arguments));
        expect(deserialized.response, equals(original.response));
        expect(deserialized.isUser, equals(original.isUser));
        expect(deserialized.timestamp, equals(original.timestamp));
        expect(deserialized.id, equals(original.id));
        expect(deserialized.messageType, equals(original.messageType));
      });

      test('should handle null response correctly', () {
        final message = FunctionCallMessage(
          functionName: 'pending_function',
          arguments: {'param': 'value'},
          isUser: false,
        );

        expect(message.response, isNull);
        
        final json = message.toJson();
        final deserialized = FunctionCallMessage.fromJson(json);
        
        expect(deserialized.response, isNull);
      });

      test('should create copy with response using withResponse', () {
        final original = FunctionCallMessage(
          functionName: 'test_function',
          arguments: {'param': 'value'},
          isUser: false,
          id: 'func-789',
        );

        final newResponse = {'result': 'completed'};
        final updated = original.withResponse(newResponse);

        expect(updated.functionName, equals(original.functionName));
        expect(updated.arguments, equals(original.arguments));
        expect(updated.response, equals(newResponse));
        expect(updated.isUser, equals(original.isUser));
        expect(updated.timestamp, equals(original.timestamp));
        expect(updated.id, equals(original.id));
      });

      test('should handle equality correctly', () {
        final timestamp = DateTime.now();
        final arguments = {'param': 'value'};
        final response = {'status': 'ok'};
        
        final message1 = FunctionCallMessage(
          functionName: 'same_function',
          arguments: arguments,
          response: response,
          isUser: false,
          timestamp: timestamp,
          id: 'same-id',
        );
        final message2 = FunctionCallMessage(
          functionName: 'same_function',
          arguments: {'param': 'value'}, // Same content
          response: {'status': 'ok'}, // Same content
          isUser: false,
          timestamp: timestamp,
          id: 'same-id',
        );
        final message3 = FunctionCallMessage(
          functionName: 'different_function',
          arguments: arguments,
          response: response,
          isUser: false,
          timestamp: timestamp,
          id: 'same-id',
        );

        expect(message1, equals(message2));
        expect(message1, isNot(equals(message3)));
      });

      test('should handle complex nested arguments and responses', () {
        final complexArgs = {
          'nested': {
            'level1': {
              'level2': ['item1', 'item2'],
              'number': 42,
            },
          },
          'list': [1, 2, 3],
        };
        final complexResponse = {
          'data': {
            'results': [
              {'id': 1, 'name': 'test1'},
              {'id': 2, 'name': 'test2'},
            ],
          },
        };

        final message = FunctionCallMessage(
          functionName: 'complex_function',
          arguments: complexArgs,
          response: complexResponse,
          isUser: false,
        );

        final json = message.toJson();
        final deserialized = FunctionCallMessage.fromJson(json);

        expect(deserialized.arguments, equals(complexArgs));
        expect(deserialized.response, equals(complexResponse));
      });
    });

    group('GemmaMessage.fromJson', () {
      test('should create correct message type from JSON', () {
        final textJson = {
          'type': 'text',
          'text': 'Hello',
          'isUser': true,
          'timestamp': DateTime.now().toIso8601String(),
          'id': 'text-1',
        };

        final imageJson = {
          'type': 'image',
          'text': 'Image message',
          'isUser': true,
          'timestamp': DateTime.now().toIso8601String(),
          'id': 'img-1',
          'imageBytes': 'AQIDBAU=', // Base64 for [1,2,3,4,5]
          'imageDescription': 'Test image',
        };

        final functionJson = {
          'type': 'function_call',
          'text': 'Function call: test',
          'isUser': false,
          'timestamp': DateTime.now().toIso8601String(),
          'id': 'func-1',
          'functionName': 'test',
          'arguments': {'param': 'value'},
          'response': null,
        };

        final textMessage = GemmaMessage.fromJson(textJson);
        final imageMessage = GemmaMessage.fromJson(imageJson);
        final functionMessage = GemmaMessage.fromJson(functionJson);

        expect(textMessage, isA<TextMessage>());
        expect(imageMessage, isA<ImageMessage>());
        expect(functionMessage, isA<FunctionCallMessage>());
      });

      test('should throw ArgumentError for unknown message type', () {
        final invalidJson = {
          'type': 'unknown',
          'text': 'Invalid message',
          'isUser': true,
          'timestamp': DateTime.now().toIso8601String(),
        };

        expect(
          () => GemmaMessage.fromJson(invalidJson),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });
}