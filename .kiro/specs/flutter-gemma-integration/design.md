# Flutter Gemma Integration Design

## Overview

This design document outlines the architecture for integrating the flutter_gemma plugin to replace the current AI implementation in the Noor learning app. The new architecture will leverage the plugin's advanced capabilities including multimodal support, function calling, and efficient model management while maintaining compatibility with the existing chat interface and user experience.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Presentation Layer                       │
├─────────────────────────────────────────────────────────────────┤
│  Chat UI  │  Vision UI  │  Achievement UI  │  Course UI        │
└─────────────────────────────────────────────────────────────────┘
                                │
┌─────────────────────────────────────────────────────────────────┐
│                        Service Layer                            │
├─────────────────────────────────────────────────────────────────┤
│           FlutterGemmaService (New)                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │ Chat Manager    │  │ Vision Manager  │  │ Function Manager│ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                                │
┌─────────────────────────────────────────────────────────────────┐
│                    Flutter Gemma Plugin                        │
├─────────────────────────────────────────────────────────────────┤
│  ModelFileManager  │  InferenceModel  │  Session/Chat APIs     │
└─────────────────────────────────────────────────────────────────┘
                                │
┌─────────────────────────────────────────────────────────────────┐
│                      Native Layer                              │
├─────────────────────────────────────────────────────────────────┤
│  MediaPipe Tasks  │  Gemma 3 Nano Model  │  GPU/CPU Backend   │
└─────────────────────────────────────────────────────────────────┘
```

### Migration Strategy

The migration will be performed in phases to ensure minimal disruption:

1. **Phase 1**: Replace core AI service with flutter_gemma
2. **Phase 2**: Add vision capabilities
3. **Phase 3**: Implement function calling
4. **Phase 4**: Integrate with existing features

## Components and Interfaces

### 1. FlutterGemmaService

The main service class that replaces `GemmaNativeService` and `ModelDownloadService`.

```dart
class FlutterGemmaService {
  // Core functionality
  Future<bool> initialize();
  Future<void> dispose();
  
  // Chat management
  Future<GemmaChat> createChat({
    double temperature = 0.8,
    int randomSeed = 1,
    int topK = 1,
    bool supportImage = false,
    List<Tool>? tools,
  });
  
  // Session management for single queries
  Future<GemmaSession> createSession({
    double temperature = 0.8,
    int randomSeed = 1,
    int topK = 1,
  });
  
  // Model management
  Future<bool> isModelReady();
  Stream<double> downloadModel();
  Future<void> deleteModel();
}
```

### 2. GemmaChat

Wrapper around flutter_gemma's chat functionality with enhanced features.

```dart
class GemmaChat {
  // Text messaging
  Future<String> sendMessage(String text);
  Stream<String> sendMessageStream(String text);
  
  // Multimodal messaging
  Future<String> sendImageMessage(String text, Uint8List imageBytes);
  Stream<String> sendImageMessageStream(String text, Uint8List imageBytes);
  
  // Function calling responses
  Stream<GemmaResponse> sendMessageWithFunctions(String text);
  
  // Context management
  Future<void> clearContext();
  Future<int> getTokenCount();
  
  // Cleanup
  Future<void> close();
}
```

### 3. GemmaSession

For single-query scenarios without conversation context.

```dart
class GemmaSession {
  Future<String> query(String text);
  Stream<String> queryStream(String text);
  Future<String> queryWithImage(String text, Uint8List imageBytes);
  Future<void> close();
}
```

### 4. Message Types

Enhanced message system supporting multimodal content.

```dart
abstract class GemmaMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? id;
}

class TextMessage extends GemmaMessage {
  TextMessage({
    required String text,
    required bool isUser,
    DateTime? timestamp,
    String? id,
  });
}

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
  });
}

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
  }) : super(text: 'Function call: $functionName', isUser: isUser, timestamp: timestamp ?? DateTime.now(), id: id);
}
```

### 5. Response Types

Different types of responses from the AI.

```dart
abstract class GemmaResponse {}

class TextResponse extends GemmaResponse {
  final String token;
  TextResponse(this.token);
}

class FunctionCallResponse extends GemmaResponse {
  final String name;
  final Map<String, dynamic> args;
  FunctionCallResponse(this.name, this.args);
}

class ErrorResponse extends GemmaResponse {
  final String error;
  ErrorResponse(this.error);
}
```

### 6. Function Tools

Predefined functions the AI can call.

```dart
class GemmaTools {
  static List<Tool> getLearningTools() => [
    // Achievement system
    Tool(
      name: 'award_achievement',
      description: 'Awards an achievement to the user for completing a learning milestone',
      parameters: {
        'type': 'object',
        'properties': {
          'achievementId': {'type': 'string', 'description': 'The achievement identifier'},
          'reason': {'type': 'string', 'description': 'Why the achievement was earned'},
        },
        'required': ['achievementId', 'reason'],
      },
    ),
    
    // Course progress
    Tool(
      name: 'update_course_progress',
      description: 'Updates the user\'s progress in a course',
      parameters: {
        'type': 'object',
        'properties': {
          'courseId': {'type': 'string', 'description': 'The course identifier'},
          'moduleId': {'type': 'string', 'description': 'The module identifier'},
          'progress': {'type': 'number', 'description': 'Progress percentage (0-100)'},
        },
        'required': ['courseId', 'moduleId', 'progress'],
      },
    ),
    
    // Learning recommendations
    Tool(
      name: 'suggest_next_lesson',
      description: 'Suggests the next lesson based on user progress',
      parameters: {
        'type': 'object',
        'properties': {
          'currentTopic': {'type': 'string', 'description': 'Current learning topic'},
          'difficulty': {'type': 'string', 'enum': ['beginner', 'intermediate', 'advanced']},
        },
        'required': ['currentTopic'],
      },
    ),
  ];
}
```

## Data Models

### 1. Model Configuration

```dart
class GemmaModelConfig {
  final ModelType modelType;
  final PreferredBackend backend;
  final int maxTokens;
  final bool supportImage;
  final int maxNumImages;
  final List<Tool>? tools;
  
