import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Manages copying the AI model from the app's assets to a persistent
/// file location for stable access by the native Gemma library.
///
/// This is necessary because the native library may hang when trying to
/// memory-map large files directly from the sandboxed asset bundle. Copying
/// it to the documents directory provides a direct, reliable file path,
/// mimicking the approach recommended in the native Google AI Edge documentation.
class ModelAssetManager {
  static const String _modelAssetName = 'assets/gemma3-1b-it-int4.task';
  static const String _modelFileName = 'gemma-3-1b-it-int4.task';

  /// Ensures the model file exists in the app's documents directory.
  ///
  /// If the file doesn't exist, it's copied from the assets. This operation
  /// only happens once. On all subsequent runs, it will quickly return the
  /// existing file's path.
  ///
  /// Returns the direct, absolute path to the model file on the device.
  Future<String> ensureModelIsCopied() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final modelPath = '${documentsDirectory.path}/$_modelFileName';
    final modelFile = File(modelPath);

    print('📋 [ModelAssetManager] Checking for model at: $modelPath');

    if (await modelFile.exists()) {
      print('✅ [ModelAssetManager] Model already exists. Skipping copy.');
    } else {
      print('⏳ [ModelAssetManager] Model not found. Copying from assets...');
      print('⚠️ [ModelAssetManager] This is a one-time operation and may take a moment.');
      try {
        final byteData = await rootBundle.load(_modelAssetName);
        await modelFile.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
        print('🎉 [ModelAssetManager] Successfully copied model to persistent storage.');
      } catch (e) {
        print('❌ [ModelAssetManager] CRITICAL: Failed to copy model from assets: $e');
        // If this fails, the app cannot function.
        throw Exception("Failed to copy model asset to device storage.");
      }
    }
    return modelPath;
  }
} 