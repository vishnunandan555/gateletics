import 'package:drift/drift.dart';
import 'connection/connection.dart' as conn;
import 'schema_version.dart';
import 'syllabus_preset.dart';

part 'app_database.g.dart';

// Deleted Categories and Subjects tables

class SyllabusCategories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get position => integer()();
  IntColumn get color => integer()();
  DateTimeColumn get lastInteractedAt => dateTime().nullable()();
}

class SyllabusTopics extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer().references(SyllabusCategories, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text().withLength(min: 1, max: 150)();
  IntColumn get position => integer()();
}

class SyllabusTasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get topicId => integer().references(SyllabusTopics, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get position => integer()();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

class FocusSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get method => text().withLength(min: 1, max: 50)();
  DateTimeColumn get startTime => dateTime()();
  IntColumn get durationSeconds => integer()();
  TextColumn get accomplishments => text().nullable()();
  RealColumn get progressDelta => real().withDefault(const Constant(0.0))();
}

class DailyHistory extends Table {
  TextColumn get dateStr => text().withLength(min: 10, max: 10)(); // "YYYY-MM-DD"
  IntColumn get totalFocusSeconds => integer().withDefault(const Constant(0))();
  IntColumn get targetGoalSeconds => integer().withDefault(const Constant(7200))();
  BoolColumn get isGoalCompleted => boolean().withDefault(const Constant(false))();
  RealColumn get syllabusProgressPct => real().withDefault(const Constant(0.0))();

  @override
  Set<Column> get primaryKey => {dateStr};
}

class CustomTasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get content => text().withLength(min: 1, max: 500)();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get position => integer().withDefault(const Constant(0))();
}

class SyllabusTopicWithTasks {
  final SyllabusTopic topic;
  final List<SyllabusTask> tasks;

  SyllabusTopicWithTasks({
    required this.topic,
    required this.tasks,
  });
}

class SyllabusCategoryWithTopics {
  final SyllabusCategory category;
  final List<SyllabusTopicWithTasks> topics;

  SyllabusCategoryWithTopics({
    required this.category,
    required this.topics,
  });
}

