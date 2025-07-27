import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import '../models/gemma_message.dart';
import '../models/gemma_response.dart';
import '../models/gemma_config.dart';
import '../models/gemma_exceptions.dart';
import 'flutter_gemma_service.dart';

/// Wrapper class for managing Gemma chat sessions with enhanced functionality
class GemmaChat {
  final FlutterGemmaService _service;
  final GemmaChatConfig _config;
  dynamic _nativeChat; // Will be the actual flutter_gemma chat instance
  
  final List<GemmaMessage> _conversationHistory = [];
  final StreamController<GemmaResponse> _responseController = StreamController<GemmaResponse>.broadcast();
  
  bool _isActive = false;
  bool _isDisposed = false;
  int _tokenCount = 0;
  
  /// Create a new GemmaChat instance
  GemmaChat._(this._service, this._config, this._nativeChat) {
    _isActive = true;
  }

  /// Factory method to create a GemmaChat instance
  static Future<GemmaChat> create({
    FlutterGemmaService? service,
    GemmaChatConfig? config,
  }) async {
    final gemmaService = service ?? FlutterGemmaService.instance;
    final chatConfig = config ?? const GemmaChatConfig();
    
    if (!gemmaService.isInitialized) {
      throw GemmaException.initializationError('FlutterGemmaService must be initialized before creating chat');
    }

    try {
      final nativeChat = await gemmaService.createChat(
        temperature: chatConfig.temperature,
        randomSeed: chatConfig.randomSeed,
        topK: chatConfig.topK,
        supportImage: chatConfig.supportImage,
        tools: chatConfig.tools,
      );

      return GemmaChat._(gemmaService, chatConfig, nativeChat);
    } catch (e) {
      throw GemmaException.inferenceError('Failed to create chat session', e);
    }
  }

  // Getters
  bool get isActive => _isActive && !_isDisposed;
  bool get isDisposed => _isDisposed;
  int get tokenCount => _tokenCount;
  List<GemmaMessage> get conversationHistory => List.unmodifiable(_conversationHistory);
  GemmaChatConfig get config => _config;
  Stream<GemmaResponse> get responseStream => _responseController.stream;

  /// Send a text message and get a complete response
  Future<String> sendMessage(String text) async {
    _validateChatState();
    
    if (text.trim().isEmpty) {
      throw GemmaException(GemmaErrorType.invalidInput, 'Message text cannot be empty');
    }

    try {
      // Add user message to history
      final userMessage = TextMessage(
        text: text,
        isUser: true,
        id: _generateMessageId(),
      );
      _conversationHistory.add(userMessage);
      _updateTokenCount(text);

      // TODO: Replace with actual flutter_gemma chat.sendMessage call
      // final response = await _nativeChat.sendMessage(text);
      
      // Placeholder implementation
      await Future.delayed(const Duration(milliseconds: 500));
      final response = 'This is a placeholder response to: $text';

      // Add AI response to history
      final aiMessage = TextMessage(
        text: response,
        isUser: false,
        id: _generateMessageId(),
      );
      _conversationHistory.add(aiMessage);
      _updateTokenCount(response);

      return response;
    } catch (e) {
      throw GemmaException.inferenceError('Failed to send message', e);
    }
  }

  /// Send a text message and get a streaming response
  Stream<String> sendMessageStream(String text) async* {
    _validateChatState();
    
    if (text.trim().isEmpty) {
      throw GemmaException(GemmaErrorType.invalidInput, 'Message text cannot be empty');
    }

    try {
      // Add user message to history
      final userMessage = TextMessage(
        text: text,
        isUser: true,
        id: _generateMessageId(),
      );
      _conversationHistory.add(userMessage);
      _updateTokenCount(text);

      // TODO: Replace with actual flutter_gemma chat.sendMessageStream call
      // final responseStream = _nativeChat.sendMessageStream(text);
      
      // Placeholder streaming implementation
      final words = 'This is a placeholder streaming response to: $text'.split(' ');
      String completeResponse = '';
      
      for (final word in words) {
        await Future.delayed(const Duration(milliseconds: 100));
        final token = words.indexOf(word) == 0 ? word : ' $word';
        completeResponse += token;
        
        // Emit text response through response stream
        final textResponse = TextResponse(token, isComplete: false);
        if (!_responseController.isClosed) {
          _responseController.add(textResponse);
        }
        
        yield token;
      }

      // Mark as complete
      final completeTextResponse = TextResponse('', isComplete: true);
      if (!_responseController.isClosed) {
        _responseController.add(completeTextResponse);
      }

      // Add complete AI response to history
      final aiMessage = TextMessage(
        text: completeResponse,
        isUser: false,
        id: _generateMessageId(),
      );
      _conversationHistory.add(aiMessage);
      _updateTokenCount(completeResponse);

    } catch (e) {
      final errorResponse = ErrorResponse('Failed to send streaming message: ${e.toString()}');
      if (!_responseController.isClosed) {
        _responseController.add(errorResponse);
      }
      throw GemmaException.inferenceError('Failed to send streaming message', e);
    }
  }