  const GemmaModelConfig({
    this.modelType = ModelType.gemmaIt,
    this.backend = PreferredBackend.gpu,
    this.maxTokens = 4096,
    this.supportImage = false,
    this.maxNumImages = 1,
    this.tools,
  });
}
```

### 2. Chat Configuration

```dart
class GemmaChatConfig {
  final double temperature;
  final int randomSeed;
  final int topK;
  final bool supportImage;
  final List<Tool>? tools;
  final bool supportsFunctionCalls;
  
  const GemmaChatConfig({
    this.temperature = 0.8,
    this.randomSeed = 1,
    this.topK = 1,
    this.supportImage = false,
    this.tools,
    this.supportsFunctionCalls = false,
  });
}
```

### 3. Model Status

```dart
enum ModelStatus {
  notDownloaded,
  downloading,
  ready,
  error,
  initializing,
  initialized,
}

class ModelInfo {
  final ModelStatus status;
  final double? downloadProgress;
  final String? error;
  final int? modelSize;
  final String? modelPath;
  
  const ModelInfo({
    required this.status,
    this.downloadProgress,
    this.error,
    this.modelSize,
    this.modelPath,
  });
}
```

## Error Handling

### 1. Error Types

```dart
enum GemmaErrorType {
  modelNotFound,
  modelLoadFailed,
  inferenceError,
  networkError,
  memoryError,
  platformNotSupported,
  functionCallError,
  imageProcessingError,
}

class GemmaException implements Exception {
  final GemmaErrorType type;
  final String message;
  final dynamic originalError;
  
  const GemmaException(this.type, this.message, [this.originalError]);
}
```

### 2. Error Recovery Strategies

```dart
class ErrorRecoveryManager {
  static Future<bool> handleModelError(GemmaException error) async {
    switch (error.type) {
      case GemmaErrorType.modelNotFound:
        return await _redownloadModel();
      case GemmaErrorType.memoryError:
        return await _reduceModelParameters();
      case GemmaErrorType.inferenceError:
        return await _reinitializeModel();
      default:
        return false;
    }
  }
  
  static Future<bool> _redownloadModel() async {
    // Implementation for model re-download
  }
  
  static Future<bool> _reduceModelParameters() async {
    // Implementation for reducing model parameters
  }
  
  static Future<bool> _reinitializeModel() async {
    // Implementation for model reinitialization
  }
}
```

## Testing Strategy

### 1. Unit Tests

- **FlutterGemmaService**: Test initialization, model management, and cleanup
- **GemmaChat**: Test message sending, streaming, and context management
- **Message Types**: Test serialization and deserialization
- **Error Handling**: Test error scenarios and recovery

### 2. Integration Tests

- **Model Download**: Test model download with progress tracking
- **Chat Flow**: Test complete chat conversations
- **Multimodal**: Test image processing capabilities
- **Function Calling**: Test AI function execution

### 3. Platform Tests

- **Android**: Test GPU acceleration and OpenGL support
- **iOS**: Test static linking and file sharing
- **Web**: Test MediaPipe integration

### 4. Performance Tests

- **Memory Usage**: Monitor memory consumption during inference
- **Response Time**: Measure response generation speed
- **Battery Impact**: Test battery usage on mobile devices
- **Model Loading**: Test model initialization time

## Platform-Specific Considerations

### Android

```xml
<!-- AndroidManifest.xml -->
<uses-native-library
    android:name="libOpenCL.so"
    android:required="false"/>
<uses-native-library 
    android:name="libOpenCL-car.so" 
    android:required="false"/>
<uses-native-library 
    android:name="libOpenCL-pixel.so" 
    android:required="false"/>
```

### iOS

```xml
<!-- Info.plist -->
<key>UIFileSharingEnabled</key>
<true/>
```

```ruby
# Podfile
use_frameworks! :linkage => :static
```

### Web

```html
<!-- index.html -->
<script type="module">
import { FilesetResolver, LlmInference } from 'https://cdn.jsdelivr.net/npm/@mediapipe/tasks-genai';
window.FilesetResolver = FilesetResolver;
window.LlmInference = LlmInference;
</script>
```

## Migration Plan

### Phase 1: Core Integration
1. Add flutter_gemma dependency
2. Create FlutterGemmaService
3. Replace GemmaNativeService usage
4. Update chat interface
5. Test basic functionality

### Phase 2: Enhanced Features
1. Add multimodal support
2. Implement vision capabilities
3. Update UI for image input
4. Test image processing

### Phase 3: Function Calling
1. Define learning tools
2. Implement function handlers
3. Update response handling
4. Test achievement system

### Phase 4: Optimization
1. Performance tuning
2. Memory optimization
3. Error handling improvements
4. Platform-specific optimizations

## Security Considerations

1. **Local Processing**: All AI processing happens on-device
2. **Model Integrity**: Verify model checksums during download
3. **Function Security**: Validate function call parameters
4. **Image Privacy**: Images processed locally, not sent to servers
5. **Data Persistence**: Secure storage of conversation history

## Performance Optimizations

1. **Model Caching**: Use PLE caching for memory efficiency
2. **Parameter Skipping**: Skip unused parameters (audio, vision when not needed)
3. **Session Management**: Reuse sessions when possible
4. **Memory Monitoring**: Track and optimize memory usage
5. **Background Processing**: Handle model operations in background threads