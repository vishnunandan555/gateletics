import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gateletics/database/app_database.dart';
import 'package:gateletics/database/backup_service.dart';
import 'package:gateletics/providers/sync_provider.dart';
import 'package:gateletics/providers/syllabus_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.transaction(() async {
      await db.delete(db.syllabusTasks).go();
      await db.delete(db.syllabusTopics).go();
      await db.delete(db.syllabusCategories).go();
      await db.delete(db.customTasks).go();
    });
  });

  tearDown(() async {
    await db.close();
  });

  test('Soft delete marks category, topic, task, and custom task as isDeleted and sets lastInteractedAt', () async {
    final catId = await db.addSyllabusCategory('Test Category', 0xFF0000FF, position: 0);
    final topicId = await db.addSyllabusTopic(catId, 'Test Topic', position: 0);
    await db.addSyllabusTask(topicId, 'Test Task', position: 0);
    final customTaskId = await db.addCustomTask('Test Custom Task');

    // Initially, none are deleted
    var categories = await db.select(db.syllabusCategories).get();
    var topics = await db.select(db.syllabusTopics).get();
    var tasks = await db.select(db.syllabusTasks).get();
    var customTasks = await db.select(db.customTasks).get();

    expect(categories.first.isDeleted, isFalse);
    expect(topics.first.isDeleted, isFalse);
    expect(tasks.first.isDeleted, isFalse);
    expect(customTasks.first.isDeleted, isFalse);

    expect(categories.first.lastInteractedAt, isNotNull);
    expect(topics.first.lastInteractedAt, isNotNull);
    expect(tasks.first.lastInteractedAt, isNotNull);
    expect(customTasks.first.lastInteractedAt, isNotNull);

    // Soft delete Category (should cascade to topics and tasks)
    final deletionTime = DateTime.now();
    await db.deleteSyllabusCategory(catId);

    categories = await db.select(db.syllabusCategories).get();
    topics = await db.select(db.syllabusTopics).get();
    tasks = await db.select(db.syllabusTasks).get();

    expect(categories.first.isDeleted, isTrue);
    expect(topics.first.isDeleted, isTrue);
    expect(tasks.first.isDeleted, isTrue);

    expect(categories.first.lastInteractedAt!.difference(deletionTime).inSeconds.abs() <= 5, isTrue);
    expect(topics.first.lastInteractedAt!.difference(deletionTime).inSeconds.abs() <= 5, isTrue);
    expect(tasks.first.lastInteractedAt!.difference(deletionTime).inSeconds.abs() <= 5, isTrue);

    // Soft delete custom task
    await db.deleteCustomTask(customTaskId);
    customTasks = await db.select(db.customTasks).get();
    expect(customTasks.first.isDeleted, isTrue);
    expect(customTasks.first.lastInteractedAt!.difference(deletionTime).inSeconds.abs() <= 5, isTrue);
  });

  test('Streams and gets exclude isDeleted = true items', () async {
    final catId = await db.addSyllabusCategory('Test Category', 0xFF0000FF, position: 0);
    final topicId = await db.addSyllabusTopic(catId, 'Test Topic', position: 0);
    await db.addSyllabusTask(topicId, 'Test Task', position: 0);
    final customTaskId = await db.addCustomTask('Test Custom Task');

    // watch streams should emit items
    expect(await db.watchSyllabusCategories().first, hasLength(1));
    expect(await db.watchSyllabusTopics().first, hasLength(1));
    expect(await db.watchSyllabusTasks().first, hasLength(1));
    expect(await db.watchCustomTasks().first, hasLength(1));
    expect(await db.getCustomTasks(), hasLength(1));

    // Delete everything
    await db.deleteSyllabusCategory(catId);
    await db.deleteCustomTask(customTaskId);

    // Now streams should be empty
    expect(await db.watchSyllabusCategories().first, isEmpty);
    expect(await db.watchSyllabusTopics().first, isEmpty);
    expect(await db.watchSyllabusTasks().first, isEmpty);
    expect(await db.watchCustomTasks().first, isEmpty);
    expect(await db.getCustomTasks(), isEmpty);
  });

  test('Backup and restore preserves isDeleted and lastInteractedAt values', () async {
    final catId = await db.addSyllabusCategory('Test Category 1', 0xFF0000FF, position: 0);
    final topicId = await db.addSyllabusTopic(catId, 'Test Topic 1', position: 0);
    await db.addSyllabusTask(topicId, 'Test Task 1', position: 0);
    final customTaskId = await db.addCustomTask('Test Custom Task 1');

    await db.deleteSyllabusCategory(catId);
    await db.deleteCustomTask(customTaskId);

    final payload = await BackupService.exportDatabase(db);

    // Verify fields in payload
    final categories = payload['syllabusCategories'] as List<dynamic>;
    expect(categories.first['isDeleted'], isTrue);
    expect(categories.first['lastInteractedAt'], isNotNull);

    final topics = payload['syllabusTopics'] as List<dynamic>;
    expect(topics.first['isDeleted'], isTrue);
    expect(topics.first['lastInteractedAt'], isNotNull);

    final tasks = payload['syllabusTasks'] as List<dynamic>;
    expect(tasks.first['isDeleted'], isTrue);
    expect(tasks.first['lastInteractedAt'], isNotNull);

    final customTasks = payload['customTasks'] as List<dynamic>;
    expect(customTasks.first['isDeleted'], isTrue);
    expect(customTasks.first['lastInteractedAt'], isNotNull);

    // Re-seed with payload
    await db.transaction(() async {
      await db.delete(db.syllabusTasks).go();
      await db.delete(db.syllabusTopics).go();
      await db.delete(db.syllabusCategories).go();
      await db.delete(db.customTasks).go();
    });

    await BackupService.restoreDatabase(db, payload);

    // Verify database has the restored deleted items
    final dbCats = await db.select(db.syllabusCategories).get();
    final dbTops = await db.select(db.syllabusTopics).get();
    final dbTsks = await db.select(db.syllabusTasks).get();
    final dbCustomTsks = await db.select(db.customTasks).get();

    expect(dbCats.first.isDeleted, isTrue);
    expect(dbTops.first.isDeleted, isTrue);
    expect(dbTsks.first.isDeleted, isTrue);
    expect(dbCustomTsks.first.isDeleted, isTrue);
  });

  test('Sync mergeData resolves deletion conflicts using Last-Write-Wins (LWW)', () async {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
      ],
    );
    addTearDown(container.dispose);

    final tOld = DateTime.now().subtract(const Duration(minutes: 10)).toIso8601String();
    final tNew = DateTime.now().toIso8601String();

    // Scenario 1: Deletion is newer than update -> Merged item is deleted
    final localData1 = {
      'syllabusCategories': [
        {'id': 1, 'name': 'Math', 'color': 0xFF0000FF, 'position': 0, 'lastInteractedAt': tNew, 'isDeleted': true}
      ]
    };
    final cloudData1 = {
      'syllabusCategories': [
        {'id': 1, 'name': 'Math', 'color': 0xFF0000FF, 'position': 0, 'lastInteractedAt': tOld, 'isDeleted': false}
      ]
    };

    final merged1 = await container.read(syncProvider.notifier).mergeData(localData1, cloudData1);
    final mergedCats1 = merged1['syllabusCategories'] as List<dynamic>;
    expect(mergedCats1.first['isDeleted'], isTrue);

    // Scenario 2: Update is newer than deletion -> Merged item is NOT deleted
    final localData2 = {
      'syllabusCategories': [
        {'id': 1, 'name': 'Math', 'color': 0xFF0000FF, 'position': 0, 'lastInteractedAt': tOld, 'isDeleted': true}
      ]
    };
    final cloudData2 = {
      'syllabusCategories': [
        {'id': 1, 'name': 'Math', 'color': 0xFF0000FF, 'position': 0, 'lastInteractedAt': tNew, 'isDeleted': false}
      ]
    };

    final merged2 = await container.read(syncProvider.notifier).mergeData(localData2, cloudData2);
    final mergedCats2 = merged2['syllabusCategories'] as List<dynamic>;
    expect(mergedCats2.first['isDeleted'], isFalse);
  });
}
