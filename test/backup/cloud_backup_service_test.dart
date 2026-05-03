import 'package:flutter_test/flutter_test.dart';

import 'package:newshangli/backup/cloud_backup_service.dart';

void main() {
  group('CloudBackupService', () {
    test('isAutoBackupDue respects interval', () {
      final now = DateTime(2026, 1, 1).millisecondsSinceEpoch;
      expect(
        CloudBackupService.isAutoBackupDue(
          lastCreatedAtMs: null,
          interval: const Duration(days: 3),
          nowMs: now,
        ),
        isTrue,
      );
      expect(
        CloudBackupService.isAutoBackupDue(
          lastCreatedAtMs: now - const Duration(days: 2).inMilliseconds,
          interval: const Duration(days: 3),
          nowMs: now,
        ),
        isFalse,
      );
      expect(
        CloudBackupService.isAutoBackupDue(
          lastCreatedAtMs: now - const Duration(days: 3).inMilliseconds,
          interval: const Duration(days: 3),
          nowMs: now,
        ),
        isTrue,
      );
    });

    test('storage path rules', () {
      expect(
        CloudBackupService.buildAutoStoragePath('u1'),
        'u1/auto/latest.zip',
      );
      expect(
        CloudBackupService.buildManualStoragePath(
          userId: 'u1',
          createdAtMs: 123,
          backupId: 'b1',
        ),
        'u1/manual/123_b1.zip',
      );
    });
  });
}

