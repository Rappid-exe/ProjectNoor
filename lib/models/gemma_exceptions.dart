/// Types of errors that can occur in the Gemma service
enum GemmaErrorType {
  modelNotFound,
  modelLoadFailed,
  inferenceError,
  networkError,
  memoryError,
  platformNotSupported,
  functionCallError,
  imageProcessingError,
  initializationError,
  configurationError,
  invalidInput,
}

/// Custom exception for Gemma-related errors
class GemmaException implements Exception {
  final GemmaErrorType type;
  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;
  
  const GemmaException(
    this.type, 
    this.message, [
    this.originalError,
    this.stackTrace,
  ]);

  /// Create a model not found exception
  factory GemmaException.modelNotFound([String? details]) {
    return GemmaException(
      GemmaErrorType.modelNotFound,
      'Model not found${details != null ? ': $details' : ''}',
    );
  }

  /// Create a model load failed exception
  factory GemmaException.modelLoadFailed([String? details, dynamic originalError]) {
    return GemmaException(
      GemmaErrorType.modelLoadFailed,
      'Failed to load model${details != null ? ': $details' : ''}',
      originalError,
    );
  }

  /// Create an inference error exception
  factory GemmaException.inferenceError([String? details, dynamic originalError]) {
    return GemmaException(
      GemmaErrorType.inferenceError,
      'Inference failed${details != null ? ': $details' : ''}',
      originalError,
    );
  }

  /// Create a network error exception
  factory GemmaException.networkError([String? details, dynamic originalError]) {
    return GemmaException(
      GemmaErrorType.networkError,
      'Network error${details != null ? ': $details' : ''}',
      originalError,
    );
  }

  /// Create a memory error exception
  factory GemmaException.memoryError([String? details]) {
    return GemmaException(
      GemmaErrorType.memoryError,
      'Memory error${details != null ? ': $details' : ''}',
    );
  }

  /// Create an initialization error exception
  factory GemmaException.initializationError([String? details, dynamic originalError]) {
    return GemmaException(
      GemmaErrorType.initializationError,
      'Initialization failed${details != null ? ': $details' : ''}',
      originalError,
    );
  }

  @override
  String toString() {
    return 'GemmaException($type): $message${originalError != null ? ' (Original: $originalError)' : ''}';
  }
}