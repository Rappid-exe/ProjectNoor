import 'package:flutter_test/flutter_test.dart';

import '../../lib/services/flutter_gemma_service.dart';
import '../../lib/services/gemma_chat.dart';
import '../../lib/models/gemma_message.dart';

void main() {
  group('Chat Service Integration Tests', () {
    late FlutterGemmaService service;
    late GemmaChat chat;

    setUp(() async {
      // Reset the singleton instance before each test
      FlutterGemmaService.disposeInstance();
      service = FlutterGemmaService.instance;
      
      // Initialize the service
      await service.initialize();
      
      // Create a chat instance
      chat = await GemmaChat.create();
    });

    tearDown(() async {
      await chat.close();
      await service.dispose();
      FlutterGemmaService.disposeInstance();
    });

    test('should send text message and receive response', () async {
      const testMessage = 'Hello, how are you?';
      
      final response = await chat.sendMessage(testMessage);
      
      expect(response, isNotEmpty);
      expect(response, contains('placeholder response'));
      expect(chat.conversationHistory.length, equals(2)); // User message + AI response
      
      final userMessage = chat.conversationHistory[0];
      final aiMessage = chat.conversationHistory[1];
      
      expect(userMessage.text, equals(testMessage));
      expect(userMessage.isUser, isTrue);
      expect(aiMessage.text, equals(response));
      expect(aiMessage.isUser, isFalse);
    });

    test('should handle streaming messages', () async {
      const testMessage = 'Tell me a story';
      
      final responseTokens = <String>[];
      await for (final token in chat.sendMessageStream(testMessage)) {
        responseTokens.add(token);
      }
      
      expect(responseTokens, isNotEmpty);
      expect(responseTokens.join(''), contains('placeholder streaming response'));
      expect(chat.conversationHistory.length, equals(2)); // User message + AI response
    });

    test('should maintain conversation history', () async {
      await chat.sendMessage('First message');
      await chat.sendMessage('Second message');
      
      expect(chat.conversationHistory.length, equals(4)); // 2 user + 2 AI messages
      
      final messages = chat.conversationHistory;
      expect(messages[0].text, equals('First message'));
      expect(messages[0].isUser, isTrue);
      expect(messages[1].isUser, isFalse);
      expect(messages[2].text, equals('Second message'));
      expect(messages[2].isUser, isTrue);
      expect(messages[3].isUser, isFalse);
    });

    test('should clear conversation context', () async {
      await chat.sendMessage('Test message');
      expect(chat.conversationHistory.length, equals(2));
      
      await chat.clearContext();
      expect(chat.conversationHistory.length, equals(0));
      expect(chat.tokenCount, equals(0));
    });

    test('should track token count', () async {
      final initialTokenCount = chat.tokenCount;
      expect(initialTokenCount, equals(0));
      
      await chat.sendMessage('Hello world');
      
      expect(chat.tokenCount, greaterThan(initialTokenCount));
    });
  });
}