// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SyllabusCategoriesTable extends SyllabusCategories
    with TableInfo<$SyllabusCategoriesTable, SyllabusCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyllabusCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastInteractedAtMeta = const VerificationMeta(
    'lastInteractedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastInteractedAt =
      GeneratedColumn<DateTime>(
        'last_interacted_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    position,
    color,
    lastInteractedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'syllabus_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyllabusCategory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('last_interacted_at')) {
      context.handle(
        _lastInteractedAtMeta,
        lastInteractedAt.isAcceptableOrUnknown(
          data['last_interacted_at']!,
          _lastInteractedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyllabusCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyllabusCategory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      )!,
      lastInteractedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_interacted_at'],
      ),
    );
  }

  @override
  $SyllabusCategoriesTable createAlias(String alias) {
    return $SyllabusCategoriesTable(attachedDatabase, alias);
  }
}

class SyllabusCategory extends DataClass
    implements Insertable<SyllabusCategory> {
  final int id;
  final String name;
  final int position;
  final int color;
  final DateTime? lastInteractedAt;
  const SyllabusCategory({
    required this.id,
    required this.name,
    required this.position,
    required this.color,
    this.lastInteractedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['position'] = Variable<int>(position);
    map['color'] = Variable<int>(color);
    if (!nullToAbsent || lastInteractedAt != null) {
      map['last_interacted_at'] = Variable<DateTime>(lastInteractedAt);
    }
    return map;
  }

  SyllabusCategoriesCompanion toCompanion(bool nullToAbsent) {
    return SyllabusCategoriesCompanion(
      id: Value(id),
      name: Value(name),
      position: Value(position),
      color: Value(color),
      lastInteractedAt: lastInteractedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastInteractedAt),
    );
  }

  factory SyllabusCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyllabusCategory(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      position: serializer.fromJson<int>(json['position']),
      color: serializer.fromJson<int>(json['color']),
      lastInteractedAt: serializer.fromJson<DateTime?>(
        json['lastInteractedAt'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'position': serializer.toJson<int>(position),
      'color': serializer.toJson<int>(color),
      'lastInteractedAt': serializer.toJson<DateTime?>(lastInteractedAt),
    };
  }

  SyllabusCategory copyWith({
    int? id,
    String? name,
    int? position,
    int? color,
    Value<DateTime?> lastInteractedAt = const Value.absent(),
  }) => SyllabusCategory(
    id: id ?? this.id,
    name: name ?? this.name,
    position: position ?? this.position,
    color: color ?? this.color,
    lastInteractedAt: lastInteractedAt.present
        ? lastInteractedAt.value
        : this.lastInteractedAt,
  );
  SyllabusCategory copyWithCompanion(SyllabusCategoriesCompanion data) {
    return SyllabusCategory(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      position: data.position.present ? data.position.value : this.position,
      color: data.color.present ? data.color.value : this.color,
      lastInteractedAt: data.lastInteractedAt.present
          ? data.lastInteractedAt.value
          : this.lastInteractedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyllabusCategory(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('position: $position, ')
          ..write('color: $color, ')
          ..write('lastInteractedAt: $lastInteractedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, position, color, lastInteractedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyllabusCategory &&
          other.id == this.id &&
          other.name == this.name &&
          other.position == this.position &&
          other.color == this.color &&
          other.lastInteractedAt == this.lastInteractedAt);
}

class SyllabusCategoriesCompanion extends UpdateCompanion<SyllabusCategory> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> position;
  final Value<int> color;
  final Value<DateTime?> lastInteractedAt;
  const SyllabusCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.position = const Value.absent(),
    this.color = const Value.absent(),
    this.lastInteractedAt = const Value.absent(),
  });
  SyllabusCategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int position,
    required int color,
    this.lastInteractedAt = const Value.absent(),
  }) : name = Value(name),
       position = Value(position),
       color = Value(color);
  static Insertable<SyllabusCategory> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? position,
    Expression<int>? color,
    Expression<DateTime>? lastInteractedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (position != null) 'position': position,
      if (color != null) 'color': color,
      if (lastInteractedAt != null) 'last_interacted_at': lastInteractedAt,
    });
  }

  SyllabusCategoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? position,
    Value<int>? color,
    Value<DateTime?>? lastInteractedAt,
  }) {
    return SyllabusCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      position: position ?? this.position,
      color: color ?? this.color,
      lastInteractedAt: lastInteractedAt ?? this.lastInteractedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (lastInteractedAt.present) {
      map['last_interacted_at'] = Variable<DateTime>(lastInteractedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyllabusCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('position: $position, ')
          ..write('color: $color, ')
          ..write('lastInteractedAt: $lastInteractedAt')
          ..write(')'))
        .toString();
  }
}

