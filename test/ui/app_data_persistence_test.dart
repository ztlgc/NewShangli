import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/ui/app_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('删除记录并清空回收站后，重启应用不会恢复', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final data = AppData();
    await data.ready;
    final target = data.records.first.id;

    data.trashRecord(target);
    data.purgeRecord(target);
    await data.flushPendingWrites();

    final restarted = AppData();
    await restarted.ready;
    expect(restarted.records.any((e) => e.id == target), false);
    expect(restarted.trashedRecords.any((e) => e.id == target), false);
    expect(restarted.findRecord(target), isNull);
  });

  test('删除联系人并清空回收站后，重启应用不会恢复', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final data = AppData();
    await data.ready;
    data.createPerson(name: '重启删除验证', relationship: '朋友');
    final target = data.persons.firstWhere((e) => e.name == '重启删除验证').id;

    data.trashPerson(target);
    data.purgePerson(target);
    await data.flushPendingWrites();

    final restarted = AppData();
    await restarted.ready;
    expect(restarted.persons.any((e) => e.id == target), false);
    expect(restarted.trashedPersons.any((e) => e.id == target), false);
    expect(restarted.findPerson(target), isNull);
  });
}
