import 'package:flutter_test/flutter_test.dart';
import 'package:tafs_flutter/core/app_status/app_status_model.dart';

void main() {
  group('AppStatusModel (Test Plan Phase 3)', () {
    test('parses maintenance and force update from API envelope data', () {
      final model = AppStatusModel.fromJson({
        'maintenanceMode': true,
        'maintenanceMessage': 'Scheduled maintenance until 10 PM.',
        'forceUpdate': false,
        'storeUrl': 'https://play.google.com/store/apps/details?id=com.example',
      });

      expect(model.maintenanceMode, isTrue);
      expect(model.maintenanceMessage, 'Scheduled maintenance until 10 PM.');
      expect(model.forceUpdate, isFalse);
      expect(model.storeUrl, contains('play.google.com'));
    });

    test('defaultOk allows app through on network failure path', () {
      final model = AppStatusModel.defaultOk();

      expect(model.maintenanceMode, isFalse);
      expect(model.forceUpdate, isFalse);
      expect(model.maintenanceMessage, isEmpty);
    });

    test('force update flag parsed correctly', () {
      final model = AppStatusModel.fromJson({
        'maintenanceMode': false,
        'maintenanceMessage': '',
        'forceUpdate': true,
        'storeUrl': 'https://apps.apple.com/app/id123',
      });

      expect(model.forceUpdate, isTrue);
      expect(model.maintenanceMode, isFalse);
    });
  });
}