@DriftDatabase(tables: [SyllabusCategories, SyllabusTopics, SyllabusTasks, FocusSessions, DailyHistory, CustomTasks])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(conn.connect(schemaVersion: appSchemaVersion));
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => appSchemaVersion;

  // ----------------------------------------------------
  // Global / Preset Actions
  // ----------------------------------------------------

  Future<void> resetTrackingData() async {
    // Clear syllabus task statistics
    final allCats = await select(syllabusCategories).get();
    await transaction(() async {
      for (final c in allCats) {
        await resetSyllabusCategoryStats(c.id);
      }
    });
  }

  Future<void> hardResetEverything() async {
    await transaction(() async {
      await delete(syllabusTasks).go();
      await delete(syllabusTopics).go();
      await delete(syllabusCategories).go();
    });
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await seedSyllabus();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(syllabusCategories);
            await m.createTable(syllabusTopics);
            await m.createTable(syllabusTasks);
            await seedSyllabus();
          }
          if (from < 3) {
            try {
              await m.addColumn(syllabusCategories, syllabusCategories.lastInteractedAt);
            } catch (_) {}
          }
          if (from < 4) {
            try {
              await m.createTable(focusSessions);
            } catch (_) {}
          }
          if (from < 5) {
            try {
              await m.addColumn(focusSessions, focusSessions.progressDelta);
            } catch (_) {}
          }
          if (from < 6) {
            try {
              await m.createTable(dailyHistory);
            } catch (_) {}
          }
          if (from < 7) {
            try {
              await m.database.customStatement('ALTER TABLE focus_sessions ADD COLUMN category_id INTEGER REFERENCES syllabus_categories(id) ON DELETE SET NULL;');
            } catch (_) {}
          }
          if (from < 9) {
            try {
              await m.createTable(customTasks);
            } catch (_) {}
          }
          if (from < 10) {
            try {
              await m.addColumn(syllabusTasks, syllabusTasks.completedAt);
            } catch (_) {}
          }
        },
      );

  // ----------------------------------------------------
  // Syllabus Streams
  // ----------------------------------------------------

  Stream<List<SyllabusCategory>> watchSyllabusCategories() {
    return (select(syllabusCategories)..orderBy([(t) => OrderingTerm(expression: t.position)])).watch();
  }

  Stream<List<SyllabusTopic>> watchSyllabusTopics() {
    return (select(syllabusTopics)..orderBy([(t) => OrderingTerm(expression: t.position)])).watch();
  }

  Stream<List<SyllabusTask>> watchSyllabusTasks() {
    return (select(syllabusTasks)..orderBy([(t) => OrderingTerm(expression: t.position)])).watch();
  }

  // ----------------------------------------------------
  // Syllabus Seeding
  // ----------------------------------------------------

  Future<void> seedSyllabus() async {
    await transaction(() async {
      await delete(syllabusTasks).go();
      await delete(syllabusTopics).go();
      await delete(syllabusCategories).go();

      for (int i = 0; i < defaultSyllabusPreset.length; i++) {
        final presetCat = defaultSyllabusPreset[i];
        final catId = await into(syllabusCategories).insert(
          SyllabusCategoriesCompanion.insert(
            name: presetCat.name,
            position: i,
            color: presetCat.color,
          ),
        );

        for (int j = 0; j < presetCat.topics.length; j++) {
          final presetTopic = presetCat.topics[j];
          final topicId = await into(syllabusTopics).insert(
            SyllabusTopicsCompanion.insert(
              categoryId: catId,
              name: presetTopic.name,
              position: j,
            ),
          );

          for (int k = 0; k < presetTopic.tasks.length; k++) {
            final taskName = presetTopic.tasks[k];
            await into(syllabusTasks).insert(
              SyllabusTasksCompanion.insert(
                topicId: topicId,
                name: taskName,
                position: k,
                isCompleted: const Value(false),
              ),
            );
          }
        }
      }
    });
  }

  // ----------------------------------------------------
  // Syllabus Category Operations
  // ----------------------------------------------------

  Future<int> addSyllabusCategory(String name, int color, {int? position, DateTime? lastInteractedAt}) async {
    int pos = position ?? 0;
    if (position == null) {
      final existing = await select(syllabusCategories).get();
      pos = existing.length;
    }
    return into(syllabusCategories).insert(SyllabusCategoriesCompanion.insert(
      name: name,
      color: color,
      position: pos,
      lastInteractedAt: Value(lastInteractedAt),
    ));
  }

  Future<void> updateSyllabusCategoryDetails(int id, String name, int color) async {
    await (update(syllabusCategories)..where((t) => t.id.equals(id))).write(
      SyllabusCategoriesCompanion(
        name: Value(name),
        color: Value(color),
      ),
    );
  }

  Future<void> deleteSyllabusCategory(int id) async {
    await transaction(() async {
      final topicsInCat = await (select(syllabusTopics)..where((t) => t.categoryId.equals(id))).get();
      for (final topic in topicsInCat) {
        await (delete(syllabusTasks)..where((t) => t.topicId.equals(topic.id))).go();
      }
      await (delete(syllabusTopics)..where((t) => t.categoryId.equals(id))).go();
      await (delete(syllabusCategories)..where((t) => t.id.equals(id))).go();
    });
  }

  Future<void> updateSyllabusCategoryPositions(List<int> orderedCategoryIds) async {
    await transaction(() async {
      for (int i = 0; i < orderedCategoryIds.length; i++) {
        await (update(syllabusCategories)..where((t) => t.id.equals(orderedCategoryIds[i]))).write(
          SyllabusCategoriesCompanion(position: Value(i)),
        );
      }
    });
  }

  // ----------------------------------------------------
  // Syllabus Topic Operations
  // ----------------------------------------------------

  Future<int> addSyllabusTopic(int categoryId, String name, {int? position}) async {
    int pos = position ?? 0;
    if (position == null) {
      final existing = await (select(syllabusTopics)..where((t) => t.categoryId.equals(categoryId))).get();
      pos = existing.length;
    }
    return into(syllabusTopics).insert(SyllabusTopicsCompanion.insert(
      categoryId: categoryId,
      name: name,
      position: pos,
    ));
  }

  Future<void> updateSyllabusTopicDetails(int id, String name) async {
    await (update(syllabusTopics)..where((t) => t.id.equals(id))).write(
      SyllabusTopicsCompanion(name: Value(name)),
    );
  }

  Future<void> deleteSyllabusTopic(int id) async {
    await transaction(() async {
      await (delete(syllabusTasks)..where((t) => t.topicId.equals(id))).go();
      await (delete(syllabusTopics)..where((t) => t.id.equals(id))).go();
    });
  }

  Future<void> updateSyllabusTopicPositions(int categoryId, List<int> orderedTopicIds) async {
    await transaction(() async {
      for (int i = 0; i < orderedTopicIds.length; i++) {
        await (update(syllabusTopics)..where((t) => t.id.equals(orderedTopicIds[i]))).write(
          SyllabusTopicsCompanion(
            position: Value(i),
            categoryId: Value(categoryId),
          ),
        );
      }
    });
  }

  // ----------------------------------------------------
  // Syllabus Task Operations
  // ----------------------------------------------------

  Future<int> addSyllabusTask(int topicId, String name, {int? position}) async {
    int pos = position ?? 0;
    if (position == null) {
      final existing = await (select(syllabusTasks)..where((t) => t.topicId.equals(topicId))).get();
      pos = existing.length;
    }
    return into(syllabusTasks).insert(SyllabusTasksCompanion.insert(
      topicId: topicId,
      name: name,
      position: pos,
      isCompleted: const Value(false),
    ));
  }

  Future<void> updateSyllabusTaskDetails(int id, String name, bool isCompleted) async {
    final current = await (select(syllabusTasks)..where((t) => t.id.equals(id))).getSingleOrNull();
    final wasCompleted = current?.isCompleted ?? false;
    final newCompletedAt = isCompleted
        ? (wasCompleted ? current?.completedAt : DateTime.now())
        : null;
    await (update(syllabusTasks)..where((t) => t.id.equals(id))).write(
      SyllabusTasksCompanion(
        name: Value(name),
        isCompleted: Value(isCompleted),
        completedAt: Value(newCompletedAt),
      ),
    );
  }

  Future<void> updateSyllabusTaskCompletion(int id, bool isCompleted, {DateTime? completedAt}) async {
    await (update(syllabusTasks)..where((t) => t.id.equals(id))).write(
      SyllabusTasksCompanion(
        isCompleted: Value(isCompleted),
        completedAt: Value(isCompleted ? (completedAt ?? DateTime.now()) : null),
      ),
    );
  }

  Future<void> deleteSyllabusTask(int id) async {
    await (delete(syllabusTasks)..where((t) => t.id.equals(id))).go();
  }

  Future<void> updateSyllabusTaskPositions(int topicId, List<int> orderedTaskIds) async {
    await transaction(() async {
      for (int i = 0; i < orderedTaskIds.length; i++) {
        await (update(syllabusTasks)..where((t) => t.id.equals(orderedTaskIds[i]))).write(
          SyllabusTasksCompanion(
            position: Value(i),
            topicId: Value(topicId),
          ),
        );
      }
    });
  }

  // ----------------------------------------------------
  // Category/Topic Interaction & Bulk Progress Operations
  // ----------------------------------------------------

  Future<void> updateSyllabusCategoryInteraction(int id) async {
    await (update(syllabusCategories)..where((t) => t.id.equals(id))).write(
      SyllabusCategoriesCompanion(lastInteractedAt: Value(DateTime.now())),
    );
  }

  Future<void> updateSyllabusCategoryInteractionByTaskId(int taskId) async {
    final task = await (select(syllabusTasks)..where((t) => t.id.equals(taskId))).getSingle();
    await updateSyllabusCategoryInteractionByTopicId(task.topicId);
  }

  Future<void> updateSyllabusCategoryInteractionByTopicId(int topicId) async {
    final topic = await (select(syllabusTopics)..where((t) => t.id.equals(topicId))).getSingle();
    await updateSyllabusCategoryInteraction(topic.categoryId);
  }

  Future<void> markSyllabusCategoryCompleted(int categoryId) async {
    await transaction(() async {
      final categoryTopics = await (select(syllabusTopics)..where((t) => t.categoryId.equals(categoryId))).get();
      for (final topic in categoryTopics) {
        final tasks = await (select(syllabusTasks)..where((t) => t.topicId.equals(topic.id))).get();
        for (final task in tasks) {
          if (!task.isCompleted) {
            await (update(syllabusTasks)..where((t) => t.id.equals(task.id))).write(
              SyllabusTasksCompanion(
                isCompleted: const Value(true),
                completedAt: Value(DateTime.now()),
              ),
            );
          }
        }
      }
      await updateSyllabusCategoryInteraction(categoryId);
    });
  }

  Future<void> resetSyllabusCategoryStats(int categoryId) async {
    await transaction(() async {
      final categoryTopics = await (select(syllabusTopics)..where((t) => t.categoryId.equals(categoryId))).get();
      for (final topic in categoryTopics) {
        await (update(syllabusTasks)..where((t) => t.topicId.equals(topic.id))).write(
          const SyllabusTasksCompanion(
            isCompleted: Value(false),
            completedAt: Value(null),
          ),
        );
      }
      await updateSyllabusCategoryInteraction(categoryId);
    });
  }

  Future<void> markSyllabusTopicCompleted(int topicId) async {
    await transaction(() async {
      final tasks = await (select(syllabusTasks)..where((t) => t.topicId.equals(topicId))).get();
      for (final task in tasks) {
        if (!task.isCompleted) {
          await (update(syllabusTasks)..where((t) => t.id.equals(task.id))).write(
            SyllabusTasksCompanion(
              isCompleted: const Value(true),
              completedAt: Value(DateTime.now()),
            ),
          );
        }
      }
      await updateSyllabusCategoryInteractionByTopicId(topicId);
    });
  }

  Future<void> resetSyllabusTopicStats(int topicId) async {
    await transaction(() async {
      await (update(syllabusTasks)..where((t) => t.topicId.equals(topicId))).write(
        const SyllabusTasksCompanion(
          isCompleted: Value(false),
          completedAt: Value(null),
        ),
      );
      await updateSyllabusCategoryInteractionByTopicId(topicId);
    });
  }

  // ----------------------------------------------------
  // Focus Session Operations & Midnight Rollover Logic
  // ----------------------------------------------------

  Future<int> addFocusSession(FocusSessionsCompanion companion) async {
    return into(focusSessions).insert(companion);
  }

  /// Convenience helper for testing and provider use.
  Future<int> insertFocusSession({
    required String method,
    required DateTime startTime,
    required int durationSeconds,
    String? accomplishments,
  }) {
    return addFocusSession(FocusSessionsCompanion.insert(
      method: method,
      startTime: startTime,
      durationSeconds: durationSeconds,
      accomplishments: Value(accomplishments),
    ));
  }

  Future<void> updateFocusSession(FocusSession session) async {
    await update(focusSessions).replace(session);
  }

  Future<void> deleteFocusSession(int id) async {
    await (delete(focusSessions)..where((t) => t.id.equals(id))).go();
  }

  Future<void> deleteOldFocusSessions({StudyDayRollover rollover = StudyDayRollover.overnight}) async {
    final now = DateTime.now();
    final todayStart = getStudyDayStart(now, rollover: rollover);
    await (delete(focusSessions)..where((t) => t.startTime.isSmallerThanValue(todayStart))).go();
  }

  Stream<List<FocusSession>> watchTodayFocusSessions({StudyDayRollover rollover = StudyDayRollover.overnight}) {
    final now = DateTime.now();
    final start = getStudyDayStart(now, rollover: rollover);
    final end = start.add(const Duration(hours: 24));
    return (select(focusSessions)
          ..where((t) => t.startTime.isBiggerOrEqualValue(start) & t.startTime.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm(expression: t.startTime, mode: OrderingMode.desc)]))
        .watch();
  }

  Future<List<FocusSession>> getTodayFocusSessions({StudyDayRollover rollover = StudyDayRollover.overnight}) async {
    final now = DateTime.now();
    final start = getStudyDayStart(now, rollover: rollover);
    final end = start.add(const Duration(hours: 24));
    return (select(focusSessions)
          ..where((t) => t.startTime.isBiggerOrEqualValue(start) & t.startTime.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm(expression: t.startTime, mode: OrderingMode.desc)]))
        .get();
  }

  Stream<int> watchTodayFocusDurationSeconds({StudyDayRollover rollover = StudyDayRollover.overnight}) {
    return watchTodayFocusSessions(rollover: rollover).map((sessions) {
      return sessions.fold(0, (sum, s) => sum + s.durationSeconds);
    });
  }

  Stream<List<FocusSession>> watchRecentFocusSessions(int daysCount, {StudyDayRollover rollover = StudyDayRollover.overnight}) {
    final now = DateTime.now();
    final since = getStudyDayStart(now, rollover: rollover).subtract(Duration(days: daysCount - 1));
    return (select(focusSessions)
          ..where((t) => t.startTime.isBiggerOrEqualValue(since))
          ..orderBy([(t) => OrderingTerm(expression: t.startTime, mode: OrderingMode.asc)]))
        .watch();
  }

  // ----------------------------------------------------
  // Daily History Operations
  // ----------------------------------------------------

  Future<void> upsertDailyHistory({
    required String dateStr,
    required int totalFocusSeconds,
    required int targetGoalSeconds,
    required bool isGoalCompleted,
    required double syllabusProgressPct,
  }) async {
    await into(dailyHistory).insertOnConflictUpdate(
      DailyHistoryCompanion(
        dateStr: Value(dateStr),
        totalFocusSeconds: Value(totalFocusSeconds),
        targetGoalSeconds: Value(targetGoalSeconds),
        isGoalCompleted: Value(isGoalCompleted),
        syllabusProgressPct: Value(syllabusProgressPct),
      ),
    );
  }

  Stream<List<DailyHistoryData>> watchDailyHistory() {
    return (select(dailyHistory)..orderBy([(t) => OrderingTerm(expression: t.dateStr, mode: OrderingMode.asc)])).watch();
  }

  Future<List<DailyHistoryData>> getDailyHistory() async {
    return (select(dailyHistory)..orderBy([(t) => OrderingTerm(expression: t.dateStr, mode: OrderingMode.asc)])).get();
  }

  // ----------------------------------------------------
  // Custom Notice Board Tasks Operations
  // ----------------------------------------------------

  Stream<List<CustomTask>> watchCustomTasks() {
    return (select(customTasks)
          ..orderBy([(t) => OrderingTerm(expression: t.position, mode: OrderingMode.asc)]))
        .watch();
  }

  Future<List<CustomTask>> getCustomTasks() {
    return (select(customTasks)
          ..orderBy([(t) => OrderingTerm(expression: t.position, mode: OrderingMode.asc)]))
        .get();
  }

  Future<int> addCustomTask(String content, {int? position}) async {
    int pos = position ?? 0;
    if (position == null) {
      final existing = await getCustomTasks();
      pos = existing.length;
    }
    return into(customTasks).insert(CustomTasksCompanion.insert(
      content: content,
      isCompleted: const Value(false),
      createdAt: DateTime.now(),
      position: Value(pos),
    ));
  }

  Future<void> updateCustomTaskCompletion(int id, bool isCompleted) async {
    await (update(customTasks)..where((t) => t.id.equals(id))).write(
      CustomTasksCompanion(isCompleted: Value(isCompleted)),
    );
  }

  Future<void> updateCustomTaskContent(int id, String content) async {
    await (update(customTasks)..where((t) => t.id.equals(id))).write(
      CustomTasksCompanion(content: Value(content)),
    );
  }

  Future<void> deleteCustomTask(int id) async {
    await (delete(customTasks)..where((t) => t.id.equals(id))).go();
  }

  Future<void> updateCustomTaskPositions(List<int> orderedIds) async {
    await transaction(() async {
      for (int i = 0; i < orderedIds.length; i++) {
        await (update(customTasks)..where((t) => t.id.equals(orderedIds[i]))).write(
          CustomTasksCompanion(position: Value(i)),
        );
      }
    });
  }

  Future<void> restoreCustomTasks(List<CustomTask> tasks) async {
    await transaction(() async {
      await delete(customTasks).go();
      for (final t in tasks) {
        await into(customTasks).insert(t);
      }
    });
  }
}

enum StudyDayRollover {
  midnight,
  overnight,
}

// Top-level function: computes the rollover study-day start.
// Located outside AppDatabase so it can be unit-tested without a DB instance.
DateTime getStudyDayStart(DateTime now, {StudyDayRollover rollover = StudyDayRollover.overnight}) {
  final hour = rollover == StudyDayRollover.overnight ? 4 : 0;
  if (now.hour < hour) {
    final yesterday = now.subtract(const Duration(days: 1));
    return DateTime(yesterday.year, yesterday.month, yesterday.day, hour);
  }
  return DateTime(now.year, now.month, now.day, hour);
}

DateTime studyDayFor(DateTime time, StudyDayRollover rollover) {
  final start = getStudyDayStart(time, rollover: rollover);
  return DateTime(start.year, start.month, start.day);
}
