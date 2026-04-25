// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AccountBooksTable extends AccountBooks
    with TableInfo<$AccountBooksTable, AccountBook> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountBooksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK(length(name) BETWEEN 1 AND 32)',
  );
  static const VerificationMeta _reasonTypeMeta = const VerificationMeta(
    'reasonType',
  );
  @override
  late final GeneratedColumn<String> reasonType = GeneratedColumn<String>(
    'reason_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _themeColorMeta = const VerificationMeta(
    'themeColor',
  );
  @override
  late final GeneratedColumn<String> themeColor = GeneratedColumn<String>(
    'theme_color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('#312E81'),
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bookTimeMeta = const VerificationMeta(
    'bookTime',
  );
  @override
  late final GeneratedColumn<int> bookTime = GeneratedColumn<int>(
    'book_time',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL',
    clientDefault: () => DateTime.now().millisecondsSinceEpoch,
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<int> isDefault = GeneratedColumn<int>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK(is_default IN (0, 1))',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    bookId,
    name,
    reasonType,
    themeColor,
    icon,
    description,
    bookTime,
    isDefault,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'account_book';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccountBook> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('reason_type')) {
      context.handle(
        _reasonTypeMeta,
        reasonType.isAcceptableOrUnknown(data['reason_type']!, _reasonTypeMeta),
      );
    }
    if (data.containsKey('theme_color')) {
      context.handle(
        _themeColorMeta,
        themeColor.isAcceptableOrUnknown(data['theme_color']!, _themeColorMeta),
      );
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('book_time')) {
      context.handle(
        _bookTimeMeta,
        bookTime.isAcceptableOrUnknown(data['book_time']!, _bookTimeMeta),
      );
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {bookId};
  @override
  AccountBook map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountBook(
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      reasonType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason_type'],
      )!,
      themeColor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_color'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      bookTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}book_time'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_default'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $AccountBooksTable createAlias(String alias) {
    return $AccountBooksTable(attachedDatabase, alias);
  }
}

