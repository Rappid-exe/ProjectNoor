# Platform-Specific Configuration Guide

This document outlines the platform-specific configurations implemented for the Flutter Gemma integration.

## ✅ Android Configuration

### OpenGL Support for GPU Acceleration
- **Location**: `android/app/src/main/AndroidManifest.xml`
- **Status**: ✅ Configured
- **Libraries**:
  - `libOpenCL.so`
  - `libOpenCL-car.so`
  - `libOpenCL-pixel.so`

### Hardware Acceleration
- **Status**: ✅ Enabled
- **Configuration**: `android:hardwareAccelerated="true"`

### Permissions
- **Camera**: ✅ Configured
- **Storage**: ✅ Configured
- **Internet**: ✅ Configured

## ✅ iOS Configuration

### Static Linking
- **Location**: `ios/Podfile`
- **Status**: ✅ Configured
- **Setting**: `use_frameworks! :linkage => :static`

### File Sharing Permissions
- **Location**: `ios/Runner/Info.plist`
- **Status**: ✅ Enabled
- **Setting**: `UIFileSharingEnabled = true`

### Camera Permissions
- **Status**: ✅ Configured
- **Permissions**:
  - `NSCameraUsageDescription`
  - `NSPhotoLibraryUsageDescription`
  - `NSPhotoLibraryAddUsageDescription`

## ✅ Web Configuration

### MediaPipe Integration
- **Location**: `web/index.html`
- **Status**: ✅ Configured
- **CDN**: `https://cdn.jsdelivr.net/npm/@mediapipe/tasks-genai`

### ES6 Modules
- **Status**: ✅ Enabled
- **Components**:
  - `FilesetResolver`
  - `LlmInference`

## Platform-Specific Features

### Android
- ✅ GPU acceleration with OpenGL
- ✅ Hardware acceleration
- ✅ Vision/multimodal support
- ✅ Function calling
- ✅ Memory limit: 2GB

### iOS
- ✅ Static linking
- ✅ Metal Performance Shaders
- ✅ Vision/multimodal support
- ✅ Function calling
- ✅ Memory limit: 1.5GB
- ✅ Aggressive memory management

### Web
- ✅ MediaPipe integration
- ✅ WebAssembly support
- ✅ Text-based AI (vision limited initially)
- ✅ Function calling
- ✅ Memory limit: 512MB
- ✅ Streaming optimization

## Performance Optimizations

### Cross-Platform
- Platform detection and configuration
- Automatic fallbacks for unsupported features
- Memory management based on platform constraints
- Performance monitoring and optimization

### Testing
- Platform-specific test suites
- Integration tests for all platforms
- Performance benchmarks
- Configuration validation

## Usage

```dart
import 'package:noor/config/platform_config.dart';
import 'package:noor/utils/platform_optimizer.dart';

// Get platform-specific configuration
final config = PlatformOptimizer.getOptimizedConfig();

// Validate platform setup
final isValid = PlatformOptimizer.validatePlatformSetup();

// Get performance recommendations
final recommendations = PlatformOptimizer.getPerformanceRecommendations();
```

## Validation

Run the platform validation script:
```bash
dart scripts/validate_platform_config.dart
```

All platform configurations have been validated and are working correctly.