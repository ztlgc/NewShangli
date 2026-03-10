import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:newshangli/ui/app_data.dart';

import '../test_utils.dart';

void main() {
  test('事由接口：enabledReasons 与启用约束', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final data = AppData();
    await waitAppDataReady(data);

    expect(data.enabledReasons, isNotEmpty);
    expect(data.enabledReasons.every((e) => e.enabled), isTrue);

    if (data.reasons.length == 1) {
      await data.createReason(name: '测试事由B', description: null);
    }

    final first = data.reasons.first;
    final name = first.name;
    expect(data.isReasonEnabledByName(name), isTrue);

    await data.setReasonEnabled(id: first.id, enabled: false);
    expect(data.isReasonEnabledByName(name), isFalse);

    final enabled = data.enabledReasons;
    expect(enabled, isNotEmpty);
    if (enabled.length == 1) {
      final last = enabled.single;
      await data.setReasonEnabled(id: last.id, enabled: false);
      expect(data.enabledReasons, isNotEmpty);
      expect(data.enabledReasons.single.id, last.id);
    }
  });
}
