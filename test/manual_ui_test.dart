import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/views/chat/chat.dart';

/// Manual test to verify the enhanced chat UI builds correctly
/// Run with: flutter test test/manual_ui_test.dart
void main() {
  testWidgets('Enhanced Chat UI builds without errors', (WidgetTester tester) async {
    // Build the chat page
    await tester.pumpWidget(
      MaterialApp(
        home: const GemmaChatPage(),
      ),
    );

    // Let the widget settle
    await tester.pump();

    // Verify basic UI elements are present
    expect(find.byType(GemmaChatPage), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Gemma Chat'), findsOneWidget);
    
    // Verify input area exists
    expect(find.byType(TextField), findsOneWidget);
    
    // Verify refresh button exists
    expect(find.byIcon(Icons.refresh), findsOneWidget);
    
    // The UI should build successfully even if the service isn't initialized
    print('✅ Enhanced Chat UI builds successfully');
  });

  testWidgets('Chat UI handles empty state correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const GemmaChatPage(),
      ),
    );

    await tester.pump();

    // Should show empty state message
    expect(find.textContaining('Start a conversation'), findsOneWidget);
    expect(find.textContaining('Running locally'), findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    
    print('✅ Empty state displays correctly');
  });

  testWidgets('Input area shows correct placeholder text', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const GemmaChatPage(),
      ),
    );

    await tester.pump();

    // Should show appropriate placeholder based on model status
    final textField = tester.widget<TextField>(find.byType(TextField));
    final decoration = textField.decoration;
    
    // The hint text should indicate model status
    expect(decoration?.hintText, isNotNull);
    print('✅ Input placeholder text: "${decoration?.hintText}"');
  });
}