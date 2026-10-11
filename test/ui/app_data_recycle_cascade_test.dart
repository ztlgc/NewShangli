import 'package:flutter_test/flutter_test.dart';
import 'package:newshangli/ui/app_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('trashing a person also trashes related records', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final data = AppData();
    await data.ready;

    data.createPerson(name: 'Cascade Person', relationship: 'Friend');
    final personId = data.persons
        .firstWhere((e) => e.name == 'Cascade Person')
        .id;
    data.createRecord(
      personId: personId,
      direction: RecordDirection.income,
      amountCent: 1200,
      eventName: 'Gift',
      occurredAt: DateTime(2026),
    );
    final recordId = data.records.firstWhere((e) => e.personId == personId).id;

    data.trashPerson(personId);

    expect(data.persons.any((e) => e.id == personId), false);
    expect(data.trashedPersons.any((e) => e.id == personId), true);
    expect(data.records.any((e) => e.id == recordId), false);
    expect(data.trashedRecords.any((e) => e.id == recordId), true);
  });

  test('restoring a trashed record also restores its missing person', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final data = AppData();
    await data.ready;

    data.createPerson(name: 'Restore Person', relationship: 'Friend');
    final personId = data.persons
        .firstWhere((e) => e.name == 'Restore Person')
        .id;
    data.createRecord(
      personId: personId,
      direction: RecordDirection.income,
      amountCent: 1200,
      eventName: 'Gift',
      occurredAt: DateTime(2026),
    );
    final recordId = data.records.firstWhere((e) => e.personId == personId).id;

    data.trashPerson(personId);
    data.restoreRecord(recordId);

    expect(data.persons.any((e) => e.id == personId), true);
    expect(data.trashedPersons.any((e) => e.id == personId), false);
    expect(data.records.any((e) => e.id == recordId), true);
    expect(data.trashedRecords.any((e) => e.id == recordId), false);
  });
}