  /// Send a message with image and get a complete response
  Future<String> sendImageMessage(String text, Uint8List imageBytes) async {
    _validateChatState();
    
    if (!_config.supportImage) {
      throw GemmaException(GemmaErrorType.configurationError, 'Image support is not enabled for this chat');
    }

    if (imageBytes.isEmpty) {
      throw GemmaException(GemmaErrorType.invalidInput, 'Image data cannot be empty');
    }

    try {
      // Add user image message to history
      final userMessage = ImageMessage(
        text: text,
        imageBytes: imageBytes,
        isUser: true,
        id: _generateMessageId(),
      );
      _conversationHistory.add(userMessage);
      _updateTokenCount(text);

      // TODO: Replace with actual flutter_gemma chat.sendImageMessage call
      // final response = await _nativeChat.sendImageMessage(text, imageBytes);
      
      // Placeholder implementation
      await Future.delayed(const Duration(milliseconds: 800));
      final response = 'This is a placeholder response to image message: $text (Image size: ${imageBytes.length} bytes)';

      // Add AI response to history
      final aiMessage = TextMessage(
        text: response,
        isUser: false,
        id: _generateMessageId(),
      );
      _conversationHistory.add(aiMessage);
      _updateTokenCount(response);

      return response;
    } catch (e) {
      throw GemmaException.inferenceError('Failed to send image message', e);
    }
  }

  /// Send a message with image and get a streaming response
  Stream<String> sendImageMessageStream(String text, Uint8List imageBytes) async* {
    _validateChatState();
    
    if (!_config.supportImage) {
      throw GemmaException(GemmaErrorType.configurationError, 'Image support is not enabled for this chat');
    }

    if (imageBytes.isEmpty) {
      throw GemmaException(GemmaErrorType.invalidInput, 'Image data cannot be empty');
    }

    try {
      // Add user image message to history
      final userMessage = ImageMessage(
        text: text,
        imageBytes: imageBytes,
        isUser: true,
        id: _generateMessageId(),
      );
      _conversationHistory.add(userMessage);
      _updateTokenCount(text);

      // TODO: Replace with actual flutter_gemma chat.sendImageMessageStream call
      // final responseStream = _nativeChat.sendImageMessageStream(text, imageBytes);
      
      // Placeholder streaming implementation
      final words = 'This is a placeholder streaming response to image: $text (${imageBytes.length} bytes)'.split(' ');
      String completeResponse = '';
      
      for (final word in words) {
        await Future.delayed(const Duration(milliseconds: 120));
        final token = words.indexOf(word) == 0 ? word : ' $word';
        completeResponse += token;
        
        // Emit text response through response stream
        final textResponse = TextResponse(token, isComplete: false);
        if (!_responseController.isClosed) {
          _responseController.add(textResponse);
        }
        
        yield token;
      }

      // Mark as complete
      final completeTextResponse = TextResponse('', isComplete: true);
      if (!_responseController.isClosed) {
        _responseController.add(completeTextResponse);
      }

      // Add complete AI response to history
      final aiMessage = TextMessage(
        text: completeResponse,
        isUser: false,
        id: _generateMessageId(),
      );
      _conversationHistory.add(aiMessage);
      _updateTokenCount(completeResponse);

    } catch (e) {
      final errorResponse = ErrorResponse('Failed to send streaming image message: ${e.toString()}');
      if (!_responseController.isClosed) {
        _responseController.add(errorResponse);
      }
      throw GemmaException.inferenceError('Failed to send streaming image message', e);
    }
  }

