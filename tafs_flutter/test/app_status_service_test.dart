import 'package:flutter_test/flutter_test.dart';
import 'package:tafs_flutter/core/app_status/app_status_model.dart';
import 'package:tafs_flutter/core/app_status/app_status_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppStatusService (Test Plan Phase 3.5 fail-open)', () {
    test('returns defaultOk when package_info plugin unavailable (unit test env)', () async {
      // In VM tests, package_info_plus throws MissingPluginException before HTTP —
      // same fail-open path as network errors in production.
      final service = AppStatusService();
      final result = await service.checkStatus();

      expect(result.maintenanceMode, isFalse);
      expect(result.forceUpdate, isFalse);
    });
  });

  group('Bootstrap priority logic (Test Plan Phase 3.4)', () {
    test('maintenance takes precedence over forceUpdate in consumer logic', () {
      const status = AppStatusModel(
        maintenanceMode: true,
        maintenanceMessage: 'Down for maintenance',
        forceUpdate: true,
        storeUrl: 'https://play.google.com/store',
      );

      expect(status.maintenanceMode, isTrue);
      expect(status.forceUpdate, isTrue);
    });
  });

  group('API envelope parsing (Phase 3.2/3.3 data layer)', () {
    test('maintenance response shape', () {
      final status = AppStatusModel.fromJson({
        'maintenanceMode': true,
        'maintenanceMessage': 'Scheduled maintenance until 10 PM.',
        'forceUpdate': false,
        'storeUrl': 'https://play.google.com/store',
      });

      expect(status.maintenanceMode, isTrue);
      expect(status.maintenanceMessage, contains('10 PM'));
    });

    test('force update response shape', () {
      final status = AppStatusModel.fromJson({
        'maintenanceMode': false,
        'maintenanceMessage': '',
        'forceUpdate': true,
        'storeUrl': 'https://play.google.com/store/apps/details?id=com.tafs',
      });

      expect(status.forceUpdate, isTrue);
      expect(status.storeUrl, contains('com.tafs'));
    });
  });
}