class AccountBook extends DataClass implements Insertable<AccountBook> {
  final String bookId;
  final String name;
  final String reasonType;
  final String themeColor;
  final String? icon;
  final String? description;
  final int bookTime;
  final int isDefault;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  const AccountBook({
    required this.bookId,
    required this.name,
    required this.reasonType,
    required this.themeColor,
    this.icon,
    this.description,
    required this.bookTime,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['book_id'] = Variable<String>(bookId);
    map['name'] = Variable<String>(name);
    map['reason_type'] = Variable<String>(reasonType);
    map['theme_color'] = Variable<String>(themeColor);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['book_time'] = Variable<int>(bookTime);
    map['is_default'] = Variable<int>(isDefault);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  AccountBooksCompanion toCompanion(bool nullToAbsent) {
    return AccountBooksCompanion(
      bookId: Value(bookId),
      name: Value(name),
      reasonType: Value(reasonType),
      themeColor: Value(themeColor),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      bookTime: Value(bookTime),
      isDefault: Value(isDefault),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory AccountBook.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountBook(
      bookId: serializer.fromJson<String>(json['bookId']),
      name: serializer.fromJson<String>(json['name']),
      reasonType: serializer.fromJson<String>(json['reasonType']),
      themeColor: serializer.fromJson<String>(json['themeColor']),
      icon: serializer.fromJson<String?>(json['icon']),
      description: serializer.fromJson<String?>(json['description']),
      bookTime: serializer.fromJson<int>(json['bookTime']),
      isDefault: serializer.fromJson<int>(json['isDefault']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'bookId': serializer.toJson<String>(bookId),
      'name': serializer.toJson<String>(name),
      'reasonType': serializer.toJson<String>(reasonType),
      'themeColor': serializer.toJson<String>(themeColor),
      'icon': serializer.toJson<String?>(icon),
      'description': serializer.toJson<String?>(description),
      'bookTime': serializer.toJson<int>(bookTime),
      'isDefault': serializer.toJson<int>(isDefault),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  AccountBook copyWith({
    String? bookId,
    String? name,
    String? reasonType,
    String? themeColor,
    Value<String?> icon = const Value.absent(),
    Value<String?> description = const Value.absent(),
    int? bookTime,
    int? isDefault,
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
  }) => AccountBook(
    bookId: bookId ?? this.bookId,
    name: name ?? this.name,
    reasonType: reasonType ?? this.reasonType,
    themeColor: themeColor ?? this.themeColor,
    icon: icon.present ? icon.value : this.icon,
    description: description.present ? description.value : this.description,
    bookTime: bookTime ?? this.bookTime,
    isDefault: isDefault ?? this.isDefault,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  AccountBook copyWithCompanion(AccountBooksCompanion data) {
    return AccountBook(
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      name: data.name.present ? data.name.value : this.name,
      reasonType: data.reasonType.present
          ? data.reasonType.value
          : this.reasonType,
      themeColor: data.themeColor.present
          ? data.themeColor.value
          : this.themeColor,
      icon: data.icon.present ? data.icon.value : this.icon,
      description: data.description.present
          ? data.description.value
          : this.description,
      bookTime: data.bookTime.present ? data.bookTime.value : this.bookTime,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountBook(')
          ..write('bookId: $bookId, ')
          ..write('name: $name, ')
          ..write('reasonType: $reasonType, ')
          ..write('themeColor: $themeColor, ')
          ..write('icon: $icon, ')
          ..write('description: $description, ')
          ..write('bookTime: $bookTime, ')
          ..write('isDefault: $isDefault, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    bookId,
    name,
    reasonType,
    themeColor,
    icon,
    description,
    bookTime,
    isDefault,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountBook &&
          other.bookId == this.bookId &&
          other.name == this.name &&
          other.reasonType == this.reasonType &&
          other.themeColor == this.themeColor &&
          other.icon == this.icon &&
          other.description == this.description &&
          other.bookTime == this.bookTime &&
          other.isDefault == this.isDefault &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class AccountBooksCompanion extends UpdateCompanion<AccountBook> {
  final Value<String> bookId;
  final Value<String> name;
  final Value<String> reasonType;
  final Value<String> themeColor;
  final Value<String?> icon;
  final Value<String?> description;
  final Value<int> bookTime;
  final Value<int> isDefault;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const AccountBooksCompanion({
    this.bookId = const Value.absent(),
    this.name = const Value.absent(),
    this.reasonType = const Value.absent(),
    this.themeColor = const Value.absent(),
    this.icon = const Value.absent(),
    this.description = const Value.absent(),
    this.bookTime = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountBooksCompanion.insert({
    this.bookId = const Value.absent(),
    required String name,
    this.reasonType = const Value.absent(),
    this.themeColor = const Value.absent(),
    this.icon = const Value.absent(),
    this.description = const Value.absent(),
    this.bookTime = const Value.absent(),
    this.isDefault = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<AccountBook> custom({
    Expression<String>? bookId,
    Expression<String>? name,
    Expression<String>? reasonType,
    Expression<String>? themeColor,
    Expression<String>? icon,
    Expression<String>? description,
    Expression<int>? bookTime,
    Expression<int>? isDefault,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (bookId != null) 'book_id': bookId,
      if (name != null) 'name': name,
      if (reasonType != null) 'reason_type': reasonType,
      if (themeColor != null) 'theme_color': themeColor,
      if (icon != null) 'icon': icon,
      if (description != null) 'description': description,
      if (bookTime != null) 'book_time': bookTime,
      if (isDefault != null) 'is_default': isDefault,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountBooksCompanion copyWith({
    Value<String>? bookId,
    Value<String>? name,
    Value<String>? reasonType,
    Value<String>? themeColor,
    Value<String?>? icon,
    Value<String?>? description,
    Value<int>? bookTime,
    Value<int>? isDefault,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return AccountBooksCompanion(
      bookId: bookId ?? this.bookId,
      name: name ?? this.name,
      reasonType: reasonType ?? this.reasonType,
      themeColor: themeColor ?? this.themeColor,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      bookTime: bookTime ?? this.bookTime,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (reasonType.present) {
      map['reason_type'] = Variable<String>(reasonType.value);
    }
    if (themeColor.present) {
      map['theme_color'] = Variable<String>(themeColor.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (bookTime.present) {
      map['book_time'] = Variable<int>(bookTime.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<int>(isDefault.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountBooksCompanion(')
          ..write('bookId: $bookId, ')
          ..write('name: $name, ')
          ..write('reasonType: $reasonType, ')
          ..write('themeColor: $themeColor, ')
          ..write('icon: $icon, ')
          ..write('description: $description, ')
          ..write('bookTime: $bookTime, ')
          ..write('isDefault: $isDefault, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PersonsTable extends Persons with TableInfo<$PersonsTable, Person> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PersonsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<String> personId = GeneratedColumn<String>(
    'person_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL REFERENCES account_book(book_id) ON DELETE CASCADE',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK(length(name) BETWEEN 1 AND 32)',
  );
  static const VerificationMeta _relationshipTypeMeta = const VerificationMeta(
    'relationshipType',
  );
  @override
  late final GeneratedColumn<String> relationshipType = GeneratedColumn<String>(
    'relationship_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('其他'),
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _birthdayMeta = const VerificationMeta(
    'birthday',
  );
  @override
  late final GeneratedColumn<String> birthday = GeneratedColumn<String>(
    'birthday',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _anniversaryMeta = const VerificationMeta(
    'anniversary',
  );
  @override
  late final GeneratedColumn<String> anniversary = GeneratedColumn<String>(
    'anniversary',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avatarUriMeta = const VerificationMeta(
    'avatarUri',
  );
  @override
  late final GeneratedColumn<String> avatarUri = GeneratedColumn<String>(
    'avatar_uri',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    personId,
    bookId,
    name,
    relationshipType,
    phone,
    birthday,
    anniversary,
    avatarUri,
    note,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'person';
  @override
  VerificationContext validateIntegrity(
    Insertable<Person> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('relationship_type')) {
      context.handle(
        _relationshipTypeMeta,
        relationshipType.isAcceptableOrUnknown(
          data['relationship_type']!,
          _relationshipTypeMeta,
        ),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('birthday')) {
      context.handle(
        _birthdayMeta,
        birthday.isAcceptableOrUnknown(data['birthday']!, _birthdayMeta),
      );
    }
    if (data.containsKey('anniversary')) {
      context.handle(
        _anniversaryMeta,
        anniversary.isAcceptableOrUnknown(
          data['anniversary']!,
          _anniversaryMeta,
        ),
      );
    }
    if (data.containsKey('avatar_uri')) {
      context.handle(
        _avatarUriMeta,
        avatarUri.isAcceptableOrUnknown(data['avatar_uri']!, _avatarUriMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {personId};
  @override
  Person map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Person(
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      relationshipType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relationship_type'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      birthday: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}birthday'],
      ),
      anniversary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}anniversary'],
      ),
      avatarUri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_uri'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $PersonsTable createAlias(String alias) {
    return $PersonsTable(attachedDatabase, alias);
  }
}

class Person extends DataClass implements Insertable<Person> {
  final String personId;
  final String bookId;
  final String name;
  final String relationshipType;
  final String? phone;
  final String? birthday;
  final String? anniversary;
  final String? avatarUri;
  final String? note;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  const Person({
    required this.personId,
    required this.bookId,
    required this.name,
    required this.relationshipType,
    this.phone,
    this.birthday,
    this.anniversary,
    this.avatarUri,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['person_id'] = Variable<String>(personId);
    map['book_id'] = Variable<String>(bookId);
    map['name'] = Variable<String>(name);
    map['relationship_type'] = Variable<String>(relationshipType);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || birthday != null) {
      map['birthday'] = Variable<String>(birthday);
    }
    if (!nullToAbsent || anniversary != null) {
      map['anniversary'] = Variable<String>(anniversary);
    }
    if (!nullToAbsent || avatarUri != null) {
      map['avatar_uri'] = Variable<String>(avatarUri);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  PersonsCompanion toCompanion(bool nullToAbsent) {
    return PersonsCompanion(
      personId: Value(personId),
      bookId: Value(bookId),
      name: Value(name),
      relationshipType: Value(relationshipType),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      birthday: birthday == null && nullToAbsent
          ? const Value.absent()
          : Value(birthday),
      anniversary: anniversary == null && nullToAbsent
          ? const Value.absent()
          : Value(anniversary),
      avatarUri: avatarUri == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarUri),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Person.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Person(
      personId: serializer.fromJson<String>(json['personId']),
      bookId: serializer.fromJson<String>(json['bookId']),
      name: serializer.fromJson<String>(json['name']),
      relationshipType: serializer.fromJson<String>(json['relationshipType']),
      phone: serializer.fromJson<String?>(json['phone']),
      birthday: serializer.fromJson<String?>(json['birthday']),
      anniversary: serializer.fromJson<String?>(json['anniversary']),
      avatarUri: serializer.fromJson<String?>(json['avatarUri']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'personId': serializer.toJson<String>(personId),
      'bookId': serializer.toJson<String>(bookId),
      'name': serializer.toJson<String>(name),
      'relationshipType': serializer.toJson<String>(relationshipType),
      'phone': serializer.toJson<String?>(phone),
      'birthday': serializer.toJson<String?>(birthday),
      'anniversary': serializer.toJson<String?>(anniversary),
      'avatarUri': serializer.toJson<String?>(avatarUri),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  Person copyWith({
    String? personId,
    String? bookId,
    String? name,
    String? relationshipType,
    Value<String?> phone = const Value.absent(),
    Value<String?> birthday = const Value.absent(),
    Value<String?> anniversary = const Value.absent(),
    Value<String?> avatarUri = const Value.absent(),
    Value<String?> note = const Value.absent(),
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
  }) => Person(
    personId: personId ?? this.personId,
    bookId: bookId ?? this.bookId,
    name: name ?? this.name,
    relationshipType: relationshipType ?? this.relationshipType,
    phone: phone.present ? phone.value : this.phone,
    birthday: birthday.present ? birthday.value : this.birthday,
    anniversary: anniversary.present ? anniversary.value : this.anniversary,
    avatarUri: avatarUri.present ? avatarUri.value : this.avatarUri,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Person copyWithCompanion(PersonsCompanion data) {
    return Person(
      personId: data.personId.present ? data.personId.value : this.personId,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      name: data.name.present ? data.name.value : this.name,
      relationshipType: data.relationshipType.present
          ? data.relationshipType.value
          : this.relationshipType,
      phone: data.phone.present ? data.phone.value : this.phone,
      birthday: data.birthday.present ? data.birthday.value : this.birthday,
      anniversary: data.anniversary.present
          ? data.anniversary.value
          : this.anniversary,
      avatarUri: data.avatarUri.present ? data.avatarUri.value : this.avatarUri,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Person(')
          ..write('personId: $personId, ')
          ..write('bookId: $bookId, ')
          ..write('name: $name, ')
          ..write('relationshipType: $relationshipType, ')
          ..write('phone: $phone, ')
          ..write('birthday: $birthday, ')
          ..write('anniversary: $anniversary, ')
          ..write('avatarUri: $avatarUri, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    personId,
    bookId,
    name,
    relationshipType,
    phone,
    birthday,
    anniversary,
    avatarUri,
    note,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Person &&
          other.personId == this.personId &&
          other.bookId == this.bookId &&
          other.name == this.name &&
          other.relationshipType == this.relationshipType &&
          other.phone == this.phone &&
          other.birthday == this.birthday &&
          other.anniversary == this.anniversary &&
          other.avatarUri == this.avatarUri &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class PersonsCompanion extends UpdateCompanion<Person> {
  final Value<String> personId;
  final Value<String> bookId;
  final Value<String> name;
  final Value<String> relationshipType;
  final Value<String?> phone;
  final Value<String?> birthday;
  final Value<String?> anniversary;
  final Value<String?> avatarUri;
  final Value<String?> note;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const PersonsCompanion({
    this.personId = const Value.absent(),
    this.bookId = const Value.absent(),
    this.name = const Value.absent(),
    this.relationshipType = const Value.absent(),
    this.phone = const Value.absent(),
    this.birthday = const Value.absent(),
    this.anniversary = const Value.absent(),
    this.avatarUri = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PersonsCompanion.insert({
    this.personId = const Value.absent(),
    required String bookId,
    required String name,
    this.relationshipType = const Value.absent(),
    this.phone = const Value.absent(),
    this.birthday = const Value.absent(),
    this.anniversary = const Value.absent(),
    this.avatarUri = const Value.absent(),
    this.note = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : bookId = Value(bookId),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Person> custom({
    Expression<String>? personId,
    Expression<String>? bookId,
    Expression<String>? name,
    Expression<String>? relationshipType,
    Expression<String>? phone,
    Expression<String>? birthday,
    Expression<String>? anniversary,
    Expression<String>? avatarUri,
    Expression<String>? note,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (personId != null) 'person_id': personId,
      if (bookId != null) 'book_id': bookId,
      if (name != null) 'name': name,
      if (relationshipType != null) 'relationship_type': relationshipType,
      if (phone != null) 'phone': phone,
      if (birthday != null) 'birthday': birthday,
      if (anniversary != null) 'anniversary': anniversary,
      if (avatarUri != null) 'avatar_uri': avatarUri,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PersonsCompanion copyWith({
    Value<String>? personId,
    Value<String>? bookId,
    Value<String>? name,
    Value<String>? relationshipType,
    Value<String?>? phone,
    Value<String?>? birthday,
    Value<String?>? anniversary,
    Value<String?>? avatarUri,
    Value<String?>? note,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return PersonsCompanion(
      personId: personId ?? this.personId,
      bookId: bookId ?? this.bookId,
      name: name ?? this.name,
      relationshipType: relationshipType ?? this.relationshipType,
      phone: phone ?? this.phone,
      birthday: birthday ?? this.birthday,
      anniversary: anniversary ?? this.anniversary,
      avatarUri: avatarUri ?? this.avatarUri,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (personId.present) {
      map['person_id'] = Variable<String>(personId.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (relationshipType.present) {
      map['relationship_type'] = Variable<String>(relationshipType.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (birthday.present) {
      map['birthday'] = Variable<String>(birthday.value);
    }
    if (anniversary.present) {
      map['anniversary'] = Variable<String>(anniversary.value);
    }
    if (avatarUri.present) {
      map['avatar_uri'] = Variable<String>(avatarUri.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PersonsCompanion(')
          ..write('personId: $personId, ')
          ..write('bookId: $bookId, ')
          ..write('name: $name, ')
          ..write('relationshipType: $relationshipType, ')
          ..write('phone: $phone, ')
          ..write('birthday: $birthday, ')
          ..write('anniversary: $anniversary, ')
          ..write('avatarUri: $avatarUri, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GiftRecordsTable extends GiftRecords
    with TableInfo<$GiftRecordsTable, GiftRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GiftRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL REFERENCES account_book(book_id) ON DELETE CASCADE',
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<String> personId = GeneratedColumn<String>(
    'person_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL REFERENCES person(person_id) ON DELETE CASCADE',
  );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        "NOT NULL DEFAULT '收入' CHECK(direction IN ('收入', '支出'))",
    defaultValue: const CustomExpression("'收入'"),
  );
  static const VerificationMeta _amountCentMeta = const VerificationMeta(
    'amountCent',
  );
  @override
  late final GeneratedColumn<int> amountCent = GeneratedColumn<int>(
    'amount_cent',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK(amount_cent > 0)',
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('CNY'),
  );
  static const VerificationMeta _eventNameMeta = const VerificationMeta(
    'eventName',
  );
  @override
  late final GeneratedColumn<String> eventName = GeneratedColumn<String>(
    'event_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<int> occurredAt = GeneratedColumn<int>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>?, String>
  attachments = GeneratedColumn<String>(
    'attachments',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<List<String>?>($GiftRecordsTable.$converterattachmentsn);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    recordId,
    bookId,
    personId,
    direction,
    amountCent,
    currency,
    eventName,
    occurredAt,
    paymentMethod,
    note,
    attachments,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'gift_record';
  @override
  VerificationContext validateIntegrity(
    Insertable<GiftRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personIdMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    }
    if (data.containsKey('amount_cent')) {
      context.handle(
        _amountCentMeta,
        amountCent.isAcceptableOrUnknown(data['amount_cent']!, _amountCentMeta),
      );
    } else if (isInserting) {
      context.missing(_amountCentMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('event_name')) {
      context.handle(
        _eventNameMeta,
        eventName.isAcceptableOrUnknown(data['event_name']!, _eventNameMeta),
      );
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {recordId};
  @override
  GiftRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GiftRecord(
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_id'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction'],
      )!,
      amountCent: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_cent'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      eventName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_name'],
      ),
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}occurred_at'],
      )!,
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      attachments: $GiftRecordsTable.$converterattachmentsn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}attachments'],
        ),
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $GiftRecordsTable createAlias(String alias) {
    return $GiftRecordsTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $converterattachments =
      const JsonStringListConverter();
  static TypeConverter<List<String>?, String?> $converterattachmentsn =
      NullAwareTypeConverter.wrap($converterattachments);
}

class GiftRecord extends DataClass implements Insertable<GiftRecord> {
  final String recordId;
  final String bookId;
  final String personId;
  final String direction;
  final int amountCent;
  final String currency;
  final String? eventName;
  final int occurredAt;
  final String? paymentMethod;
  final String? note;
  final List<String>? attachments;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;
  const GiftRecord({
    required this.recordId,
    required this.bookId,
    required this.personId,
    required this.direction,
    required this.amountCent,
    required this.currency,
    this.eventName,
    required this.occurredAt,
    this.paymentMethod,
    this.note,
    this.attachments,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['record_id'] = Variable<String>(recordId);
    map['book_id'] = Variable<String>(bookId);
    map['person_id'] = Variable<String>(personId);
    map['direction'] = Variable<String>(direction);
    map['amount_cent'] = Variable<int>(amountCent);
    map['currency'] = Variable<String>(currency);
    if (!nullToAbsent || eventName != null) {
      map['event_name'] = Variable<String>(eventName);
    }
    map['occurred_at'] = Variable<int>(occurredAt);
    if (!nullToAbsent || paymentMethod != null) {
      map['payment_method'] = Variable<String>(paymentMethod);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || attachments != null) {
      map['attachments'] = Variable<String>(
        $GiftRecordsTable.$converterattachmentsn.toSql(attachments),
      );
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  GiftRecordsCompanion toCompanion(bool nullToAbsent) {
    return GiftRecordsCompanion(
      recordId: Value(recordId),
      bookId: Value(bookId),
      personId: Value(personId),
      direction: Value(direction),
      amountCent: Value(amountCent),
      currency: Value(currency),
      eventName: eventName == null && nullToAbsent
          ? const Value.absent()
          : Value(eventName),
      occurredAt: Value(occurredAt),
      paymentMethod: paymentMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentMethod),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      attachments: attachments == null && nullToAbsent
          ? const Value.absent()
          : Value(attachments),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory GiftRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GiftRecord(
      recordId: serializer.fromJson<String>(json['recordId']),
      bookId: serializer.fromJson<String>(json['bookId']),
      personId: serializer.fromJson<String>(json['personId']),
      direction: serializer.fromJson<String>(json['direction']),
      amountCent: serializer.fromJson<int>(json['amountCent']),
      currency: serializer.fromJson<String>(json['currency']),
      eventName: serializer.fromJson<String?>(json['eventName']),
      occurredAt: serializer.fromJson<int>(json['occurredAt']),
      paymentMethod: serializer.fromJson<String?>(json['paymentMethod']),
      note: serializer.fromJson<String?>(json['note']),
      attachments: serializer.fromJson<List<String>?>(json['attachments']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'recordId': serializer.toJson<String>(recordId),
      'bookId': serializer.toJson<String>(bookId),
      'personId': serializer.toJson<String>(personId),
      'direction': serializer.toJson<String>(direction),
      'amountCent': serializer.toJson<int>(amountCent),
      'currency': serializer.toJson<String>(currency),
      'eventName': serializer.toJson<String?>(eventName),
      'occurredAt': serializer.toJson<int>(occurredAt),
      'paymentMethod': serializer.toJson<String?>(paymentMethod),
      'note': serializer.toJson<String?>(note),
      'attachments': serializer.toJson<List<String>?>(attachments),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  GiftRecord copyWith({
    String? recordId,
    String? bookId,
    String? personId,
    String? direction,
    int? amountCent,
    String? currency,
    Value<String?> eventName = const Value.absent(),
    int? occurredAt,
    Value<String?> paymentMethod = const Value.absent(),
    Value<String?> note = const Value.absent(),
    Value<List<String>?> attachments = const Value.absent(),
    int? createdAt,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
  }) => GiftRecord(
    recordId: recordId ?? this.recordId,
    bookId: bookId ?? this.bookId,
    personId: personId ?? this.personId,
    direction: direction ?? this.direction,
    amountCent: amountCent ?? this.amountCent,
    currency: currency ?? this.currency,
    eventName: eventName.present ? eventName.value : this.eventName,
    occurredAt: occurredAt ?? this.occurredAt,
    paymentMethod: paymentMethod.present
        ? paymentMethod.value
        : this.paymentMethod,
    note: note.present ? note.value : this.note,
    attachments: attachments.present ? attachments.value : this.attachments,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  GiftRecord copyWithCompanion(GiftRecordsCompanion data) {
    return GiftRecord(
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      personId: data.personId.present ? data.personId.value : this.personId,
      direction: data.direction.present ? data.direction.value : this.direction,
      amountCent: data.amountCent.present
          ? data.amountCent.value
          : this.amountCent,
      currency: data.currency.present ? data.currency.value : this.currency,
      eventName: data.eventName.present ? data.eventName.value : this.eventName,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      note: data.note.present ? data.note.value : this.note,
      attachments: data.attachments.present
          ? data.attachments.value
          : this.attachments,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GiftRecord(')
          ..write('recordId: $recordId, ')
          ..write('bookId: $bookId, ')
          ..write('personId: $personId, ')
          ..write('direction: $direction, ')
          ..write('amountCent: $amountCent, ')
          ..write('currency: $currency, ')
          ..write('eventName: $eventName, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('note: $note, ')
          ..write('attachments: $attachments, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    recordId,
    bookId,
    personId,
    direction,
    amountCent,
    currency,
    eventName,
    occurredAt,
    paymentMethod,
    note,
    attachments,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GiftRecord &&
          other.recordId == this.recordId &&
          other.bookId == this.bookId &&
          other.personId == this.personId &&
          other.direction == this.direction &&
          other.amountCent == this.amountCent &&
          other.currency == this.currency &&
          other.eventName == this.eventName &&
          other.occurredAt == this.occurredAt &&
          other.paymentMethod == this.paymentMethod &&
          other.note == this.note &&
          other.attachments == this.attachments &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class GiftRecordsCompanion extends UpdateCompanion<GiftRecord> {
  final Value<String> recordId;
  final Value<String> bookId;
  final Value<String> personId;
  final Value<String> direction;
  final Value<int> amountCent;
  final Value<String> currency;
  final Value<String?> eventName;
  final Value<int> occurredAt;
  final Value<String?> paymentMethod;
  final Value<String?> note;
  final Value<List<String>?> attachments;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const GiftRecordsCompanion({
    this.recordId = const Value.absent(),
    this.bookId = const Value.absent(),
    this.personId = const Value.absent(),
    this.direction = const Value.absent(),
    this.amountCent = const Value.absent(),
    this.currency = const Value.absent(),
    this.eventName = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.note = const Value.absent(),
    this.attachments = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GiftRecordsCompanion.insert({
    this.recordId = const Value.absent(),
    required String bookId,
    required String personId,
    this.direction = const Value.absent(),
    required int amountCent,
    this.currency = const Value.absent(),
    this.eventName = const Value.absent(),
    required int occurredAt,
    this.paymentMethod = const Value.absent(),
    this.note = const Value.absent(),
    this.attachments = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : bookId = Value(bookId),
       personId = Value(personId),
       amountCent = Value(amountCent),
       occurredAt = Value(occurredAt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<GiftRecord> custom({
    Expression<String>? recordId,
    Expression<String>? bookId,
    Expression<String>? personId,
    Expression<String>? direction,
    Expression<int>? amountCent,
    Expression<String>? currency,
    Expression<String>? eventName,
    Expression<int>? occurredAt,
    Expression<String>? paymentMethod,
    Expression<String>? note,
    Expression<String>? attachments,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (recordId != null) 'record_id': recordId,
      if (bookId != null) 'book_id': bookId,
      if (personId != null) 'person_id': personId,
      if (direction != null) 'direction': direction,
      if (amountCent != null) 'amount_cent': amountCent,
      if (currency != null) 'currency': currency,
      if (eventName != null) 'event_name': eventName,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (note != null) 'note': note,
      if (attachments != null) 'attachments': attachments,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GiftRecordsCompanion copyWith({
    Value<String>? recordId,
    Value<String>? bookId,
    Value<String>? personId,
    Value<String>? direction,
    Value<int>? amountCent,
    Value<String>? currency,
    Value<String?>? eventName,
    Value<int>? occurredAt,
    Value<String?>? paymentMethod,
    Value<String?>? note,
    Value<List<String>?>? attachments,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return GiftRecordsCompanion(
      recordId: recordId ?? this.recordId,
      bookId: bookId ?? this.bookId,
      personId: personId ?? this.personId,
      direction: direction ?? this.direction,
      amountCent: amountCent ?? this.amountCent,
      currency: currency ?? this.currency,
      eventName: eventName ?? this.eventName,
      occurredAt: occurredAt ?? this.occurredAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      note: note ?? this.note,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<String>(personId.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (amountCent.present) {
      map['amount_cent'] = Variable<int>(amountCent.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (eventName.present) {
      map['event_name'] = Variable<String>(eventName.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<int>(occurredAt.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (attachments.present) {
      map['attachments'] = Variable<String>(
        $GiftRecordsTable.$converterattachmentsn.toSql(attachments.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GiftRecordsCompanion(')
          ..write('recordId: $recordId, ')
          ..write('bookId: $bookId, ')
          ..write('personId: $personId, ')
          ..write('direction: $direction, ')
          ..write('amountCent: $amountCent, ')
          ..write('currency: $currency, ')
          ..write('eventName: $eventName, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('note: $note, ')
          ..write('attachments: $attachments, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReasonsTable extends Reasons with TableInfo<$ReasonsTable, Reason> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReasonsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _reasonIdMeta = const VerificationMeta(
    'reasonId',
  );
  @override
  late final GeneratedColumn<String> reasonId = GeneratedColumn<String>(
    'reason_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    reasonId,
    name,
    description,
    enabled,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reason';
  @override
  VerificationContext validateIntegrity(
    Insertable<Reason> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('reason_id')) {
      context.handle(
        _reasonIdMeta,
        reasonId.isAcceptableOrUnknown(data['reason_id']!, _reasonIdMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {reasonId};
  @override
  Reason map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Reason(
      reasonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ReasonsTable createAlias(String alias) {
    return $ReasonsTable(attachedDatabase, alias);
  }
}

class Reason extends DataClass implements Insertable<Reason> {
  final String reasonId;
  final String name;
  final String? description;
  final bool enabled;
  final int createdAt;
  final int updatedAt;
  const Reason({
    required this.reasonId,
    required this.name,
    this.description,
    required this.enabled,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['reason_id'] = Variable<String>(reasonId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['enabled'] = Variable<bool>(enabled);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ReasonsCompanion toCompanion(bool nullToAbsent) {
    return ReasonsCompanion(
      reasonId: Value(reasonId),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      enabled: Value(enabled),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Reason.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Reason(
      reasonId: serializer.fromJson<String>(json['reasonId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'reasonId': serializer.toJson<String>(reasonId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'enabled': serializer.toJson<bool>(enabled),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Reason copyWith({
    String? reasonId,
    String? name,
    Value<String?> description = const Value.absent(),
    bool? enabled,
    int? createdAt,
    int? updatedAt,
  }) => Reason(
    reasonId: reasonId ?? this.reasonId,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    enabled: enabled ?? this.enabled,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Reason copyWithCompanion(ReasonsCompanion data) {
    return Reason(
      reasonId: data.reasonId.present ? data.reasonId.value : this.reasonId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reason(')
          ..write('reasonId: $reasonId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('enabled: $enabled, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(reasonId, name, description, enabled, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reason &&
          other.reasonId == this.reasonId &&
          other.name == this.name &&
          other.description == this.description &&
          other.enabled == this.enabled &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ReasonsCompanion extends UpdateCompanion<Reason> {
  final Value<String> reasonId;
  final Value<String> name;
  final Value<String?> description;
  final Value<bool> enabled;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const ReasonsCompanion({
    this.reasonId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.enabled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReasonsCompanion.insert({
    required String reasonId,
    required String name,
    this.description = const Value.absent(),
    this.enabled = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : reasonId = Value(reasonId),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Reason> custom({
    Expression<String>? reasonId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<bool>? enabled,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (reasonId != null) 'reason_id': reasonId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (enabled != null) 'enabled': enabled,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReasonsCompanion copyWith({
    Value<String>? reasonId,
    Value<String>? name,
    Value<String?>? description,
    Value<bool>? enabled,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return ReasonsCompanion(
      reasonId: reasonId ?? this.reasonId,
      name: name ?? this.name,
      description: description ?? this.description,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (reasonId.present) {
      map['reason_id'] = Variable<String>(reasonId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReasonsCompanion(')
          ..write('reasonId: $reasonId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('enabled: $enabled, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RelationTypesTable extends RelationTypes
    with TableInfo<$RelationTypesTable, RelationType> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RelationTypesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _typeIdMeta = const VerificationMeta('typeId');
  @override
  late final GeneratedColumn<String> typeId = GeneratedColumn<String>(
    'type_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [typeId, name, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'relation_type';
  @override
  VerificationContext validateIntegrity(
    Insertable<RelationType> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('type_id')) {
      context.handle(
        _typeIdMeta,
        typeId.isAcceptableOrUnknown(data['type_id']!, _typeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_typeIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {typeId};
  @override
  RelationType map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RelationType(
      typeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $RelationTypesTable createAlias(String alias) {
    return $RelationTypesTable(attachedDatabase, alias);
  }
}

class RelationType extends DataClass implements Insertable<RelationType> {
  final String typeId;
  final String name;
  final int createdAt;
  final int updatedAt;
  const RelationType({
    required this.typeId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['type_id'] = Variable<String>(typeId);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  RelationTypesCompanion toCompanion(bool nullToAbsent) {
    return RelationTypesCompanion(
      typeId: Value(typeId),
      name: Value(name),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory RelationType.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RelationType(
      typeId: serializer.fromJson<String>(json['typeId']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'typeId': serializer.toJson<String>(typeId),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  RelationType copyWith({
    String? typeId,
    String? name,
    int? createdAt,
    int? updatedAt,
  }) => RelationType(
    typeId: typeId ?? this.typeId,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  RelationType copyWithCompanion(RelationTypesCompanion data) {
    return RelationType(
      typeId: data.typeId.present ? data.typeId.value : this.typeId,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RelationType(')
          ..write('typeId: $typeId, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(typeId, name, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RelationType &&
          other.typeId == this.typeId &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class RelationTypesCompanion extends UpdateCompanion<RelationType> {
  final Value<String> typeId;
  final Value<String> name;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const RelationTypesCompanion({
    this.typeId = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RelationTypesCompanion.insert({
    required String typeId,
    required String name,
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : typeId = Value(typeId),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<RelationType> custom({
    Expression<String>? typeId,
    Expression<String>? name,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (typeId != null) 'type_id': typeId,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RelationTypesCompanion copyWith({
    Value<String>? typeId,
    Value<String>? name,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return RelationTypesCompanion(
      typeId: typeId ?? this.typeId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (typeId.present) {
      map['type_id'] = Variable<String>(typeId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RelationTypesCompanion(')
          ..write('typeId: $typeId, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContactRelationsTable extends ContactRelations
    with TableInfo<$ContactRelationsTable, ContactRelation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContactRelationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _relationIdMeta = const VerificationMeta(
    'relationId',
  );
  @override
  late final GeneratedColumn<String> relationId = GeneratedColumn<String>(
    'relation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _personAIdMeta = const VerificationMeta(
    'personAId',
  );
  @override
  late final GeneratedColumn<String> personAId = GeneratedColumn<String>(
    'person_a_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL REFERENCES person(person_id) ON DELETE CASCADE',
  );
  static const VerificationMeta _personBIdMeta = const VerificationMeta(
    'personBId',
  );
  @override
  late final GeneratedColumn<String> personBId = GeneratedColumn<String>(
    'person_b_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL REFERENCES person(person_id) ON DELETE CASCADE',
  );
  static const VerificationMeta _typeIdMeta = const VerificationMeta('typeId');
  @override
  late final GeneratedColumn<String> typeId = GeneratedColumn<String>(
    'type_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL REFERENCES relation_type(type_id) ON DELETE RESTRICT',
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    relationId,
    personAId,
    personBId,
    typeId,
    note,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contact_relation';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContactRelation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('relation_id')) {
      context.handle(
        _relationIdMeta,
        relationId.isAcceptableOrUnknown(data['relation_id']!, _relationIdMeta),
      );
    } else if (isInserting) {
      context.missing(_relationIdMeta);
    }
    if (data.containsKey('person_a_id')) {
      context.handle(
        _personAIdMeta,
        personAId.isAcceptableOrUnknown(data['person_a_id']!, _personAIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personAIdMeta);
    }
    if (data.containsKey('person_b_id')) {
      context.handle(
        _personBIdMeta,
        personBId.isAcceptableOrUnknown(data['person_b_id']!, _personBIdMeta),
      );
    } else if (isInserting) {
      context.missing(_personBIdMeta);
    }
    if (data.containsKey('type_id')) {
      context.handle(
        _typeIdMeta,
        typeId.isAcceptableOrUnknown(data['type_id']!, _typeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_typeIdMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {relationId};
  @override
  ContactRelation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContactRelation(
      relationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relation_id'],
      )!,
      personAId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_a_id'],
      )!,
      personBId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_b_id'],
      )!,
      typeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type_id'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ContactRelationsTable createAlias(String alias) {
    return $ContactRelationsTable(attachedDatabase, alias);
  }
}

class ContactRelation extends DataClass implements Insertable<ContactRelation> {
  final String relationId;
  final String personAId;
  final String personBId;
  final String typeId;
  final String? note;
  final int createdAt;
  final int updatedAt;
  const ContactRelation({
    required this.relationId,
    required this.personAId,
    required this.personBId,
    required this.typeId,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['relation_id'] = Variable<String>(relationId);
    map['person_a_id'] = Variable<String>(personAId);
    map['person_b_id'] = Variable<String>(personBId);
    map['type_id'] = Variable<String>(typeId);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ContactRelationsCompanion toCompanion(bool nullToAbsent) {
    return ContactRelationsCompanion(
      relationId: Value(relationId),
      personAId: Value(personAId),
      personBId: Value(personBId),
      typeId: Value(typeId),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ContactRelation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContactRelation(
      relationId: serializer.fromJson<String>(json['relationId']),
      personAId: serializer.fromJson<String>(json['personAId']),
      personBId: serializer.fromJson<String>(json['personBId']),
      typeId: serializer.fromJson<String>(json['typeId']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'relationId': serializer.toJson<String>(relationId),
      'personAId': serializer.toJson<String>(personAId),
      'personBId': serializer.toJson<String>(personBId),
      'typeId': serializer.toJson<String>(typeId),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ContactRelation copyWith({
    String? relationId,
    String? personAId,
    String? personBId,
    String? typeId,
    Value<String?> note = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => ContactRelation(
    relationId: relationId ?? this.relationId,
    personAId: personAId ?? this.personAId,
    personBId: personBId ?? this.personBId,
    typeId: typeId ?? this.typeId,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ContactRelation copyWithCompanion(ContactRelationsCompanion data) {
    return ContactRelation(
      relationId: data.relationId.present
          ? data.relationId.value
          : this.relationId,
      personAId: data.personAId.present ? data.personAId.value : this.personAId,
      personBId: data.personBId.present ? data.personBId.value : this.personBId,
      typeId: data.typeId.present ? data.typeId.value : this.typeId,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContactRelation(')
          ..write('relationId: $relationId, ')
          ..write('personAId: $personAId, ')
          ..write('personBId: $personBId, ')
          ..write('typeId: $typeId, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    relationId,
    personAId,
    personBId,
    typeId,
    note,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContactRelation &&
          other.relationId == this.relationId &&
          other.personAId == this.personAId &&
          other.personBId == this.personBId &&
          other.typeId == this.typeId &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ContactRelationsCompanion extends UpdateCompanion<ContactRelation> {
  final Value<String> relationId;
  final Value<String> personAId;
  final Value<String> personBId;
  final Value<String> typeId;
  final Value<String?> note;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const ContactRelationsCompanion({
    this.relationId = const Value.absent(),
    this.personAId = const Value.absent(),
    this.personBId = const Value.absent(),
    this.typeId = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContactRelationsCompanion.insert({
    required String relationId,
    required String personAId,
    required String personBId,
    required String typeId,
    this.note = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : relationId = Value(relationId),
       personAId = Value(personAId),
       personBId = Value(personBId),
       typeId = Value(typeId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ContactRelation> custom({
    Expression<String>? relationId,
    Expression<String>? personAId,
    Expression<String>? personBId,
    Expression<String>? typeId,
    Expression<String>? note,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (relationId != null) 'relation_id': relationId,
      if (personAId != null) 'person_a_id': personAId,
      if (personBId != null) 'person_b_id': personBId,
      if (typeId != null) 'type_id': typeId,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContactRelationsCompanion copyWith({
    Value<String>? relationId,
    Value<String>? personAId,
    Value<String>? personBId,
    Value<String>? typeId,
    Value<String?>? note,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return ContactRelationsCompanion(
      relationId: relationId ?? this.relationId,
      personAId: personAId ?? this.personAId,
      personBId: personBId ?? this.personBId,
      typeId: typeId ?? this.typeId,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (relationId.present) {
      map['relation_id'] = Variable<String>(relationId.value);
    }
    if (personAId.present) {
      map['person_a_id'] = Variable<String>(personAId.value);
    }
    if (personBId.present) {
      map['person_b_id'] = Variable<String>(personBId.value);
    }
    if (typeId.present) {
      map['type_id'] = Variable<String>(typeId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContactRelationsCompanion(')
          ..write('relationId: $relationId, ')
          ..write('personAId: $personAId, ')
          ..write('personBId: $personBId, ')
          ..write('typeId: $typeId, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DataImportJobsTable extends DataImportJobs
    with TableInfo<$DataImportJobsTable, DataImportJob> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DataImportJobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
    'job_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL REFERENCES account_book(book_id) ON DELETE CASCADE',
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileHashMeta = const VerificationMeta(
    'fileHash',
  );
  @override
  late final GeneratedColumn<String> fileHash = GeneratedColumn<String>(
    'file_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
    'format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _importKindMeta = const VerificationMeta(
    'importKind',
  );
  @override
  late final GeneratedColumn<String> importKind = GeneratedColumn<String>(
    'import_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mappingJsonMeta = const VerificationMeta(
    'mappingJson',
  );
  @override
  late final GeneratedColumn<String> mappingJson = GeneratedColumn<String>(
    'mapping_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalRowsMeta = const VerificationMeta(
    'totalRows',
  );
  @override
  late final GeneratedColumn<int> totalRows = GeneratedColumn<int>(
    'total_rows',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _processedRowsMeta = const VerificationMeta(
    'processedRows',
  );
  @override
  late final GeneratedColumn<int> processedRows = GeneratedColumn<int>(
    'processed_rows',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _successRowsMeta = const VerificationMeta(
    'successRows',
  );
  @override
  late final GeneratedColumn<int> successRows = GeneratedColumn<int>(
    'success_rows',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _skippedRowsMeta = const VerificationMeta(
    'skippedRows',
  );
  @override
  late final GeneratedColumn<int> skippedRows = GeneratedColumn<int>(
    'skipped_rows',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _failedRowsMeta = const VerificationMeta(
    'failedRows',
  );
  @override
  late final GeneratedColumn<int> failedRows = GeneratedColumn<int>(
    'failed_rows',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _byteOffsetMeta = const VerificationMeta(
    'byteOffset',
  );
  @override
  late final GeneratedColumn<int> byteOffset = GeneratedColumn<int>(
    'byte_offset',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastRowIndexMeta = const VerificationMeta(
    'lastRowIndex',
  );
  @override
  late final GeneratedColumn<int> lastRowIndex = GeneratedColumn<int>(
    'last_row_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _errorLogPathMeta = const VerificationMeta(
    'errorLogPath',
  );
  @override
  late final GeneratedColumn<String> errorLogPath = GeneratedColumn<String>(
    'error_log_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<int> finishedAt = GeneratedColumn<int>(
    'finished_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    jobId,
    bookId,
    filePath,
    fileName,
    fileHash,
    fileSize,
    format,
    status,
    importKind,
    mappingJson,
    totalRows,
    processedRows,
    successRows,
    skippedRows,
    failedRows,
    byteOffset,
    lastRowIndex,
    errorLogPath,
    startedAt,
    finishedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'data_import_job';
  @override
  VerificationContext validateIntegrity(
    Insertable<DataImportJob> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('job_id')) {
      context.handle(
        _jobIdMeta,
        jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta),
      );
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('file_hash')) {
      context.handle(
        _fileHashMeta,
        fileHash.isAcceptableOrUnknown(data['file_hash']!, _fileHashMeta),
      );
    } else if (isInserting) {
      context.missing(_fileHashMeta);
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_fileSizeMeta);
    }
    if (data.containsKey('format')) {
      context.handle(
        _formatMeta,
        format.isAcceptableOrUnknown(data['format']!, _formatMeta),
      );
    } else if (isInserting) {
      context.missing(_formatMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('import_kind')) {
      context.handle(
        _importKindMeta,
        importKind.isAcceptableOrUnknown(data['import_kind']!, _importKindMeta),
      );
    } else if (isInserting) {
      context.missing(_importKindMeta);
    }
    if (data.containsKey('mapping_json')) {
      context.handle(
        _mappingJsonMeta,
        mappingJson.isAcceptableOrUnknown(
          data['mapping_json']!,
          _mappingJsonMeta,
        ),
      );
    }
    if (data.containsKey('total_rows')) {
      context.handle(
        _totalRowsMeta,
        totalRows.isAcceptableOrUnknown(data['total_rows']!, _totalRowsMeta),
      );
    }
    if (data.containsKey('processed_rows')) {
      context.handle(
        _processedRowsMeta,
        processedRows.isAcceptableOrUnknown(
          data['processed_rows']!,
          _processedRowsMeta,
        ),
      );
    }
    if (data.containsKey('success_rows')) {
      context.handle(
        _successRowsMeta,
        successRows.isAcceptableOrUnknown(
          data['success_rows']!,
          _successRowsMeta,
        ),
      );
    }
    if (data.containsKey('skipped_rows')) {
      context.handle(
        _skippedRowsMeta,
        skippedRows.isAcceptableOrUnknown(
          data['skipped_rows']!,
          _skippedRowsMeta,
        ),
      );
    }
    if (data.containsKey('failed_rows')) {
      context.handle(
        _failedRowsMeta,
        failedRows.isAcceptableOrUnknown(data['failed_rows']!, _failedRowsMeta),
      );
    }
    if (data.containsKey('byte_offset')) {
      context.handle(
        _byteOffsetMeta,
        byteOffset.isAcceptableOrUnknown(data['byte_offset']!, _byteOffsetMeta),
      );
    }
    if (data.containsKey('last_row_index')) {
      context.handle(
        _lastRowIndexMeta,
        lastRowIndex.isAcceptableOrUnknown(
          data['last_row_index']!,
          _lastRowIndexMeta,
        ),
      );
    }
    if (data.containsKey('error_log_path')) {
      context.handle(
        _errorLogPathMeta,
        errorLogPath.isAcceptableOrUnknown(
          data['error_log_path']!,
          _errorLogPathMeta,
        ),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {jobId};
  @override
  DataImportJob map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DataImportJob(
      jobId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}job_id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      fileHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_hash'],
      )!,
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      )!,
      format: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}format'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      importKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}import_kind'],
      )!,
      mappingJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mapping_json'],
      ),
      totalRows: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_rows'],
      ),
      processedRows: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}processed_rows'],
      )!,
      successRows: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}success_rows'],
      )!,
      skippedRows: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}skipped_rows'],
      )!,
      failedRows: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}failed_rows'],
      )!,
      byteOffset: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}byte_offset'],
      )!,
      lastRowIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_row_index'],
      )!,
      errorLogPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_log_path'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at'],
      )!,
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}finished_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DataImportJobsTable createAlias(String alias) {
    return $DataImportJobsTable(attachedDatabase, alias);
  }
}

class DataImportJob extends DataClass implements Insertable<DataImportJob> {
  final String jobId;
  final String bookId;
  final String filePath;
  final String fileName;
  final String fileHash;
  final int fileSize;
  final String format;
  final String status;
  final String importKind;
  final String? mappingJson;
  final int? totalRows;
  final int processedRows;
  final int successRows;
  final int skippedRows;
  final int failedRows;
  final int byteOffset;
  final int lastRowIndex;
  final String? errorLogPath;
  final int startedAt;
  final int? finishedAt;
  final int updatedAt;
  const DataImportJob({
    required this.jobId,
    required this.bookId,
    required this.filePath,
    required this.fileName,
    required this.fileHash,
    required this.fileSize,
    required this.format,
    required this.status,
    required this.importKind,
    this.mappingJson,
    this.totalRows,
    required this.processedRows,
    required this.successRows,
    required this.skippedRows,
    required this.failedRows,
    required this.byteOffset,
    required this.lastRowIndex,
    this.errorLogPath,
    required this.startedAt,
    this.finishedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['job_id'] = Variable<String>(jobId);
    map['book_id'] = Variable<String>(bookId);
    map['file_path'] = Variable<String>(filePath);
    map['file_name'] = Variable<String>(fileName);
    map['file_hash'] = Variable<String>(fileHash);
    map['file_size'] = Variable<int>(fileSize);
    map['format'] = Variable<String>(format);
    map['status'] = Variable<String>(status);
    map['import_kind'] = Variable<String>(importKind);
    if (!nullToAbsent || mappingJson != null) {
      map['mapping_json'] = Variable<String>(mappingJson);
    }
    if (!nullToAbsent || totalRows != null) {
      map['total_rows'] = Variable<int>(totalRows);
    }
    map['processed_rows'] = Variable<int>(processedRows);
    map['success_rows'] = Variable<int>(successRows);
    map['skipped_rows'] = Variable<int>(skippedRows);
    map['failed_rows'] = Variable<int>(failedRows);
    map['byte_offset'] = Variable<int>(byteOffset);
    map['last_row_index'] = Variable<int>(lastRowIndex);
    if (!nullToAbsent || errorLogPath != null) {
      map['error_log_path'] = Variable<String>(errorLogPath);
    }
    map['started_at'] = Variable<int>(startedAt);
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<int>(finishedAt);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  DataImportJobsCompanion toCompanion(bool nullToAbsent) {
    return DataImportJobsCompanion(
      jobId: Value(jobId),
      bookId: Value(bookId),
      filePath: Value(filePath),
      fileName: Value(fileName),
      fileHash: Value(fileHash),
      fileSize: Value(fileSize),
      format: Value(format),
      status: Value(status),
      importKind: Value(importKind),
      mappingJson: mappingJson == null && nullToAbsent
          ? const Value.absent()
          : Value(mappingJson),
      totalRows: totalRows == null && nullToAbsent
          ? const Value.absent()
          : Value(totalRows),
      processedRows: Value(processedRows),
      successRows: Value(successRows),
      skippedRows: Value(skippedRows),
      failedRows: Value(failedRows),
      byteOffset: Value(byteOffset),
      lastRowIndex: Value(lastRowIndex),
      errorLogPath: errorLogPath == null && nullToAbsent
          ? const Value.absent()
          : Value(errorLogPath),
      startedAt: Value(startedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DataImportJob.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DataImportJob(
      jobId: serializer.fromJson<String>(json['jobId']),
      bookId: serializer.fromJson<String>(json['bookId']),
      filePath: serializer.fromJson<String>(json['filePath']),
      fileName: serializer.fromJson<String>(json['fileName']),
      fileHash: serializer.fromJson<String>(json['fileHash']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      format: serializer.fromJson<String>(json['format']),
      status: serializer.fromJson<String>(json['status']),
      importKind: serializer.fromJson<String>(json['importKind']),
      mappingJson: serializer.fromJson<String?>(json['mappingJson']),
      totalRows: serializer.fromJson<int?>(json['totalRows']),
      processedRows: serializer.fromJson<int>(json['processedRows']),
      successRows: serializer.fromJson<int>(json['successRows']),
      skippedRows: serializer.fromJson<int>(json['skippedRows']),
      failedRows: serializer.fromJson<int>(json['failedRows']),
      byteOffset: serializer.fromJson<int>(json['byteOffset']),
      lastRowIndex: serializer.fromJson<int>(json['lastRowIndex']),
      errorLogPath: serializer.fromJson<String?>(json['errorLogPath']),
      startedAt: serializer.fromJson<int>(json['startedAt']),
      finishedAt: serializer.fromJson<int?>(json['finishedAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'jobId': serializer.toJson<String>(jobId),
      'bookId': serializer.toJson<String>(bookId),
      'filePath': serializer.toJson<String>(filePath),
      'fileName': serializer.toJson<String>(fileName),
      'fileHash': serializer.toJson<String>(fileHash),
      'fileSize': serializer.toJson<int>(fileSize),
      'format': serializer.toJson<String>(format),
      'status': serializer.toJson<String>(status),
      'importKind': serializer.toJson<String>(importKind),
      'mappingJson': serializer.toJson<String?>(mappingJson),
      'totalRows': serializer.toJson<int?>(totalRows),
      'processedRows': serializer.toJson<int>(processedRows),
      'successRows': serializer.toJson<int>(successRows),
      'skippedRows': serializer.toJson<int>(skippedRows),
      'failedRows': serializer.toJson<int>(failedRows),
      'byteOffset': serializer.toJson<int>(byteOffset),
      'lastRowIndex': serializer.toJson<int>(lastRowIndex),
      'errorLogPath': serializer.toJson<String?>(errorLogPath),
      'startedAt': serializer.toJson<int>(startedAt),
      'finishedAt': serializer.toJson<int?>(finishedAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  DataImportJob copyWith({
    String? jobId,
    String? bookId,
    String? filePath,
    String? fileName,
    String? fileHash,
    int? fileSize,
    String? format,
    String? status,
    String? importKind,
    Value<String?> mappingJson = const Value.absent(),
    Value<int?> totalRows = const Value.absent(),
    int? processedRows,
    int? successRows,
    int? skippedRows,
    int? failedRows,
    int? byteOffset,
    int? lastRowIndex,
    Value<String?> errorLogPath = const Value.absent(),
    int? startedAt,
    Value<int?> finishedAt = const Value.absent(),
    int? updatedAt,
  }) => DataImportJob(
    jobId: jobId ?? this.jobId,
    bookId: bookId ?? this.bookId,
    filePath: filePath ?? this.filePath,
    fileName: fileName ?? this.fileName,
    fileHash: fileHash ?? this.fileHash,
    fileSize: fileSize ?? this.fileSize,
    format: format ?? this.format,
    status: status ?? this.status,
    importKind: importKind ?? this.importKind,
    mappingJson: mappingJson.present ? mappingJson.value : this.mappingJson,
    totalRows: totalRows.present ? totalRows.value : this.totalRows,
    processedRows: processedRows ?? this.processedRows,
    successRows: successRows ?? this.successRows,
    skippedRows: skippedRows ?? this.skippedRows,
    failedRows: failedRows ?? this.failedRows,
    byteOffset: byteOffset ?? this.byteOffset,
    lastRowIndex: lastRowIndex ?? this.lastRowIndex,
    errorLogPath: errorLogPath.present ? errorLogPath.value : this.errorLogPath,
    startedAt: startedAt ?? this.startedAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DataImportJob copyWithCompanion(DataImportJobsCompanion data) {
    return DataImportJob(
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      fileHash: data.fileHash.present ? data.fileHash.value : this.fileHash,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      format: data.format.present ? data.format.value : this.format,
      status: data.status.present ? data.status.value : this.status,
      importKind: data.importKind.present
          ? data.importKind.value
          : this.importKind,
      mappingJson: data.mappingJson.present
          ? data.mappingJson.value
          : this.mappingJson,
      totalRows: data.totalRows.present ? data.totalRows.value : this.totalRows,
      processedRows: data.processedRows.present
          ? data.processedRows.value
          : this.processedRows,
      successRows: data.successRows.present
          ? data.successRows.value
          : this.successRows,
      skippedRows: data.skippedRows.present
          ? data.skippedRows.value
          : this.skippedRows,
      failedRows: data.failedRows.present
          ? data.failedRows.value
          : this.failedRows,
      byteOffset: data.byteOffset.present
          ? data.byteOffset.value
          : this.byteOffset,
      lastRowIndex: data.lastRowIndex.present
          ? data.lastRowIndex.value
          : this.lastRowIndex,
      errorLogPath: data.errorLogPath.present
          ? data.errorLogPath.value
          : this.errorLogPath,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DataImportJob(')
          ..write('jobId: $jobId, ')
          ..write('bookId: $bookId, ')
          ..write('filePath: $filePath, ')
          ..write('fileName: $fileName, ')
          ..write('fileHash: $fileHash, ')
          ..write('fileSize: $fileSize, ')
          ..write('format: $format, ')
          ..write('status: $status, ')
          ..write('importKind: $importKind, ')
          ..write('mappingJson: $mappingJson, ')
          ..write('totalRows: $totalRows, ')
          ..write('processedRows: $processedRows, ')
          ..write('successRows: $successRows, ')
          ..write('skippedRows: $skippedRows, ')
          ..write('failedRows: $failedRows, ')
          ..write('byteOffset: $byteOffset, ')
          ..write('lastRowIndex: $lastRowIndex, ')
          ..write('errorLogPath: $errorLogPath, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    jobId,
    bookId,
    filePath,
    fileName,
    fileHash,
    fileSize,
    format,
    status,
    importKind,
    mappingJson,
    totalRows,
    processedRows,
    successRows,
    skippedRows,
    failedRows,
    byteOffset,
    lastRowIndex,
    errorLogPath,
    startedAt,
    finishedAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DataImportJob &&
          other.jobId == this.jobId &&
          other.bookId == this.bookId &&
          other.filePath == this.filePath &&
          other.fileName == this.fileName &&
          other.fileHash == this.fileHash &&
          other.fileSize == this.fileSize &&
          other.format == this.format &&
          other.status == this.status &&
          other.importKind == this.importKind &&
          other.mappingJson == this.mappingJson &&
          other.totalRows == this.totalRows &&
          other.processedRows == this.processedRows &&
          other.successRows == this.successRows &&
          other.skippedRows == this.skippedRows &&
          other.failedRows == this.failedRows &&
          other.byteOffset == this.byteOffset &&
          other.lastRowIndex == this.lastRowIndex &&
          other.errorLogPath == this.errorLogPath &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt &&
          other.updatedAt == this.updatedAt);
}

class DataImportJobsCompanion extends UpdateCompanion<DataImportJob> {
  final Value<String> jobId;
  final Value<String> bookId;
  final Value<String> filePath;
  final Value<String> fileName;
  final Value<String> fileHash;
  final Value<int> fileSize;
  final Value<String> format;
  final Value<String> status;
  final Value<String> importKind;
  final Value<String?> mappingJson;
  final Value<int?> totalRows;
  final Value<int> processedRows;
  final Value<int> successRows;
  final Value<int> skippedRows;
  final Value<int> failedRows;
  final Value<int> byteOffset;
  final Value<int> lastRowIndex;
  final Value<String?> errorLogPath;
  final Value<int> startedAt;
  final Value<int?> finishedAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const DataImportJobsCompanion({
    this.jobId = const Value.absent(),
    this.bookId = const Value.absent(),
    this.filePath = const Value.absent(),
    this.fileName = const Value.absent(),
    this.fileHash = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.format = const Value.absent(),
    this.status = const Value.absent(),
    this.importKind = const Value.absent(),
    this.mappingJson = const Value.absent(),
    this.totalRows = const Value.absent(),
    this.processedRows = const Value.absent(),
    this.successRows = const Value.absent(),
    this.skippedRows = const Value.absent(),
    this.failedRows = const Value.absent(),
    this.byteOffset = const Value.absent(),
    this.lastRowIndex = const Value.absent(),
    this.errorLogPath = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DataImportJobsCompanion.insert({
    this.jobId = const Value.absent(),
    required String bookId,
    required String filePath,
    required String fileName,
    required String fileHash,
    required int fileSize,
    required String format,
    required String status,
    required String importKind,
    this.mappingJson = const Value.absent(),
    this.totalRows = const Value.absent(),
    this.processedRows = const Value.absent(),
    this.successRows = const Value.absent(),
    this.skippedRows = const Value.absent(),
    this.failedRows = const Value.absent(),
    this.byteOffset = const Value.absent(),
    this.lastRowIndex = const Value.absent(),
    this.errorLogPath = const Value.absent(),
    required int startedAt,
    this.finishedAt = const Value.absent(),
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : bookId = Value(bookId),
       filePath = Value(filePath),
       fileName = Value(fileName),
       fileHash = Value(fileHash),
       fileSize = Value(fileSize),
       format = Value(format),
       status = Value(status),
       importKind = Value(importKind),
       startedAt = Value(startedAt),
       updatedAt = Value(updatedAt);
  static Insertable<DataImportJob> custom({
    Expression<String>? jobId,
    Expression<String>? bookId,
    Expression<String>? filePath,
    Expression<String>? fileName,
    Expression<String>? fileHash,
    Expression<int>? fileSize,
    Expression<String>? format,
    Expression<String>? status,
    Expression<String>? importKind,
    Expression<String>? mappingJson,
    Expression<int>? totalRows,
    Expression<int>? processedRows,
    Expression<int>? successRows,
    Expression<int>? skippedRows,
    Expression<int>? failedRows,
    Expression<int>? byteOffset,
    Expression<int>? lastRowIndex,
    Expression<String>? errorLogPath,
    Expression<int>? startedAt,
    Expression<int>? finishedAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (jobId != null) 'job_id': jobId,
      if (bookId != null) 'book_id': bookId,
      if (filePath != null) 'file_path': filePath,
      if (fileName != null) 'file_name': fileName,
      if (fileHash != null) 'file_hash': fileHash,
      if (fileSize != null) 'file_size': fileSize,
      if (format != null) 'format': format,
      if (status != null) 'status': status,
      if (importKind != null) 'import_kind': importKind,
      if (mappingJson != null) 'mapping_json': mappingJson,
      if (totalRows != null) 'total_rows': totalRows,
      if (processedRows != null) 'processed_rows': processedRows,
      if (successRows != null) 'success_rows': successRows,
      if (skippedRows != null) 'skipped_rows': skippedRows,
      if (failedRows != null) 'failed_rows': failedRows,
      if (byteOffset != null) 'byte_offset': byteOffset,
      if (lastRowIndex != null) 'last_row_index': lastRowIndex,
      if (errorLogPath != null) 'error_log_path': errorLogPath,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DataImportJobsCompanion copyWith({
    Value<String>? jobId,
    Value<String>? bookId,
    Value<String>? filePath,
    Value<String>? fileName,
    Value<String>? fileHash,
    Value<int>? fileSize,
    Value<String>? format,
    Value<String>? status,
    Value<String>? importKind,
    Value<String?>? mappingJson,
    Value<int?>? totalRows,
    Value<int>? processedRows,
    Value<int>? successRows,
    Value<int>? skippedRows,
    Value<int>? failedRows,
    Value<int>? byteOffset,
    Value<int>? lastRowIndex,
    Value<String?>? errorLogPath,
    Value<int>? startedAt,
    Value<int?>? finishedAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return DataImportJobsCompanion(
      jobId: jobId ?? this.jobId,
      bookId: bookId ?? this.bookId,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileHash: fileHash ?? this.fileHash,
      fileSize: fileSize ?? this.fileSize,
      format: format ?? this.format,
      status: status ?? this.status,
      importKind: importKind ?? this.importKind,
      mappingJson: mappingJson ?? this.mappingJson,
      totalRows: totalRows ?? this.totalRows,
      processedRows: processedRows ?? this.processedRows,
      successRows: successRows ?? this.successRows,
      skippedRows: skippedRows ?? this.skippedRows,
      failedRows: failedRows ?? this.failedRows,
      byteOffset: byteOffset ?? this.byteOffset,
      lastRowIndex: lastRowIndex ?? this.lastRowIndex,
      errorLogPath: errorLogPath ?? this.errorLogPath,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (jobId.present) {
      map['job_id'] = Variable<String>(jobId.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (fileHash.present) {
      map['file_hash'] = Variable<String>(fileHash.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (importKind.present) {
      map['import_kind'] = Variable<String>(importKind.value);
    }
    if (mappingJson.present) {
      map['mapping_json'] = Variable<String>(mappingJson.value);
    }
    if (totalRows.present) {
      map['total_rows'] = Variable<int>(totalRows.value);
    }
    if (processedRows.present) {
      map['processed_rows'] = Variable<int>(processedRows.value);
    }
    if (successRows.present) {
      map['success_rows'] = Variable<int>(successRows.value);
    }
    if (skippedRows.present) {
      map['skipped_rows'] = Variable<int>(skippedRows.value);
    }
    if (failedRows.present) {
      map['failed_rows'] = Variable<int>(failedRows.value);
    }
    if (byteOffset.present) {
      map['byte_offset'] = Variable<int>(byteOffset.value);
    }
    if (lastRowIndex.present) {
      map['last_row_index'] = Variable<int>(lastRowIndex.value);
    }
    if (errorLogPath.present) {
      map['error_log_path'] = Variable<String>(errorLogPath.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(startedAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<int>(finishedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DataImportJobsCompanion(')
          ..write('jobId: $jobId, ')
          ..write('bookId: $bookId, ')
          ..write('filePath: $filePath, ')
          ..write('fileName: $fileName, ')
          ..write('fileHash: $fileHash, ')
          ..write('fileSize: $fileSize, ')
          ..write('format: $format, ')
          ..write('status: $status, ')
          ..write('importKind: $importKind, ')
          ..write('mappingJson: $mappingJson, ')
          ..write('totalRows: $totalRows, ')
          ..write('processedRows: $processedRows, ')
          ..write('successRows: $successRows, ')
          ..write('skippedRows: $skippedRows, ')
          ..write('failedRows: $failedRows, ')
          ..write('byteOffset: $byteOffset, ')
          ..write('lastRowIndex: $lastRowIndex, ')
          ..write('errorLogPath: $errorLogPath, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AccountBooksTable accountBooks = $AccountBooksTable(this);
  late final $PersonsTable persons = $PersonsTable(this);
  late final $GiftRecordsTable giftRecords = $GiftRecordsTable(this);
  late final $ReasonsTable reasons = $ReasonsTable(this);
  late final $RelationTypesTable relationTypes = $RelationTypesTable(this);
  late final $ContactRelationsTable contactRelations = $ContactRelationsTable(
    this,
  );
  late final $DataImportJobsTable dataImportJobs = $DataImportJobsTable(this);
  late final AccountBooksDao accountBooksDao = AccountBooksDao(
    this as AppDatabase,
  );
  late final PersonsDao personsDao = PersonsDao(this as AppDatabase);
  late final GiftRecordsDao giftRecordsDao = GiftRecordsDao(
    this as AppDatabase,
  );
  late final ReasonsDao reasonsDao = ReasonsDao(this as AppDatabase);
  late final RelationTypesDao relationTypesDao = RelationTypesDao(
    this as AppDatabase,
  );
  late final ContactRelationsDao contactRelationsDao = ContactRelationsDao(
    this as AppDatabase,
  );
  late final DataImportJobsDao dataImportJobsDao = DataImportJobsDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    accountBooks,
    persons,
    giftRecords,
    reasons,
    relationTypes,
    contactRelations,
    dataImportJobs,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'account_book',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('person', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'account_book',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('gift_record', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'person',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('gift_record', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'person',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('contact_relation', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'person',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('contact_relation', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'account_book',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('data_import_job', kind: UpdateKind.delete)],
    ),
  ]);
}

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
}

mixin _$AccountBooksDaoMixin on DatabaseAccessor<AppDatabase> {
  $AccountBooksTable get accountBooks => attachedDatabase.accountBooks;
}

mixin _$PersonsDaoMixin on DatabaseAccessor<AppDatabase> {
  $AccountBooksTable get accountBooks => attachedDatabase.accountBooks;
  $PersonsTable get persons => attachedDatabase.persons;
}

mixin _$GiftRecordsDaoMixin on DatabaseAccessor<AppDatabase> {
  $AccountBooksTable get accountBooks => attachedDatabase.accountBooks;
  $PersonsTable get persons => attachedDatabase.persons;
  $GiftRecordsTable get giftRecords => attachedDatabase.giftRecords;
}

mixin _$ReasonsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ReasonsTable get reasons => attachedDatabase.reasons;
}

mixin _$RelationTypesDaoMixin on DatabaseAccessor<AppDatabase> {
  $RelationTypesTable get relationTypes => attachedDatabase.relationTypes;
  $AccountBooksTable get accountBooks => attachedDatabase.accountBooks;
  $PersonsTable get persons => attachedDatabase.persons;
}

mixin _$ContactRelationsDaoMixin on DatabaseAccessor<AppDatabase> {
  $AccountBooksTable get accountBooks => attachedDatabase.accountBooks;
  $PersonsTable get persons => attachedDatabase.persons;
  $RelationTypesTable get relationTypes => attachedDatabase.relationTypes;
  $ContactRelationsTable get contactRelations =>
      attachedDatabase.contactRelations;
}

mixin _$DataImportJobsDaoMixin on DatabaseAccessor<AppDatabase> {
  $AccountBooksTable get accountBooks => attachedDatabase.accountBooks;
  $DataImportJobsTable get dataImportJobs => attachedDatabase.dataImportJobs;
}
