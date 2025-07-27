import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/gemma_message.dart';
import '../../lib/models/gemma_response.dart';
import '../../lib/utils/message_serializer.dart';

void main() {
  group('MessageSerializer', () {
    late List<GemmaMessage> testMessages;
    late List<GemmaResponse> testResponses;

    setUp(() {
      final timestamp = DateTime.now();
      testMessages = [
        TextMessage(
          text: 'Hello, world!',
          isUser: true,
          timestamp: timestamp,
          id: 'msg-1',
        ),
        ImageMessage(
          text: 'Look at this image',
          imageBytes: Uint8List.fromList([1, 2, 3, 4, 5]),
          isUser: true,
          imageDescription: 'Test image',
          timestamp: timestamp.add(const Duration(minutes: 1)),
          id: 'msg-2',
        ),
        FunctionCallMessage(
          functionName: 'test_function',
          arguments: {'param': 'value'},
          response: {'result': 'success'},
          isUser: false,
          timestamp: timestamp.add(const Duration(minutes: 2)),
          id: 'msg-3',
        ),
      ];

      testResponses = [
        const TextResponse('Hello'),
        const TextResponse(' world', isComplete: true),
        const FunctionCallResponse('test_func', {'arg': 'val'}),
        const ErrorResponse('Test error', errorCode: 'TEST_ERROR'),
      ];
    });

    group('Message Serialization', () {
      test('should serialize and deserialize list of messages correctly', () {
        final serialized = MessageSerializer.serializeMessages(testMessages);
        final deserialized = MessageSerializer.deserializeMessages(serialized);

        expect(deserialized.length, equals(testMessages.length));
        for (int i = 0; i < testMessages.length; i++) {
          expect(deserialized[i], equals(testMessages[i]));
        }
      });

      test('should serialize and deserialize single message correctly', () {
        final message = testMessages.first;
        final serialized = MessageSerializer.serializeMessage(message);
        final deserialized = MessageSerializer.deserializeMessage(serialized);

        expect(deserialized, equals(message));
      });

      test('should handle empty message list', () {
        final emptyList = <GemmaMessage>[];
        final serialized = MessageSerializer.serializeMessages(emptyList);
        final deserialized = MessageSerializer.deserializeMessages(serialized);

        expect(deserialized, isEmpty);
      });

      test('should handle TextMessage serialization', () {
        final textMessage = TextMessage(
          text: 'Test text message',
          isUser: true,
          timestamp: DateTime.now(),
          id: 'text-1',
        );

        final serialized = MessageSerializer.serializeMessage(textMessage);
        final deserialized = MessageSerializer.deserializeMessage(serialized);

        expect(deserialized, isA<TextMessage>());
        expect(deserialized, equals(textMessage));
      });

      test('should handle ImageMessage serialization with large image', () {
        final largeImageBytes = Uint8List.fromList(List.generate(1000, (i) => i % 256));
        final imageMessage = ImageMessage(
          text: 'Large image message',
          imageBytes: largeImageBytes,
          isUser: true,
          imageDescription: 'Large test image',
          timestamp: DateTime.now(),
          id: 'img-large',
        );

        final serialized = MessageSerializer.serializeMessage(imageMessage);
        final deserialized = MessageSerializer.deserializeMessage(serialized);

        expect(deserialized, isA<ImageMessage>());
        expect(deserialized, equals(imageMessage));
        expect((deserialized as ImageMessage).imageBytes.length, equals(1000));
      });

      test('should handle FunctionCallMessage serialization with complex data', () {
        final complexArgs = {
          'nested': {
            'array': [1, 2, 3],
            'object': {'key': 'value'},
          },
          'boolean': true,
          'number': 42,
        };
        final complexResponse = {
          'status': 'success',
          'data': {
            'results': ['item1', 'item2'],
            'count': 2,
          },
        };

        final functionMessage = FunctionCallMessage(
          functionName: 'complex_function',
          arguments: complexArgs,
          response: complexResponse,
          isUser: false,
          timestamp: DateTime.now(),
          id: 'func-complex',
        );

        final serialized = MessageSerializer.serializeMessage(functionMessage);
        final deserialized = MessageSerializer.deserializeMessage(serialized);

        expect(deserialized, isA<FunctionCallMessage>());
        expect(deserialized, equals(functionMessage));
      });
    });

    group('Response Serialization', () {
      test('should serialize and deserialize list of responses correctly', () {
        final serialized = MessageSerializer.serializeResponses(testResponses);
        final deserialized = MessageSerializer.deserializeResponses(serialized);

        expect(deserialized.length, equals(testResponses.length));
        for (int i = 0; i < testResponses.length; i++) {
          expect(deserialized[i], equals(testResponses[i]));
        }
      });

      test('should serialize and deserialize single response correctly', () {
        final response = testResponses.first;
        final serialized = MessageSerializer.serializeResponse(response);
        final deserialized = MessageSerializer.deserializeResponse(serialized);

        expect(deserialized, equals(response));
      });

      test('should handle empty response list', () {
        final emptyList = <GemmaResponse>[];
        final serialized = MessageSerializer.serializeResponses(emptyList);
        final deserialized = MessageSerializer.deserializeResponses(serialized);

        expect(deserialized, isEmpty);
      });
    });

    group('Conversation History', () {
      test('should convert messages to conversation history format', () {
        final history = MessageSerializer.messagesToConversationHistory(testMessages);

        expect(history.length, equals(testMessages.length));

        // Check text message
        expect(history[0]['role'], equals('user'));
        expect(history[0]['content'], equals('Hello, world!'));
        expect(history[0]['type'], equals('text'));

        // Check image message
        expect(history[1]['role'], equals('user'));
        expect(history[1]['content'], equals('Look at this image'));
        expect(history[1]['type'], equals('image'));
        expect(history[1]['hasImage'], isTrue);
        expect(history[1]['imageDescription'], equals('Test image'));

        // Check function call message
        expect(history[2]['role'], equals('assistant'));
        expect(history[2]['content'], equals('Function call: test_function'));
        expect(history[2]['type'], equals('function_call'));
        expect(history[2]['functionName'], equals('test_function'));
        expect(history[2]['arguments'], equals({'param': 'value'}));
        expect(history[2]['response'], equals({'result': 'success'}));
      });

      test('should handle empty message list for conversation history', () {
        final history = MessageSerializer.messagesToConversationHistory([]);
        expect(history, isEmpty);
      });
    });

    group('Conversation Summary', () {
      test('should create conversation summary correctly', () {
        final summary = MessageSerializer.createConversationSummary(testMessages);

        expect(summary['totalMessages'], equals(3));
        expect(summary['messageTypes']['text'], equals(1));
        expect(summary['messageTypes']['image'], equals(1));
        expect(summary['messageTypes']['function_call'], equals(1));
        expect(summary['participants']['user'], equals(2));
        expect(summary['participants']['assistant'], equals(1));
        expect(summary['firstMessage'], isNotNull);
        expect(summary['lastMessage'], isNotNull);
        expect(summary['estimatedTokens'], isA<int>());
        expect(summary['estimatedTokens'], greaterThan(0));
      });

      test('should handle empty message list for summary', () {
        final summary = MessageSerializer.createConversationSummary([]);

        expect(summary['totalMessages'], equals(0));
        expect(summary['messageTypes']['text'], equals(0));
        expect(summary['messageTypes']['image'], equals(0));
        expect(summary['messageTypes']['function_call'], equals(0));
        expect(summary['participants']['user'], equals(0));
        expect(summary['participants']['assistant'], equals(0));
        expect(summary['firstMessage'], isNull);
        expect(summary['lastMessage'], isNull);
        expect(summary['estimatedTokens'], equals(0));
      });

      test('should estimate tokens reasonably', () {
        final longTextMessage = TextMessage(
          text: 'This is a very long message that should have more tokens than a short message',
          isUser: true,
        );
        final shortTextMessage = TextMessage(
          text: 'Short',
          isUser: true,
        );

        final longSummary = MessageSerializer.createConversationSummary([longTextMessage]);
        final shortSummary = MessageSerializer.createConversationSummary([shortTextMessage]);

        expect(longSummary['estimatedTokens'], greaterThan(shortSummary['estimatedTokens']));
      });
    });

    group('Validation', () {
      test('should validate correct messages', () {
        for (final message in testMessages) {
          expect(MessageSerializer.validateMessage(message), isTrue);
        }
      });

      test('should validate correct responses', () {
        for (final response in testResponses) {
          expect(MessageSerializer.validateResponse(response), isTrue);
        }
      });

      test('should reject message with empty text', () {
        final invalidMessage = TextMessage(
          text: '',
          isUser: true,
        );

        expect(MessageSerializer.validateMessage(invalidMessage), isFalse);
      });

      test('should reject ImageMessage with empty image bytes', () {
        final invalidImageMessage = ImageMessage(
          text: 'Valid text',
          imageBytes: Uint8List(0),
          isUser: true,
        );

        expect(MessageSerializer.validateMessage(invalidImageMessage), isFalse);
      });

      test('should reject FunctionCallMessage with empty function name', () {
        final invalidFunctionMessage = FunctionCallMessage(
          functionName: '',
          arguments: {'param': 'value'},
          isUser: false,
        );

        expect(MessageSerializer.validateMessage(invalidFunctionMessage), isFalse);
      });

      test('should reject TextResponse with empty token', () {
        const invalidResponse = TextResponse('');

        expect(MessageSerializer.validateResponse(invalidResponse), isFalse);
      });

      test('should reject FunctionCallResponse with empty name', () {
        final invalidResponse = FunctionCallResponse('', {'param': 'value'});

        expect(MessageSerializer.validateResponse(invalidResponse), isFalse);
      });

      test('should reject ErrorResponse with empty error', () {
        const invalidResponse = ErrorResponse('');

        expect(MessageSerializer.validateResponse(invalidResponse), isFalse);
      });
    });

    group('Backup and Restore', () {
      test('should create and restore message backup correctly', () {
        final backup = MessageSerializer.createMessageBackup(testMessages);

        expect(backup['version'], equals('1.0'));
        expect(backup['messageCount'], equals(testMessages.length));
        expect(backup['timestamp'], isNotNull);
        expect(backup['messages'], isA<List>());
        expect(backup['summary'], isA<Map>());

        final restoredMessages = MessageSerializer.restoreFromBackup(backup);

        expect(restoredMessages.length, equals(testMessages.length));
        for (int i = 0; i < testMessages.length; i++) {
          expect(restoredMessages[i], equals(testMessages[i]));
        }
      });

      test('should handle empty message list for backup', () {
        final emptyMessages = <GemmaMessage>[];
        final backup = MessageSerializer.createMessageBackup(emptyMessages);

        expect(backup['messageCount'], equals(0));
        expect(backup['messages'], isEmpty);

        final restoredMessages = MessageSerializer.restoreFromBackup(backup);
        expect(restoredMessages, isEmpty);
      });

      test('should include summary in backup', () {
        final backup = MessageSerializer.createMessageBackup(testMessages);
        final summary = backup['summary'] as Map<String, dynamic>;

        expect(summary['totalMessages'], equals(testMessages.length));
        expect(summary['messageTypes'], isA<Map>());
        expect(summary['participants'], isA<Map>());
      });
    });

    group('Error Handling', () {
      test('should handle malformed JSON gracefully', () {
        expect(
          () => MessageSerializer.deserializeMessage('invalid json'),
          throwsA(isA<FormatException>()),
        );
      });

      test('should handle unknown message type in JSON', () {
        final invalidJson = '{"type": "unknown", "text": "test", "isUser": true, "timestamp": "2023-01-01T00:00:00.000Z"}';

        expect(
          () => MessageSerializer.deserializeMessage(invalidJson),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should handle missing required fields in JSON', () {
        final incompleteJson = '{"type": "text", "isUser": true}'; // Missing text and timestamp

        expect(
          () => MessageSerializer.deserializeMessage(incompleteJson),
          throwsA(isA<TypeError>()),
        );
      });
    });
  });
}