class $SyllabusTopicsTable extends SyllabusTopics
    with TableInfo<$SyllabusTopicsTable, SyllabusTopic> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyllabusTopicsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES syllabus_categories (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 150,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, categoryId, name, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'syllabus_topics';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyllabusTopic> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyllabusTopic map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyllabusTopic(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $SyllabusTopicsTable createAlias(String alias) {
    return $SyllabusTopicsTable(attachedDatabase, alias);
  }
}

class SyllabusTopic extends DataClass implements Insertable<SyllabusTopic> {
  final int id;
  final int categoryId;
  final String name;
  final int position;
  const SyllabusTopic({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['category_id'] = Variable<int>(categoryId);
    map['name'] = Variable<String>(name);
    map['position'] = Variable<int>(position);
    return map;
  }

  SyllabusTopicsCompanion toCompanion(bool nullToAbsent) {
    return SyllabusTopicsCompanion(
      id: Value(id),
      categoryId: Value(categoryId),
      name: Value(name),
      position: Value(position),
    );
  }

  factory SyllabusTopic.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyllabusTopic(
      id: serializer.fromJson<int>(json['id']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      name: serializer.fromJson<String>(json['name']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'categoryId': serializer.toJson<int>(categoryId),
      'name': serializer.toJson<String>(name),
      'position': serializer.toJson<int>(position),
    };
  }

  SyllabusTopic copyWith({
    int? id,
    int? categoryId,
    String? name,
    int? position,
  }) => SyllabusTopic(
    id: id ?? this.id,
    categoryId: categoryId ?? this.categoryId,
    name: name ?? this.name,
    position: position ?? this.position,
  );
  SyllabusTopic copyWithCompanion(SyllabusTopicsCompanion data) {
    return SyllabusTopic(
      id: data.id.present ? data.id.value : this.id,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      name: data.name.present ? data.name.value : this.name,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyllabusTopic(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, categoryId, name, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyllabusTopic &&
          other.id == this.id &&
          other.categoryId == this.categoryId &&
          other.name == this.name &&
          other.position == this.position);
}

class SyllabusTopicsCompanion extends UpdateCompanion<SyllabusTopic> {
  final Value<int> id;
  final Value<int> categoryId;
  final Value<String> name;
  final Value<int> position;
  const SyllabusTopicsCompanion({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.name = const Value.absent(),
    this.position = const Value.absent(),
  });
  SyllabusTopicsCompanion.insert({
    this.id = const Value.absent(),
    required int categoryId,
    required String name,
    required int position,
  }) : categoryId = Value(categoryId),
       name = Value(name),
       position = Value(position);
  static Insertable<SyllabusTopic> custom({
    Expression<int>? id,
    Expression<int>? categoryId,
    Expression<String>? name,
    Expression<int>? position,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (categoryId != null) 'category_id': categoryId,
      if (name != null) 'name': name,
      if (position != null) 'position': position,
    });
  }

  SyllabusTopicsCompanion copyWith({
    Value<int>? id,
    Value<int>? categoryId,
    Value<String>? name,
    Value<int>? position,
  }) {
    return SyllabusTopicsCompanion(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      position: position ?? this.position,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyllabusTopicsCompanion(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }
}

class $SyllabusTasksTable extends SyllabusTasks
    with TableInfo<$SyllabusTasksTable, SyllabusTask> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyllabusTasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _topicIdMeta = const VerificationMeta(
    'topicId',
  );
  @override
  late final GeneratedColumn<int> topicId = GeneratedColumn<int>(
    'topic_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES syllabus_topics (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    topicId,
    name,
    isCompleted,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'syllabus_tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyllabusTask> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('topic_id')) {
      context.handle(
        _topicIdMeta,
        topicId.isAcceptableOrUnknown(data['topic_id']!, _topicIdMeta),
      );
    } else if (isInserting) {
      context.missing(_topicIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyllabusTask map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyllabusTask(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      topicId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}topic_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $SyllabusTasksTable createAlias(String alias) {
    return $SyllabusTasksTable(attachedDatabase, alias);
  }
}

class SyllabusTask extends DataClass implements Insertable<SyllabusTask> {
  final int id;
  final int topicId;
  final String name;
  final bool isCompleted;
  final int position;
  const SyllabusTask({
    required this.id,
    required this.topicId,
    required this.name,
    required this.isCompleted,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['topic_id'] = Variable<int>(topicId);
    map['name'] = Variable<String>(name);
    map['is_completed'] = Variable<bool>(isCompleted);
    map['position'] = Variable<int>(position);
    return map;
  }

  SyllabusTasksCompanion toCompanion(bool nullToAbsent) {
    return SyllabusTasksCompanion(
      id: Value(id),
      topicId: Value(topicId),
      name: Value(name),
      isCompleted: Value(isCompleted),
      position: Value(position),
    );
  }

  factory SyllabusTask.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyllabusTask(
      id: serializer.fromJson<int>(json['id']),
      topicId: serializer.fromJson<int>(json['topicId']),
      name: serializer.fromJson<String>(json['name']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'topicId': serializer.toJson<int>(topicId),
      'name': serializer.toJson<String>(name),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'position': serializer.toJson<int>(position),
    };
  }

  SyllabusTask copyWith({
    int? id,
    int? topicId,
    String? name,
    bool? isCompleted,
    int? position,
  }) => SyllabusTask(
    id: id ?? this.id,
    topicId: topicId ?? this.topicId,
    name: name ?? this.name,
    isCompleted: isCompleted ?? this.isCompleted,
    position: position ?? this.position,
  );
  SyllabusTask copyWithCompanion(SyllabusTasksCompanion data) {
    return SyllabusTask(
      id: data.id.present ? data.id.value : this.id,
      topicId: data.topicId.present ? data.topicId.value : this.topicId,
      name: data.name.present ? data.name.value : this.name,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyllabusTask(')
          ..write('id: $id, ')
          ..write('topicId: $topicId, ')
          ..write('name: $name, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, topicId, name, isCompleted, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyllabusTask &&
          other.id == this.id &&
          other.topicId == this.topicId &&
          other.name == this.name &&
          other.isCompleted == this.isCompleted &&
          other.position == this.position);
}

class SyllabusTasksCompanion extends UpdateCompanion<SyllabusTask> {
  final Value<int> id;
  final Value<int> topicId;
  final Value<String> name;
  final Value<bool> isCompleted;
  final Value<int> position;
  const SyllabusTasksCompanion({
    this.id = const Value.absent(),
    this.topicId = const Value.absent(),
    this.name = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.position = const Value.absent(),
  });
  SyllabusTasksCompanion.insert({
    this.id = const Value.absent(),
    required int topicId,
    required String name,
    this.isCompleted = const Value.absent(),
    required int position,
  }) : topicId = Value(topicId),
       name = Value(name),
       position = Value(position);
  static Insertable<SyllabusTask> custom({
    Expression<int>? id,
    Expression<int>? topicId,
    Expression<String>? name,
    Expression<bool>? isCompleted,
    Expression<int>? position,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (topicId != null) 'topic_id': topicId,
      if (name != null) 'name': name,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (position != null) 'position': position,
    });
  }

  SyllabusTasksCompanion copyWith({
    Value<int>? id,
    Value<int>? topicId,
    Value<String>? name,
    Value<bool>? isCompleted,
    Value<int>? position,
  }) {
    return SyllabusTasksCompanion(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      name: name ?? this.name,
      isCompleted: isCompleted ?? this.isCompleted,
      position: position ?? this.position,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (topicId.present) {
      map['topic_id'] = Variable<int>(topicId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyllabusTasksCompanion(')
          ..write('id: $id, ')
          ..write('topicId: $topicId, ')
          ..write('name: $name, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }
}

class $FocusSessionsTable extends FocusSessions
    with TableInfo<$FocusSessionsTable, FocusSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FocusSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
    'method',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accomplishmentsMeta = const VerificationMeta(
    'accomplishments',
  );
  @override
  late final GeneratedColumn<String> accomplishments = GeneratedColumn<String>(
    'accomplishments',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _progressDeltaMeta = const VerificationMeta(
    'progressDelta',
  );
  @override
  late final GeneratedColumn<double> progressDelta = GeneratedColumn<double>(
    'progress_delta',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    method,
    startTime,
    durationSeconds,
    accomplishments,
    progressDelta,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'focus_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<FocusSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('method')) {
      context.handle(
        _methodMeta,
        method.isAcceptableOrUnknown(data['method']!, _methodMeta),
      );
    } else if (isInserting) {
      context.missing(_methodMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationSecondsMeta);
    }
    if (data.containsKey('accomplishments')) {
      context.handle(
        _accomplishmentsMeta,
        accomplishments.isAcceptableOrUnknown(
          data['accomplishments']!,
          _accomplishmentsMeta,
        ),
      );
    }
    if (data.containsKey('progress_delta')) {
      context.handle(
        _progressDeltaMeta,
        progressDelta.isAcceptableOrUnknown(
          data['progress_delta']!,
          _progressDeltaMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FocusSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FocusSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      method: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_time'],
      )!,
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      )!,
      accomplishments: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}accomplishments'],
      ),
      progressDelta: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}progress_delta'],
      )!,
    );
  }

  @override
  $FocusSessionsTable createAlias(String alias) {
    return $FocusSessionsTable(attachedDatabase, alias);
  }
}

class FocusSession extends DataClass implements Insertable<FocusSession> {
  final int id;
  final String method;
  final DateTime startTime;
  final int durationSeconds;
  final String? accomplishments;
  final double progressDelta;
  const FocusSession({
    required this.id,
    required this.method,
    required this.startTime,
    required this.durationSeconds,
    this.accomplishments,
    required this.progressDelta,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['method'] = Variable<String>(method);
    map['start_time'] = Variable<DateTime>(startTime);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    if (!nullToAbsent || accomplishments != null) {
      map['accomplishments'] = Variable<String>(accomplishments);
    }
    map['progress_delta'] = Variable<double>(progressDelta);
    return map;
  }

  FocusSessionsCompanion toCompanion(bool nullToAbsent) {
    return FocusSessionsCompanion(
      id: Value(id),
      method: Value(method),
      startTime: Value(startTime),
      durationSeconds: Value(durationSeconds),
      accomplishments: accomplishments == null && nullToAbsent
          ? const Value.absent()
          : Value(accomplishments),
      progressDelta: Value(progressDelta),
    );
  }

  factory FocusSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FocusSession(
      id: serializer.fromJson<int>(json['id']),
      method: serializer.fromJson<String>(json['method']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      accomplishments: serializer.fromJson<String?>(json['accomplishments']),
      progressDelta: serializer.fromJson<double>(json['progressDelta']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'method': serializer.toJson<String>(method),
      'startTime': serializer.toJson<DateTime>(startTime),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'accomplishments': serializer.toJson<String?>(accomplishments),
      'progressDelta': serializer.toJson<double>(progressDelta),
    };
  }

  FocusSession copyWith({
    int? id,
    String? method,
    DateTime? startTime,
    int? durationSeconds,
    Value<String?> accomplishments = const Value.absent(),
    double? progressDelta,
  }) => FocusSession(
    id: id ?? this.id,
    method: method ?? this.method,
    startTime: startTime ?? this.startTime,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    accomplishments: accomplishments.present
        ? accomplishments.value
        : this.accomplishments,
    progressDelta: progressDelta ?? this.progressDelta,
  );
  FocusSession copyWithCompanion(FocusSessionsCompanion data) {
    return FocusSession(
      id: data.id.present ? data.id.value : this.id,
      method: data.method.present ? data.method.value : this.method,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      accomplishments: data.accomplishments.present
          ? data.accomplishments.value
          : this.accomplishments,
      progressDelta: data.progressDelta.present
          ? data.progressDelta.value
          : this.progressDelta,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FocusSession(')
          ..write('id: $id, ')
          ..write('method: $method, ')
          ..write('startTime: $startTime, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('accomplishments: $accomplishments, ')
          ..write('progressDelta: $progressDelta')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    method,
    startTime,
    durationSeconds,
    accomplishments,
    progressDelta,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FocusSession &&
          other.id == this.id &&
          other.method == this.method &&
          other.startTime == this.startTime &&
          other.durationSeconds == this.durationSeconds &&
          other.accomplishments == this.accomplishments &&
          other.progressDelta == this.progressDelta);
}

class FocusSessionsCompanion extends UpdateCompanion<FocusSession> {
  final Value<int> id;
  final Value<String> method;
  final Value<DateTime> startTime;
  final Value<int> durationSeconds;
  final Value<String?> accomplishments;
  final Value<double> progressDelta;
  const FocusSessionsCompanion({
    this.id = const Value.absent(),
    this.method = const Value.absent(),
    this.startTime = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.accomplishments = const Value.absent(),
    this.progressDelta = const Value.absent(),
  });
  FocusSessionsCompanion.insert({
    this.id = const Value.absent(),
    required String method,
    required DateTime startTime,
    required int durationSeconds,
    this.accomplishments = const Value.absent(),
    this.progressDelta = const Value.absent(),
  }) : method = Value(method),
       startTime = Value(startTime),
       durationSeconds = Value(durationSeconds);
  static Insertable<FocusSession> custom({
    Expression<int>? id,
    Expression<String>? method,
    Expression<DateTime>? startTime,
    Expression<int>? durationSeconds,
    Expression<String>? accomplishments,
    Expression<double>? progressDelta,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (method != null) 'method': method,
      if (startTime != null) 'start_time': startTime,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (accomplishments != null) 'accomplishments': accomplishments,
      if (progressDelta != null) 'progress_delta': progressDelta,
    });
  }

  FocusSessionsCompanion copyWith({
    Value<int>? id,
    Value<String>? method,
    Value<DateTime>? startTime,
    Value<int>? durationSeconds,
    Value<String?>? accomplishments,
    Value<double>? progressDelta,
  }) {
    return FocusSessionsCompanion(
      id: id ?? this.id,
      method: method ?? this.method,
      startTime: startTime ?? this.startTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      accomplishments: accomplishments ?? this.accomplishments,
      progressDelta: progressDelta ?? this.progressDelta,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (accomplishments.present) {
      map['accomplishments'] = Variable<String>(accomplishments.value);
    }
    if (progressDelta.present) {
      map['progress_delta'] = Variable<double>(progressDelta.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FocusSessionsCompanion(')
          ..write('id: $id, ')
          ..write('method: $method, ')
          ..write('startTime: $startTime, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('accomplishments: $accomplishments, ')
          ..write('progressDelta: $progressDelta')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SyllabusCategoriesTable syllabusCategories =
      $SyllabusCategoriesTable(this);
  late final $SyllabusTopicsTable syllabusTopics = $SyllabusTopicsTable(this);
  late final $SyllabusTasksTable syllabusTasks = $SyllabusTasksTable(this);
  late final $FocusSessionsTable focusSessions = $FocusSessionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    syllabusCategories,
    syllabusTopics,
    syllabusTasks,
    focusSessions,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'syllabus_categories',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('syllabus_topics', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'syllabus_topics',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('syllabus_tasks', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$SyllabusCategoriesTableCreateCompanionBuilder =
    SyllabusCategoriesCompanion Function({
      Value<int> id,
      required String name,
      required int position,
      required int color,
      Value<DateTime?> lastInteractedAt,
    });
typedef $$SyllabusCategoriesTableUpdateCompanionBuilder =
    SyllabusCategoriesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> position,
      Value<int> color,
      Value<DateTime?> lastInteractedAt,
    });

final class $$SyllabusCategoriesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $SyllabusCategoriesTable,
          SyllabusCategory
        > {
  $$SyllabusCategoriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$SyllabusTopicsTable, List<SyllabusTopic>>
  _syllabusTopicsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.syllabusTopics,
    aliasName: $_aliasNameGenerator(
      db.syllabusCategories.id,
      db.syllabusTopics.categoryId,
    ),
  );

  $$SyllabusTopicsTableProcessedTableManager get syllabusTopicsRefs {
    final manager = $$SyllabusTopicsTableTableManager(
      $_db,
      $_db.syllabusTopics,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_syllabusTopicsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SyllabusCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $SyllabusCategoriesTable> {
  $$SyllabusCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastInteractedAt => $composableBuilder(
    column: $table.lastInteractedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> syllabusTopicsRefs(
    Expression<bool> Function($$SyllabusTopicsTableFilterComposer f) f,
  ) {
    final $$SyllabusTopicsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syllabusTopics,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyllabusTopicsTableFilterComposer(
            $db: $db,
            $table: $db.syllabusTopics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SyllabusCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyllabusCategoriesTable> {
  $$SyllabusCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastInteractedAt => $composableBuilder(
    column: $table.lastInteractedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyllabusCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyllabusCategoriesTable> {
  $$SyllabusCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<DateTime> get lastInteractedAt => $composableBuilder(
    column: $table.lastInteractedAt,
    builder: (column) => column,
  );

  Expression<T> syllabusTopicsRefs<T extends Object>(
    Expression<T> Function($$SyllabusTopicsTableAnnotationComposer a) f,
  ) {
    final $$SyllabusTopicsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syllabusTopics,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyllabusTopicsTableAnnotationComposer(
            $db: $db,
            $table: $db.syllabusTopics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SyllabusCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyllabusCategoriesTable,
          SyllabusCategory,
          $$SyllabusCategoriesTableFilterComposer,
          $$SyllabusCategoriesTableOrderingComposer,
          $$SyllabusCategoriesTableAnnotationComposer,
          $$SyllabusCategoriesTableCreateCompanionBuilder,
          $$SyllabusCategoriesTableUpdateCompanionBuilder,
          (SyllabusCategory, $$SyllabusCategoriesTableReferences),
          SyllabusCategory,
          PrefetchHooks Function({bool syllabusTopicsRefs})
        > {
  $$SyllabusCategoriesTableTableManager(
    _$AppDatabase db,
    $SyllabusCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyllabusCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyllabusCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyllabusCategoriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<DateTime?> lastInteractedAt = const Value.absent(),
              }) => SyllabusCategoriesCompanion(
                id: id,
                name: name,
                position: position,
                color: color,
                lastInteractedAt: lastInteractedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required int position,
                required int color,
                Value<DateTime?> lastInteractedAt = const Value.absent(),
              }) => SyllabusCategoriesCompanion.insert(
                id: id,
                name: name,
                position: position,
                color: color,
                lastInteractedAt: lastInteractedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SyllabusCategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({syllabusTopicsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (syllabusTopicsRefs) db.syllabusTopics,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (syllabusTopicsRefs)
                    await $_getPrefetchedData<
                      SyllabusCategory,
                      $SyllabusCategoriesTable,
                      SyllabusTopic
                    >(
                      currentTable: table,
                      referencedTable: $$SyllabusCategoriesTableReferences
                          ._syllabusTopicsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SyllabusCategoriesTableReferences(
                            db,
                            table,
                            p0,
                          ).syllabusTopicsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.categoryId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SyllabusCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyllabusCategoriesTable,
      SyllabusCategory,
      $$SyllabusCategoriesTableFilterComposer,
      $$SyllabusCategoriesTableOrderingComposer,
      $$SyllabusCategoriesTableAnnotationComposer,
      $$SyllabusCategoriesTableCreateCompanionBuilder,
      $$SyllabusCategoriesTableUpdateCompanionBuilder,
      (SyllabusCategory, $$SyllabusCategoriesTableReferences),
      SyllabusCategory,
      PrefetchHooks Function({bool syllabusTopicsRefs})
    >;
typedef $$SyllabusTopicsTableCreateCompanionBuilder =
    SyllabusTopicsCompanion Function({
      Value<int> id,
      required int categoryId,
      required String name,
      required int position,
    });
typedef $$SyllabusTopicsTableUpdateCompanionBuilder =
    SyllabusTopicsCompanion Function({
      Value<int> id,
      Value<int> categoryId,
      Value<String> name,
      Value<int> position,
    });

final class $$SyllabusTopicsTableReferences
    extends BaseReferences<_$AppDatabase, $SyllabusTopicsTable, SyllabusTopic> {
  $$SyllabusTopicsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SyllabusCategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.syllabusCategories.createAlias(
        $_aliasNameGenerator(
          db.syllabusTopics.categoryId,
          db.syllabusCategories.id,
        ),
      );

  $$SyllabusCategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<int>('category_id')!;

    final manager = $$SyllabusCategoriesTableTableManager(
      $_db,
      $_db.syllabusCategories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SyllabusTasksTable, List<SyllabusTask>>
  _syllabusTasksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.syllabusTasks,
    aliasName: $_aliasNameGenerator(
      db.syllabusTopics.id,
      db.syllabusTasks.topicId,
    ),
  );

  $$SyllabusTasksTableProcessedTableManager get syllabusTasksRefs {
    final manager = $$SyllabusTasksTableTableManager(
      $_db,
      $_db.syllabusTasks,
    ).filter((f) => f.topicId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_syllabusTasksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SyllabusTopicsTableFilterComposer
    extends Composer<_$AppDatabase, $SyllabusTopicsTable> {
  $$SyllabusTopicsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$SyllabusCategoriesTableFilterComposer get categoryId {
    final $$SyllabusCategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.syllabusCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyllabusCategoriesTableFilterComposer(
            $db: $db,
            $table: $db.syllabusCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> syllabusTasksRefs(
    Expression<bool> Function($$SyllabusTasksTableFilterComposer f) f,
  ) {
    final $$SyllabusTasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syllabusTasks,
      getReferencedColumn: (t) => t.topicId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyllabusTasksTableFilterComposer(
            $db: $db,
            $table: $db.syllabusTasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SyllabusTopicsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyllabusTopicsTable> {
  $$SyllabusTopicsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$SyllabusCategoriesTableOrderingComposer get categoryId {
    final $$SyllabusCategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.syllabusCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyllabusCategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.syllabusCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyllabusTopicsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyllabusTopicsTable> {
  $$SyllabusTopicsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$SyllabusCategoriesTableAnnotationComposer get categoryId {
    final $$SyllabusCategoriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.categoryId,
          referencedTable: $db.syllabusCategories,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SyllabusCategoriesTableAnnotationComposer(
                $db: $db,
                $table: $db.syllabusCategories,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<T> syllabusTasksRefs<T extends Object>(
    Expression<T> Function($$SyllabusTasksTableAnnotationComposer a) f,
  ) {
    final $$SyllabusTasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syllabusTasks,
      getReferencedColumn: (t) => t.topicId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyllabusTasksTableAnnotationComposer(
            $db: $db,
            $table: $db.syllabusTasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SyllabusTopicsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyllabusTopicsTable,
          SyllabusTopic,
          $$SyllabusTopicsTableFilterComposer,
          $$SyllabusTopicsTableOrderingComposer,
          $$SyllabusTopicsTableAnnotationComposer,
          $$SyllabusTopicsTableCreateCompanionBuilder,
          $$SyllabusTopicsTableUpdateCompanionBuilder,
          (SyllabusTopic, $$SyllabusTopicsTableReferences),
          SyllabusTopic,
          PrefetchHooks Function({bool categoryId, bool syllabusTasksRefs})
        > {
  $$SyllabusTopicsTableTableManager(
    _$AppDatabase db,
    $SyllabusTopicsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyllabusTopicsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyllabusTopicsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyllabusTopicsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> categoryId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> position = const Value.absent(),
              }) => SyllabusTopicsCompanion(
                id: id,
                categoryId: categoryId,
                name: name,
                position: position,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int categoryId,
                required String name,
                required int position,
              }) => SyllabusTopicsCompanion.insert(
                id: id,
                categoryId: categoryId,
                name: name,
                position: position,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SyllabusTopicsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({categoryId = false, syllabusTasksRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (syllabusTasksRefs) db.syllabusTasks,
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
                        if (categoryId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.categoryId,
                                    referencedTable:
                                        $$SyllabusTopicsTableReferences
                                            ._categoryIdTable(db),
                                    referencedColumn:
                                        $$SyllabusTopicsTableReferences
                                            ._categoryIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (syllabusTasksRefs)
                        await $_getPrefetchedData<
                          SyllabusTopic,
                          $SyllabusTopicsTable,
                          SyllabusTask
                        >(
                          currentTable: table,
                          referencedTable: $$SyllabusTopicsTableReferences
                              ._syllabusTasksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SyllabusTopicsTableReferences(
                                db,
                                table,
                                p0,
                              ).syllabusTasksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.topicId == item.id,
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

typedef $$SyllabusTopicsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyllabusTopicsTable,
      SyllabusTopic,
      $$SyllabusTopicsTableFilterComposer,
      $$SyllabusTopicsTableOrderingComposer,
      $$SyllabusTopicsTableAnnotationComposer,
      $$SyllabusTopicsTableCreateCompanionBuilder,
      $$SyllabusTopicsTableUpdateCompanionBuilder,
      (SyllabusTopic, $$SyllabusTopicsTableReferences),
      SyllabusTopic,
      PrefetchHooks Function({bool categoryId, bool syllabusTasksRefs})
    >;
typedef $$SyllabusTasksTableCreateCompanionBuilder =
    SyllabusTasksCompanion Function({
      Value<int> id,
      required int topicId,
      required String name,
      Value<bool> isCompleted,
      required int position,
    });
typedef $$SyllabusTasksTableUpdateCompanionBuilder =
    SyllabusTasksCompanion Function({
      Value<int> id,
      Value<int> topicId,
      Value<String> name,
      Value<bool> isCompleted,
      Value<int> position,
    });

final class $$SyllabusTasksTableReferences
    extends BaseReferences<_$AppDatabase, $SyllabusTasksTable, SyllabusTask> {
  $$SyllabusTasksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SyllabusTopicsTable _topicIdTable(_$AppDatabase db) =>
      db.syllabusTopics.createAlias(
        $_aliasNameGenerator(db.syllabusTasks.topicId, db.syllabusTopics.id),
      );

  $$SyllabusTopicsTableProcessedTableManager get topicId {
    final $_column = $_itemColumn<int>('topic_id')!;

    final manager = $$SyllabusTopicsTableTableManager(
      $_db,
      $_db.syllabusTopics,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_topicIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SyllabusTasksTableFilterComposer
    extends Composer<_$AppDatabase, $SyllabusTasksTable> {
  $$SyllabusTasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$SyllabusTopicsTableFilterComposer get topicId {
    final $$SyllabusTopicsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.topicId,
      referencedTable: $db.syllabusTopics,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyllabusTopicsTableFilterComposer(
            $db: $db,
            $table: $db.syllabusTopics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyllabusTasksTableOrderingComposer
    extends Composer<_$AppDatabase, $SyllabusTasksTable> {
  $$SyllabusTasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$SyllabusTopicsTableOrderingComposer get topicId {
    final $$SyllabusTopicsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.topicId,
      referencedTable: $db.syllabusTopics,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyllabusTopicsTableOrderingComposer(
            $db: $db,
            $table: $db.syllabusTopics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyllabusTasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyllabusTasksTable> {
  $$SyllabusTasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$SyllabusTopicsTableAnnotationComposer get topicId {
    final $$SyllabusTopicsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.topicId,
      referencedTable: $db.syllabusTopics,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyllabusTopicsTableAnnotationComposer(
            $db: $db,
            $table: $db.syllabusTopics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyllabusTasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyllabusTasksTable,
          SyllabusTask,
          $$SyllabusTasksTableFilterComposer,
          $$SyllabusTasksTableOrderingComposer,
          $$SyllabusTasksTableAnnotationComposer,
          $$SyllabusTasksTableCreateCompanionBuilder,
          $$SyllabusTasksTableUpdateCompanionBuilder,
          (SyllabusTask, $$SyllabusTasksTableReferences),
          SyllabusTask,
          PrefetchHooks Function({bool topicId})
        > {
  $$SyllabusTasksTableTableManager(_$AppDatabase db, $SyllabusTasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyllabusTasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyllabusTasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyllabusTasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> topicId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<int> position = const Value.absent(),
              }) => SyllabusTasksCompanion(
                id: id,
                topicId: topicId,
                name: name,
                isCompleted: isCompleted,
                position: position,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int topicId,
                required String name,
                Value<bool> isCompleted = const Value.absent(),
                required int position,
              }) => SyllabusTasksCompanion.insert(
                id: id,
                topicId: topicId,
                name: name,
                isCompleted: isCompleted,
                position: position,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SyllabusTasksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({topicId = false}) {
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
                    if (topicId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.topicId,
                                referencedTable: $$SyllabusTasksTableReferences
                                    ._topicIdTable(db),
                                referencedColumn: $$SyllabusTasksTableReferences
                                    ._topicIdTable(db)
                                    .id,
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

typedef $$SyllabusTasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyllabusTasksTable,
      SyllabusTask,
      $$SyllabusTasksTableFilterComposer,
      $$SyllabusTasksTableOrderingComposer,
      $$SyllabusTasksTableAnnotationComposer,
      $$SyllabusTasksTableCreateCompanionBuilder,
      $$SyllabusTasksTableUpdateCompanionBuilder,
      (SyllabusTask, $$SyllabusTasksTableReferences),
      SyllabusTask,
      PrefetchHooks Function({bool topicId})
    >;
typedef $$FocusSessionsTableCreateCompanionBuilder =
    FocusSessionsCompanion Function({
      Value<int> id,
      required String method,
      required DateTime startTime,
      required int durationSeconds,
      Value<String?> accomplishments,
      Value<double> progressDelta,
    });
typedef $$FocusSessionsTableUpdateCompanionBuilder =
    FocusSessionsCompanion Function({
      Value<int> id,
      Value<String> method,
      Value<DateTime> startTime,
      Value<int> durationSeconds,
      Value<String?> accomplishments,
      Value<double> progressDelta,
    });

class $$FocusSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $FocusSessionsTable> {
  $$FocusSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accomplishments => $composableBuilder(
    column: $table.accomplishments,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get progressDelta => $composableBuilder(
    column: $table.progressDelta,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FocusSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $FocusSessionsTable> {
  $$FocusSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accomplishments => $composableBuilder(
    column: $table.accomplishments,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get progressDelta => $composableBuilder(
    column: $table.progressDelta,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FocusSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FocusSessionsTable> {
  $$FocusSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accomplishments => $composableBuilder(
    column: $table.accomplishments,
    builder: (column) => column,
  );

  GeneratedColumn<double> get progressDelta => $composableBuilder(
    column: $table.progressDelta,
    builder: (column) => column,
  );
}

class $$FocusSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FocusSessionsTable,
          FocusSession,
          $$FocusSessionsTableFilterComposer,
          $$FocusSessionsTableOrderingComposer,
          $$FocusSessionsTableAnnotationComposer,
          $$FocusSessionsTableCreateCompanionBuilder,
          $$FocusSessionsTableUpdateCompanionBuilder,
          (
            FocusSession,
            BaseReferences<_$AppDatabase, $FocusSessionsTable, FocusSession>,
          ),
          FocusSession,
          PrefetchHooks Function()
        > {
  $$FocusSessionsTableTableManager(_$AppDatabase db, $FocusSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FocusSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FocusSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FocusSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> method = const Value.absent(),
                Value<DateTime> startTime = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<String?> accomplishments = const Value.absent(),
                Value<double> progressDelta = const Value.absent(),
              }) => FocusSessionsCompanion(
                id: id,
                method: method,
                startTime: startTime,
                durationSeconds: durationSeconds,
                accomplishments: accomplishments,
                progressDelta: progressDelta,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String method,
                required DateTime startTime,
                required int durationSeconds,
                Value<String?> accomplishments = const Value.absent(),
                Value<double> progressDelta = const Value.absent(),
              }) => FocusSessionsCompanion.insert(
                id: id,
                method: method,
                startTime: startTime,
                durationSeconds: durationSeconds,
                accomplishments: accomplishments,
                progressDelta: progressDelta,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FocusSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FocusSessionsTable,
      FocusSession,
      $$FocusSessionsTableFilterComposer,
      $$FocusSessionsTableOrderingComposer,
      $$FocusSessionsTableAnnotationComposer,
      $$FocusSessionsTableCreateCompanionBuilder,
      $$FocusSessionsTableUpdateCompanionBuilder,
      (
        FocusSession,
        BaseReferences<_$AppDatabase, $FocusSessionsTable, FocusSession>,
      ),
      FocusSession,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SyllabusCategoriesTableTableManager get syllabusCategories =>
      $$SyllabusCategoriesTableTableManager(_db, _db.syllabusCategories);
  $$SyllabusTopicsTableTableManager get syllabusTopics =>
      $$SyllabusTopicsTableTableManager(_db, _db.syllabusTopics);
  $$SyllabusTasksTableTableManager get syllabusTasks =>
      $$SyllabusTasksTableTableManager(_db, _db.syllabusTasks);
  $$FocusSessionsTableTableManager get focusSessions =>
      $$FocusSessionsTableTableManager(_db, _db.focusSessions);
}
