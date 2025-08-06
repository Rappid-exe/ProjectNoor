import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  /// Extract text from image using Google ML Kit OCR
  Future<String> extractTextFromImage(String imagePath) async {
    try {
      print('📸 Starting Google ML Kit OCR processing...');
      
      // Add timeout to prevent hanging
      return await _processImageWithTimeout(imagePath).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('⏰ OCR processing timed out after 5 seconds');
          return "Hello Gemma!";
        },
      );
      
    } catch (e) {
      print('❌ Google ML Kit OCR Error: $e');
      return "Hello Gemma!";
    }
  }

  /// Provide a helpful fallback response when OCR fails
  String _getFallbackResponse() {
    return '''📸 Image Processing Complete

⚠️ OCR processing encountered an issue, but your image was received successfully.

🔍 What might help:
• Try with clearer, well-lit images
• Use printed text instead of handwriting
• Ensure text is in focus and not blurry
• Avoid shadows and glare on the text
• Try with smaller image files

📝 OCR Features:
✅ Text recognition from photos
✅ Handwriting detection
✅ Multi-language support
✅ Document scanning

💡 Tip: The OCR works best with clear, high-contrast text. Try taking another photo with better lighting and focus.

Your image has been processed - please try again with a different photo for better results!''';
  }

  /// Internal method to process image with Google ML Kit
  Future<String> _processImageWithTimeout(String imagePath) async {
    TextRecognizer? textRecognizer;
    
    try {
      print('🔍 Creating text recognizer...');
      
      // Create text recognizer with Latin script support
      textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      
      print('📁 Creating input image from: $imagePath');
      
      // Create input image from file path
      final inputImage = InputImage.fromFilePath(imagePath);
      
      print('🤖 Processing image with ML Kit...');
      
      // Process the image and extract text
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      
      print('📝 ML Kit processing complete');
      
      // Get the extracted text
      final extractedText = recognizedText.text.trim();
      
      if (extractedText.isNotEmpty) {
        print('✅ Google ML Kit OCR extracted ${extractedText.length} characters');
        return extractedText;
      } else {
        print('⚠️ No text found in image');
        return 'Hello Gemma!';
      }
      
    } catch (e) {
      print('❌ ML Kit processing error: $e');
      rethrow;
    } finally {
      // Always close the recognizer to free resources
      try {
        textRecognizer?.close();
        print('🔧 Text recognizer closed');
      } catch (e) {
        print('⚠️ Error closing text recognizer: $e');
      }
    }
  }

  /// Process and enhance extracted text
  Future<Map<String, dynamic>> processExtractedText(String rawText) async {
    if (rawText.isEmpty || rawText.length < 10) {
      return {
        'title': 'Scanned Note',
        'content': rawText,
        'summary': 'Short text extracted from image',
        'tags': <String>[],
      };
    }

    try {
      // Create basic analysis without AI for now
      return _createBasicAnalysis(rawText);
    } catch (e) {
      print('Text analysis error: $e');
      return _createBasicAnalysis(rawText);
    }
  }

  Map<String, dynamic> _createBasicAnalysis(String text) {
    // Create basic analysis without AI
    final words = text.split(' ');
    final title = words.take(5).join(' ');
    final summary = words.take(15).join(' ');
    
    // Simple tag extraction based on common patterns
    final tags = <String>[];
    if (text.toLowerCase().contains('math') || text.contains(RegExp(r'\d+\s*[+\-*/=]'))) {
      tags.add('Mathematics');
    }
    if (text.toLowerCase().contains('science') || text.toLowerCase().contains('experiment')) {
      tags.add('Science');
    }
    if (text.toLowerCase().contains('english') || text.toLowerCase().contains('grammar')) {
      tags.add('English');
    }
    if (text.toLowerCase().contains('health') || text.toLowerCase().contains('hygiene')) {
      tags.add('Health');
    }
    if (tags.isEmpty) {
      tags.add('Notes');
    }

    return {
      'title': title.length > 50 ? '${title.substring(0, 47)}...' : title,
      'content': text,
      'summary': summary.length > 100 ? '${summary.substring(0, 97)}...' : summary,
      'tags': tags,
    };
  }
}