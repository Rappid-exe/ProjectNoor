import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Mock AI service that simulates Gemma responses for testing app architecture
/// This bypasses the flutter_gemma enum issues while we work on the real solution
class MockAiService {
  static MockAiService? _instance;
  static MockAiService get instance => _instance ??= MockAiService._();
  
  MockAiService._();
  
  bool _isInitialized = false;
  final Random _random = Random();
  
  /// Mock responses for testing
  final List<String> _mockResponses = [
    'Hello! I\'m a mock AI assistant simulating Gemma responses. How can I help you today?',
    'This is a simulated response while we work on fixing the flutter_gemma enum issues.',
    'I\'m currently running in mock mode, but I can still help test the app architecture!',
    'The model file has been detected successfully. This would be a real AI response in production.',
    'Mock mode: I can see you\'re testing the educational platform. What would you like to learn about?',
    'Simulated Gemma response: I\'m here to help with your educational journey!',
  ];
  
  /// Initialize the mock service
  Future<bool> initialize() async {
    try {
      if (_isInitialized) return true;
      
      print('🚀 Starting MockAiService initialization...');
      print('⚠️ This is a MOCK service to test app architecture');
      print('⚠️ Real AI responses will be available once flutter_gemma enum issues are resolved');
      
      // Step 1: Check if model file exists (for compatibility)
      print('📁 Checking for model file...');
      
      final documentsDir = await getApplicationDocumentsDirectory();
      final expectedModelPath = '${documentsDir.path}/gemma-3n-E2B-it-int4.task';
      
      File? modelFile;
      
      if (File(expectedModelPath).existsSync()) {
        modelFile = File(expectedModelPath);
        print('✅ Model file found in app documents: ${modelFile.lengthSync() / (1024 * 1024)} MB');
      } else if (Platform.isWindows) {
        final userDocsPath = 'C:\\Users\\${Platform.environment['USERNAME']}\\Documents\\gemma-3n-E2B-it-int4.task';
        if (File(userDocsPath).existsSync()) {
          modelFile = File(userDocsPath);
          print('✅ Model file found in user documents: ${modelFile.lengthSync() / (1024 * 1024)} MB');
        }
      }
      
      if (modelFile != null) {
        print('✅ Model file verified - ready for real implementation');
      } else {
        print('⚠️ Model file not found - this would be needed for real AI');
        print('Checked locations:');
        print('  - $expectedModelPath');
        if (Platform.isWindows) {
          print('  - C:\\Users\\${Platform.environment['USERNAME']}\\Documents\\gemma-3n-E2B-it-int4.task');
        }
      }
      
      // Step 2: Simulate initialization delay
      print('🔧 Simulating model initialization...');
      await Future.delayed(Duration(milliseconds: 500));
      
      // Step 3: Simulate chat setup
      print('💬 Setting up mock chat interface...');
      await Future.delayed(Duration(milliseconds: 200));
      
      _isInitialized = true;
      print('🎉 MockAiService initialized successfully!');
      print('💡 Ready to test app architecture with mock responses');
      
      return true;
      
    } catch (e) {
      print('❌ MockAiService initialization failed: $e');
      return false;
    }
  }
  
  /// Send a message and get streaming response (mock)
  Stream<String> sendMessage(String message) async* {
    if (!_isInitialized) {
      yield 'Error: Mock service not initialized';
      return;
    }
    
    try {
      print('📤 Mock processing message: ${message.substring(0, message.length.clamp(0, 50))}...');
      
      // Simulate thinking time
      await Future.delayed(Duration(milliseconds: 300));
      
      // Select a mock response
      final response = _mockResponses[_random.nextInt(_mockResponses.length)];
      
      // Simulate streaming by yielding word by word
      final words = response.split(' ');
      for (int i = 0; i < words.length; i++) {
        await Future.delayed(Duration(milliseconds: 50 + _random.nextInt(100)));
        if (i == 0) {
          yield words[i];
        } else {
          yield ' ${words[i]}';
        }
      }
      
    } catch (e) {
      print('❌ Mock error: $e');
      yield 'Mock error: Failed to generate response - $e';
    }
  }
  
  /// Send a message and get complete response (mock)
  Future<String> sendMessageSync(String message) async {
    if (!_isInitialized) {
      return 'Error: Mock service not initialized';
    }
    
    try {
      print('📤 Mock processing sync message: ${message.substring(0, message.length.clamp(0, 50))}...');
      
      // Simulate processing time
      await Future.delayed(Duration(milliseconds: 500 + _random.nextInt(1000)));
      
      // Generate a contextual mock response
      String response;
      if (message.toLowerCase().contains('joke')) {
        response = 'Mock joke: Why did the AI go to school? To improve its neural networks! 😄';
      } else if (message.toLowerCase().contains('hello') || message.toLowerCase().contains('hi')) {
        response = 'Mock greeting: Hello! I\'m a simulated AI assistant. I\'d love to help you test this educational platform!';
      } else if (message.toLowerCase().contains('learn') || message.toLowerCase().contains('education')) {
        response = 'Mock educational response: This platform is designed to support learning! What subject would you like to explore? (Note: This is a mock response)';
      } else if (message.toLowerCase().contains('math') || message.toLowerCase().contains('2+2')) {
        response = 'Mock math response: 2 + 2 = 4. I\'m simulating mathematical reasoning! In the real version, I\'d provide detailed explanations.';
      } else {
        response = _mockResponses[_random.nextInt(_mockResponses.length)];
      }
      
      print('📥 Mock response generated: ${response.substring(0, response.length.clamp(0, 100))}...');
      return response;
      
    } catch (e) {
      print('❌ Mock error: $e');
      return 'Mock error: Failed to generate response - $e';
    }
  }
  
  /// Check if service is ready
  bool get isReady => _isInitialized;
  
  /// Get service info
  String get serviceInfo => 'MockAiService v1.0 - Simulating Gemma responses for testing';
  
  /// Dispose resources (mock)
  Future<void> dispose() async {
    try {
      _isInitialized = false;
      print('🧹 MockAiService disposed');
    } catch (e) {
      print('❌ Error disposing MockAiService: $e');
    }
  }
} 