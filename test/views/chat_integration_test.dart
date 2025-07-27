import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/views/chat/chat.dart';
import '../../lib/services/flutter_gemma_service.dart';

void main() {
  group('GemmaChatPage Integration Tests', () {
    setUp(() {
      // Reset the singleton instance before each test
      FlutterGemmaService.disposeInstance();
    });

    testWidgets('should display chat interface', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const GemmaChatPage(),
        ),
      );

      // Verify the basic UI elements are present
      expect(find.text('Gemma Chat'), findsOneWidget);
      expect(find.text('Start a conversation with Gemma'), findsOneWidget);
      expect(find.text('Running locally on your device'), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('should show loading state initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const GemmaChatPage(),
        ),
      );

      // Should show loading indicator
      expect(find.text('Loading Gemma model...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should have text input field', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const GemmaChatPage(),
        ),
      );

      // Pump once to build the widget
      await tester.pump();

      // Find the text field
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
    });
  });
}