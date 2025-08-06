import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModelDownloadService {
  static const String _modelFileName = 'gemma-3n-E2B-it-int4.task';
  static const String _downloadUrlKey = 'https://storage.googleapis.com/noormodel/gemma-3n-E2B-it-int4.task';
  static const String _modelVersionKey = 'gemma-3n-E2B-it-int4_model_version';

  static const String defaultModelUrl = 'https://storage.googleapis.com/noormodel/gemma-3n-E2B-it-int4.task';

  static const String currentModelVersion = '1.0';

  // Get the local path where the model will be stored
  static Future<String> getModelPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$_modelFileName';
  }

  // Check if model exists and is up to date
  static Future<bool> isModelReady() async {
    final modelPath = await getModelPath();
    final modelFile = File(modelPath);

    if (!await modelFile.exists()) {
      return false;
    }

    // Check version
    final prefs = await SharedPreferences.getInstance();
    final savedVersion = prefs.getString(_modelVersionKey);

    return savedVersion == currentModelVersion;
  }

  // Get model download URL (can be updated remotely)
  static Future<String> getModelUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_downloadUrlKey) ?? defaultModelUrl;
  }

  // Update model URL (useful for remote configuration)
  static Future<void> setModelUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_downloadUrlKey, url);
  }

  // Download model with progress callback
  static Future<String?> downloadModel({
    required Function(double progress, String status) onProgress,
    required VoidCallback onComplete,
    required Function(String error) onError,
    CancelToken? cancelToken,
  }) async {
    try {
      final modelUrl = await getModelUrl();

      if (modelUrl == 'YOUR_MODEL_DOWNLOAD_URL_HERE') {
        onError('Please configure the model download URL in model_download_service.dart');
        return null;
      }

      final modelPath = await getModelPath();
      final modelFile = File(modelPath);
      final tempFile = File('$modelPath.tmp');

      // Start download
      onProgress(0.0, 'Connecting...');

      final request = http.Request('GET', Uri.parse(modelUrl));
      final response = await request.send();

      if (response.statusCode != 200) {
        throw Exception('Failed to download: HTTP ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? 0;
      int downloadedBytes = 0;

      // Create temp file
      final sink = tempFile.openWrite();

      // Listen to download stream
      final completer = Completer<void>();

      final subscription = response.stream.listen(
            (chunk) {
          if (cancelToken?.isCancelled ?? false) {
            throw Exception('Download cancelled');
          }

          sink.add(chunk);
          downloadedBytes += chunk.length;

          if (contentLength > 0) {
            final progress = downloadedBytes / contentLength;
            final sizeMB = (downloadedBytes / 1024 / 1024).toStringAsFixed(1);
            final totalMB = (contentLength / 1024 / 1024).toStringAsFixed(1);
            onProgress(progress, 'Downloading... $sizeMB MB / $totalMB MB');
          } else {
            final sizeMB = (downloadedBytes / 1024 / 1024).toStringAsFixed(1);
            onProgress(0.0, 'Downloading... $sizeMB MB');
          }
        },
        onDone: () async {
          await sink.close();

          // Move temp file to final location
          if (await modelFile.exists()) {
            await modelFile.delete();
          }
          await tempFile.rename(modelPath);

          // Save version
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_modelVersionKey, currentModelVersion);

          completer.complete();
        },
        onError: (error) async {
          await sink.close();
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
          completer.completeError(error);
        },
        cancelOnError: true,
      );

      // Handle cancellation
      cancelToken?.onCancel = () {
        subscription.cancel();
        sink.close();
        tempFile.deleteSync();
      };

      await completer.future;

      onProgress(1.0, 'Download complete!');
      onComplete();

      return modelPath;
    } catch (e) {
      onError(e.toString());
      return null;
    }
  }

  // Delete model (for cleanup or re-download)
  static Future<void> deleteModel() async {
    final modelPath = await getModelPath();
    final modelFile = File(modelPath);

    if (await modelFile.exists()) {
      await modelFile.delete();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_modelVersionKey);
  }

  // Get model size if exists
  static Future<int?> getModelSize() async {
    final modelPath = await getModelPath();
    final modelFile = File(modelPath);

    if (await modelFile.exists()) {
      return await modelFile.length();
    }

    return null;
  }
}

// Cancel token for download cancellation
class CancelToken {
  bool _isCancelled = false;
  VoidCallback? onCancel;

  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
    onCancel?.call();
  }
}