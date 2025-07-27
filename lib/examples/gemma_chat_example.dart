import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import '../services/gemma_chat.dart';
import '../services/flutter_gemma_service.dart';
import '../models/gemma_config.dart';
import '../models/gemma_response.dart';

/// Example demonstrating how to use the GemmaChat wrapper class
class GemmaChatExample {
  
  /// Example of basic text messaging
  static Future<void> basicTextMessaging() async {
    print('=== Basic Text Messaging Example ===');
    
    try {
      // Initialize the service
      final service = FlutterGemmaService.instance;
      await service.initialize();
      
      // Create a chat with basic configuration
      final chat = await GemmaChat.create(
        service: service,
        config: const GemmaChatConfig(
          temperature: 0.8,
          topK: 1,
        ),
      );
      
      print('Chat created successfully');
      print('Initial token count: ${chat.tokenCount}');
      
      // Send a message and get response
      final response = await chat.sendMessage('Hello! Can you help me learn about Flutter?');
      print('AI Response: $response');
      print('Token count after message: ${chat.tokenCount}');
      print('Conversation history length: ${chat.conversationHistory.length}');
      
      // Send another message
      await chat.sendMessage('What are the key concepts I should know?');
      print('Token count after second message: ${chat.tokenCount}');
      
      // Get conversation summary
      final summary = chat.getConversationSummary();
      print('Conversation summary:\n$summary');
      
      // Clean up
      await chat.close();
      print('Chat session closed');
      
    } catch (e) {
      print('Error in basic text messaging: $e');
    }
  }
  
  /// Example of streaming text responses
  static Future<void> streamingTextMessaging() async {
    print('\n=== Streaming Text Messaging Example ===');
    
    try {
      final service = FlutterGemmaService.instance;
      await service.initialize();
      
      final chat = await GemmaChat.create(
        service: service,
        config: const GemmaChatConfig(temperature: 0.7),
      );
      
      print('Sending streaming message...');
      print('AI Response (streaming): ');
      
      // Send message with streaming response
      await for (final token in chat.sendMessageStream('Explain the concept of widgets in Flutter')) {
        // Print each token as it arrives (simulating real-time display)
        print(token, end: '');
      }
      print('\n'); // New line after streaming is complete
      
      print('Streaming complete. Final token count: ${chat.tokenCount}');
      
      await chat.close();
      
    } catch (e) {
      print('Error in streaming messaging: $e');
    }
  }
  
  /// Example of image messaging (when supported)
  static Future<void> imageMessaging() async {
    print('\n=== Image Messaging Example ===');
    
    try {
      final service = FlutterGemmaService.instance;
      await service.initialize();
      
      // Create chat with image support enabled
      final chat = await GemmaChat.create(
        service: service,
        config: const GemmaChatConfig(
          supportImage: true,
          temperature: 0.8,
        ),
      );
      
      // Create mock image data (in real app, this would be actual image bytes)
      final mockImageBytes = Uint8List.fromList(
        List.generate(1000, (index) => index % 256), // Mock image data
      );
      
      print('Sending image message...');
      final response = await chat.sendImageMessage(
        'What do you see in this image?',
        mockImageBytes,
      );
      
      print('AI Response to image: $response');
      print('Image message added to history');
      
      // Check that image message is in history
      final lastMessage = chat.conversationHistory.last;
      print('Last message type: ${lastMessage.messageType}');
      
      await chat.close();
      
    } catch (e) {
      print('Error in image messaging: $e');
    }
  }
  
  /// Example of function calling
  static Future<void> functionCalling() async {
    print('\n=== Function Calling Example ===');
    
    try {
      final service = FlutterGemmaService.instance;
      await service.initialize();
      
      // Create chat with function calling support
      final chat = await GemmaChat.create(
        service: service,
        config: const GemmaChatConfig(
          supportsFunctionCalls: true,
          temperature: 0.8,
        ),
      );
      
      print('Sending message that might trigger function calls...');
      
      // Listen to response stream to handle different response types
      final responses = <GemmaResponse>[];
      await for (final response in chat.sendMessageWithFunctions(
        'I just completed my first Flutter app! Can you award me an achievement?'
      )) {
        responses.add(response);
        
        if (response is TextResponse) {
          print('Text: ${response.token}');
        } else if (response is FunctionCallResponse) {
          print('Function Call: ${response.name} with args: ${response.args}');
        }
      }
      
      print('Total responses received: ${responses.length}');
      print('Function calls in history: ${chat.conversationHistory.where((m) => m.messageType == 'function_call').length}');
      
      await chat.close();
      
    } catch (e) {
      print('Error in function calling: $e');
    }
  }
  
  /// Example of context management
  static Future<void> contextManagement() async {
    print('\n=== Context Management Example ===');
    
    try {
      final service = FlutterGemmaService.instance;
      await service.initialize();
      
      final chat = await GemmaChat.create(service: service);
      
      // Add several messages to build up context
      print('Building conversation context...');
      for (int i = 1; i <= 5; i++) {
        await chat.sendMessage('This is message number $i in our conversation.');
        print('Message $i sent. Token count: ${chat.tokenCount}');
      }
      
      print('Conversation history length: ${chat.conversationHistory.length}');
      
      // Check if context management is needed
      if (chat.shouldManageContext(maxTokens: 100)) {
        print('Context management needed. Optimizing...');
        await chat.optimizeContext(targetTokens: 50);
        print('After optimization - History length: ${chat.conversationHistory.length}, Tokens: ${chat.tokenCount}');
      }
      
      // Clear context completely
      print('Clearing all context...');
      await chat.clearContext();
      print('After clearing - History length: ${chat.conversationHistory.length}, Tokens: ${chat.tokenCount}');
      
      await chat.close();
      
    } catch (e) {
      print('Error in context management: $e');
    }
  }
  
  /// Example of error handling
  static Future<void> errorHandling() async {
    print('\n=== Error Handling Example ===');
    
    try {
      final service = FlutterGemmaService.instance;
      await service.initialize();
      
      final chat = await GemmaChat.create(service: service);
      
      // Test empty message error
      try {
        await chat.sendMessage('');
      } catch (e) {
        print('Caught expected error for empty message: $e');
      }
      
      // Test image message without support
      try {
        final imageBytes = Uint8List.fromList([1, 2, 3]);
        await chat.sendImageMessage('Test', imageBytes);
      } catch (e) {
        print('Caught expected error for image without support: $e');
      }
      
      // Test function calling without support
      try {
        await for (final _ in chat.sendMessageWithFunctions('Test')) {
          // This should throw an error
        }
      } catch (e) {
        print('Caught expected error for function calling without support: $e');
      }
      
      await chat.close();
      
      // Test using disposed chat
      try {
        await chat.sendMessage('This should fail');
      } catch (e) {
        print('Caught expected error for disposed chat: $e');
      }
      
    } catch (e) {
      print('Error in error handling example: $e');
    }
  }
  
  /// Run all examples
  static Future<void> runAllExamples() async {
    print('🚀 Running GemmaChat Examples\n');
    
    await basicTextMessaging();
    await streamingTextMessaging();
    await imageMessaging();
    await functionCalling();
    await contextManagement();
    await errorHandling();
    
    print('\n✅ All examples completed!');
    
    // Clean up singleton
    FlutterGemmaService.disposeInstance();
  }
}

/// Extension to print without newline (for streaming demo)
extension PrintExtension on String {
  void print({String end = '\n'}) {
    if (kDebugMode) {
      stdout.write(this + end);
    }
  }
}

// For console output in examples
abstract class stdout {
  static void write(String text) {
    if (kDebugMode) {
      print(text);
    }
  }
}