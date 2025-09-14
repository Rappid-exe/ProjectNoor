# Design Document

## Overview

The standalone Flutter Gemma test application will be a minimal Flutter app designed to validate the flutter_gemma plugin functionality. The app will implement the core features of the flutter_gemma package including model management, initialization, and basic chat functionality. This design follows the official flutter_gemma documentation patterns and provides a clean testing environment separate from the main Noor application.

The application will use the latest flutter_gemma API (v0.10.0) which splits functionality into ModelFileManager for file handling and InferenceModel for model operations. The design prioritizes simplicity and clear error handling to facilitate debugging and validation.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────┐
│           Flutter App               │
├─────────────────────────────────────┤
│         UI Layer                    │
│  - Main Screen                      │
│  - Model Status Widget              │
│  - Chat Interface                   │
│  - Error Display                    │
├─────────────────────────────────────┤
│       Service Layer                 │
│  - Gemma Service                    │
│  - Model Manager                    │
│  - Chat Manager                     │
├─────────────────────────────────────┤
│      Flutter Gemma Plugin          │
│  - ModelFileManager                 │
│  - InferenceModel                   │
│  - Chat/Session APIs                │
└─────────────────────────────────────┘
```

### Component Structure

The app will be organized into the following main components:

1. **Main Application**: Entry point and app configuration
2. **Home Screen**: Primary UI for testing flutter_gemma functionality
3. **Gemma Service**: Wrapper service for flutter_gemma operations
4. **Model Manager**: Handles model loading and management
5. **Chat Manager**: Manages chat sessions and responses

## Components and Interfaces

### 1. Main Application (main.dart)

**Purpose**: Application entry point with basic Flutter app setup

**Key Features**:
- Material app configuration
- Home screen routing
- Basic theme setup

### 2. Home Screen (home_screen.dart)

**Purpose**: Primary UI for testing flutter_gemma functionality

**Key Features**:
- Model status display
- Model loading controls
- Chat interface
- Error message display
- Loading indicators

**UI Elements**:
- AppBar with title
- Model status card showing current state
- Load model button
- Chat message list
- Text input field for messages
- Send button
- Error display area

### 3. Gemma Service (gemma_service.dart)

**Purpose**: Service layer wrapper for flutter_gemma plugin operations

**Key Methods**:
```dart
class GemmaService {
  static final FlutterGemmaPlugin _plugin = FlutterGemmaPlugin.instance;
  
  Future<void> initializeModel();
  Future<void> loadModelFromAsset(String modelPath);
  Future<InferenceModel?> createInferenceModel();
  Future<String> sendMessage(String message);
  Future<void> closeModel();
  Stream<String> sendMessageStream(String message);
}
```

**Responsibilities**:
- Plugin initialization
- Model loading with progress tracking
- Chat session management
- Error handling and logging
- Resource cleanup

### 4. Model Manager (model_manager.dart)

**Purpose**: Handles model file operations and status tracking

**Key Features**:
- Model loading from assets
- Loading progress tracking
- Model status management
- Error handling for model operations

**State Management**:
```dart
enum ModelStatus {
  notLoaded,
  loading,
  loaded,
  error
}
```

### 5. Chat Manager (chat_manager.dart)

**Purpose**: Manages chat sessions and message handling

**Key Features**:
- Chat session creation
- Message sending and receiving
- Conversation history
- Streaming response handling

## Data Models

### Message Model
```dart
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;
  
  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });
}
```

### Model Status Model
```dart
class ModelState {
  final ModelStatus status;
  final String? errorMessage;
  final double? loadingProgress;
  final String? modelPath;
  
  ModelState({
    required this.status,
    this.errorMessage,
    this.loadingProgress,
    this.modelPath,
  });
}
```

## Error Handling

### Error Categories

1. **Model Loading Errors**:
   - File not found
   - Insufficient memory
   - Corrupted model file
   - Platform compatibility issues

2. **Inference Errors**:
   - Model not initialized
   - Token limit exceeded
   - Processing timeout
   - Memory allocation failures

3. **Chat Errors**:
   - Session creation failure
   - Message processing errors
   - Context overflow

### Error Handling Strategy

- **User-Friendly Messages**: Convert technical errors to readable messages
- **Logging**: Comprehensive logging for debugging
- **Recovery**: Graceful degradation and retry mechanisms
- **State Management**: Clear error states in UI

### Error Display

```dart
class ErrorDisplay extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback? onRetry;
  
  // Shows error with optional retry button
}
```

## Testing Strategy

### Unit Tests

1. **Service Layer Tests**:
   - GemmaService initialization
   - Model loading operations
   - Message processing
   - Error handling scenarios

2. **Model Tests**:
   - ChatMessage creation and validation
   - ModelState transitions
   - Data serialization

### Integration Tests

1. **Plugin Integration**:
   - flutter_gemma plugin initialization
   - Model loading from assets
   - Basic inference operations
   - Chat session management

2. **UI Integration**:
   - User interaction flows
   - Error state handling
   - Loading state management

### Manual Testing Scenarios

1. **Happy Path**:
   - App launch → Model load → Send message → Receive response

2. **Error Scenarios**:
   - Model loading failure
   - Inference errors
   - Memory issues
   - Network problems (if applicable)

3. **Edge Cases**:
   - Very long messages
   - Rapid message sending
   - App backgrounding during operations

## Platform-Specific Considerations

### Android Setup

- OpenGL support configuration in AndroidManifest.xml for GPU acceleration
- Memory management for model loading
- File permissions for model access

### iOS Setup

- File sharing enabled in Info.plist
- Static framework linking in Podfile
- Memory warnings handling

### Web Setup (Future)

- MediaPipe dependencies in index.html
- CORS configuration for model loading
- GPU backend requirements

## Implementation Approach

### Phase 1: Basic Setup
- Create Flutter project structure
- Add flutter_gemma dependency
- Implement basic UI layout
- Set up platform-specific configurations

### Phase 2: Model Management
- Implement model loading from assets
- Add progress tracking
- Create status management
- Handle loading errors

### Phase 3: Chat Functionality
- Implement basic chat interface
- Add message sending/receiving
- Create conversation display
- Handle inference errors

### Phase 4: Polish and Testing
- Add comprehensive error handling
- Implement logging
- Create test scenarios
- Performance optimization

## Resource Management

### Memory Management
- Proper model cleanup on app termination
- Session management to prevent memory leaks
- Token usage monitoring

### File Management
- Model file validation
- Temporary file cleanup
- Storage space monitoring

### Performance Considerations
- Lazy loading of UI components
- Efficient message rendering
- Background processing for model operations