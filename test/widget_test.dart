// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:arcgis_app_demo/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App loads without errors', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    // Verify that the app loads and shows the main navigation
    expect(find.text('ArcGIS App'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Giám sát'), findsOneWidget);
    expect(find.text('Báo cáo'), findsOneWidget);
  });

  testWidgets('Navigation works correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    // Test navigation to different tabs
    await tester.tap(find.text('Giám sát'));
    await tester.pump();
      // Should not crash and should maintain navigation state
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
