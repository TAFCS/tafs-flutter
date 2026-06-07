import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tafs_flutter/core/app_status/app_status_screens.dart';

void main() {
  group('MaintenanceScreen (Test Plan Phase 3.2)', () {
    testWidgets('shows custom admin message and Check Again button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MaintenanceScreen(
            message: 'Scheduled maintenance until 10 PM.',
            onRetry: () async {},
          ),
        ),
      );

      expect(find.text('Under Maintenance'), findsOneWidget);
      expect(find.text('Scheduled maintenance until 10 PM.'), findsOneWidget);
      expect(find.text('Check Again'), findsOneWidget);
    });

    testWidgets('Check Again invokes onRetry callback', (tester) async {
      var retryCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: MaintenanceScreen(
            message: 'Test message',
            onRetry: () async {
              retryCount++;
            },
          ),
        ),
      );

      await tester.tap(find.text('Check Again'));
      await tester.pump();

      expect(retryCount, 1);
    });

    testWidgets('uses fallback when message is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MaintenanceScreen(
            message: '',
            onRetry: () async {},
          ),
        ),
      );

      expect(find.textContaining('scheduled system maintenance'), findsOneWidget);
    });
  });

  group('ForceUpdateScreen (Test Plan Phase 3.3)', () {
    testWidgets('shows Update Required and Update Now button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ForceUpdateScreen(storeUrl: 'https://play.google.com/store'),
        ),
      );

      expect(find.text('Update Required'), findsOneWidget);
      expect(find.text('Update Now'), findsOneWidget);
    });

    testWidgets('shows Check Again when onRetry provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ForceUpdateScreen(
            storeUrl: 'https://play.google.com/store',
            onRetry: () async {},
          ),
        ),
      );

      expect(find.text('Check Again'), findsOneWidget);
    });
  });
}
