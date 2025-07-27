import 'dart:convert';
import 'dart:typed_data';
import '../models/gemma_message.dart';
import '../models/gemma_response.dart';

/// Utility class for serializing and deserializing Gemma messages and responses
class MessageSerializer {
  /// Serialize a list of messages to JSON string
  static String serializeMessages(List<GemmaMessage> messages) {
    final jsonList = messages.map((message) => message.toJson()).toList();
    return jsonEncode(jsonList);
  }

  /// Deserialize messages from JSON string
  static List<GemmaMessage> deserializeMessages(String jsonString) {
    final jsonList = jsonDecode(jsonString) as List<dynamic>;
    return jsonList
        .map((json) => GemmaMessage.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Serialize a single message to JSON string
  static String serializeMessage(GemmaMessage message) {
    return jsonEncode(message.toJson());
  }

  /// Deserialize a single message from JSON string
  static GemmaMessage deserializeMessage(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return GemmaMessage.fromJson(json);
  }

  /// Serialize a list of responses to JSON string
  static String serializeResponses(List<GemmaResponse> responses) {
    final jsonList = responses.map((response) => response.toJson()).toList();
    return jsonEncode(jsonList);
  }

  /// Deserialize responses from JSON string
  static List<GemmaResponse> deserializeResponses(String jsonString) {
    final jsonList = jsonDecode(jsonString) as List<dynamic>;
    return jsonList
        .map((json) => GemmaResponse.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Serialize a single response to JSON string
  static String serializeResponse(GemmaResponse response) {
    return jsonEncode(response.toJson());
  }

  /// Deserialize a single response from JSON string
  static GemmaResponse deserializeResponse(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return GemmaResponse.fromJson(json);
  }

  /// Convert messages to a format suitable for conversation history
  static List<Map<String, dynamic>> messagesToConversationHistory(
      List<GemmaMessage> messages) {
    return messages.map((message) {
      final baseData = <String, dynamic>{
        'role': message.isUser ? 'user' : 'assistant',
        'content': message.text,
        'timestamp': message.timestamp.toIso8601String(),
        'id': message.id,
      };

      // Add type-specific data
      if (message is ImageMessage) {
        baseData['type'] = 'image';
        baseData['imageDescription'] = message.imageDescription;
        // Note: Image bytes are not included in conversation history for size reasons
        baseData['hasImage'] = true;
      } else if (message is FunctionCallMessage) {
        baseData['type'] = 'function_call';
        baseData['functionName'] = message.functionName;
        baseData['arguments'] = message.arguments;
        baseData['response'] = message.response;
      } else {
        baseData['type'] = 'text';
      }

      return baseData;
    }).toList();
  }

  /// Create a conversation summary for context management
  static Map<String, dynamic> createConversationSummary(
      List<GemmaMessage> messages) {
    final textMessages = messages.whereType<TextMessage>().length;
    final imageMessages = messages.whereType<ImageMessage>().length;
    final functionMessages = messages.whereType<FunctionCallMessage>().length;
    
    final userMessages = messages.where((m) => m.isUser).length;
    final assistantMessages = messages.where((m) => !m.isUser).length;

    return {
      'totalMessages': messages.length,
      'messageTypes': {
        'text': textMessages,
        'image': imageMessages,
        'function_call': functionMessages,
      },
      'participants': {
        'user': userMessages,
        'assistant': assistantMessages,
      },
      'firstMessage': messages.isNotEmpty 
          ? messages.first.timestamp.toIso8601String()
          : null,
      'lastMessage': messages.isNotEmpty 
          ? messages.last.timestamp.toIso8601String()
          : null,
      'estimatedTokens': _estimateTokenCount(messages),
    };
  }

  /// Estimate token count for messages (rough approximation)
  static int _estimateTokenCount(List<GemmaMessage> messages) {
    int totalTokens = 0;
    for (final message in messages) {
      // Rough estimation: 1 token per 4 characters
      totalTokens += (message.text.length / 4).ceil();
      
      // Add extra tokens for special message types
      if (message is ImageMessage) {
        totalTokens += 100; // Estimated tokens for image processing
      } else if (message is FunctionCallMessage) {
        totalTokens += 50; // Estimated tokens for function call overhead
      }
    }
    return totalTokens;
  }

  /// Validate message data integrity
  static bool validateMessage(GemmaMessage message) {
    try {
      // Basic validation
      if (message.text.isEmpty) return false;
      
      // Type-specific validation
      if (message is ImageMessage) {
        if (message.imageBytes.isEmpty) return false;
      } else if (message is FunctionCallMessage) {
        if (message.functionName.isEmpty) return false;
      }
      
      // Try serialization/deserialization round trip
      final serialized = serializeMessage(message);
      final deserialized = deserializeMessage(serialized);
      
      return message == deserialized;
    } catch (e) {
      return false;
    }
  }

  /// Validate response data integrity
  static bool validateResponse(GemmaResponse response) {
    try {
      // Type-specific validation
      if (response is TextResponse) {
        if (response.token.isEmpty) return false;
      } else if (response is FunctionCallResponse) {
        if (response.name.isEmpty) return false;
      } else if (response is ErrorResponse) {
        if (response.error.isEmpty) return false;
      }
      
      // Try serialization/deserialization round trip
      final serialized = serializeResponse(response);
      final deserialized = deserializeResponse(serialized);
      
      return response == deserialized;
    } catch (e) {
      return false;
    }
  }

  /// Create a backup-friendly format for messages
  static Map<String, dynamic> createMessageBackup(List<GemmaMessage> messages) {
    return {
      'version': '1.0',
      'timestamp': DateTime.now().toIso8601String(),
      'messageCount': messages.length,
      'messages': messages.map((m) => m.toJson()).toList(),
      'summary': createConversationSummary(messages),
    };
  }

  /// Restore messages from backup format
  static List<GemmaMessage> restoreFromBackup(Map<String, dynamic> backup) {
    final messages = backup['messages'] as List<dynamic>;
    return messages
        .map((json) => GemmaMessage.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}