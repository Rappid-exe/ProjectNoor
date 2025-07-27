import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:typed_data';

import '../../lib/models/gemma_message.dart';
import '../../lib/models/gemma_status.dart';

void main() {
  group('Enhanced Chat UI Message Tests', () {
    testWidgets('text message creates correctly', (WidgetTester tester) async {
      final textMessage = TextMessage(
        text: 'Hello, this is a test message',
        isUser: true,
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(textMessage.text),
                  Text('User: ${textMessage.isUser}'),
                  Text('Type: ${textMessage.messageType}'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Hello, this is a test message'), findsOneWidget);
      expect(find.text('User: true'), findsOneWidget);
      expect(find.text('Type: text'), findsOneWidget);
    });

    testWidgets('image message creates correctly', (WidgetTester tester) async {
      final imageBytes = Uint8List.fromList([1, 2, 3, 4]); // Dummy image data
      final imageMessage = ImageMessage(
        text: 'Image with description',
        imageBytes: imageBytes,
        isUser: true,
        imageDescription: 'Test image',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(imageMessage.text),
                  Text('Type: ${imageMessage.messageType}'),
                  Text('Image size: ${imageMessage.imageBytes.length} bytes'),
                  Text('Description: ${imageMessage.imageDescription ?? 'None'}'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Image with description'), findsOneWidget);
      expect(find.text('Type: image'), findsOneWidget);
      expect(find.text('Image size: 4 bytes'), findsOneWidget);
      expect(find.text('Description: Test image'), findsOneWidget);
    });

    testWidgets('function call message creates correctly', (WidgetTester tester) async {
      final functionMessage = FunctionCallMessage(
        functionName: 'award_achievement',
        arguments: {'achievementId': 'test_achievement', 'reason': 'Test completion'},
        isUser: false,
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(functionMessage.text),
                  Text('Type: ${functionMessage.messageType}'),
                  Text('Function: ${functionMessage.functionName}'),
                  Text('Args: ${functionMessage.arguments.length}'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Function call: award_achievement'), findsOneWidget);
      expect(find.text('Type: function_call'), findsOneWidget);
      expect(find.text('Function: award_achievement'), findsOneWidget);
      expect(find.text('Args: 2'), findsOneWidget);
    });

    testWidgets('error message detection works', (WidgetTester tester) async {
      final errorMessage = TextMessage(
        text: 'Error: Failed to generate response',
        isUser: false,
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text(errorMessage.text),
                Text('Is Error: ${errorMessage.text.startsWith('Error')}'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Error: Failed to generate response'), findsOneWidget);
      expect(find.text('Is Error: true'), findsOneWidget);
    });
  });

  group('Model Status Tests', () {
    testWidgets('model status enum values work correctly', (WidgetTester tester) async {
      const statuses = [
        ModelStatus.notDownloaded,
        ModelStatus.downloading,
        ModelStatus.ready,
        ModelStatus.error,
        ModelStatus.initializing,
        ModelStatus.initialized,
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: statuses.map((status) => 
                Text('Status: ${status.toString()}')
              ).toList(),
            ),
          ),
        ),
      );

      for (final status in statuses) {
        expect(find.text('Status: ${status.toString()}'), findsOneWidget);
      }
    });

    testWidgets('model info creates correctly', (WidgetTester tester) async {
      const modelInfo = ModelInfo(
        status: ModelStatus.downloading,
        downloadProgress: 75.5,
        error: null,
        modelSize: 1024,
        modelPath: '/path/to/model',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text('Status: ${modelInfo.status}'),
                Text('Progress: ${modelInfo.downloadProgress}%'),
                Text('Size: ${modelInfo.modelSize} bytes'),
                Text('Path: ${modelInfo.modelPath}'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Status: ModelStatus.downloading'), findsOneWidget);
      expect(find.text('Progress: 75.5%'), findsOneWidget);
      expect(find.text('Size: 1024 bytes'), findsOneWidget);
      expect(find.text('Path: /path/to/model'), findsOneWidget);
    });
  });

  group('Message Serialization Tests', () {
    test('text message serialization works', () {
      final message = TextMessage(
        text: 'Test message',
        isUser: true,
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
        id: 'test-id',
      );

      final json = message.toJson();
      expect(json['type'], equals('text'));
      expect(json['text'], equals('Test message'));
      expect(json['isUser'], equals(true));
      expect(json['id'], equals('test-id'));

      final restored = TextMessage.fromJson(json);
      expect(restored.text, equals(message.text));
      expect(restored.isUser, equals(message.isUser));
      expect(restored.id, equals(message.id));
    });

    test('function call message serialization works', () {
      final message = FunctionCallMessage(
        functionName: 'test_function',
        arguments: {'key': 'value'},
        response: {'result': 'success'},
        isUser: false,
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
      );

      final json = message.toJson();
      expect(json['type'], equals('function_call'));
      expect(json['functionName'], equals('test_function'));
      expect(json['arguments'], equals({'key': 'value'}));
      expect(json['response'], equals({'result': 'success'}));

      final restored = FunctionCallMessage.fromJson(json);
      expect(restored.functionName, equals(message.functionName));
      expect(restored.arguments, equals(message.arguments));
      expect(restored.response, equals(message.response));
    });
  });
}