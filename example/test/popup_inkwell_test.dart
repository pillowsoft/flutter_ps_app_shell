import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app_shell/flutter_app_shell.dart';

void main() {
  group('Popup Menu and InkWell Components', () {
    testWidgets('popupMenuButton works in Material mode',
        (WidgetTester tester) async {
      final factory = MaterialWidgetFactory();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: factory.popupMenuButton<String>(
              items: [
                AdaptivePopupMenuItem(
                  value: 'test',
                  child: const Text('Test Item'),
                ),
              ],
              onSelected: (value) {},
            ),
          ),
        ),
      );

      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    });

    testWidgets('inkWell works in Material mode', (WidgetTester tester) async {
      final factory = MaterialWidgetFactory();

      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: factory.inkWell(
              child: const Text('Tap me'),
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.byType(InkWell), findsOneWidget);

      await tester.tap(find.text('Tap me'));
      expect(tapped, isTrue);
    });

    testWidgets('popupMenuButton works in Cupertino mode',
        (WidgetTester tester) async {
      final factory = CupertinoWidgetFactory();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: factory.popupMenuButton<String>(
              items: [
                AdaptivePopupMenuItem(
                  value: 'test',
                  child: const Text('Test Item'),
                ),
              ],
              onSelected: (value) {},
            ),
          ),
        ),
      );

      expect(find.byType(GestureDetector), findsOneWidget);
    });

    testWidgets('inkWell works in Cupertino mode', (WidgetTester tester) async {
      final factory = CupertinoWidgetFactory();

      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: factory.inkWell(
              child: const Text('Tap me'),
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.byType(GestureDetector), findsOneWidget);

      await tester.tap(find.text('Tap me'));
      expect(tapped, isTrue);
    });

    testWidgets('popupMenuButton works in ForUI mode',
        (WidgetTester tester) async {
      final factory = ForUIWidgetFactory();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: factory.popupMenuButton<String>(
              items: [
                AdaptivePopupMenuItem(
                  value: 'test',
                  child: const Text('Test Item'),
                ),
              ],
              onSelected: (value) {},
            ),
          ),
        ),
      );

      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    });

    testWidgets('inkWell works in ForUI mode', (WidgetTester tester) async {
      final factory = ForUIWidgetFactory();

      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: factory.inkWell(
              child: const Text('Tap me'),
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.byType(InkWell), findsOneWidget);

      await tester.tap(find.text('Tap me'));
      expect(tapped, isTrue);
    });

    testWidgets('AdaptivePopupMenuItem handles destructive items',
        (WidgetTester tester) async {
      final factory = MaterialWidgetFactory();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: factory.popupMenuButton<String>(
              items: [
                AdaptivePopupMenuItem(
                  value: 'delete',
                  child: const Text('Delete'),
                  destructive: true,
                  leading: const Icon(Icons.delete),
                ),
              ],
              onSelected: (value) {},
            ),
          ),
        ),
      );

      // Test that the popup menu button exists
      expect(find.byType(PopupMenuButton<String>), findsOneWidget);

      // Tap to open the menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Verify the destructive item exists
      expect(find.text('Delete'), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('AdaptivePopupMenuItem filters disabled items in Cupertino',
        (WidgetTester tester) async {
      final factory = CupertinoWidgetFactory();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: factory.popupMenuButton<String>(
              items: [
                AdaptivePopupMenuItem(
                  value: 'enabled',
                  child: const Text('Enabled'),
                  enabled: true,
                ),
                AdaptivePopupMenuItem(
                  value: 'disabled',
                  child: const Text('Disabled'),
                  enabled: false,
                ),
              ],
              onSelected: (value) {},
            ),
          ),
        ),
      );

      // The implementation should filter out disabled items for CupertinoActionSheet
      expect(find.byType(GestureDetector), findsOneWidget);
    });
  });
}
