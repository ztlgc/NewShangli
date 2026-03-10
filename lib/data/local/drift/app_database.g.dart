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
    defaultValue: const Constant('结婚礼金'),
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
  @override
  List<GeneratedColumn> get $columns => [
    bookId,
    name,
    reasonType,
    themeColor,
    icon,
    description,
    isDefault,
    createdAt,
    updatedAt,
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
  final int isDefault;
  final int createdAt;
  final int updatedAt;
  const AccountBook({
    required this.bookId,
    required this.name,
    required this.reasonType,
    required this.themeColor,
    this.icon,
    this.description,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
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
    map['is_default'] = Variable<int>(isDefault);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
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
      isDefault: Value(isDefault),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
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
      isDefault: serializer.fromJson<int>(json['isDefault']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
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
      'isDefault': serializer.toJson<int>(isDefault),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  AccountBook copyWith({
    String? bookId,
    String? name,
    String? reasonType,
    String? themeColor,
    Value<String?> icon = const Value.absent(),
    Value<String?> description = const Value.absent(),
    int? isDefault,
    int? createdAt,
    int? updatedAt,
  }) => AccountBook(
    bookId: bookId ?? this.bookId,
    name: name ?? this.name,
    reasonType: reasonType ?? this.reasonType,
    themeColor: themeColor ?? this.themeColor,
    icon: icon.present ? icon.value : this.icon,
    description: description.present ? description.value : this.description,
    isDefault: isDefault ?? this.isDefault,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
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
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
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
          ..write('isDefault: $isDefault, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
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
    isDefault,
    createdAt,
    updatedAt,
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
          other.isDefault == this.isDefault &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AccountBooksCompanion extends UpdateCompanion<AccountBook> {
  final Value<String> bookId;
  final Value<String> name;
  final Value<String> reasonType;
  final Value<String> themeColor;
  final Value<String?> icon;
  final Value<String?> description;
  final Value<int> isDefault;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const AccountBooksCompanion({
    this.bookId = const Value.absent(),
    this.name = const Value.absent(),
    this.reasonType = const Value.absent(),
    this.themeColor = const Value.absent(),
    this.icon = const Value.absent(),
    this.description = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountBooksCompanion.insert({
    this.bookId = const Value.absent(),
    required String name,
    this.reasonType = const Value.absent(),
    this.themeColor = const Value.absent(),
    this.icon = const Value.absent(),
    this.description = const Value.absent(),
    this.isDefault = const Value.absent(),
    required int createdAt,
    required int updatedAt,
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
    Expression<int>? isDefault,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (bookId != null) 'book_id': bookId,
      if (name != null) 'name': name,
      if (reasonType != null) 'reason_type': reasonType,
      if (themeColor != null) 'theme_color': themeColor,
      if (icon != null) 'icon': icon,
      if (description != null) 'description': description,
      if (isDefault != null) 'is_default': isDefault,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
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
    Value<int>? isDefault,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return AccountBooksCompanion(
      bookId: bookId ?? this.bookId,
      name: name ?? this.name,
      reasonType: reasonType ?? this.reasonType,
      themeColor: themeColor ?? this.themeColor,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (isDefault.present) {
      map['is_default'] = Variable<int>(isDefault.value);
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
    return (StringBuffer('AccountBooksCompanion(')
          ..write('bookId: $bookId, ')
          ..write('name: $name, ')
          ..write('reasonType: $reasonType, ')
          ..write('themeColor: $themeColor, ')
          ..write('icon: $icon, ')
          ..write('description: $description, ')
          ..write('isDefault: $isDefault, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
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
          ..write('updatedAt: $updatedAt')
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
          other.updatedAt == this.updatedAt);
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
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EventRemindersTable extends EventReminders
    with TableInfo<$EventRemindersTable, EventReminder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventRemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _reminderIdMeta = const VerificationMeta(
    'reminderId',
  );
  @override
  late final GeneratedColumn<String> reminderId = GeneratedColumn<String>(
    'reminder_id',
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
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NULL REFERENCES person(person_id) ON DELETE SET NULL',
  );
  static const VerificationMeta _reminderTypeMeta = const VerificationMeta(
    'reminderType',
  );
  @override
  late final GeneratedColumn<String> reminderType = GeneratedColumn<String>(
    'reminder_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('自定义'),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _targetDateMeta = const VerificationMeta(
    'targetDate',
  );
  @override
  late final GeneratedColumn<String> targetDate = GeneratedColumn<String>(
    'target_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _remindAtMeta = const VerificationMeta(
    'remindAt',
  );
  @override
  late final GeneratedColumn<int> remindAt = GeneratedColumn<int>(
    'remind_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _repeatRuleMeta = const VerificationMeta(
    'repeatRule',
  );
  @override
  late final GeneratedColumn<String> repeatRule = GeneratedColumn<String>(
    'repeat_rule',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _channelMeta = const VerificationMeta(
    'channel',
  );
  @override
  late final GeneratedColumn<String> channel = GeneratedColumn<String>(
    'channel',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('notification'),
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
    reminderId,
    bookId,
    personId,
    reminderType,
    title,
    targetDate,
    remindAt,
    repeatRule,
    status,
    channel,
    note,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'event_reminder';
  @override
  VerificationContext validateIntegrity(
    Insertable<EventReminder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('reminder_id')) {
      context.handle(
        _reminderIdMeta,
        reminderId.isAcceptableOrUnknown(data['reminder_id']!, _reminderIdMeta),
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
    }
    if (data.containsKey('reminder_type')) {
      context.handle(
        _reminderTypeMeta,
        reminderType.isAcceptableOrUnknown(
          data['reminder_type']!,
          _reminderTypeMeta,
        ),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('target_date')) {
      context.handle(
        _targetDateMeta,
        targetDate.isAcceptableOrUnknown(data['target_date']!, _targetDateMeta),
      );
    } else if (isInserting) {
      context.missing(_targetDateMeta);
    }
    if (data.containsKey('remind_at')) {
      context.handle(
        _remindAtMeta,
        remindAt.isAcceptableOrUnknown(data['remind_at']!, _remindAtMeta),
      );
    } else if (isInserting) {
      context.missing(_remindAtMeta);
    }
    if (data.containsKey('repeat_rule')) {
      context.handle(
        _repeatRuleMeta,
        repeatRule.isAcceptableOrUnknown(data['repeat_rule']!, _repeatRuleMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('channel')) {
      context.handle(
        _channelMeta,
        channel.isAcceptableOrUnknown(data['channel']!, _channelMeta),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {reminderId};
  @override
  EventReminder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventReminder(
      reminderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reminder_id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person_id'],
      ),
      reminderType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reminder_type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      targetDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_date'],
      )!,
      remindAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remind_at'],
      )!,
      repeatRule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repeat_rule'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      channel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel'],
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
  $EventRemindersTable createAlias(String alias) {
    return $EventRemindersTable(attachedDatabase, alias);
  }
}

class EventReminder extends DataClass implements Insertable<EventReminder> {
  final String reminderId;
  final String bookId;
  final String? personId;
  final String reminderType;

  /// 提醒标题（UI 展示用）。
  ///
  /// 说明：
  /// - 历史上 reminder_type 既被当作“类型”也被当作“名称”使用，语义容易混淆；
  /// - 这里新增 title 作为稳定的展示字段，类型仍保留在 reminder_type。
  final String title;
  final String targetDate;
  final int remindAt;
  final String repeatRule;
  final String status;
  final String channel;
  final String? note;
  final int createdAt;
  final int updatedAt;
  const EventReminder({
    required this.reminderId,
    required this.bookId,
    this.personId,
    required this.reminderType,
    required this.title,
    required this.targetDate,
    required this.remindAt,
    required this.repeatRule,
    required this.status,
    required this.channel,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['reminder_id'] = Variable<String>(reminderId);
    map['book_id'] = Variable<String>(bookId);
    if (!nullToAbsent || personId != null) {
      map['person_id'] = Variable<String>(personId);
    }
    map['reminder_type'] = Variable<String>(reminderType);
    map['title'] = Variable<String>(title);
    map['target_date'] = Variable<String>(targetDate);
    map['remind_at'] = Variable<int>(remindAt);
    map['repeat_rule'] = Variable<String>(repeatRule);
    map['status'] = Variable<String>(status);
    map['channel'] = Variable<String>(channel);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  EventRemindersCompanion toCompanion(bool nullToAbsent) {
    return EventRemindersCompanion(
      reminderId: Value(reminderId),
      bookId: Value(bookId),
      personId: personId == null && nullToAbsent
          ? const Value.absent()
          : Value(personId),
      reminderType: Value(reminderType),
      title: Value(title),
      targetDate: Value(targetDate),
      remindAt: Value(remindAt),
      repeatRule: Value(repeatRule),
      status: Value(status),
      channel: Value(channel),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory EventReminder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventReminder(
      reminderId: serializer.fromJson<String>(json['reminderId']),
      bookId: serializer.fromJson<String>(json['bookId']),
      personId: serializer.fromJson<String?>(json['personId']),
      reminderType: serializer.fromJson<String>(json['reminderType']),
      title: serializer.fromJson<String>(json['title']),
      targetDate: serializer.fromJson<String>(json['targetDate']),
      remindAt: serializer.fromJson<int>(json['remindAt']),
      repeatRule: serializer.fromJson<String>(json['repeatRule']),
      status: serializer.fromJson<String>(json['status']),
      channel: serializer.fromJson<String>(json['channel']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'reminderId': serializer.toJson<String>(reminderId),
      'bookId': serializer.toJson<String>(bookId),
      'personId': serializer.toJson<String?>(personId),
      'reminderType': serializer.toJson<String>(reminderType),
      'title': serializer.toJson<String>(title),
      'targetDate': serializer.toJson<String>(targetDate),
      'remindAt': serializer.toJson<int>(remindAt),
      'repeatRule': serializer.toJson<String>(repeatRule),
      'status': serializer.toJson<String>(status),
      'channel': serializer.toJson<String>(channel),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  EventReminder copyWith({
    String? reminderId,
    String? bookId,
    Value<String?> personId = const Value.absent(),
    String? reminderType,
    String? title,
    String? targetDate,
    int? remindAt,
    String? repeatRule,
    String? status,
    String? channel,
    Value<String?> note = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => EventReminder(
    reminderId: reminderId ?? this.reminderId,
    bookId: bookId ?? this.bookId,
    personId: personId.present ? personId.value : this.personId,
    reminderType: reminderType ?? this.reminderType,
    title: title ?? this.title,
    targetDate: targetDate ?? this.targetDate,
    remindAt: remindAt ?? this.remindAt,
    repeatRule: repeatRule ?? this.repeatRule,
    status: status ?? this.status,
    channel: channel ?? this.channel,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  EventReminder copyWithCompanion(EventRemindersCompanion data) {
    return EventReminder(
      reminderId: data.reminderId.present
          ? data.reminderId.value
          : this.reminderId,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      personId: data.personId.present ? data.personId.value : this.personId,
      reminderType: data.reminderType.present
          ? data.reminderType.value
          : this.reminderType,
      title: data.title.present ? data.title.value : this.title,
      targetDate: data.targetDate.present
          ? data.targetDate.value
          : this.targetDate,
      remindAt: data.remindAt.present ? data.remindAt.value : this.remindAt,
      repeatRule: data.repeatRule.present
          ? data.repeatRule.value
          : this.repeatRule,
      status: data.status.present ? data.status.value : this.status,
      channel: data.channel.present ? data.channel.value : this.channel,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventReminder(')
          ..write('reminderId: $reminderId, ')
          ..write('bookId: $bookId, ')
          ..write('personId: $personId, ')
          ..write('reminderType: $reminderType, ')
          ..write('title: $title, ')
          ..write('targetDate: $targetDate, ')
          ..write('remindAt: $remindAt, ')
          ..write('repeatRule: $repeatRule, ')
          ..write('status: $status, ')
          ..write('channel: $channel, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    reminderId,
    bookId,
    personId,
    reminderType,
    title,
    targetDate,
    remindAt,
    repeatRule,
    status,
    channel,
    note,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventReminder &&
          other.reminderId == this.reminderId &&
          other.bookId == this.bookId &&
          other.personId == this.personId &&
          other.reminderType == this.reminderType &&
          other.title == this.title &&
          other.targetDate == this.targetDate &&
          other.remindAt == this.remindAt &&
          other.repeatRule == this.repeatRule &&
          other.status == this.status &&
          other.channel == this.channel &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class EventRemindersCompanion extends UpdateCompanion<EventReminder> {
  final Value<String> reminderId;
  final Value<String> bookId;
  final Value<String?> personId;
  final Value<String> reminderType;
  final Value<String> title;
  final Value<String> targetDate;
  final Value<int> remindAt;
  final Value<String> repeatRule;
  final Value<String> status;
  final Value<String> channel;
  final Value<String?> note;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const EventRemindersCompanion({
    this.reminderId = const Value.absent(),
    this.bookId = const Value.absent(),
    this.personId = const Value.absent(),
    this.reminderType = const Value.absent(),
    this.title = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.remindAt = const Value.absent(),
    this.repeatRule = const Value.absent(),
    this.status = const Value.absent(),
    this.channel = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventRemindersCompanion.insert({
    this.reminderId = const Value.absent(),
    required String bookId,
    this.personId = const Value.absent(),
    this.reminderType = const Value.absent(),
    this.title = const Value.absent(),
    required String targetDate,
    required int remindAt,
    this.repeatRule = const Value.absent(),
    this.status = const Value.absent(),
    this.channel = const Value.absent(),
    this.note = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : bookId = Value(bookId),
       targetDate = Value(targetDate),
       remindAt = Value(remindAt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<EventReminder> custom({
    Expression<String>? reminderId,
    Expression<String>? bookId,
    Expression<String>? personId,
    Expression<String>? reminderType,
    Expression<String>? title,
    Expression<String>? targetDate,
    Expression<int>? remindAt,
    Expression<String>? repeatRule,
    Expression<String>? status,
    Expression<String>? channel,
    Expression<String>? note,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (reminderId != null) 'reminder_id': reminderId,
      if (bookId != null) 'book_id': bookId,
      if (personId != null) 'person_id': personId,
      if (reminderType != null) 'reminder_type': reminderType,
      if (title != null) 'title': title,
      if (targetDate != null) 'target_date': targetDate,
      if (remindAt != null) 'remind_at': remindAt,
      if (repeatRule != null) 'repeat_rule': repeatRule,
      if (status != null) 'status': status,
      if (channel != null) 'channel': channel,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventRemindersCompanion copyWith({
    Value<String>? reminderId,
    Value<String>? bookId,
    Value<String?>? personId,
    Value<String>? reminderType,
    Value<String>? title,
    Value<String>? targetDate,
    Value<int>? remindAt,
    Value<String>? repeatRule,
    Value<String>? status,
    Value<String>? channel,
    Value<String?>? note,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return EventRemindersCompanion(
      reminderId: reminderId ?? this.reminderId,
      bookId: bookId ?? this.bookId,
      personId: personId ?? this.personId,
      reminderType: reminderType ?? this.reminderType,
      title: title ?? this.title,
      targetDate: targetDate ?? this.targetDate,
      remindAt: remindAt ?? this.remindAt,
      repeatRule: repeatRule ?? this.repeatRule,
      status: status ?? this.status,
      channel: channel ?? this.channel,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (reminderId.present) {
      map['reminder_id'] = Variable<String>(reminderId.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<String>(personId.value);
    }
    if (reminderType.present) {
      map['reminder_type'] = Variable<String>(reminderType.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (targetDate.present) {
      map['target_date'] = Variable<String>(targetDate.value);
    }
    if (remindAt.present) {
      map['remind_at'] = Variable<int>(remindAt.value);
    }
    if (repeatRule.present) {
      map['repeat_rule'] = Variable<String>(repeatRule.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (channel.present) {
      map['channel'] = Variable<String>(channel.value);
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
    return (StringBuffer('EventRemindersCompanion(')
          ..write('reminderId: $reminderId, ')
          ..write('bookId: $bookId, ')
          ..write('personId: $personId, ')
          ..write('reminderType: $reminderType, ')
          ..write('title: $title, ')
          ..write('targetDate: $targetDate, ')
          ..write('remindAt: $remindAt, ')
          ..write('repeatRule: $repeatRule, ')
          ..write('status: $status, ')
          ..write('channel: $channel, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
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
  static const VerificationMeta _reminderIdMeta = const VerificationMeta(
    'reminderId',
  );
  @override
  late final GeneratedColumn<String> reminderId = GeneratedColumn<String>(
    'reminder_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NULL REFERENCES event_reminder(reminder_id) ON DELETE SET NULL',
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
        'NOT NULL DEFAULT \'收入\' CHECK(direction IN (\'收入\', \'支出\'))',
    defaultValue: const CustomExpression('\'收入\''),
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
  @override
  List<GeneratedColumn> get $columns => [
    recordId,
    bookId,
    personId,
    reminderId,
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
    if (data.containsKey('reminder_id')) {
      context.handle(
        _reminderIdMeta,
        reminderId.isAcceptableOrUnknown(data['reminder_id']!, _reminderIdMeta),
      );
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
      reminderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reminder_id'],
      ),
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
  final String? reminderId;
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
  const GiftRecord({
    required this.recordId,
    required this.bookId,
    required this.personId,
    this.reminderId,
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
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['record_id'] = Variable<String>(recordId);
    map['book_id'] = Variable<String>(bookId);
    map['person_id'] = Variable<String>(personId);
    if (!nullToAbsent || reminderId != null) {
      map['reminder_id'] = Variable<String>(reminderId);
    }
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
    return map;
  }

  GiftRecordsCompanion toCompanion(bool nullToAbsent) {
    return GiftRecordsCompanion(
      recordId: Value(recordId),
      bookId: Value(bookId),
      personId: Value(personId),
      reminderId: reminderId == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderId),
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
      reminderId: serializer.fromJson<String?>(json['reminderId']),
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
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'recordId': serializer.toJson<String>(recordId),
      'bookId': serializer.toJson<String>(bookId),
      'personId': serializer.toJson<String>(personId),
      'reminderId': serializer.toJson<String?>(reminderId),
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
    };
  }

  GiftRecord copyWith({
    String? recordId,
    String? bookId,
    String? personId,
    Value<String?> reminderId = const Value.absent(),
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
  }) => GiftRecord(
    recordId: recordId ?? this.recordId,
    bookId: bookId ?? this.bookId,
    personId: personId ?? this.personId,
    reminderId: reminderId.present ? reminderId.value : this.reminderId,
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
  );
  GiftRecord copyWithCompanion(GiftRecordsCompanion data) {
    return GiftRecord(
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      personId: data.personId.present ? data.personId.value : this.personId,
      reminderId: data.reminderId.present
          ? data.reminderId.value
          : this.reminderId,
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
    );
  }

  @override
  String toString() {
    return (StringBuffer('GiftRecord(')
          ..write('recordId: $recordId, ')
          ..write('bookId: $bookId, ')
          ..write('personId: $personId, ')
          ..write('reminderId: $reminderId, ')
          ..write('direction: $direction, ')
          ..write('amountCent: $amountCent, ')
          ..write('currency: $currency, ')
          ..write('eventName: $eventName, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('note: $note, ')
          ..write('attachments: $attachments, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    recordId,
    bookId,
    personId,
    reminderId,
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
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GiftRecord &&
          other.recordId == this.recordId &&
          other.bookId == this.bookId &&
          other.personId == this.personId &&
          other.reminderId == this.reminderId &&
          other.direction == this.direction &&
          other.amountCent == this.amountCent &&
          other.currency == this.currency &&
          other.eventName == this.eventName &&
          other.occurredAt == this.occurredAt &&
          other.paymentMethod == this.paymentMethod &&
          other.note == this.note &&
          other.attachments == this.attachments &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class GiftRecordsCompanion extends UpdateCompanion<GiftRecord> {
  final Value<String> recordId;
  final Value<String> bookId;
  final Value<String> personId;
  final Value<String?> reminderId;
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
  final Value<int> rowid;
  const GiftRecordsCompanion({
    this.recordId = const Value.absent(),
    this.bookId = const Value.absent(),
    this.personId = const Value.absent(),
    this.reminderId = const Value.absent(),
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
    this.rowid = const Value.absent(),
  });
  GiftRecordsCompanion.insert({
    this.recordId = const Value.absent(),
    required String bookId,
    required String personId,
    this.reminderId = const Value.absent(),
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
    Expression<String>? reminderId,
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
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (recordId != null) 'record_id': recordId,
      if (bookId != null) 'book_id': bookId,
      if (personId != null) 'person_id': personId,
      if (reminderId != null) 'reminder_id': reminderId,
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
      if (rowid != null) 'rowid': rowid,
    });
  }

  GiftRecordsCompanion copyWith({
    Value<String>? recordId,
    Value<String>? bookId,
    Value<String>? personId,
    Value<String?>? reminderId,
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
    Value<int>? rowid,
  }) {
    return GiftRecordsCompanion(
      recordId: recordId ?? this.recordId,
      bookId: bookId ?? this.bookId,
      personId: personId ?? this.personId,
      reminderId: reminderId ?? this.reminderId,
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
    if (reminderId.present) {
      map['reminder_id'] = Variable<String>(reminderId.value);
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
          ..write('reminderId: $reminderId, ')
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
  late final $EventRemindersTable eventReminders = $EventRemindersTable(this);
  late final $GiftRecordsTable giftRecords = $GiftRecordsTable(this);
  late final $DataImportJobsTable dataImportJobs = $DataImportJobsTable(this);
  late final AccountBooksDao accountBooksDao = AccountBooksDao(
    this as AppDatabase,
  );
  late final PersonsDao personsDao = PersonsDao(this as AppDatabase);
  late final GiftRecordsDao giftRecordsDao = GiftRecordsDao(
    this as AppDatabase,
  );
  late final EventRemindersDao eventRemindersDao = EventRemindersDao(
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
    eventReminders,
    giftRecords,
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
      result: [TableUpdate('event_reminder', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'person',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('event_reminder', kind: UpdateKind.update)],
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
        'event_reminder',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('gift_record', kind: UpdateKind.update)],
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

typedef $$AccountBooksTableCreateCompanionBuilder =
    AccountBooksCompanion Function({
      Value<String> bookId,
      required String name,
      Value<String> reasonType,
      Value<String> themeColor,
      Value<String?> icon,
      Value<String?> description,
      Value<int> isDefault,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$AccountBooksTableUpdateCompanionBuilder =
    AccountBooksCompanion Function({
      Value<String> bookId,
      Value<String> name,
      Value<String> reasonType,
      Value<String> themeColor,
      Value<String?> icon,
      Value<String?> description,
      Value<int> isDefault,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$AccountBooksTableReferences
    extends BaseReferences<_$AppDatabase, $AccountBooksTable, AccountBook> {
  $$AccountBooksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PersonsTable, List<Person>> _personsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.persons,
    aliasName: $_aliasNameGenerator(db.accountBooks.bookId, db.persons.bookId),
  );

  $$PersonsTableProcessedTableManager get personsRefs {
    final manager = $$PersonsTableTableManager($_db, $_db.persons).filter(
      (f) => f.bookId.bookId.sqlEquals($_itemColumn<String>('book_id')!),
    );

    final cache = $_typedResult.readTableOrNull(_personsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EventRemindersTable, List<EventReminder>>
  _eventRemindersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.eventReminders,
    aliasName: $_aliasNameGenerator(
      db.accountBooks.bookId,
      db.eventReminders.bookId,
    ),
  );

  $$EventRemindersTableProcessedTableManager get eventRemindersRefs {
    final manager = $$EventRemindersTableTableManager($_db, $_db.eventReminders)
        .filter(
          (f) => f.bookId.bookId.sqlEquals($_itemColumn<String>('book_id')!),
        );

    final cache = $_typedResult.readTableOrNull(_eventRemindersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$GiftRecordsTable, List<GiftRecord>>
  _giftRecordsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.giftRecords,
    aliasName: $_aliasNameGenerator(
      db.accountBooks.bookId,
      db.giftRecords.bookId,
    ),
  );

  $$GiftRecordsTableProcessedTableManager get giftRecordsRefs {
    final manager = $$GiftRecordsTableTableManager($_db, $_db.giftRecords)
        .filter(
          (f) => f.bookId.bookId.sqlEquals($_itemColumn<String>('book_id')!),
        );

    final cache = $_typedResult.readTableOrNull(_giftRecordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DataImportJobsTable, List<DataImportJob>>
  _dataImportJobsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.dataImportJobs,
    aliasName: $_aliasNameGenerator(
      db.accountBooks.bookId,
      db.dataImportJobs.bookId,
    ),
  );

  $$DataImportJobsTableProcessedTableManager get dataImportJobsRefs {
    final manager = $$DataImportJobsTableTableManager($_db, $_db.dataImportJobs)
        .filter(
          (f) => f.bookId.bookId.sqlEquals($_itemColumn<String>('book_id')!),
        );

    final cache = $_typedResult.readTableOrNull(_dataImportJobsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AccountBooksTableFilterComposer
    extends Composer<_$AppDatabase, $AccountBooksTable> {
  $$AccountBooksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reasonType => $composableBuilder(
    column: $table.reasonType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themeColor => $composableBuilder(
    column: $table.themeColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> personsRefs(
    Expression<bool> Function($$PersonsTableFilterComposer f) f,
  ) {
    final $$PersonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableFilterComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> eventRemindersRefs(
    Expression<bool> Function($$EventRemindersTableFilterComposer f) f,
  ) {
    final $$EventRemindersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.eventReminders,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventRemindersTableFilterComposer(
            $db: $db,
            $table: $db.eventReminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> giftRecordsRefs(
    Expression<bool> Function($$GiftRecordsTableFilterComposer f) f,
  ) {
    final $$GiftRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.giftRecords,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GiftRecordsTableFilterComposer(
            $db: $db,
            $table: $db.giftRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> dataImportJobsRefs(
    Expression<bool> Function($$DataImportJobsTableFilterComposer f) f,
  ) {
    final $$DataImportJobsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.dataImportJobs,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DataImportJobsTableFilterComposer(
            $db: $db,
            $table: $db.dataImportJobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountBooksTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountBooksTable> {
  $$AccountBooksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get bookId => $composableBuilder(
    column: $table.bookId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reasonType => $composableBuilder(
    column: $table.reasonType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themeColor => $composableBuilder(
    column: $table.themeColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AccountBooksTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountBooksTable> {
  $$AccountBooksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get bookId =>
      $composableBuilder(column: $table.bookId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get reasonType => $composableBuilder(
    column: $table.reasonType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get themeColor => $composableBuilder(
    column: $table.themeColor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> personsRefs<T extends Object>(
    Expression<T> Function($$PersonsTableAnnotationComposer a) f,
  ) {
    final $$PersonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableAnnotationComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> eventRemindersRefs<T extends Object>(
    Expression<T> Function($$EventRemindersTableAnnotationComposer a) f,
  ) {
    final $$EventRemindersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.eventReminders,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventRemindersTableAnnotationComposer(
            $db: $db,
            $table: $db.eventReminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> giftRecordsRefs<T extends Object>(
    Expression<T> Function($$GiftRecordsTableAnnotationComposer a) f,
  ) {
    final $$GiftRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.giftRecords,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GiftRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.giftRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> dataImportJobsRefs<T extends Object>(
    Expression<T> Function($$DataImportJobsTableAnnotationComposer a) f,
  ) {
    final $$DataImportJobsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.dataImportJobs,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DataImportJobsTableAnnotationComposer(
            $db: $db,
            $table: $db.dataImportJobs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountBooksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountBooksTable,
          AccountBook,
          $$AccountBooksTableFilterComposer,
          $$AccountBooksTableOrderingComposer,
          $$AccountBooksTableAnnotationComposer,
          $$AccountBooksTableCreateCompanionBuilder,
          $$AccountBooksTableUpdateCompanionBuilder,
          (AccountBook, $$AccountBooksTableReferences),
          AccountBook,
          PrefetchHooks Function({
            bool personsRefs,
            bool eventRemindersRefs,
            bool giftRecordsRefs,
            bool dataImportJobsRefs,
          })
        > {
  $$AccountBooksTableTableManager(_$AppDatabase db, $AccountBooksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountBooksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountBooksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountBooksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> bookId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> reasonType = const Value.absent(),
                Value<String> themeColor = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> isDefault = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountBooksCompanion(
                bookId: bookId,
                name: name,
                reasonType: reasonType,
                themeColor: themeColor,
                icon: icon,
                description: description,
                isDefault: isDefault,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> bookId = const Value.absent(),
                required String name,
                Value<String> reasonType = const Value.absent(),
                Value<String> themeColor = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> isDefault = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AccountBooksCompanion.insert(
                bookId: bookId,
                name: name,
                reasonType: reasonType,
                themeColor: themeColor,
                icon: icon,
                description: description,
                isDefault: isDefault,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AccountBooksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                personsRefs = false,
                eventRemindersRefs = false,
                giftRecordsRefs = false,
                dataImportJobsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (personsRefs) db.persons,
                    if (eventRemindersRefs) db.eventReminders,
                    if (giftRecordsRefs) db.giftRecords,
                    if (dataImportJobsRefs) db.dataImportJobs,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (personsRefs)
                        await $_getPrefetchedData<
                          AccountBook,
                          $AccountBooksTable,
                          Person
                        >(
                          currentTable: table,
                          referencedTable: $$AccountBooksTableReferences
                              ._personsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountBooksTableReferences(
                                db,
                                table,
                                p0,
                              ).personsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bookId == item.bookId,
                              ),
                          typedResults: items,
                        ),
                      if (eventRemindersRefs)
                        await $_getPrefetchedData<
                          AccountBook,
                          $AccountBooksTable,
                          EventReminder
                        >(
                          currentTable: table,
                          referencedTable: $$AccountBooksTableReferences
                              ._eventRemindersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountBooksTableReferences(
                                db,
                                table,
                                p0,
                              ).eventRemindersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bookId == item.bookId,
                              ),
                          typedResults: items,
                        ),
                      if (giftRecordsRefs)
                        await $_getPrefetchedData<
                          AccountBook,
                          $AccountBooksTable,
                          GiftRecord
                        >(
                          currentTable: table,
                          referencedTable: $$AccountBooksTableReferences
                              ._giftRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountBooksTableReferences(
                                db,
                                table,
                                p0,
                              ).giftRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bookId == item.bookId,
                              ),
                          typedResults: items,
                        ),
                      if (dataImportJobsRefs)
                        await $_getPrefetchedData<
                          AccountBook,
                          $AccountBooksTable,
                          DataImportJob
                        >(
                          currentTable: table,
                          referencedTable: $$AccountBooksTableReferences
                              ._dataImportJobsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountBooksTableReferences(
                                db,
                                table,
                                p0,
                              ).dataImportJobsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bookId == item.bookId,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AccountBooksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountBooksTable,
      AccountBook,
      $$AccountBooksTableFilterComposer,
      $$AccountBooksTableOrderingComposer,
      $$AccountBooksTableAnnotationComposer,
      $$AccountBooksTableCreateCompanionBuilder,
      $$AccountBooksTableUpdateCompanionBuilder,
      (AccountBook, $$AccountBooksTableReferences),
      AccountBook,
      PrefetchHooks Function({
        bool personsRefs,
        bool eventRemindersRefs,
        bool giftRecordsRefs,
        bool dataImportJobsRefs,
      })
    >;
typedef $$PersonsTableCreateCompanionBuilder =
    PersonsCompanion Function({
      Value<String> personId,
      required String bookId,
      required String name,
      Value<String> relationshipType,
      Value<String?> phone,
      Value<String?> birthday,
      Value<String?> anniversary,
      Value<String?> avatarUri,
      Value<String?> note,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$PersonsTableUpdateCompanionBuilder =
    PersonsCompanion Function({
      Value<String> personId,
      Value<String> bookId,
      Value<String> name,
      Value<String> relationshipType,
      Value<String?> phone,
      Value<String?> birthday,
      Value<String?> anniversary,
      Value<String?> avatarUri,
      Value<String?> note,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$PersonsTableReferences
    extends BaseReferences<_$AppDatabase, $PersonsTable, Person> {
  $$PersonsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AccountBooksTable _bookIdTable(_$AppDatabase db) =>
      db.accountBooks.createAlias(
        $_aliasNameGenerator(db.persons.bookId, db.accountBooks.bookId),
      );

  $$AccountBooksTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<String>('book_id')!;

    final manager = $$AccountBooksTableTableManager(
      $_db,
      $_db.accountBooks,
    ).filter((f) => f.bookId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$EventRemindersTable, List<EventReminder>>
  _eventRemindersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.eventReminders,
    aliasName: $_aliasNameGenerator(
      db.persons.personId,
      db.eventReminders.personId,
    ),
  );

  $$EventRemindersTableProcessedTableManager get eventRemindersRefs {
    final manager = $$EventRemindersTableTableManager($_db, $_db.eventReminders)
        .filter(
          (f) =>
              f.personId.personId.sqlEquals($_itemColumn<String>('person_id')!),
        );

    final cache = $_typedResult.readTableOrNull(_eventRemindersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$GiftRecordsTable, List<GiftRecord>>
  _giftRecordsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.giftRecords,
    aliasName: $_aliasNameGenerator(
      db.persons.personId,
      db.giftRecords.personId,
    ),
  );

  $$GiftRecordsTableProcessedTableManager get giftRecordsRefs {
    final manager = $$GiftRecordsTableTableManager($_db, $_db.giftRecords)
        .filter(
          (f) =>
              f.personId.personId.sqlEquals($_itemColumn<String>('person_id')!),
        );

    final cache = $_typedResult.readTableOrNull(_giftRecordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PersonsTableFilterComposer
    extends Composer<_$AppDatabase, $PersonsTable> {
  $$PersonsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relationshipType => $composableBuilder(
    column: $table.relationshipType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get birthday => $composableBuilder(
    column: $table.birthday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get anniversary => $composableBuilder(
    column: $table.anniversary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarUri => $composableBuilder(
    column: $table.avatarUri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AccountBooksTableFilterComposer get bookId {
    final $$AccountBooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.accountBooks,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountBooksTableFilterComposer(
            $db: $db,
            $table: $db.accountBooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> eventRemindersRefs(
    Expression<bool> Function($$EventRemindersTableFilterComposer f) f,
  ) {
    final $$EventRemindersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.eventReminders,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventRemindersTableFilterComposer(
            $db: $db,
            $table: $db.eventReminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> giftRecordsRefs(
    Expression<bool> Function($$GiftRecordsTableFilterComposer f) f,
  ) {
    final $$GiftRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.giftRecords,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GiftRecordsTableFilterComposer(
            $db: $db,
            $table: $db.giftRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PersonsTableOrderingComposer
    extends Composer<_$AppDatabase, $PersonsTable> {
  $$PersonsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get personId => $composableBuilder(
    column: $table.personId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relationshipType => $composableBuilder(
    column: $table.relationshipType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get birthday => $composableBuilder(
    column: $table.birthday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get anniversary => $composableBuilder(
    column: $table.anniversary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarUri => $composableBuilder(
    column: $table.avatarUri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AccountBooksTableOrderingComposer get bookId {
    final $$AccountBooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.accountBooks,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountBooksTableOrderingComposer(
            $db: $db,
            $table: $db.accountBooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PersonsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PersonsTable> {
  $$PersonsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get personId =>
      $composableBuilder(column: $table.personId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get relationshipType => $composableBuilder(
    column: $table.relationshipType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get birthday =>
      $composableBuilder(column: $table.birthday, builder: (column) => column);

  GeneratedColumn<String> get anniversary => $composableBuilder(
    column: $table.anniversary,
    builder: (column) => column,
  );

  GeneratedColumn<String> get avatarUri =>
      $composableBuilder(column: $table.avatarUri, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$AccountBooksTableAnnotationComposer get bookId {
    final $$AccountBooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.accountBooks,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountBooksTableAnnotationComposer(
            $db: $db,
            $table: $db.accountBooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> eventRemindersRefs<T extends Object>(
    Expression<T> Function($$EventRemindersTableAnnotationComposer a) f,
  ) {
    final $$EventRemindersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.eventReminders,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventRemindersTableAnnotationComposer(
            $db: $db,
            $table: $db.eventReminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> giftRecordsRefs<T extends Object>(
    Expression<T> Function($$GiftRecordsTableAnnotationComposer a) f,
  ) {
    final $$GiftRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.giftRecords,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GiftRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.giftRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PersonsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PersonsTable,
          Person,
          $$PersonsTableFilterComposer,
          $$PersonsTableOrderingComposer,
          $$PersonsTableAnnotationComposer,
          $$PersonsTableCreateCompanionBuilder,
          $$PersonsTableUpdateCompanionBuilder,
          (Person, $$PersonsTableReferences),
          Person,
          PrefetchHooks Function({
            bool bookId,
            bool eventRemindersRefs,
            bool giftRecordsRefs,
          })
        > {
  $$PersonsTableTableManager(_$AppDatabase db, $PersonsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PersonsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PersonsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PersonsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> personId = const Value.absent(),
                Value<String> bookId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> relationshipType = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> birthday = const Value.absent(),
                Value<String?> anniversary = const Value.absent(),
                Value<String?> avatarUri = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PersonsCompanion(
                personId: personId,
                bookId: bookId,
                name: name,
                relationshipType: relationshipType,
                phone: phone,
                birthday: birthday,
                anniversary: anniversary,
                avatarUri: avatarUri,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> personId = const Value.absent(),
                required String bookId,
                required String name,
                Value<String> relationshipType = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> birthday = const Value.absent(),
                Value<String?> anniversary = const Value.absent(),
                Value<String?> avatarUri = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PersonsCompanion.insert(
                personId: personId,
                bookId: bookId,
                name: name,
                relationshipType: relationshipType,
                phone: phone,
                birthday: birthday,
                anniversary: anniversary,
                avatarUri: avatarUri,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PersonsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                bookId = false,
                eventRemindersRefs = false,
                giftRecordsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (eventRemindersRefs) db.eventReminders,
                    if (giftRecordsRefs) db.giftRecords,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (bookId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.bookId,
                                    referencedTable: $$PersonsTableReferences
                                        ._bookIdTable(db),
                                    referencedColumn: $$PersonsTableReferences
                                        ._bookIdTable(db)
                                        .bookId,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (eventRemindersRefs)
                        await $_getPrefetchedData<
                          Person,
                          $PersonsTable,
                          EventReminder
                        >(
                          currentTable: table,
                          referencedTable: $$PersonsTableReferences
                              ._eventRemindersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PersonsTableReferences(
                                db,
                                table,
                                p0,
                              ).eventRemindersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.personId == item.personId,
                              ),
                          typedResults: items,
                        ),
                      if (giftRecordsRefs)
                        await $_getPrefetchedData<
                          Person,
                          $PersonsTable,
                          GiftRecord
                        >(
                          currentTable: table,
                          referencedTable: $$PersonsTableReferences
                              ._giftRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PersonsTableReferences(
                                db,
                                table,
                                p0,
                              ).giftRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.personId == item.personId,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PersonsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PersonsTable,
      Person,
      $$PersonsTableFilterComposer,
      $$PersonsTableOrderingComposer,
      $$PersonsTableAnnotationComposer,
      $$PersonsTableCreateCompanionBuilder,
      $$PersonsTableUpdateCompanionBuilder,
      (Person, $$PersonsTableReferences),
      Person,
      PrefetchHooks Function({
        bool bookId,
        bool eventRemindersRefs,
        bool giftRecordsRefs,
      })
    >;
typedef $$EventRemindersTableCreateCompanionBuilder =
    EventRemindersCompanion Function({
      Value<String> reminderId,
      required String bookId,
      Value<String?> personId,
      Value<String> reminderType,
      Value<String> title,
      required String targetDate,
      required int remindAt,
      Value<String> repeatRule,
      Value<String> status,
      Value<String> channel,
      Value<String?> note,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$EventRemindersTableUpdateCompanionBuilder =
    EventRemindersCompanion Function({
      Value<String> reminderId,
      Value<String> bookId,
      Value<String?> personId,
      Value<String> reminderType,
      Value<String> title,
      Value<String> targetDate,
      Value<int> remindAt,
      Value<String> repeatRule,
      Value<String> status,
      Value<String> channel,
      Value<String?> note,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$EventRemindersTableReferences
    extends BaseReferences<_$AppDatabase, $EventRemindersTable, EventReminder> {
  $$EventRemindersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AccountBooksTable _bookIdTable(_$AppDatabase db) =>
      db.accountBooks.createAlias(
        $_aliasNameGenerator(db.eventReminders.bookId, db.accountBooks.bookId),
      );

  $$AccountBooksTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<String>('book_id')!;

    final manager = $$AccountBooksTableTableManager(
      $_db,
      $_db.accountBooks,
    ).filter((f) => f.bookId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PersonsTable _personIdTable(_$AppDatabase db) =>
      db.persons.createAlias(
        $_aliasNameGenerator(db.eventReminders.personId, db.persons.personId),
      );

  $$PersonsTableProcessedTableManager? get personId {
    final $_column = $_itemColumn<String>('person_id');
    if ($_column == null) return null;
    final manager = $$PersonsTableTableManager(
      $_db,
      $_db.persons,
    ).filter((f) => f.personId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$GiftRecordsTable, List<GiftRecord>>
  _giftRecordsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.giftRecords,
    aliasName: $_aliasNameGenerator(
      db.eventReminders.reminderId,
      db.giftRecords.reminderId,
    ),
  );

  $$GiftRecordsTableProcessedTableManager get giftRecordsRefs {
    final manager = $$GiftRecordsTableTableManager($_db, $_db.giftRecords)
        .filter(
          (f) => f.reminderId.reminderId.sqlEquals(
            $_itemColumn<String>('reminder_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(_giftRecordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$EventRemindersTableFilterComposer
    extends Composer<_$AppDatabase, $EventRemindersTable> {
  $$EventRemindersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get reminderId => $composableBuilder(
    column: $table.reminderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reminderType => $composableBuilder(
    column: $table.reminderType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get remindAt => $composableBuilder(
    column: $table.remindAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get repeatRule => $composableBuilder(
    column: $table.repeatRule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get channel => $composableBuilder(
    column: $table.channel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AccountBooksTableFilterComposer get bookId {
    final $$AccountBooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.accountBooks,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountBooksTableFilterComposer(
            $db: $db,
            $table: $db.accountBooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PersonsTableFilterComposer get personId {
    final $$PersonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableFilterComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> giftRecordsRefs(
    Expression<bool> Function($$GiftRecordsTableFilterComposer f) f,
  ) {
    final $$GiftRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.reminderId,
      referencedTable: $db.giftRecords,
      getReferencedColumn: (t) => t.reminderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GiftRecordsTableFilterComposer(
            $db: $db,
            $table: $db.giftRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EventRemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $EventRemindersTable> {
  $$EventRemindersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get reminderId => $composableBuilder(
    column: $table.reminderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reminderType => $composableBuilder(
    column: $table.reminderType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get remindAt => $composableBuilder(
    column: $table.remindAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repeatRule => $composableBuilder(
    column: $table.repeatRule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get channel => $composableBuilder(
    column: $table.channel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AccountBooksTableOrderingComposer get bookId {
    final $$AccountBooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.accountBooks,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountBooksTableOrderingComposer(
            $db: $db,
            $table: $db.accountBooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PersonsTableOrderingComposer get personId {
    final $$PersonsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableOrderingComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EventRemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventRemindersTable> {
  $$EventRemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get reminderId => $composableBuilder(
    column: $table.reminderId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reminderType => $composableBuilder(
    column: $table.reminderType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get remindAt =>
      $composableBuilder(column: $table.remindAt, builder: (column) => column);

  GeneratedColumn<String> get repeatRule => $composableBuilder(
    column: $table.repeatRule,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get channel =>
      $composableBuilder(column: $table.channel, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$AccountBooksTableAnnotationComposer get bookId {
    final $$AccountBooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.accountBooks,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountBooksTableAnnotationComposer(
            $db: $db,
            $table: $db.accountBooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PersonsTableAnnotationComposer get personId {
    final $$PersonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableAnnotationComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> giftRecordsRefs<T extends Object>(
    Expression<T> Function($$GiftRecordsTableAnnotationComposer a) f,
  ) {
    final $$GiftRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.reminderId,
      referencedTable: $db.giftRecords,
      getReferencedColumn: (t) => t.reminderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GiftRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.giftRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EventRemindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventRemindersTable,
          EventReminder,
          $$EventRemindersTableFilterComposer,
          $$EventRemindersTableOrderingComposer,
          $$EventRemindersTableAnnotationComposer,
          $$EventRemindersTableCreateCompanionBuilder,
          $$EventRemindersTableUpdateCompanionBuilder,
          (EventReminder, $$EventRemindersTableReferences),
          EventReminder,
          PrefetchHooks Function({
            bool bookId,
            bool personId,
            bool giftRecordsRefs,
          })
        > {
  $$EventRemindersTableTableManager(
    _$AppDatabase db,
    $EventRemindersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventRemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventRemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventRemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> reminderId = const Value.absent(),
                Value<String> bookId = const Value.absent(),
                Value<String?> personId = const Value.absent(),
                Value<String> reminderType = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> targetDate = const Value.absent(),
                Value<int> remindAt = const Value.absent(),
                Value<String> repeatRule = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> channel = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventRemindersCompanion(
                reminderId: reminderId,
                bookId: bookId,
                personId: personId,
                reminderType: reminderType,
                title: title,
                targetDate: targetDate,
                remindAt: remindAt,
                repeatRule: repeatRule,
                status: status,
                channel: channel,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> reminderId = const Value.absent(),
                required String bookId,
                Value<String?> personId = const Value.absent(),
                Value<String> reminderType = const Value.absent(),
                Value<String> title = const Value.absent(),
                required String targetDate,
                required int remindAt,
                Value<String> repeatRule = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> channel = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => EventRemindersCompanion.insert(
                reminderId: reminderId,
                bookId: bookId,
                personId: personId,
                reminderType: reminderType,
                title: title,
                targetDate: targetDate,
                remindAt: remindAt,
                repeatRule: repeatRule,
                status: status,
                channel: channel,
                note: note,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EventRemindersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({bookId = false, personId = false, giftRecordsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (giftRecordsRefs) db.giftRecords,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (bookId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.bookId,
                                    referencedTable:
                                        $$EventRemindersTableReferences
                                            ._bookIdTable(db),
                                    referencedColumn:
                                        $$EventRemindersTableReferences
                                            ._bookIdTable(db)
                                            .bookId,
                                  )
                                  as T;
                        }
                        if (personId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.personId,
                                    referencedTable:
                                        $$EventRemindersTableReferences
                                            ._personIdTable(db),
                                    referencedColumn:
                                        $$EventRemindersTableReferences
                                            ._personIdTable(db)
                                            .personId,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (giftRecordsRefs)
                        await $_getPrefetchedData<
                          EventReminder,
                          $EventRemindersTable,
                          GiftRecord
                        >(
                          currentTable: table,
                          referencedTable: $$EventRemindersTableReferences
                              ._giftRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EventRemindersTableReferences(
                                db,
                                table,
                                p0,
                              ).giftRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.reminderId == item.reminderId,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$EventRemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventRemindersTable,
      EventReminder,
      $$EventRemindersTableFilterComposer,
      $$EventRemindersTableOrderingComposer,
      $$EventRemindersTableAnnotationComposer,
      $$EventRemindersTableCreateCompanionBuilder,
      $$EventRemindersTableUpdateCompanionBuilder,
      (EventReminder, $$EventRemindersTableReferences),
      EventReminder,
      PrefetchHooks Function({bool bookId, bool personId, bool giftRecordsRefs})
    >;
typedef $$GiftRecordsTableCreateCompanionBuilder =
    GiftRecordsCompanion Function({
      Value<String> recordId,
      required String bookId,
      required String personId,
      Value<String?> reminderId,
      Value<String> direction,
      required int amountCent,
      Value<String> currency,
      Value<String?> eventName,
      required int occurredAt,
      Value<String?> paymentMethod,
      Value<String?> note,
      Value<List<String>?> attachments,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$GiftRecordsTableUpdateCompanionBuilder =
    GiftRecordsCompanion Function({
      Value<String> recordId,
      Value<String> bookId,
      Value<String> personId,
      Value<String?> reminderId,
      Value<String> direction,
      Value<int> amountCent,
      Value<String> currency,
      Value<String?> eventName,
      Value<int> occurredAt,
      Value<String?> paymentMethod,
      Value<String?> note,
      Value<List<String>?> attachments,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$GiftRecordsTableReferences
    extends BaseReferences<_$AppDatabase, $GiftRecordsTable, GiftRecord> {
  $$GiftRecordsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AccountBooksTable _bookIdTable(_$AppDatabase db) =>
      db.accountBooks.createAlias(
        $_aliasNameGenerator(db.giftRecords.bookId, db.accountBooks.bookId),
      );

  $$AccountBooksTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<String>('book_id')!;

    final manager = $$AccountBooksTableTableManager(
      $_db,
      $_db.accountBooks,
    ).filter((f) => f.bookId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PersonsTable _personIdTable(_$AppDatabase db) =>
      db.persons.createAlias(
        $_aliasNameGenerator(db.giftRecords.personId, db.persons.personId),
      );

  $$PersonsTableProcessedTableManager get personId {
    final $_column = $_itemColumn<String>('person_id')!;

    final manager = $$PersonsTableTableManager(
      $_db,
      $_db.persons,
    ).filter((f) => f.personId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $EventRemindersTable _reminderIdTable(_$AppDatabase db) =>
      db.eventReminders.createAlias(
        $_aliasNameGenerator(
          db.giftRecords.reminderId,
          db.eventReminders.reminderId,
        ),
      );

  $$EventRemindersTableProcessedTableManager? get reminderId {
    final $_column = $_itemColumn<String>('reminder_id');
    if ($_column == null) return null;
    final manager = $$EventRemindersTableTableManager(
      $_db,
      $_db.eventReminders,
    ).filter((f) => f.reminderId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_reminderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$GiftRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $GiftRecordsTable> {
  $$GiftRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountCent => $composableBuilder(
    column: $table.amountCent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventName => $composableBuilder(
    column: $table.eventName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>?, List<String>, String>
  get attachments => $composableBuilder(
    column: $table.attachments,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AccountBooksTableFilterComposer get bookId {
    final $$AccountBooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.accountBooks,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountBooksTableFilterComposer(
            $db: $db,
            $table: $db.accountBooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PersonsTableFilterComposer get personId {
    final $$PersonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableFilterComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EventRemindersTableFilterComposer get reminderId {
    final $$EventRemindersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.reminderId,
      referencedTable: $db.eventReminders,
      getReferencedColumn: (t) => t.reminderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventRemindersTableFilterComposer(
            $db: $db,
            $table: $db.eventReminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GiftRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $GiftRecordsTable> {
  $$GiftRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountCent => $composableBuilder(
    column: $table.amountCent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventName => $composableBuilder(
    column: $table.eventName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attachments => $composableBuilder(
    column: $table.attachments,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AccountBooksTableOrderingComposer get bookId {
    final $$AccountBooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.accountBooks,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountBooksTableOrderingComposer(
            $db: $db,
            $table: $db.accountBooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PersonsTableOrderingComposer get personId {
    final $$PersonsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableOrderingComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EventRemindersTableOrderingComposer get reminderId {
    final $$EventRemindersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.reminderId,
      referencedTable: $db.eventReminders,
      getReferencedColumn: (t) => t.reminderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventRemindersTableOrderingComposer(
            $db: $db,
            $table: $db.eventReminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GiftRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GiftRecordsTable> {
  $$GiftRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<int> get amountCent => $composableBuilder(
    column: $table.amountCent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get eventName =>
      $composableBuilder(column: $table.eventName, builder: (column) => column);

  GeneratedColumn<int> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>?, String> get attachments =>
      $composableBuilder(
        column: $table.attachments,
        builder: (column) => column,
      );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$AccountBooksTableAnnotationComposer get bookId {
    final $$AccountBooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.accountBooks,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountBooksTableAnnotationComposer(
            $db: $db,
            $table: $db.accountBooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PersonsTableAnnotationComposer get personId {
    final $$PersonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableAnnotationComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EventRemindersTableAnnotationComposer get reminderId {
    final $$EventRemindersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.reminderId,
      referencedTable: $db.eventReminders,
      getReferencedColumn: (t) => t.reminderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventRemindersTableAnnotationComposer(
            $db: $db,
            $table: $db.eventReminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GiftRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GiftRecordsTable,
          GiftRecord,
          $$GiftRecordsTableFilterComposer,
          $$GiftRecordsTableOrderingComposer,
          $$GiftRecordsTableAnnotationComposer,
          $$GiftRecordsTableCreateCompanionBuilder,
          $$GiftRecordsTableUpdateCompanionBuilder,
          (GiftRecord, $$GiftRecordsTableReferences),
          GiftRecord,
          PrefetchHooks Function({bool bookId, bool personId, bool reminderId})
        > {
  $$GiftRecordsTableTableManager(_$AppDatabase db, $GiftRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GiftRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GiftRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GiftRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> recordId = const Value.absent(),
                Value<String> bookId = const Value.absent(),
                Value<String> personId = const Value.absent(),
                Value<String?> reminderId = const Value.absent(),
                Value<String> direction = const Value.absent(),
                Value<int> amountCent = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String?> eventName = const Value.absent(),
                Value<int> occurredAt = const Value.absent(),
                Value<String?> paymentMethod = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<List<String>?> attachments = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GiftRecordsCompanion(
                recordId: recordId,
                bookId: bookId,
                personId: personId,
                reminderId: reminderId,
                direction: direction,
                amountCent: amountCent,
                currency: currency,
                eventName: eventName,
                occurredAt: occurredAt,
                paymentMethod: paymentMethod,
                note: note,
                attachments: attachments,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> recordId = const Value.absent(),
                required String bookId,
                required String personId,
                Value<String?> reminderId = const Value.absent(),
                Value<String> direction = const Value.absent(),
                required int amountCent,
                Value<String> currency = const Value.absent(),
                Value<String?> eventName = const Value.absent(),
                required int occurredAt,
                Value<String?> paymentMethod = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<List<String>?> attachments = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => GiftRecordsCompanion.insert(
                recordId: recordId,
                bookId: bookId,
                personId: personId,
                reminderId: reminderId,
                direction: direction,
                amountCent: amountCent,
                currency: currency,
                eventName: eventName,
                occurredAt: occurredAt,
                paymentMethod: paymentMethod,
                note: note,
                attachments: attachments,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$GiftRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({bookId = false, personId = false, reminderId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (bookId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.bookId,
                                    referencedTable:
                                        $$GiftRecordsTableReferences
                                            ._bookIdTable(db),
                                    referencedColumn:
                                        $$GiftRecordsTableReferences
                                            ._bookIdTable(db)
                                            .bookId,
                                  )
                                  as T;
                        }
                        if (personId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.personId,
                                    referencedTable:
                                        $$GiftRecordsTableReferences
                                            ._personIdTable(db),
                                    referencedColumn:
                                        $$GiftRecordsTableReferences
                                            ._personIdTable(db)
                                            .personId,
                                  )
                                  as T;
                        }
                        if (reminderId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.reminderId,
                                    referencedTable:
                                        $$GiftRecordsTableReferences
                                            ._reminderIdTable(db),
                                    referencedColumn:
                                        $$GiftRecordsTableReferences
                                            ._reminderIdTable(db)
                                            .reminderId,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$GiftRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GiftRecordsTable,
      GiftRecord,
      $$GiftRecordsTableFilterComposer,
      $$GiftRecordsTableOrderingComposer,
      $$GiftRecordsTableAnnotationComposer,
      $$GiftRecordsTableCreateCompanionBuilder,
      $$GiftRecordsTableUpdateCompanionBuilder,
      (GiftRecord, $$GiftRecordsTableReferences),
      GiftRecord,
      PrefetchHooks Function({bool bookId, bool personId, bool reminderId})
    >;
typedef $$DataImportJobsTableCreateCompanionBuilder =
    DataImportJobsCompanion Function({
      Value<String> jobId,
      required String bookId,
      required String filePath,
      required String fileName,
      required String fileHash,
      required int fileSize,
      required String format,
      required String status,
      required String importKind,
      Value<String?> mappingJson,
      Value<int?> totalRows,
      Value<int> processedRows,
      Value<int> successRows,
      Value<int> skippedRows,
      Value<int> failedRows,
      Value<int> byteOffset,
      Value<int> lastRowIndex,
      Value<String?> errorLogPath,
      required int startedAt,
      Value<int?> finishedAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$DataImportJobsTableUpdateCompanionBuilder =
    DataImportJobsCompanion Function({
      Value<String> jobId,
      Value<String> bookId,
      Value<String> filePath,
      Value<String> fileName,
      Value<String> fileHash,
      Value<int> fileSize,
      Value<String> format,
      Value<String> status,
      Value<String> importKind,
      Value<String?> mappingJson,
      Value<int?> totalRows,
      Value<int> processedRows,
      Value<int> successRows,
      Value<int> skippedRows,
      Value<int> failedRows,
      Value<int> byteOffset,
      Value<int> lastRowIndex,
      Value<String?> errorLogPath,
      Value<int> startedAt,
      Value<int?> finishedAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

final class $$DataImportJobsTableReferences
    extends BaseReferences<_$AppDatabase, $DataImportJobsTable, DataImportJob> {
  $$DataImportJobsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AccountBooksTable _bookIdTable(_$AppDatabase db) =>
      db.accountBooks.createAlias(
        $_aliasNameGenerator(db.dataImportJobs.bookId, db.accountBooks.bookId),
      );

  $$AccountBooksTableProcessedTableManager get bookId {
    final $_column = $_itemColumn<String>('book_id')!;

    final manager = $$AccountBooksTableTableManager(
      $_db,
      $_db.accountBooks,
    ).filter((f) => f.bookId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DataImportJobsTableFilterComposer
    extends Composer<_$AppDatabase, $DataImportJobsTable> {
  $$DataImportJobsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get jobId => $composableBuilder(
    column: $table.jobId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileHash => $composableBuilder(
    column: $table.fileHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get importKind => $composableBuilder(
    column: $table.importKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mappingJson => $composableBuilder(
    column: $table.mappingJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalRows => $composableBuilder(
    column: $table.totalRows,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get processedRows => $composableBuilder(
    column: $table.processedRows,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get successRows => $composableBuilder(
    column: $table.successRows,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get skippedRows => $composableBuilder(
    column: $table.skippedRows,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get failedRows => $composableBuilder(
    column: $table.failedRows,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get byteOffset => $composableBuilder(
    column: $table.byteOffset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastRowIndex => $composableBuilder(
    column: $table.lastRowIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorLogPath => $composableBuilder(
    column: $table.errorLogPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AccountBooksTableFilterComposer get bookId {
    final $$AccountBooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.accountBooks,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountBooksTableFilterComposer(
            $db: $db,
            $table: $db.accountBooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DataImportJobsTableOrderingComposer
    extends Composer<_$AppDatabase, $DataImportJobsTable> {
  $$DataImportJobsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get jobId => $composableBuilder(
    column: $table.jobId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileHash => $composableBuilder(
    column: $table.fileHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get importKind => $composableBuilder(
    column: $table.importKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mappingJson => $composableBuilder(
    column: $table.mappingJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalRows => $composableBuilder(
    column: $table.totalRows,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get processedRows => $composableBuilder(
    column: $table.processedRows,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get successRows => $composableBuilder(
    column: $table.successRows,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get skippedRows => $composableBuilder(
    column: $table.skippedRows,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get failedRows => $composableBuilder(
    column: $table.failedRows,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get byteOffset => $composableBuilder(
    column: $table.byteOffset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastRowIndex => $composableBuilder(
    column: $table.lastRowIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorLogPath => $composableBuilder(
    column: $table.errorLogPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AccountBooksTableOrderingComposer get bookId {
    final $$AccountBooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.accountBooks,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountBooksTableOrderingComposer(
            $db: $db,
            $table: $db.accountBooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DataImportJobsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DataImportJobsTable> {
  $$DataImportJobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get jobId =>
      $composableBuilder(column: $table.jobId, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get fileHash =>
      $composableBuilder(column: $table.fileHash, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get importKind => $composableBuilder(
    column: $table.importKind,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mappingJson => $composableBuilder(
    column: $table.mappingJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalRows =>
      $composableBuilder(column: $table.totalRows, builder: (column) => column);

  GeneratedColumn<int> get processedRows => $composableBuilder(
    column: $table.processedRows,
    builder: (column) => column,
  );

  GeneratedColumn<int> get successRows => $composableBuilder(
    column: $table.successRows,
    builder: (column) => column,
  );

  GeneratedColumn<int> get skippedRows => $composableBuilder(
    column: $table.skippedRows,
    builder: (column) => column,
  );

  GeneratedColumn<int> get failedRows => $composableBuilder(
    column: $table.failedRows,
    builder: (column) => column,
  );

  GeneratedColumn<int> get byteOffset => $composableBuilder(
    column: $table.byteOffset,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastRowIndex => $composableBuilder(
    column: $table.lastRowIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorLogPath => $composableBuilder(
    column: $table.errorLogPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$AccountBooksTableAnnotationComposer get bookId {
    final $$AccountBooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookId,
      referencedTable: $db.accountBooks,
      getReferencedColumn: (t) => t.bookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountBooksTableAnnotationComposer(
            $db: $db,
            $table: $db.accountBooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DataImportJobsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DataImportJobsTable,
          DataImportJob,
          $$DataImportJobsTableFilterComposer,
          $$DataImportJobsTableOrderingComposer,
          $$DataImportJobsTableAnnotationComposer,
          $$DataImportJobsTableCreateCompanionBuilder,
          $$DataImportJobsTableUpdateCompanionBuilder,
          (DataImportJob, $$DataImportJobsTableReferences),
          DataImportJob,
          PrefetchHooks Function({bool bookId})
        > {
  $$DataImportJobsTableTableManager(
    _$AppDatabase db,
    $DataImportJobsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DataImportJobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DataImportJobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DataImportJobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> jobId = const Value.absent(),
                Value<String> bookId = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<String> fileHash = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<String> format = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> importKind = const Value.absent(),
                Value<String?> mappingJson = const Value.absent(),
                Value<int?> totalRows = const Value.absent(),
                Value<int> processedRows = const Value.absent(),
                Value<int> successRows = const Value.absent(),
                Value<int> skippedRows = const Value.absent(),
                Value<int> failedRows = const Value.absent(),
                Value<int> byteOffset = const Value.absent(),
                Value<int> lastRowIndex = const Value.absent(),
                Value<String?> errorLogPath = const Value.absent(),
                Value<int> startedAt = const Value.absent(),
                Value<int?> finishedAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DataImportJobsCompanion(
                jobId: jobId,
                bookId: bookId,
                filePath: filePath,
                fileName: fileName,
                fileHash: fileHash,
                fileSize: fileSize,
                format: format,
                status: status,
                importKind: importKind,
                mappingJson: mappingJson,
                totalRows: totalRows,
                processedRows: processedRows,
                successRows: successRows,
                skippedRows: skippedRows,
                failedRows: failedRows,
                byteOffset: byteOffset,
                lastRowIndex: lastRowIndex,
                errorLogPath: errorLogPath,
                startedAt: startedAt,
                finishedAt: finishedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> jobId = const Value.absent(),
                required String bookId,
                required String filePath,
                required String fileName,
                required String fileHash,
                required int fileSize,
                required String format,
                required String status,
                required String importKind,
                Value<String?> mappingJson = const Value.absent(),
                Value<int?> totalRows = const Value.absent(),
                Value<int> processedRows = const Value.absent(),
                Value<int> successRows = const Value.absent(),
                Value<int> skippedRows = const Value.absent(),
                Value<int> failedRows = const Value.absent(),
                Value<int> byteOffset = const Value.absent(),
                Value<int> lastRowIndex = const Value.absent(),
                Value<String?> errorLogPath = const Value.absent(),
                required int startedAt,
                Value<int?> finishedAt = const Value.absent(),
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DataImportJobsCompanion.insert(
                jobId: jobId,
                bookId: bookId,
                filePath: filePath,
                fileName: fileName,
                fileHash: fileHash,
                fileSize: fileSize,
                format: format,
                status: status,
                importKind: importKind,
                mappingJson: mappingJson,
                totalRows: totalRows,
                processedRows: processedRows,
                successRows: successRows,
                skippedRows: skippedRows,
                failedRows: failedRows,
                byteOffset: byteOffset,
                lastRowIndex: lastRowIndex,
                errorLogPath: errorLogPath,
                startedAt: startedAt,
                finishedAt: finishedAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DataImportJobsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({bookId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (bookId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.bookId,
                                referencedTable: $$DataImportJobsTableReferences
                                    ._bookIdTable(db),
                                referencedColumn:
                                    $$DataImportJobsTableReferences
                                        ._bookIdTable(db)
                                        .bookId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DataImportJobsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DataImportJobsTable,
      DataImportJob,
      $$DataImportJobsTableFilterComposer,
      $$DataImportJobsTableOrderingComposer,
      $$DataImportJobsTableAnnotationComposer,
      $$DataImportJobsTableCreateCompanionBuilder,
      $$DataImportJobsTableUpdateCompanionBuilder,
      (DataImportJob, $$DataImportJobsTableReferences),
      DataImportJob,
      PrefetchHooks Function({bool bookId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AccountBooksTableTableManager get accountBooks =>
      $$AccountBooksTableTableManager(_db, _db.accountBooks);
  $$PersonsTableTableManager get persons =>
      $$PersonsTableTableManager(_db, _db.persons);
  $$EventRemindersTableTableManager get eventReminders =>
      $$EventRemindersTableTableManager(_db, _db.eventReminders);
  $$GiftRecordsTableTableManager get giftRecords =>
      $$GiftRecordsTableTableManager(_db, _db.giftRecords);
  $$DataImportJobsTableTableManager get dataImportJobs =>
      $$DataImportJobsTableTableManager(_db, _db.dataImportJobs);
}

mixin _$AccountBooksDaoMixin on DatabaseAccessor<AppDatabase> {
  $AccountBooksTable get accountBooks => attachedDatabase.accountBooks;
  AccountBooksDaoManager get managers => AccountBooksDaoManager(this);
}

class AccountBooksDaoManager {
  final _$AccountBooksDaoMixin _db;
  AccountBooksDaoManager(this._db);
  $$AccountBooksTableTableManager get accountBooks =>
      $$AccountBooksTableTableManager(_db.attachedDatabase, _db.accountBooks);
}

mixin _$PersonsDaoMixin on DatabaseAccessor<AppDatabase> {
  $AccountBooksTable get accountBooks => attachedDatabase.accountBooks;
  $PersonsTable get persons => attachedDatabase.persons;
  PersonsDaoManager get managers => PersonsDaoManager(this);
}

class PersonsDaoManager {
  final _$PersonsDaoMixin _db;
  PersonsDaoManager(this._db);
  $$AccountBooksTableTableManager get accountBooks =>
      $$AccountBooksTableTableManager(_db.attachedDatabase, _db.accountBooks);
  $$PersonsTableTableManager get persons =>
      $$PersonsTableTableManager(_db.attachedDatabase, _db.persons);
}

mixin _$GiftRecordsDaoMixin on DatabaseAccessor<AppDatabase> {
  $AccountBooksTable get accountBooks => attachedDatabase.accountBooks;
  $PersonsTable get persons => attachedDatabase.persons;
  $EventRemindersTable get eventReminders => attachedDatabase.eventReminders;
  $GiftRecordsTable get giftRecords => attachedDatabase.giftRecords;
  GiftRecordsDaoManager get managers => GiftRecordsDaoManager(this);
}

class GiftRecordsDaoManager {
  final _$GiftRecordsDaoMixin _db;
  GiftRecordsDaoManager(this._db);
  $$AccountBooksTableTableManager get accountBooks =>
      $$AccountBooksTableTableManager(_db.attachedDatabase, _db.accountBooks);
  $$PersonsTableTableManager get persons =>
      $$PersonsTableTableManager(_db.attachedDatabase, _db.persons);
  $$EventRemindersTableTableManager get eventReminders =>
      $$EventRemindersTableTableManager(
        _db.attachedDatabase,
        _db.eventReminders,
      );
  $$GiftRecordsTableTableManager get giftRecords =>
      $$GiftRecordsTableTableManager(_db.attachedDatabase, _db.giftRecords);
}

mixin _$EventRemindersDaoMixin on DatabaseAccessor<AppDatabase> {
  $AccountBooksTable get accountBooks => attachedDatabase.accountBooks;
  $PersonsTable get persons => attachedDatabase.persons;
  $EventRemindersTable get eventReminders => attachedDatabase.eventReminders;
  EventRemindersDaoManager get managers => EventRemindersDaoManager(this);
}

class EventRemindersDaoManager {
  final _$EventRemindersDaoMixin _db;
  EventRemindersDaoManager(this._db);
  $$AccountBooksTableTableManager get accountBooks =>
      $$AccountBooksTableTableManager(_db.attachedDatabase, _db.accountBooks);
  $$PersonsTableTableManager get persons =>
      $$PersonsTableTableManager(_db.attachedDatabase, _db.persons);
  $$EventRemindersTableTableManager get eventReminders =>
      $$EventRemindersTableTableManager(
        _db.attachedDatabase,
        _db.eventReminders,
      );
}

mixin _$DataImportJobsDaoMixin on DatabaseAccessor<AppDatabase> {
  $AccountBooksTable get accountBooks => attachedDatabase.accountBooks;
  $DataImportJobsTable get dataImportJobs => attachedDatabase.dataImportJobs;
  DataImportJobsDaoManager get managers => DataImportJobsDaoManager(this);
}

class DataImportJobsDaoManager {
  final _$DataImportJobsDaoMixin _db;
  DataImportJobsDaoManager(this._db);
  $$AccountBooksTableTableManager get accountBooks =>
      $$AccountBooksTableTableManager(_db.attachedDatabase, _db.accountBooks);
  $$DataImportJobsTableTableManager get dataImportJobs =>
      $$DataImportJobsTableTableManager(
        _db.attachedDatabase,
        _db.dataImportJobs,
      );
}
