import 'dart:async';
import 'package:flutter/services.dart';
import 'model_download_service.dart';

class GemmaNativeService {
  static const MethodChannel _channel = MethodChannel('com.example.noor/gemma');

  // Stream controller for handling streaming responses
  StreamController<String>? _responseStreamController;

  // Track initialization status
  bool _isInitialized = false;

  GemmaNativeService() {
    // Set up method call handler for receiving data from native
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  // Handle calls from native to Flutter
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onStreamChunk':
        final chunk = call.arguments as String;
        _responseStreamController?.add(chunk);
        break;
      case 'onStreamComplete':
        _responseStreamController?.close();
        break;
      case 'onError':
        final error = call.arguments as String;
        _responseStreamController?.addError(error);
        _responseStreamController?.close();
        break;
    }
  }

  Future<bool> initializeModel() async {
    if (_isInitialized) {
      return true;
    }

    try {
      // Get the model path from download service
      final modelPath = await ModelDownloadService.getModelPath();

      // Call native method with model path
      final bool result = await _channel.invokeMethod(
        'initializeModel',
        {'modelPath': modelPath},
      );

      _isInitialized = result;
      return result;
    } on PlatformException catch (e) {
      print('Failed to initialize model: ${e.message}');
      return false;
    }
  }

  // Simple text generation (non-streaming)
  Future<String> generateText(String prompt, {
    int maxTokens = 512,
    double temperature = 0.8,
  }) async {
    if (!_isInitialized) {
      throw Exception('Model not initialized. Call initializeModel() first.');
    }

    try {
      final String response = await _channel.invokeMethod(
        'generateText',
        {
          'prompt': prompt,
          'maxTokens': maxTokens,
          'temperature': temperature,
        },
      );
      return response;
    } on PlatformException catch (e) {
      return 'Error: ${e.message}';
    }
  }

  // Streaming text generation
  Stream<String> generateTextStream(String prompt, {
    int maxTokens = 512,
    double temperature = 0.8,
  }) {
    if (!_isInitialized) {
      throw Exception('Model not initialized. Call initializeModel() first.');
    }

    // Create a new stream controller for this generation
    _responseStreamController?.close();
    _responseStreamController = StreamController<String>.broadcast();

    // Start the generation
    _channel.invokeMethod('generateTextStream', {
      'prompt': prompt,
      'maxTokens': maxTokens,
      'temperature': temperature,
    }).catchError((error) {
      _responseStreamController?.addError(error);
      _responseStreamController?.close();
    });

    return _responseStreamController!.stream;
  }

  bool get isInitialized => _isInitialized;

  void dispose() {
    _channel.invokeMethod('dispose');
    _responseStreamController?.close();
    _isInitialized = false;
  }
}
