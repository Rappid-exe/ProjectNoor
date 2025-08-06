import 'package:flutter/material.dart';
import 'views/student/model_check_wrapper.dart';
import 'services/gemma_native_service.dart';
import 'services/model_download_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Gemma model on app startup for faster interactions
  _initializeGemmaModel();
  
  runApp(const MyApp());
}

/// Initialize Gemma model in the background on app startup
void _initializeGemmaModel() async {
  try {
    print('🚀 Starting Gemma model initialization on app startup...');
    
    // Check if model is available
    final isModelReady = await ModelDownloadService.isModelReady();
    if (!isModelReady) {
      print('📥 Model not downloaded yet - will initialize when available');
      return;
    }
    
    // Initialize the model service
    final gemmaService = GemmaNativeService.instance;
    final initialized = await gemmaService.initializeModel();
    
    if (initialized) {
      print('✅ Gemma model pre-initialized successfully! Interactions will be faster.');
    } else {
      print('⚠️ Model initialization completed with fallback mode');
    }
  } catch (e) {
    print('⚠️ Background model initialization failed: $e');
    // Don't block app startup - model will initialize on first use
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Noor - Educational AI Platform',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const ModelCheckWrapper(),
    );
  }
}




