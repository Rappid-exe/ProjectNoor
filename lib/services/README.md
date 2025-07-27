# FlutterGemmaService

The `FlutterGemmaService` is a core service class that provides a unified interface for managing the Flutter Gemma AI integration in the Noor learning app.

## Features

- **Singleton Pattern**: Ensures only one instance of the service exists throughout the app lifecycle
- **Model Management**: Download, initialize, and manage AI models
- **Configuration Management**: Flexible configuration system for different model types and backends
- **Status Tracking**: Real-time status updates through streams
- **Error Handling**: Comprehensive error handling with custom exception types
- **Session Management**: Create chat sessions and single-query sessions
- **Resource Management**: Proper cleanup and disposal of resources

## Architecture

### Core Components

1. **FlutterGemmaService**: Main service class (singleton)
2. **GemmaModelConfig**: Configuration for model settings
3. **GemmaChatConfig**: Configuration for chat sessions
4. **ModelInfo**: Status information about the model
5. **GemmaException**: Custom exception types for error handling

### Status Flow

```
NotDownloaded → Downloading → Ready → Initializing → Initialized
                     ↓              ↓         ↓
                   Error ←────────────────────┘
```

## Usage

### Basic Initialization

```dart
import 'package:noor/services/flutter_gemma_service.dart';
import 'package:noor/models/gemma_config.dart';

// Get the singleton instance
final gemmaService = FlutterGemmaService.instance;

// Configure the service
const config = GemmaModelConfig(
  modelType: 'gemmaIt',
  backend: 'gpu',
  maxTokens: 2048,
  supportImage: true,
);

// Initialize the service
final success = await gemmaService.initialize(config);
if (success) {
  print('Service initialized successfully');
} else {
  print('Failed to initialize service');
}
```

### Status Monitoring

```dart
// Listen to status updates
gemmaService.statusStream.listen((status) {
  switch (status.status) {
    case ModelStatus.downloading:
      print('Downloading: ${status.downloadProgress * 100}%');
      break;
    case ModelStatus.initialized:
      print('Ready to use!');
      break;
    case ModelStatus.error:
      print('Error: ${status.error}');
      break;
    // ... handle other statuses
  }
});
```

### Model Download

```dart
try {
  await for (final progress in gemmaService.downloadModel()) {
    print('Download progress: ${(progress * 100).toStringAsFixed(1)}%');
  }
  print('Model downloaded successfully');
} catch (e) {
  print('Download failed: $e');
}
```

### Creating Sessions

```dart
// Create a chat session for conversations
final chat = await gemmaService.createChat(
  temperature: 0.8,
  topK: 5,
  supportImage: false,
);

// Create a session for single queries
final session = await gemmaService.createSession(
  temperature: 0.7,
  randomSeed: 42,
);
```

### Configuration Updates

```dart
// Update configuration (may trigger reinitialization)
const newConfig = GemmaModelConfig(
  backend: 'cpu', // Switch to CPU backend
  maxTokens: 4096,
);

await gemmaService.updateConfig(newConfig);
```

## Configuration Options

### GemmaModelConfig

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `modelType` | String | 'gemmaIt' | Type of Gemma model to use |
| `backend` | String | 'gpu' | Preferred backend ('gpu' or 'cpu') |
| `maxTokens` | int | 4096 | Maximum number of tokens |
| `supportImage` | bool | false | Enable image processing |
| `maxNumImages` | int | 1 | Maximum number of images |
| `tools` | List<dynamic>? | null | Function calling tools |

### GemmaChatConfig

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `temperature` | double | 0.8 | Randomness in responses (0.0-1.0) |
| `randomSeed` | int | 1 | Seed for reproducible results |
| `topK` | int | 1 | Top-K sampling parameter |
| `supportImage` | bool | false | Enable image input |
| `tools` | List<dynamic>? | null | Available function tools |
| `supportsFunctionCalls` | bool | false | Enable function calling |

## Error Handling

The service uses custom exception types for different error scenarios:

```dart
try {
  await gemmaService.initialize();
} on GemmaException catch (e) {
  switch (e.type) {
    case GemmaErrorType.modelNotFound:
      // Handle model not found
      break;
    case GemmaErrorType.initializationError:
      // Handle initialization failure
      break;
    case GemmaErrorType.networkError:
      // Handle network issues
      break;
    // ... handle other error types
  }
}
```

### Error Types

- `modelNotFound`: Model file not found
- `modelLoadFailed`: Failed to load model
- `inferenceError`: Error during AI inference
- `networkError`: Network-related errors
- `memoryError`: Memory allocation issues
- `initializationError`: Service initialization failure
- `configurationError`: Invalid configuration

## Testing

The service includes comprehensive unit tests covering:

- Singleton pattern behavior
- Initialization scenarios
- Configuration management
- Status tracking
- Error handling
- Resource management

Run tests with:
```bash
flutter test test/services/flutter_gemma_service_test.dart
```

## Implementation Notes

### Current Status

This implementation provides a complete foundation for the Flutter Gemma integration. The service is currently using placeholder implementations for the actual flutter_gemma package integration, which will be replaced with real implementations once the package is properly configured.

### TODOs

1. Replace placeholder model initialization with actual `InferenceModel.createFromAsset()`
2. Implement real chat and session creation using flutter_gemma APIs
3. Add proper model disposal calls
4. Integrate with actual model download mechanisms
5. Add platform-specific optimizations

### Platform Support

The service is designed to work across:
- Android (with GPU acceleration support)
- iOS (with static linking support)
- Web (with MediaPipe integration)

### Performance Considerations

- Uses singleton pattern to avoid multiple service instances
- Implements proper resource cleanup
- Supports streaming for real-time updates
- Handles memory management efficiently

### Performance Monitoring

The service provides additional methods for performance monitoring and optimization:

```dart
// Get memory usage information
final memoryInfo = await gemmaService.getMemoryInfo();
print('Memory info: $memoryInfo');

// Check GPU acceleration availability
final hasGpu = await gemmaService.isGpuAccelerationAvailable();
print('GPU available: $hasGpu');

// Optimize resource usage
await gemmaService.optimizeResources();
```

## Integration with Existing Code

To integrate with the existing `GemmaNativeService`, follow these steps:

1. Replace imports of `GemmaNativeService` with `FlutterGemmaService`
2. Update initialization calls to use the new configuration system
3. Replace direct method calls with the new session-based approach
4. Update error handling to use the new exception types

Example migration:

```dart
// Old approach
final gemmaService = GemmaNativeService();
await gemmaService.initializeModel();
final response = await gemmaService.generateText(prompt);

// New approach
final gemmaService = FlutterGemmaService.instance;
await gemmaService.initialize();
final chat = await gemmaService.createChat();
// Use chat for text generation
```

This service provides a solid foundation for the enhanced AI capabilities planned for the Noor learning app, including multimodal support, function calling, and improved performance management.