  /// Send a message with function calling support
  Stream<GemmaResponse> sendMessageWithFunctions(String text) async* {
    _validateChatState();
    
    if (!_config.supportsFunctionCalls) {
      throw GemmaException(GemmaErrorType.configurationError, 'Function calling is not enabled for this chat');
    }

    if (text.trim().isEmpty) {
      throw GemmaException(GemmaErrorType.invalidInput, 'Message text cannot be empty');
    }

    try {
      // Add user message to history
      final userMessage = TextMessage(
        text: text,
        isUser: true,
        id: _generateMessageId(),
      );
      _conversationHistory.add(userMessage);
      _updateTokenCount(text);

      // TODO: Replace with actual flutter_gemma function calling
      // final responseStream = _nativeChat.sendMessageWithFunctions(text);
      
      // Placeholder implementation with mixed responses
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Simulate text response
      yield TextResponse('I can help you with that. Let me ', isComplete: false);
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Simulate function call
      yield FunctionCallResponse('award_achievement', {
        'achievementId': 'first_question',
        'reason': 'Asked their first question'
      });
      
      await Future.delayed(const Duration(milliseconds: 100));
      yield TextResponse('check your progress.', isComplete: true);

      // Add function call to history
      final functionMessage = FunctionCallMessage(
        functionName: 'award_achievement',
        arguments: {'achievementId': 'first_question', 'reason': 'Asked their first question'},
        isUser: false,
        id: _generateMessageId(),
      );
      _conversationHistory.add(functionMessage);

    } catch (e) {
      yield ErrorResponse('Failed to send message with functions: ${e.toString()}');
      throw GemmaException.inferenceError('Failed to send message with functions', e);
    }
  }

  /// Clear the conversation context
  Future<void> clearContext() async {
    _validateChatState();
    
    try {
      // TODO: Replace with actual flutter_gemma context clearing
      // await _nativeChat.clearContext();
      
      _conversationHistory.clear();
      _tokenCount = 0;
      
      if (kDebugMode) {
        print('GemmaChat: Context cleared');
      }
    } catch (e) {
      throw GemmaException.inferenceError('Failed to clear context', e);
    }
  }

  /// Get the current token count
  Future<int> getTokenCount() async {
    _validateChatState();
    
    try {
      // TODO: Replace with actual flutter_gemma token counting
      // final actualCount = await _nativeChat.getTokenCount();
      // return actualCount;
      
      return _tokenCount;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get accurate token count, returning estimated: $e');
      }
      return _tokenCount;
    }
  }

  /// Get conversation summary for context management
  String getConversationSummary({int maxMessages = 10}) {
    final recentMessages = _conversationHistory.length > maxMessages
        ? _conversationHistory.sublist(_conversationHistory.length - maxMessages)
        : _conversationHistory;
    
    return recentMessages
        .map((msg) => '${msg.isUser ? "User" : "AI"}: ${msg.text}')
        .join('\n');
  }

  /// Check if context needs to be managed due to token limits
  bool shouldManageContext({int maxTokens = 3000}) {
    return _tokenCount > maxTokens;
  }

  /// Optimize context by removing older messages
  Future<void> optimizeContext({int targetTokens = 2000}) async {
    if (_tokenCount <= targetTokens) return;
    
    try {
      // Remove messages from the beginning until we're under the target
      while (_conversationHistory.isNotEmpty && _tokenCount > targetTokens) {
        final removedMessage = _conversationHistory.removeAt(0);
        _tokenCount -= _estimateTokenCount(removedMessage.text);
      }
      
      // TODO: If using actual flutter_gemma, we might need to recreate the chat
      // with the optimized history
      
      if (kDebugMode) {
        print('GemmaChat: Context optimized, remaining tokens: $_tokenCount');
      }
    } catch (e) {
      throw GemmaException.inferenceError('Failed to optimize context', e);
    }
  }

  /// Close the chat session and clean up resources
  Future<void> close() async {
    if (_isDisposed) return;
    
    try {
      _isActive = false;
      
      // TODO: Replace with actual flutter_gemma chat disposal
      // await _nativeChat?.dispose();
      
      await _responseController.close();
      _conversationHistory.clear();
      _tokenCount = 0;
      _isDisposed = true;
      
      if (kDebugMode) {
        print('GemmaChat: Session closed and resources cleaned up');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during GemmaChat disposal: $e');
      }
    }
  }

  /// Validate that the chat is in a valid state for operations
  void _validateChatState() {
    if (_isDisposed) {
      throw GemmaException(GemmaErrorType.configurationError, 'Chat session has been disposed');
    }
    
    if (!_isActive) {
      throw GemmaException(GemmaErrorType.configurationError, 'Chat session is not active');
    }
    
    if (!_service.isInitialized) {
      throw GemmaException.initializationError('FlutterGemmaService is not initialized');
    }
  }

  /// Generate a unique message ID
  String _generateMessageId() {
    return 'msg_${DateTime.now().millisecondsSinceEpoch}_${_conversationHistory.length}';
  }

  /// Update token count with new text
  void _updateTokenCount(String text) {
    _tokenCount += _estimateTokenCount(text);
  }

  /// Estimate token count for text (rough approximation)
  int _estimateTokenCount(String text) {
    // Rough estimation: ~4 characters per token on average
    return (text.length / 4).ceil();
  }

  @override
  String toString() {
    return 'GemmaChat(isActive: $isActive, messages: ${_conversationHistory.length}, tokens: $_tokenCount)';
  }
}