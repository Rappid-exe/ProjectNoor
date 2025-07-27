import 'dart:convert';

/// Abstract base class for all Gemma responses
abstract class GemmaResponse {
  const GemmaResponse();

  /// Convert response to JSON for serialization
  Map<String, dynamic> toJson();

  /// Create response from JSON
  static GemmaResponse fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'text':
        return TextResponse.fromJson(json);
      case 'function_call':
        return FunctionCallResponse.fromJson(json);
      case 'error':
        return ErrorResponse.fromJson(json);
      default:
        throw ArgumentError('Unknown response type: $type');
    }
  }

  /// Get the response type identifier
  String get responseType;
}

/// Text token response from the AI
class TextResponse extends GemmaResponse {
  final String token;
  final bool isComplete;

  const TextResponse(this.token, {this.isComplete = false});

  @override
  String get responseType => 'text';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': responseType,
      'token': token,
      'isComplete': isComplete,
    };
  }

  static TextResponse fromJson(Map<String, dynamic> json) {
    return TextResponse(
      json['token'] as String,
      isComplete: json['isComplete'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TextResponse &&
        other.token == token &&
        other.isComplete == isComplete;
  }

  @override
  int get hashCode => token.hashCode ^ isComplete.hashCode;

  @override
  String toString() {
    return 'TextResponse(token: $token, isComplete: $isComplete)';
  }
}

/// Function call response from the AI
class FunctionCallResponse extends GemmaResponse {
  final String name;
  final Map<String, dynamic> args;
  final String? callId;

  const FunctionCallResponse(this.name, this.args, {this.callId});

  @override
  String get responseType => 'function_call';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': responseType,
      'name': name,
      'args': args,
      'callId': callId,
    };
  }

  static FunctionCallResponse fromJson(Map<String, dynamic> json) {
    return FunctionCallResponse(
      json['name'] as String,
      Map<String, dynamic>.from(json['args'] as Map),
      callId: json['callId'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FunctionCallResponse &&
        other.name == name &&
        _mapEquals(other.args, args) &&
        other.callId == callId;
  }

  @override
  int get hashCode => name.hashCode ^ _mapHashCode(args) ^ callId.hashCode;

  /// Helper method to compute hash code for maps
  int _mapHashCode(Map<String, dynamic> map) {
    int hash = 0;
    for (final entry in map.entries) {
      hash ^= entry.key.hashCode ^ entry.value.hashCode;
    }
    return hash;
  }

  @override
  String toString() {
    return 'FunctionCallResponse(name: $name, args: $args, callId: $callId)';
  }

  /// Helper method to compare maps
  bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}

/// Error response from the AI or system
class ErrorResponse extends GemmaResponse {
  final String error;
  final String? errorCode;
  final Map<String, dynamic>? details;

  const ErrorResponse(this.error, {this.errorCode, this.details});

  @override
  String get responseType => 'error';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': responseType,
      'error': error,
      'errorCode': errorCode,
      'details': details,
    };
  }

  static ErrorResponse fromJson(Map<String, dynamic> json) {
    return ErrorResponse(
      json['error'] as String,
      errorCode: json['errorCode'] as String?,
      details: json['details'] != null 
          ? Map<String, dynamic>.from(json['details'] as Map)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ErrorResponse &&
        other.error == error &&
        other.errorCode == errorCode &&
        _mapEquals(other.details, details);
  }

  @override
  int get hashCode => error.hashCode ^ errorCode.hashCode ^ _mapHashCode(details);

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
    return 'ErrorResponse(error: $error, errorCode: $errorCode, details: $details)';
  }

  /// Helper method to compare maps
  bool _mapEquals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}

/// Utility class for handling streaming responses
class StreamingResponseHandler {
  final List<TextResponse> _tokens = [];
  String _completeText = '';

  /// Add a new token to the stream
  void addToken(TextResponse token) {
    _tokens.add(token);
    _completeText += token.token;
  }

  /// Get the complete text so far
  String get completeText => _completeText;

  /// Get all tokens received
  List<TextResponse> get tokens => List.unmodifiable(_tokens);

  /// Check if the response is complete
  bool get isComplete => _tokens.isNotEmpty && _tokens.last.isComplete;

  /// Clear the handler for reuse
  void clear() {
    _tokens.clear();
    _completeText = '';
  }

  /// Convert to a single complete text response
  TextResponse toCompleteResponse() {
    return TextResponse(_completeText, isComplete: true);
  }
}