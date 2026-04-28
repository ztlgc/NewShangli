import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum RecordDirection { income, expense }

/// 礼簿（账簿）数据。
///
/// 说明：
/// - UI 原型层会用到“所属礼簿”的展示与筛选，因此这里提供一份轻量的内存态“礼簿表”。
/// - 当记录未显式指定 bookId 时，统一按默认礼簿处理（见 [AppData.resolveBookId]）。
class BookData {
  BookData({required this.id, required this.name, required this.createdAt});

  final String id;
  final String name;
  final DateTime createdAt;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
  };

  static BookData fromJson(Object? json) {
    final map = json is Map ? json : <String, Object?>{};
    return BookData(
      id: (map['id'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      createdAt:
          DateTime.tryParse((map['createdAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class PersonData {
  PersonData({
    required this.id,
    required this.name,
    required this.relationship,
    this.phone,
    this.note,
    this.avatarUrl,
    this.birthday,
    this.isLunarBirthday = false,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String relationship;
  final String? phone;
  final String? note;
  final String? avatarUrl;
  final DateTime? birthday;
  final bool isLunarBirthday;
  final DateTime createdAt;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'name': name,
    'relationship': relationship,
    'phone': phone,
    'note': note,
    'avatarUrl': avatarUrl,
    'birthday': birthday?.toIso8601String(),
    'isLunarBirthday': isLunarBirthday,
    'createdAt': createdAt.toIso8601String(),
  };

  static PersonData fromJson(Object? json) {
    final map = json is Map ? json : <String, Object?>{};
    return PersonData(
      id: (map['id'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      relationship: (map['relationship'] as String?) ?? '',
      phone: map['phone'] as String?,
      note: map['note'] as String?,
      avatarUrl: map['avatarUrl'] as String?,
      birthday: DateTime.tryParse((map['birthday'] as String?) ?? ''),
      isLunarBirthday: (map['isLunarBirthday'] as bool?) ?? false,
      createdAt:
          DateTime.tryParse((map['createdAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class RecordData {
  RecordData({
    required this.id,
    this.bookId,
    required this.personId,
    required this.personName,
    required this.personAvatarUrl,
    required this.direction,
    required this.amountCent,
    required this.eventName,
    required this.paymentMethod,
    required this.occurredAt,
    this.note,
  });

  final String id;
  final String? bookId;
  final String personId;
  final String personName;
  final String? personAvatarUrl;
  final RecordDirection direction;
  final int amountCent;
  final String eventName;
  final String paymentMethod;
  final DateTime occurredAt;
  final String? note;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'bookId': bookId,
    'personId': personId,
    'personName': personName,
    'personAvatarUrl': personAvatarUrl,
    'direction': direction.name,
    'amountCent': amountCent,
    'eventName': eventName,
    'paymentMethod': paymentMethod,
    'occurredAt': occurredAt.toIso8601String(),
    'note': note,
  };

  static RecordData fromJson(Object? json) {
    final map = json is Map ? json : <String, Object?>{};
    final directionRaw = (map['direction'] as String?) ?? '';
    final direction = directionRaw == RecordDirection.expense.name
        ? RecordDirection.expense
        : RecordDirection.income;
    final amountRaw = map['amountCent'];
    final amount = amountRaw is num ? amountRaw.toInt() : 0;
    return RecordData(
      id: (map['id'] as String?) ?? '',
      bookId: map['bookId'] as String?,
      personId: (map['personId'] as String?) ?? '',
      personName: (map['personName'] as String?) ?? '',
      personAvatarUrl: map['personAvatarUrl'] as String?,
      direction: direction,
      amountCent: amount,
      eventName: (map['eventName'] as String?) ?? '',
      paymentMethod: (map['paymentMethod'] as String?) ?? '',
      occurredAt:
          DateTime.tryParse((map['occurredAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      note: map['note'] as String?,
    );
  }
}

class ReasonData {
  ReasonData({
    required this.id,
    required this.name,
    this.description,
    this.enabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? description;
  final bool enabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'name': name,
    'description': description,
    'enabled': enabled,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  static ReasonData fromJson(Object? json) {
    final map = json is Map ? json : <String, Object?>{};
    return ReasonData(
      id: (map['id'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      description: map['description'] as String?,
      enabled: (map['enabled'] as bool?) ?? true,
      createdAt:
          DateTime.tryParse((map['createdAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          DateTime.tryParse((map['updatedAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class RelationTypeData {
  RelationTypeData({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  static RelationTypeData fromJson(Object? json) {
    final map = json is Map ? json : <String, Object?>{};
    return RelationTypeData(
      id: (map['id'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      createdAt:
          DateTime.tryParse((map['createdAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          DateTime.tryParse((map['updatedAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class ContactRelationData {
  ContactRelationData({
    required this.id,
    required this.personAId,
    required this.personBId,
    required this.typeId,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String personAId;
  final String personBId;
  final String typeId;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'personAId': personAId,
    'personBId': personBId,
    'typeId': typeId,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  static ContactRelationData fromJson(Object? json) {
    final map = json is Map ? json : <String, Object?>{};
    return ContactRelationData(
      id: (map['id'] as String?) ?? '',
      personAId: (map['personAId'] as String?) ?? '',
      personBId: (map['personBId'] as String?) ?? '',
      typeId: (map['typeId'] as String?) ?? '',
      note: map['note'] as String?,
      createdAt:
          DateTime.tryParse((map['createdAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          DateTime.tryParse((map['updatedAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class AppData extends ChangeNotifier {
  AppData() {
    _seed();
    _prefsFuture = SharedPreferences.getInstance();
    _initFuture = _initialize();
  }

  /// 系统预设的默认礼簿 ID。
  ///
  /// 注意：
  /// - 这里使用稳定常量，便于在统计/导出/页面展示中统一兜底。
  /// - “未显式指定所属账簿”的记录会被自动归入该礼簿。
  static const String defaultBookId = 'book_default';

  /// 系统预设的默认礼簿名称（UI 展示用）。
  static const String defaultBookName = '默认礼簿';

  static const String _kReasonsKey = 'reasons_v1';
  static const String _kRelationTypesKey = 'relation_types_v1';
  static const String _kContactRelationsKey = 'contact_relations_v1';
  static const String _kCoreStateKey = 'app_core_state_v1';

  late final Future<SharedPreferences> _prefsFuture;
  late final Future<void> _initFuture;
  Future<void> _persistQueue = Future<void>.value();

  final List<BookData> _books = [];
  final List<PersonData> _persons = [];
  final List<PersonData> _trashedPersons = [];
  final List<RecordData> _records = [];
  final List<RecordData> _trashedRecords = [];
  final List<ReasonData> _reasons = [];
  final List<RelationTypeData> _relationTypes = [];
  final List<ContactRelationData> _contactRelations = [];

  bool _reasonsReady = false;
  String? _reasonsLoadError;
  bool _relationsReady = false;
  String? _relationsLoadError;

  /// 当前可用礼簿列表（内存态）。
  List<BookData> get books => List.unmodifiable(_books);

  List<PersonData> get persons => List.unmodifiable(_persons);
  List<PersonData> get trashedPersons => List.unmodifiable(_trashedPersons);
  List<RecordData> get records => List.unmodifiable(_records);
  List<RecordData> get trashedRecords => List.unmodifiable(_trashedRecords);
  List<ReasonData> get reasons => List.unmodifiable(_reasons);
  List<ReasonData> get enabledReasons =>
      List.unmodifiable(_reasons.where((e) => e.enabled));
  bool get reasonsReady => _reasonsReady;
  String? get reasonsLoadError => _reasonsLoadError;
  List<RelationTypeData> get relationTypes => List.unmodifiable(_relationTypes);
  List<ContactRelationData> get contactRelations =>
      List.unmodifiable(_contactRelations);
  bool get relationsReady => _relationsReady;
  String? get relationsLoadError => _relationsLoadError;
  Future<void> get ready => _initFuture;
  Future<void> flushPendingWrites() => _persistQueue;

  Future<void> _initialize() async {
    await _bootstrapCoreData();
    await _bootstrapReasons();
    await _bootstrapContactRelations();
  }

  /// 将“记录的 bookId”标准化为可用值：
  /// - 为 null 或空串时，返回系统默认礼簿 [defaultBookId]
  /// - 其它情况返回去空格后的原值
  String resolveBookId(String? bookId) {
    final v = bookId?.trim();
    if (v == null || v.isEmpty) return defaultBookId;
    return v;
  }

  /// 获取礼簿名称：
  /// - 优先按记录关联的 bookId 查找
  /// - 未指定或找不到时，返回默认礼簿名称
  String resolveBookName(String? bookId) {
    final id = resolveBookId(bookId);
    for (final b in _books) {
      if (b.id == id) return b.name;
    }
    return defaultBookName;
  }

  /// 检查手机号是否已存在（排除指定 ID 的联系人）
  bool isPhoneExists(String phone, {String? excludeId}) {
    String clean(String s) {
      var d = s.replaceAll(RegExp(r'\D'), '');
      if (d.startsWith('86') && d.length == 13) {
        d = d.substring(2);
      }
      return d;
    }

    final target = clean(phone);
    if (target.isEmpty) return false;

    bool match(String? p) {
      if (p == null) return false;
      return clean(p) == target;
    }

    return _persons.any((p) => p.id != excludeId && match(p.phone)) ||
        _trashedPersons.any((p) => p.id != excludeId && match(p.phone));
  }

  PersonData? findPerson(String id) {
    for (final p in _persons) {
      if (p.id == id) return p;
    }
    for (final p in _trashedPersons) {
      if (p.id == id) return p;
    }
    return null;
  }

  void createPerson({
    required String name,
    required String relationship,
    String? phone,
    String? note,
    String? avatarUrl,
    DateTime? birthday,
    bool isLunarBirthday = false,
  }) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError.value(name, 'name', '不能为空');
    }
    final now = DateTime.now();
    _persons.insert(
      0,
      PersonData(
        id: _newId('p'),
        name: trimmedName,
        relationship: relationship.trim().isEmpty ? '朋友' : relationship.trim(),
        phone: phone?.trim().isEmpty == true ? null : phone?.trim(),
        note: note?.trim().isEmpty == true ? null : note?.trim(),
        avatarUrl: avatarUrl?.trim().isEmpty == true ? null : avatarUrl?.trim(),
        birthday: birthday,
        isLunarBirthday: isLunarBirthday,
        createdAt: now,
      ),
    );
    _persistCoreDataSoon();
    notifyListeners();
  }

  void updatePerson({
    required String id,
    required String name,
    required String relationship,
    String? phone,
    String? note,
    String? avatarUrl,
    DateTime? birthday,
    bool isLunarBirthday = false,
  }) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError.value(name, 'name', '不能为空');
    }

    var idx = _persons.indexWhere((e) => e.id == id);
    var inTrash = false;
    if (idx < 0) {
      idx = _trashedPersons.indexWhere((e) => e.id == id);
      inTrash = true;
    }
    if (idx < 0) return;

    final old = inTrash ? _trashedPersons[idx] : _persons[idx];
    final updated = PersonData(
      id: old.id,
      name: trimmedName,
      relationship: relationship.trim().isEmpty
          ? old.relationship
          : relationship.trim(),
      phone: phone?.trim().isEmpty == true ? null : phone?.trim(),
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      avatarUrl: avatarUrl?.trim().isEmpty == true ? null : avatarUrl?.trim(),
      birthday: birthday,
      isLunarBirthday: isLunarBirthday,
      createdAt: old.createdAt,
    );
    if (inTrash) {
      _trashedPersons[idx] = updated;
    } else {
      _persons[idx] = updated;
    }

    _updateRecordsForPerson(updated);
    _persistCoreDataSoon();
    notifyListeners();
  }

  void _updateRecordsForPerson(PersonData p) {
    for (var i = 0; i < _records.length; i++) {
      final r = _records[i];
      if (r.personId != p.id) continue;
      _records[i] = RecordData(
        id: r.id,
        bookId: r.bookId,
        personId: r.personId,
        personName: p.name,
        personAvatarUrl: p.avatarUrl,
        direction: r.direction,
        amountCent: r.amountCent,
        eventName: r.eventName,
        paymentMethod: r.paymentMethod,
        occurredAt: r.occurredAt,
        note: r.note,
      );
    }
    for (var i = 0; i < _trashedRecords.length; i++) {
      final r = _trashedRecords[i];
      if (r.personId != p.id) continue;
      _trashedRecords[i] = RecordData(
        id: r.id,
        bookId: r.bookId,
        personId: r.personId,
        personName: p.name,
        personAvatarUrl: p.avatarUrl,
        direction: r.direction,
        amountCent: r.amountCent,
        eventName: r.eventName,
        paymentMethod: r.paymentMethod,
        occurredAt: r.occurredAt,
        note: r.note,
      );
    }
  }

  RecordData? findRecord(String id) {
    for (final r in _records) {
      if (r.id == id) return r;
    }
    for (final r in _trashedRecords) {
      if (r.id == id) return r;
    }
    return null;
  }

  void mergeImportedData({
    required Iterable<PersonData> persons,
    required Iterable<RecordData> records,
  }) {
    var changed = false;
    final personIndex = <String, int>{
      for (var i = 0; i < _persons.length; i++) _persons[i].id: i,
    };
    for (final person in persons) {
      if (person.id.trim().isEmpty || person.name.trim().isEmpty) {
        continue;
      }
      _trashedPersons.removeWhere((e) => e.id == person.id);
      final index = personIndex[person.id];
      if (index == null) {
        _persons.add(person);
        personIndex[person.id] = _persons.length - 1;
        changed = true;
      } else {
        _persons[index] = person;
        changed = true;
      }
    }
    final recordIndex = <String, int>{
      for (var i = 0; i < _records.length; i++) _records[i].id: i,
    };
    for (final record in records) {
      if (record.id.trim().isEmpty || record.personId.trim().isEmpty) {
        continue;
      }
      _trashedRecords.removeWhere((e) => e.id == record.id);
      final index = recordIndex[record.id];
      if (index == null) {
        _records.add(record);
        recordIndex[record.id] = _records.length - 1;
        changed = true;
      } else {
        _records[index] = record;
        changed = true;
      }
    }
    if (!changed) return;
    _records.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    _persons.sort((a, b) => a.name.compareTo(b.name));
    _persistCoreDataSoon();
    notifyListeners();
  }

  void createRecord({
    String? bookId,
    required String personId,
    required RecordDirection direction,
    required int amountCent,
    required String eventName,
    required String paymentMethod,
    required DateTime occurredAt,
    String? note,
  }) {
    if (amountCent <= 0) {
      throw ArgumentError.value(amountCent, 'amountCent', '必须大于 0');
    }
    final trimmedEvent = eventName.trim();
    if (trimmedEvent.isEmpty) {
      throw ArgumentError.value(eventName, 'eventName', '不能为空');
    }
    final trimmedPay = paymentMethod.trim();
    if (trimmedPay.isEmpty) {
      throw ArgumentError.value(paymentMethod, 'paymentMethod', '不能为空');
    }
    final person = findPerson(personId);
    if (person == null) {
      throw ArgumentError.value(personId, 'personId', '不存在');
    }
    _records.add(
      RecordData(
        id: _newId('r'),
        bookId: resolveBookId(bookId),
        personId: person.id,
        personName: person.name,
        personAvatarUrl: person.avatarUrl,
        direction: direction,
        amountCent: amountCent,
        eventName: trimmedEvent,
        paymentMethod: trimmedPay,
        occurredAt: occurredAt,
        note: note?.trim().isEmpty == true ? null : note?.trim(),
      ),
    );
    _records.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    _persistCoreDataSoon();
    notifyListeners();
  }

  void updateRecord({
    required String id,
    String? bookId,
    required String personId,
    required RecordDirection direction,
    required int amountCent,
    required String eventName,
    required String paymentMethod,
    required DateTime occurredAt,
    String? note,
  }) {
    final idx = _records.indexWhere((e) => e.id == id);
    if (idx < 0) return;
    if (amountCent <= 0) {
      throw ArgumentError.value(amountCent, 'amountCent', '必须大于 0');
    }
    final trimmedEvent = eventName.trim();
    if (trimmedEvent.isEmpty) {
      throw ArgumentError.value(eventName, 'eventName', '不能为空');
    }
    final trimmedPay = paymentMethod.trim();
    if (trimmedPay.isEmpty) {
      throw ArgumentError.value(paymentMethod, 'paymentMethod', '不能为空');
    }
    final person = findPerson(personId);
    if (person == null) {
      throw ArgumentError.value(personId, 'personId', '不存在');
    }
    _records[idx] = RecordData(
      id: id,
      bookId: resolveBookId(bookId),
      personId: person.id,
      personName: person.name,
      personAvatarUrl: person.avatarUrl,
      direction: direction,
      amountCent: amountCent,
      eventName: trimmedEvent,
      paymentMethod: trimmedPay,
      occurredAt: occurredAt,
      note: note?.trim().isEmpty == true ? null : note?.trim(),
    );
    _records.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    _persistCoreDataSoon();
    notifyListeners();
  }

  void trashPerson(String id) {
    final index = _persons.indexWhere((e) => e.id == id);
    if (index < 0) return;
    final movedRecords = <RecordData>[];
    _records.removeWhere((e) {
      if (e.personId != id) return false;
      movedRecords.add(e);
      return true;
    });
    if (movedRecords.isNotEmpty) {
      _trashedRecords.insertAll(0, movedRecords);
    }
    _trashedPersons.insert(0, _persons.removeAt(index));
    _persistCoreDataSoon();
    notifyListeners();
  }

  void restorePerson(String id) {
    final index = _trashedPersons.indexWhere((e) => e.id == id);
    if (index < 0) return;
    _persons.insert(0, _trashedPersons.removeAt(index));
    _persistCoreDataSoon();
    notifyListeners();
  }

  void purgePerson(String id) {
    _trashedPersons.removeWhere((e) => e.id == id);
    _persistCoreDataSoon();
    notifyListeners();
  }

  void trashRecord(String id) {
    final index = _records.indexWhere((e) => e.id == id);
    if (index < 0) return;
    _trashedRecords.insert(0, _records.removeAt(index));
    _persistCoreDataSoon();
    notifyListeners();
  }

  void trashRecords(Iterable<String> ids) {
    final idSet = ids.toSet();
    if (idSet.isEmpty) return;
    final moved = <RecordData>[];
    _records.removeWhere((e) {
      if (!idSet.contains(e.id)) return false;
      moved.add(e);
      return true;
    });
    if (moved.isEmpty) return;
    _trashedRecords.insertAll(0, moved);
    _persistCoreDataSoon();
    notifyListeners();
  }

  void restoreRecord(String id) {
    final index = _trashedRecords.indexWhere((e) => e.id == id);
    if (index < 0) return;
    final record = _trashedRecords.removeAt(index);
    if (!_persons.any((e) => e.id == record.personId)) {
      final personIndex = _trashedPersons.indexWhere(
        (e) => e.id == record.personId,
      );
      if (personIndex >= 0) {
        _persons.insert(0, _trashedPersons.removeAt(personIndex));
      } else {
        _persons.insert(
          0,
          PersonData(
            id: record.personId,
            name: record.personName.trim().isEmpty
                ? 'Unknown'
                : record.personName.trim(),
            relationship: 'Other',
            avatarUrl: record.personAvatarUrl,
            createdAt: DateTime.now(),
          ),
        );
      }
    }
    _records.insert(0, record);
    _persistCoreDataSoon();
    notifyListeners();
  }

  void purgeRecord(String id) {
    _trashedRecords.removeWhere((e) => e.id == id);
    _persistCoreDataSoon();
    notifyListeners();
  }

  Future<void> _bootstrapCoreData() async {
    try {
      final prefs = await _prefsFuture;
      final raw = prefs.getString(_kCoreStateKey);
      if (raw == null || raw.trim().isEmpty) {
        await _persistCoreData();
        return;
      }
      final decoded = jsonDecode(raw);
      final map = decoded is Map ? decoded : <String, Object?>{};
      final booksRaw = map['books'];
      final personsRaw = map['persons'];
      final trashedPersonsRaw = map['trashedPersons'];
      final recordsRaw = map['records'];
      final trashedRecordsRaw = map['trashedRecords'];

      final loadedBooks = booksRaw is List
          ? booksRaw
                .map(BookData.fromJson)
                .where((e) => e.id.isNotEmpty && e.name.isNotEmpty)
                .toList()
          : <BookData>[];
      final loadedPersons = personsRaw is List
          ? personsRaw
                .map(PersonData.fromJson)
                .where((e) => e.id.isNotEmpty && e.name.isNotEmpty)
                .toList()
          : <PersonData>[];
      final loadedTrashedPersons = trashedPersonsRaw is List
          ? trashedPersonsRaw
                .map(PersonData.fromJson)
                .where((e) => e.id.isNotEmpty && e.name.isNotEmpty)
                .toList()
          : <PersonData>[];
      final loadedRecords = recordsRaw is List
          ? recordsRaw
                .map(RecordData.fromJson)
                .where((e) => e.id.isNotEmpty && e.personId.isNotEmpty)
                .toList()
          : <RecordData>[];
      final loadedTrashedRecords = trashedRecordsRaw is List
          ? trashedRecordsRaw
                .map(RecordData.fromJson)
                .where((e) => e.id.isNotEmpty && e.personId.isNotEmpty)
                .toList()
          : <RecordData>[];

      if (loadedBooks.isEmpty) {
        await _persistCoreData();
        return;
      }

      _books
        ..clear()
        ..addAll(loadedBooks);
      _persons
        ..clear()
        ..addAll(loadedPersons);
      _trashedPersons
        ..clear()
        ..addAll(loadedTrashedPersons);
      _records
        ..clear()
        ..addAll(loadedRecords);
      _trashedRecords
        ..clear()
        ..addAll(loadedTrashedRecords);
      _records.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
      _trashedRecords.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    } catch (_) {
      await _persistCoreData();
    } finally {
      notifyListeners();
    }
  }

  void _persistCoreDataSoon() {
    _persistQueue = _persistQueue
        .then((_) => _persistCoreData())
        .catchError((_) {});
  }

  Future<void> _persistCoreData() async {
    final prefs = await _prefsFuture;
    final payload = <String, Object?>{
      'books': _books.map((e) => e.toJson()).toList(),
      'persons': _persons.map((e) => e.toJson()).toList(),
      'trashedPersons': _trashedPersons.map((e) => e.toJson()).toList(),
      'records': _records.map((e) => e.toJson()).toList(),
      'trashedRecords': _trashedRecords.map((e) => e.toJson()).toList(),
    };
    await prefs.setString(_kCoreStateKey, jsonEncode(payload));
  }

  ReasonData? findReason(String id) {
    for (final r in _reasons) {
      if (r.id == id) return r;
    }
    return null;
  }

  bool isReasonEnabledByName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    final key = trimmed.toLowerCase();
    for (final r in _reasons) {
      if (!r.enabled) continue;
      if (r.name.trim().toLowerCase() == key) return true;
    }
    return false;
  }

  Future<void> ensureReasonExists({required String name}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final key = trimmed.toLowerCase();
    final exists = _reasons.any((e) => e.name.trim().toLowerCase() == key);
    if (exists) return;
    final now = DateTime.now();
    _reasons.insert(
      0,
      ReasonData(
        id: _newId('reason'),
        name: trimmed,
        description: null,
        enabled: true,
        createdAt: now,
        updatedAt: now,
      ),
    );
    notifyListeners();
    await _persistReasons();
  }

  Future<void> setReasonEnabled({
    required String id,
    required bool enabled,
  }) async {
    final idx = _reasons.indexWhere((e) => e.id == id);
    if (idx < 0) return;
    final old = _reasons[idx];
    if (old.enabled == enabled) return;
    if (!enabled && old.enabled) {
      final enabledCount = _reasons.where((e) => e.enabled).length;
      if (enabledCount <= 1) return;
    }
    _reasons[idx] = ReasonData(
      id: old.id,
      name: old.name,
      description: old.description,
      enabled: enabled,
      createdAt: old.createdAt,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    await _persistReasons();
  }

  Future<void> createReason({required String name, String? description}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', '不能为空');
    }
    final exists = _reasons.any(
      (e) => e.name.trim().toLowerCase() == trimmed.toLowerCase(),
    );
    if (exists) {
      throw ArgumentError.value(name, 'name', '已存在同名事由');
    }
    final now = DateTime.now();
    _reasons.insert(
      0,
      ReasonData(
        id: _newId('reason'),
        name: trimmed,
        description: description?.trim().isEmpty == true
            ? null
            : description?.trim(),
        enabled: true,
        createdAt: now,
        updatedAt: now,
      ),
    );
    notifyListeners();
    await _persistReasons();
  }

  Future<void> updateReason({
    required String id,
    required String name,
    String? description,
  }) async {
    final idx = _reasons.indexWhere((e) => e.id == id);
    if (idx < 0) return;
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', '不能为空');
    }
    final exists = _reasons.any(
      (e) => e.id != id && e.name.trim().toLowerCase() == trimmed.toLowerCase(),
    );
    if (exists) {
      throw ArgumentError.value(name, 'name', '已存在同名事由');
    }
    final old = _reasons[idx];
    _reasons[idx] = ReasonData(
      id: old.id,
      name: trimmed,
      description: description?.trim().isEmpty == true
          ? null
          : description?.trim(),
      enabled: old.enabled,
      createdAt: old.createdAt,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    await _persistReasons();
  }

  Future<void> deleteReason(String id) async {
    _reasons.removeWhere((e) => e.id == id);
    notifyListeners();
    await _persistReasons();
  }

  RelationTypeData? findRelationType(String id) {
    for (final t in _relationTypes) {
      if (t.id == id) return t;
    }
    return null;
  }

  ContactRelationData? findContactRelation(String id) {
    for (final r in _contactRelations) {
      if (r.id == id) return r;
    }
    return null;
  }

  Future<void> createRelationType({required String name}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError.value(name, 'name', '不能为空');
    final exists = _relationTypes.any(
      (e) => e.name.trim().toLowerCase() == trimmed.toLowerCase(),
    );
    if (exists) throw ArgumentError.value(name, 'name', '已存在同名关系类型');
    final now = DateTime.now();
    _relationTypes.insert(
      0,
      RelationTypeData(
        id: _newId('reltype'),
        name: trimmed,
        createdAt: now,
        updatedAt: now,
      ),
    );
    notifyListeners();
    await _persistRelationTypes();
  }

  Future<void> updateRelationType({
    required String id,
    required String name,
  }) async {
    final idx = _relationTypes.indexWhere((e) => e.id == id);
    if (idx < 0) return;
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError.value(name, 'name', '不能为空');
    final exists = _relationTypes.any(
      (e) => e.id != id && e.name.trim().toLowerCase() == trimmed.toLowerCase(),
    );
    if (exists) throw ArgumentError.value(name, 'name', '已存在同名关系类型');
    final old = _relationTypes[idx];
    final oldName = old.name.trim();
    var personsChanged = false;
    if (oldName.toLowerCase() != trimmed.toLowerCase()) {
      for (var i = 0; i < _persons.length; i++) {
        final person = _persons[i];
        if (person.relationship.trim().toLowerCase() != oldName.toLowerCase()) {
          continue;
        }
        _persons[i] = PersonData(
          id: person.id,
          name: person.name,
          relationship: trimmed,
          phone: person.phone,
          note: person.note,
          avatarUrl: person.avatarUrl,
          birthday: person.birthday,
          isLunarBirthday: person.isLunarBirthday,
          createdAt: person.createdAt,
        );
        personsChanged = true;
      }
      for (var i = 0; i < _trashedPersons.length; i++) {
        final person = _trashedPersons[i];
        if (person.relationship.trim().toLowerCase() != oldName.toLowerCase()) {
          continue;
        }
        _trashedPersons[i] = PersonData(
          id: person.id,
          name: person.name,
          relationship: trimmed,
          phone: person.phone,
          note: person.note,
          avatarUrl: person.avatarUrl,
          birthday: person.birthday,
          isLunarBirthday: person.isLunarBirthday,
          createdAt: person.createdAt,
        );
        personsChanged = true;
      }
    }
    _relationTypes[idx] = RelationTypeData(
      id: old.id,
      name: trimmed,
      createdAt: old.createdAt,
      updatedAt: DateTime.now(),
    );
    if (personsChanged) {
      _persistCoreDataSoon();
    }
    notifyListeners();
    await _persistRelationTypes();
  }

  Future<void> deleteRelationType(String id) async {
    final used = _contactRelations.any((e) => e.typeId == id);
    if (used) throw StateError('该类型正在被使用，无法删除');
    final target = findRelationType(id);
    if (target == null) return;
    final name = target.name.trim().toLowerCase();
    final usedByPerson = _persons.any(
      (e) => e.relationship.trim().toLowerCase() == name,
    );
    if (usedByPerson) throw StateError('该类型已被联系人使用，无法删除');
    _relationTypes.removeWhere((e) => e.id == id);
    notifyListeners();
    await _persistRelationTypes();
  }

  Future<void> createContactRelation({
    required String personAId,
    required String personBId,
    required String typeId,
    String? note,
  }) async {
    final a = personAId.trim();
    final b = personBId.trim();
    if (a.isEmpty || b.isEmpty) throw ArgumentError('联系人不能为空');
    if (a == b) throw ArgumentError('两个联系人不能相同');
    if (findPerson(a) == null || findPerson(b) == null) {
      throw ArgumentError('联系人不存在');
    }
    if (findRelationType(typeId) == null) throw ArgumentError('关系类型不存在');
    final key = _pairKey(a, b, typeId);
    final exists = _contactRelations.any(
      (e) => _pairKey(e.personAId, e.personBId, e.typeId) == key,
    );
    if (exists) throw ArgumentError('该关系已存在');
    final now = DateTime.now();
    _contactRelations.insert(
      0,
      ContactRelationData(
        id: _newId('rel'),
        personAId: a,
        personBId: b,
        typeId: typeId,
        note: note?.trim().isEmpty == true ? null : note?.trim(),
        createdAt: now,
        updatedAt: now,
      ),
    );
    notifyListeners();
    await _persistContactRelations();
  }

  Future<void> updateContactRelation({
    required String id,
    required String personAId,
    required String personBId,
    required String typeId,
    String? note,
  }) async {
    final idx = _contactRelations.indexWhere((e) => e.id == id);
    if (idx < 0) return;
    final a = personAId.trim();
    final b = personBId.trim();
    if (a.isEmpty || b.isEmpty) throw ArgumentError('联系人不能为空');
    if (a == b) throw ArgumentError('两个联系人不能相同');
    if (findPerson(a) == null || findPerson(b) == null) {
      throw ArgumentError('联系人不存在');
    }
    if (findRelationType(typeId) == null) throw ArgumentError('关系类型不存在');
    final key = _pairKey(a, b, typeId);
    final exists = _contactRelations.any(
      (e) => e.id != id && _pairKey(e.personAId, e.personBId, e.typeId) == key,
    );
    if (exists) throw ArgumentError('该关系已存在');
    final old = _contactRelations[idx];
    _contactRelations[idx] = ContactRelationData(
      id: old.id,
      personAId: a,
      personBId: b,
      typeId: typeId,
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      createdAt: old.createdAt,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    await _persistContactRelations();
  }

  Future<void> deleteContactRelation(String id) async {
    _contactRelations.removeWhere((e) => e.id == id);
    notifyListeners();
    await _persistContactRelations();
  }

  Future<void> _bootstrapReasons() async {
    try {
      final prefs = await _prefsFuture;
      final raw = prefs.getString(_kReasonsKey);
      if (raw == null || raw.trim().isEmpty) {
        _seedReasons();
        await _persistReasons();
      } else {
        final decoded = jsonDecode(raw);
        final list = decoded is List ? decoded : const <Object?>[];
        _reasons
          ..clear()
          ..addAll(
            list
                .map(ReasonData.fromJson)
                .where((e) => e.id.isNotEmpty && e.name.isNotEmpty),
          );
        _reasons.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        if (_reasons.isEmpty) {
          _seedReasons();
          await _persistReasons();
        }
      }
      if (_reasons.isNotEmpty && !_reasons.any((e) => e.enabled)) {
        final old = _reasons.first;
        _reasons[0] = ReasonData(
          id: old.id,
          name: old.name,
          description: old.description,
          enabled: true,
          createdAt: old.createdAt,
          updatedAt: DateTime.now(),
        );
        await _persistReasons();
      }
    } catch (e) {
      _reasonsLoadError = e.toString();
      _seedReasons();
      try {
        await _persistReasons();
      } catch (_) {}
    } finally {
      _reasonsReady = true;
      notifyListeners();
    }
  }

  void _seedReasons() {
    final now = DateTime.now();
    final seen = <String>{};
    final list = <ReasonData>[];
    for (final r in _records) {
      final name = r.eventName.trim();
      if (name.isEmpty) continue;
      if (!seen.add(name.toLowerCase())) continue;
      list.add(
        ReasonData(
          id: _newId('reason'),
          name: name,
          description: null,
          enabled: true,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    if (list.isEmpty) {
      list.add(
        ReasonData(
          id: _newId('reason'),
          name: '结婚礼金',
          description: null,
          enabled: true,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    _reasons
      ..clear()
      ..addAll(list);
  }

  Future<void> _persistReasons() async {
    final prefs = await _prefsFuture;
    final raw = jsonEncode(_reasons.map((e) => e.toJson()).toList());
    await prefs.setString(_kReasonsKey, raw);
  }

  Future<void> _bootstrapContactRelations() async {
    try {
      final prefs = await _prefsFuture;
      final typeRaw = prefs.getString(_kRelationTypesKey);
      final relRaw = prefs.getString(_kContactRelationsKey);

      if (typeRaw == null || typeRaw.trim().isEmpty) {
        _seedRelationTypes();
        await _persistRelationTypes();
      } else {
        final decoded = jsonDecode(typeRaw);
        final list = decoded is List ? decoded : const <Object?>[];
        _relationTypes
          ..clear()
          ..addAll(
            list
                .map(RelationTypeData.fromJson)
                .where((e) => e.id.isNotEmpty && e.name.isNotEmpty),
          );
        _relationTypes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        if (_relationTypes.isEmpty) {
          _seedRelationTypes();
          await _persistRelationTypes();
        }
      }

      if (relRaw == null || relRaw.trim().isEmpty) {
        _seedContactRelations();
        await _persistContactRelations();
      } else {
        final decoded = jsonDecode(relRaw);
        final list = decoded is List ? decoded : const <Object?>[];
        _contactRelations
          ..clear()
          ..addAll(
            list
                .map(ContactRelationData.fromJson)
                .where(
                  (e) =>
                      e.id.isNotEmpty &&
                      e.personAId.isNotEmpty &&
                      e.personBId.isNotEmpty &&
                      e.typeId.isNotEmpty,
                ),
          );
        _contactRelations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        if (_contactRelations.isEmpty) {
          _seedContactRelations();
          await _persistContactRelations();
        }
      }
    } catch (e) {
      _relationsLoadError = e.toString();
      _seedRelationTypes();
      _seedContactRelations();
      try {
        await _persistRelationTypes();
        await _persistContactRelations();
      } catch (_) {}
    } finally {
      _relationsReady = true;
      notifyListeners();
    }
  }

  void _seedRelationTypes() {
    final now = DateTime.now();
    final list = <String>['家人', '亲戚', '同事', '朋友', '同学', '邻居'];
    _relationTypes
      ..clear()
      ..addAll(
        list.map(
          (name) => RelationTypeData(
            id: _newId('reltype'),
            name: name,
            createdAt: now,
            updatedAt: now,
          ),
        ),
      );
  }

  void _seedContactRelations() {
    final now = DateTime.now();
    String? typeIdByName(String name) {
      for (final t in _relationTypes) {
        if (t.name == name) return t.id;
      }
      return null;
    }

    final friend =
        typeIdByName('朋友') ??
        (_relationTypes.isEmpty ? _newId('reltype') : _relationTypes.first.id);
    final colleague =
        typeIdByName('同事') ??
        (_relationTypes.isEmpty ? _newId('reltype') : _relationTypes.first.id);
    final relative =
        typeIdByName('亲戚') ??
        (_relationTypes.isEmpty ? _newId('reltype') : _relationTypes.first.id);

    _contactRelations
      ..clear()
      ..addAll([
        ContactRelationData(
          id: _newId('rel'),
          personAId: 'p_zhangwei',
          personBId: 'p_wangqiang',
          typeId: friend,
          note: '同学时期认识',
          createdAt: now,
          updatedAt: now,
        ),
        ContactRelationData(
          id: _newId('rel'),
          personAId: 'p_aliang',
          personBId: 'p_wangqiang',
          typeId: colleague,
          note: null,
          createdAt: now,
          updatedAt: now,
        ),
        ContactRelationData(
          id: _newId('rel'),
          personAId: 'p_lina',
          personBId: 'p_lianguo',
          typeId: relative,
          note: '家里长辈',
          createdAt: now,
          updatedAt: now,
        ),
      ]);
  }

  Future<void> _persistRelationTypes() async {
    final prefs = await _prefsFuture;
    final raw = jsonEncode(_relationTypes.map((e) => e.toJson()).toList());
    await prefs.setString(_kRelationTypesKey, raw);
  }

  Future<void> _persistContactRelations() async {
    final prefs = await _prefsFuture;
    final raw = jsonEncode(_contactRelations.map((e) => e.toJson()).toList());
    await prefs.setString(_kContactRelationsKey, raw);
  }

  String _pairKey(String a, String b, String typeId) {
    if (a.compareTo(b) <= 0) return '$a|$b|$typeId';
    return '$b|$a|$typeId';
  }

  String _newId(String prefix) {
    final r = Random().nextInt(900) + 100;
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_$r';
  }

  void _seed() {
    final now = DateTime.now();
    final books = <BookData>[
      BookData(
        id: defaultBookId,
        name: defaultBookName,
        createdAt: now.subtract(const Duration(days: 365)),
      ),
    ];
    _books
      ..clear()
      ..addAll(books);

    final persons = <PersonData>[
      PersonData(
        id: 'p_zhangwei',
        name: '张伟',
        relationship: '朋友',
        phone: '13800000001',
        note: '大学室友，喜欢喝茶',
        avatarUrl:
            'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100&h=100&fit=crop',
        createdAt: now.subtract(const Duration(days: 320)),
      ),
      PersonData(
        id: 'p_lina',
        name: '李娜',
        relationship: '亲戚 - 表妹',
        phone: '13800000002',
        note: null,
        avatarUrl:
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&h=100&fit=crop',
        createdAt: now.subtract(const Duration(days: 280)),
      ),
      PersonData(
        id: 'p_wangqiang',
        name: '王强',
        relationship: '同学',
        phone: '13800000003',
        note: null,
        avatarUrl:
            'https://images.unsplash.com/photo-1599566150163-29194dcaad36?w=100&h=100&fit=crop',
        createdAt: now.subtract(const Duration(days: 210)),
      ),
      PersonData(
        id: 'p_zhaotiezhu',
        name: '赵铁柱',
        relationship: '邻居',
        phone: '13800000004',
        note: null,
        avatarUrl: null,
        createdAt: now.subtract(const Duration(days: 150)),
      ),
      PersonData(
        id: 'p_aliang',
        name: '阿强',
        relationship: '同事',
        phone: '13800000005',
        note: null,
        avatarUrl: null,
        createdAt: now.subtract(const Duration(days: 60)),
      ),
      PersonData(
        id: 'p_lianguo',
        name: '李建国',
        relationship: '长辈',
        phone: '13800000006',
        note: null,
        avatarUrl: null,
        createdAt: now.subtract(const Duration(days: 30)),
      ),
    ];
    _persons
      ..clear()
      ..addAll(persons);

    PersonData byId(String id) => _persons.firstWhere((p) => p.id == id);

    final records = <RecordData>[
      RecordData(
        id: 'r_20260210_zw',
        bookId: defaultBookId,
        personId: 'p_zhangwei',
        personName: byId('p_zhangwei').name,
        personAvatarUrl: byId('p_zhangwei').avatarUrl,
        direction: RecordDirection.income,
        amountCent: 200000,
        eventName: '结婚礼金',
        paymentMethod: '微信支付',
        occurredAt: DateTime(now.year, 2, 10, 12, 30),
        note: '现场收礼',
      ),
      RecordData(
        id: 'r_20260208_ln',
        bookId: defaultBookId,
        personId: 'p_lina',
        personName: byId('p_lina').name,
        personAvatarUrl: byId('p_lina').avatarUrl,
        direction: RecordDirection.expense,
        amountCent: 80000,
        eventName: '孩子满月',
        paymentMethod: '现金',
        occurredAt: DateTime(now.year, 2, 8, 19, 10),
      ),
      RecordData(
        id: 'r_20260205_wq',
        bookId: defaultBookId,
        personId: 'p_wangqiang',
        personName: byId('p_wangqiang').name,
        personAvatarUrl: byId('p_wangqiang').avatarUrl,
        direction: RecordDirection.expense,
        amountCent: 120000,
        eventName: '乔迁之喜',
        paymentMethod: '支付宝',
        occurredAt: DateTime(now.year, 2, 5, 18, 45),
      ),
      RecordData(
        id: 'r_20260124_ztz',
        bookId: defaultBookId,
        personId: 'p_zhaotiezhu',
        personName: byId('p_zhaotiezhu').name,
        personAvatarUrl: byId('p_zhaotiezhu').avatarUrl,
        direction: RecordDirection.income,
        amountCent: 50000,
        eventName: '春节红包',
        paymentMethod: '微信',
        occurredAt: DateTime(now.year, 1, 24, 10, 0),
      ),
      RecordData(
        id: 'r_20260115_lg',
        bookId: defaultBookId,
        personId: 'p_lianguo',
        personName: byId('p_lianguo').name,
        personAvatarUrl: byId('p_lianguo').avatarUrl,
        direction: RecordDirection.income,
        amountCent: 100000,
        eventName: '公司年会',
        paymentMethod: '现金',
        occurredAt: DateTime(now.year, 1, 15, 21, 5),
      ),
      RecordData(
        id: 'r_20251212_aq',
        bookId: defaultBookId,
        personId: 'p_aliang',
        personName: byId('p_aliang').name,
        personAvatarUrl: byId('p_aliang').avatarUrl,
        direction: RecordDirection.expense,
        amountCent: 30000,
        eventName: '探望',
        paymentMethod: '微信',
        occurredAt: DateTime(now.year - 1, 12, 12, 14, 20),
        note: '顺路带点心意',
      ),
    ];
    records.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    _records
      ..clear()
      ..addAll(records);
  }
}

class AppDataScope extends InheritedNotifier<AppData> {
  const AppDataScope({super.key, required AppData data, required super.child})
    : super(notifier: data);

  static AppData of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppDataScope>();
    assert(scope != null, 'AppDataScope not found in widget tree.');
    return scope!.notifier!;
  }
}
