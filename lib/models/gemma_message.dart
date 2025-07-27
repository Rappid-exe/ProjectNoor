import 'dart:typed_data';
import 'dart:convert';

/// Abstract base class for all Gemma messages
abstract class GemmaMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? id;

  const GemmaMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.id,
  });

  /// Convert message to JSON for serialization
  Map<String, dynamic> toJson();

  /// Create message from JSON
  static GemmaMessage fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'text':
        return TextMessage.fromJson(json);
      case 'image':
        return ImageMessage.fromJson(json);
      case 'function_call':
        return FunctionCallMessage.fromJson(json);
      default:
        throw ArgumentError('Unknown message type: $type');
    }
  }

  /// Get the message type identifier
  String get messageType;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GemmaMessage &&
        other.text == text &&
        other.isUser == isUser &&
        other.timestamp == timestamp &&
        other.id == id;
  }

  @override
  int get hashCode {
    return text.hashCode ^
        isUser.hashCode ^
        timestamp.hashCode ^
        id.hashCode;
  }
}

/// Text-only message implementation
class TextMessage extends GemmaMessage {
  TextMessage({
    required String text,
    required bool isUser,
    DateTime? timestamp,
    String? id,
  }) : super(
          text: text,
          isUser: isUser,
          timestamp: timestamp ?? DateTime.now(),
          id: id,
        );

  @override
  String get messageType => 'text';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': messageType,
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'id': id,
    };
  }

  static TextMessage fromJson(Map<String, dynamic> json) {
    return TextMessage(
      text: json['text'] as String,
      isUser: json['isUser'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      id: json['id'] as String?,
    );
  }

  @override
  String toString() {
    return 'TextMessage(text: $text, isUser: $isUser, timestamp: $timestamp, id: $id)';
  }
}

/// Image message with optional text description
class ImageMessage extends GemmaMessage {
  final Uint8List imageBytes;
  final String? imageDescription;

  ImageMessage({
    required String text,
    required this.imageBytes,
    required bool isUser,
    this.imageDescription,
    DateTime? timestamp,
    String? id,
  }) : super(
          text: text,
          isUser: isUser,
          timestamp: timestamp ?? DateTime.now(),
          id: id,
        );

  @override
  String get messageType => 'image';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': messageType,
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'id': id,
      'imageBytes': base64Encode(imageBytes),
      'imageDescription': imageDescription,
    };
  }

  static ImageMessage fromJson(Map<String, dynamic> json) {
    return ImageMessage(
      text: json['text'] as String,
      imageBytes: base64Decode(json['imageBytes'] as String),
      isUser: json['isUser'] as bool,
      imageDescription: json['imageDescription'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      id: json['id'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ImageMessage &&
        super == other &&
        _listEquals(other.imageBytes, imageBytes) &&
        other.imageDescription == imageDescription;
  }

  @override
  int get hashCode {
    return super.hashCode ^
        imageBytes.hashCode ^
        imageDescription.hashCode;
  }

  @override
  String toString() {
    return 'ImageMessage(text: $text, isUser: $isUser, timestamp: $timestamp, id: $id, imageSize: ${imageBytes.length}, description: $imageDescription)';
  }

  /// Helper method to compare Uint8List
  bool _listEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Function call message for AI-triggered actions
class FunctionCallMessage extends GemmaMessage {
  final String functionName;
  final Map<String, dynamic> arguments;
  final Map<String, dynamic>? response;

  FunctionCallMessage({
    required this.functionName,
    required this.arguments,
    this.response,
    required bool isUser,
    DateTime? timestamp,
    String? id,
  }) : super(
          text: 'Function call: $functionName',
          isUser: isUser,
          timestamp: timestamp ?? DateTime.now(),
          id: id,
        );

  @override
  String get messageType => 'function_call';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': messageType,
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'id': id,
      'functionName': functionName,
      'arguments': arguments,
      'response': response,
    };
  }

  static FunctionCallMessage fromJson(Map<String, dynamic> json) {
    return FunctionCallMessage(
      functionName: json['functionName'] as String,
      arguments: Map<String, dynamic>.from(json['arguments'] as Map),
      response: json['response'] != null 
          ? Map<String, dynamic>.from(json['response'] as Map)
          : null,
      isUser: json['isUser'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      id: json['id'] as String?,
    );
  }

  /// Create a copy with updated response
  FunctionCallMessage withResponse(Map<String, dynamic> newResponse) {
    return FunctionCallMessage(
      functionName: functionName,
      arguments: arguments,
      response: newResponse,
      isUser: isUser,
      timestamp: timestamp,
      id: id,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FunctionCallMessage &&
        super == other &&
        other.functionName == functionName &&
        _mapEquals(other.arguments, arguments) &&
        _mapEquals(other.response, response);
  }

  @override
  int get hashCode {
    return super.hashCode ^
        functionName.hashCode ^
        _mapHashCode(arguments) ^
        _mapHashCode(response);
  }

  /// Helper method to compute hash code for maps
  int _mapHashCode(Map<String, dynamic>? map) {
    if (map == null) return 0;
    int hash = 0;
    for (final entry in map.entries) {
      hash ^= entry.key.hashCode ^ entry.value.hashCode;
    }
    return hash;
  }

  @override
  String toString() {
    return 'FunctionCallMessage(functionName: $functionName, arguments: $arguments, response: $response, isUser: $isUser, timestamp: $timestamp, id: $id)';
  }

  /// Helper method to compare maps
  bool _mapEquals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || !_deepEquals(a[key], b[key])) return false;
    }
    return true;
  }

  /// Helper method for deep equality comparison
  bool _deepEquals(dynamic a, dynamic b) {
    if (identical(a, b)) return true;
    
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key) || !_deepEquals(a[key], b[key])) return false;
      }
      return true;
    }
    
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (int i = 0; i < a.length; i++) {
        if (!_deepEquals(a[i], b[i])) return false;
      }
      return true;
    }
    
    return a == b;
  }
}