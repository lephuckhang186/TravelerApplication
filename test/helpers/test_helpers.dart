import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Test helper utilities
class TestHelpers {
  /// Create a testable widget wrapped with MaterialApp
  static Widget createTestableWidget(Widget child) {
    return MaterialApp(home: child);
  }

  /// Create a widget with providers for testing
  static Widget createWidgetWithProviders({
    required Widget child,
    required List<ChangeNotifierProvider> providers,
  }) {
    return MultiProvider(
      providers: providers,
      child: MaterialApp(home: child),
    );
  }

  /// Wait for all microtasks and timers to complete
  static Future<void> pumpAndSettle(WidgetTester tester) async {
    await tester.pumpAndSettle();
  }

  /// Simulate a tap on a widget
  static Future<void> tapWidget(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Enter text into a text field
  static Future<void> enterText(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await tester.enterText(finder, text);
    await tester.pumpAndSettle();
  }

  /// Verify that a widget exists
  static void expectWidgetFound(Finder finder) {
    expect(finder, findsOneWidget);
  }

  /// Verify that a widget does not exist
  static void expectWidgetNotFound(Finder finder) {
    expect(finder, findsNothing);
  }

  /// Verify text appears on screen
  static void expectTextFound(String text) {
    expect(find.text(text), findsOneWidget);
  }
}
