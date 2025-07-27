import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/services/gemma_chat.dart';
import '../../lib/services/flutter_gemma_service.dart';
import '../../lib/models/gemma_config.dart';
import '../../lib/models/gemma_message.dart';
import '../../lib/models/gemma_response.dart';
import '../../lib/models/gemma_exceptions.dart';

void main() {
  group('GemmaChat', () {
    late FlutterGemmaService service;
    late GemmaChatConfig testConfig;

    setUp(() async {
      service = FlutterGemmaService.instance;
      testConfig = const GemmaChatConfig(
        temperature: 0.8,
        randomSeed: 1,
        topK: 1,
        supportImage: true,
        supportsFunctionCalls: true,
      );
      
      // Initialize the service for testing
      await service.initialize();
    });

    tearDown(() {
      // Clean up any singleton instances
      FlutterGemmaService.disposeInstance();
    });

    group('Factory Creation', () {
      test('should create GemmaChat successfully with initialized service', () async {
        final chat = await GemmaChat.create(
          service: service,
          config: testConfig,
        );

        expect(chat.isActive, isTrue);
        expect(chat.isDisposed, isFalse);
        expect(chat.config, equals(testConfig));
        expect(chat.tokenCount, equals(0));
        expect(chat.conversationHistory, isEmpty);

        await chat.close();
      });

      test('should throw exception when service is not initialized', () async {
        // Dispose the service to make it uninitialized
        FlutterGemmaService.disposeInstance();
        final uninitializedService = FlutterGemmaService.instance;

        expect(
          () => GemmaChat.create(service: uninitializedService, config: testConfig),
          throwsA(isA<GemmaException>().having(
            (e) => e.type,
            'type',
            GemmaErrorType.initializationError,
          )),
        );
        
        // Reinitialize for other tests
        await service.initialize();
      });

      test('should use default config when none provided', () async {
        final chat = await GemmaChat.create(service: service);

        expect(chat.config.temperature, equals(0.8));
        expect(chat.config.randomSeed, equals(1));
        expect(chat.config.topK, equals(1));
        expect(chat.config.supportImage, isFalse);
        expect(chat.config.supportsFunctionCalls, isFalse);

        await chat.close();
      });
    });

    group('Text Messaging', () {
      late GemmaChat chat;

      setUp(() async {
        chat = await GemmaChat.create(
          service: service,
          config: testConfig,
        );
      });

      tearDown(() async {
        await chat.close();
      });

      test('should send text message and return response', () async {
        const testMessage = 'Hello, AI!';
        
        final response = await chat.sendMessage(testMessage);

        expect(response, contains(testMessage));
        expect(chat.conversationHistory, hasLength(2));
        expect(chat.conversationHistory[0].text, equals(testMessage));
        expect(chat.conversationHistory[0].isUser, isTrue);
        expect(chat.conversationHistory[1].isUser, isFalse);
        expect(chat.tokenCount, greaterThan(0));
      });

      test('should throw exception for empty message', () async {
        expect(
          () => chat.sendMessage(''),
          throwsA(isA<GemmaException>().having(
            (e) => e.type,
            'type',
            GemmaErrorType.invalidInput,
          )),
        );

        expect(
          () => chat.sendMessage('   '),
          throwsA(isA<GemmaException>().having(
            (e) => e.type,
            'type',
            GemmaErrorType.invalidInput,
          )),
        );
      });

      test('should handle streaming text messages', () async {
        const testMessage = 'Stream this message';
        final tokens = <String>[];

        await for (final token in chat.sendMessageStream(testMessage)) {
          tokens.add(token);
        }

        expect(tokens, isNotEmpty);
        expect(tokens.join(''), contains(testMessage));
        expect(chat.conversationHistory, hasLength(2));
        expect(chat.conversationHistory[0].text, equals(testMessage));
        expect(chat.conversationHistory[1].text, equals(tokens.join('')));
      });

      test('should emit responses through response stream', () async {
        const testMessage = 'Test streaming';
        final responses = <GemmaResponse>[];
        
        // Listen to response stream
        final subscription = chat.responseStream.listen((response) {
          responses.add(response);
        });

        // Send streaming message
        await for (final _ in chat.sendMessageStream(testMessage)) {
          // Just consume the stream
        }

        await Future.delayed(const Duration(milliseconds: 100));
        await subscription.cancel();

        expect(responses, isNotEmpty);
        expect(responses.any((r) => r is TextResponse), isTrue);
        expect(responses.any((r) => r is TextResponse && r.isComplete), isTrue);
      });
    });

    group('Image Messaging', () {
      late GemmaChat chat;
      late Uint8List testImageBytes;

      setUp(() async {
        chat = await GemmaChat.create(
          service: service,
          config: testConfig,
        );
        testImageBytes = Uint8List.fromList([1, 2, 3, 4, 5]); // Mock image data
      });

      tearDown(() async {
        await chat.close();
      });

      test('should send image message and return response', () async {
        const testText = 'What is in this image?';
        
        final response = await chat.sendImageMessage(testText, testImageBytes);

        expect(response, contains(testText));
        expect(response, contains('${testImageBytes.length} bytes'));
        expect(chat.conversationHistory, hasLength(2));
        
        final userMessage = chat.conversationHistory[0] as ImageMessage;
        expect(userMessage.text, equals(testText));
        expect(userMessage.imageBytes, equals(testImageBytes));
        expect(userMessage.isUser, isTrue);
      });

      test('should handle streaming image messages', () async {
        const testText = 'Describe this image';
        final tokens = <String>[];

        await for (final token in chat.sendImageMessageStream(testText, testImageBytes)) {
          tokens.add(token);
        }

        expect(tokens, isNotEmpty);
        expect(tokens.join(''), contains(testText));
        expect(chat.conversationHistory, hasLength(2));
        
        final userMessage = chat.conversationHistory[0] as ImageMessage;
        expect(userMessage.imageBytes, equals(testImageBytes));
      });

      test('should throw exception when image support is disabled', () async {
        final chatWithoutImages = await GemmaChat.create(
          service: service,
          config: const GemmaChatConfig(supportImage: false),
        );

        expect(
          () => chatWithoutImages.sendImageMessage('Test', testImageBytes),
          throwsA(isA<GemmaException>().having(
            (e) => e.type,
            'type',
            GemmaErrorType.configurationError,
          )),
        );

        expect(
          () => chatWithoutImages.sendImageMessageStream('Test', testImageBytes),
          throwsA(isA<GemmaException>().having(
            (e) => e.type,
            'type',
            GemmaErrorType.configurationError,
          )),
        );

        await chatWithoutImages.close();
      });

      test('should throw exception for empty image data', () async {
        final emptyImageBytes = Uint8List(0);

        expect(
          () => chat.sendImageMessage('Test', emptyImageBytes),
          throwsA(isA<GemmaException>().having(
            (e) => e.type,
            'type',
            GemmaErrorType.invalidInput,
          )),
        );

        expect(
          () => chat.sendImageMessageStream('Test', emptyImageBytes),
          throwsA(isA<GemmaException>().having(
            (e) => e.type,
            'type',
            GemmaErrorType.invalidInput,
          )),
        );
      });
    });

    group('Function Calling', () {
      late GemmaChat chat;

      setUp(() async {
        chat = await GemmaChat.create(
          service: service,
          config: testConfig,
        );
      });

      tearDown(() async {
        await chat.close();
      });

      test('should handle function calling messages', () async {
        const testMessage = 'Award me an achievement';
        final responses = <GemmaResponse>[];

        await for (final response in chat.sendMessageWithFunctions(testMessage)) {
          responses.add(response);
        }

        expect(responses, isNotEmpty);
        expect(responses.any((r) => r is TextResponse), isTrue);
        expect(responses.any((r) => r is FunctionCallResponse), isTrue);
        
        final functionCall = responses.firstWhere((r) => r is FunctionCallResponse) as FunctionCallResponse;
        expect(functionCall.name, equals('award_achievement'));
        expect(functionCall.args, containsPair('achievementId', 'first_question'));
      });

      test('should throw exception when function calling is disabled', () async {
        final chatWithoutFunctions = await GemmaChat.create(
          service: service,
          config: const GemmaChatConfig(supportsFunctionCalls: false),
        );

        expect(
          () => chatWithoutFunctions.sendMessageWithFunctions('Test'),
          throwsA(isA<GemmaException>().having(
            (e) => e.type,
            'type',
            GemmaErrorType.configurationError,
          )),
        );

        await chatWithoutFunctions.close();
      });

      test('should add function call messages to history', () async {
        const testMessage = 'Test function calling';

        await for (final _ in chat.sendMessageWithFunctions(testMessage)) {
          // Just consume the stream
        }

        expect(chat.conversationHistory, hasLength(2));
        expect(chat.conversationHistory[0].text, equals(testMessage));
        expect(chat.conversationHistory[1], isA<FunctionCallMessage>());
        
        final functionMessage = chat.conversationHistory[1] as FunctionCallMessage;
        expect(functionMessage.functionName, equals('award_achievement'));
      });
    });

    group('Context Management', () {
      late GemmaChat chat;

      setUp(() async {
        chat = await GemmaChat.create(
          service: service,
          config: testConfig,
        );
      });

      tearDown(() async {
        await chat.close();
      });

      test('should clear conversation context', () async {
        // Add some messages first
        await chat.sendMessage('First message');
        await chat.sendMessage('Second message');
        
        expect(chat.conversationHistory, hasLength(4));
        expect(chat.tokenCount, greaterThan(0));

        await chat.clearContext();

        expect(chat.conversationHistory, isEmpty);
        expect(chat.tokenCount, equals(0));
      });

      test('should return current token count', () async {
        await chat.sendMessage('Test message for token counting');
        
        final tokenCount = await chat.getTokenCount();
        
        expect(tokenCount, greaterThan(0));
        expect(tokenCount, equals(chat.tokenCount));
      });

      test('should generate conversation summary', () async {
        await chat.sendMessage('First message');
        await chat.sendMessage('Second message');
        
        final summary = chat.getConversationSummary();
        
        expect(summary, contains('User: First message'));
        expect(summary, contains('User: Second message'));
        expect(summary, contains('AI:'));
      });

      test('should limit conversation summary to max messages', () async {
        // Add multiple messages
        for (int i = 0; i < 5; i++) {
          await chat.sendMessage('Message $i');
        }
        
        final summary = chat.getConversationSummary(maxMessages: 4);
        final lines = summary.split('\n');
        
        expect(lines.length, equals(4));
        expect(summary, contains('Message 3'));
        expect(summary, contains('Message 4'));
        expect(summary, isNot(contains('Message 0')));
      });

      test('should detect when context needs management', () async {
        // Initially should not need management
        expect(chat.shouldManageContext(), isFalse);
        
        // Add many messages to exceed token limit
        for (int i = 0; i < 100; i++) {
          await chat.sendMessage('This is a long message that will increase token count significantly $i');
        }
        
        expect(chat.shouldManageContext(maxTokens: 1000), isTrue);
      });

      test('should optimize context by removing old messages', () async {
        // Add many messages
        for (int i = 0; i < 20; i++) {
          await chat.sendMessage('Message $i with some content to increase tokens');
        }
        
        final initialCount = chat.conversationHistory.length;
        final initialTokens = chat.tokenCount;
        
        await chat.optimizeContext(targetTokens: initialTokens ~/ 2);
        
        expect(chat.conversationHistory.length, lessThan(initialCount));
        expect(chat.tokenCount, lessThan(initialTokens));
      });
    });

    group('Session Lifecycle', () {
      test('should properly initialize and track state', () async {
        final chat = await GemmaChat.create(
          service: service,
          config: testConfig,
        );

        expect(chat.isActive, isTrue);
        expect(chat.isDisposed, isFalse);

        await chat.close();

        expect(chat.isActive, isFalse);
        expect(chat.isDisposed, isTrue);
      });

      test('should throw exception when using disposed chat', () async {
        final chat = await GemmaChat.create(
          service: service,
          config: testConfig,
        );

        await chat.close();

        expect(
          () => chat.sendMessage('Test'),
          throwsA(isA<GemmaException>().having(
            (e) => e.type,
            'type',
            GemmaErrorType.configurationError,
          )),
        );
      });

      test('should handle multiple close calls gracefully', () async {
        final chat = await GemmaChat.create(
          service: service,
          config: testConfig,
        );

        await chat.close();
        await chat.close(); // Should not throw

        expect(chat.isDisposed, isTrue);
      });
    });

    group('Token Estimation', () {
      late GemmaChat chat;

      setUp(() async {
        chat = await GemmaChat.create(
          service: service,
          config: testConfig,
        );
      });

      tearDown(() async {
        await chat.close();
      });

      test('should estimate tokens correctly', () async {
        const shortMessage = 'Hi';
        const longMessage = 'This is a much longer message that should have more tokens';

        await chat.sendMessage(shortMessage);
        final shortTokens = chat.tokenCount;

        await chat.clearContext();
        await chat.sendMessage(longMessage);
        final longTokens = chat.tokenCount;

        expect(longTokens, greaterThan(shortTokens));
      });

      test('should track cumulative token count', () async {
        await chat.sendMessage('First message');
        final firstCount = chat.tokenCount;

        await chat.sendMessage('Second message');
        final secondCount = chat.tokenCount;

        expect(secondCount, greaterThan(firstCount));
      });
    });
  });
}