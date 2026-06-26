import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:gateletics/database/app_database.dart';
import 'package:gateletics/database/backup_service.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // Clear default seed data to start with a clean state for testing
    await db.transaction(() async {
      await db.delete(db.subjects).go();
      await db.delete(db.categories).go();
      await db.delete(db.syllabusTasks).go();
      await db.delete(db.syllabusTopics).go();
      await db.delete(db.syllabusCategories).go();
    });
  });

  tearDown(() async {
    await db.close();
  });

  test('Backup and restore preserves resource-based subject progress and categories', () async {
    // 1. Seed custom category and subject
    final catId = await db.addCategory('My Custom Cat', 0xFF00FF00, position: 0);
    
    await db.addSubject(
      name: 'Custom Subject 1',
      categoryId: catId,
      totalVideos: 10,
      playlistLink: 'https://example.com/playlist1',
      sourceName: 'My Source',
      isActive: true,
      completedVideos: 7,
      color: 0xFFFF0000,
      position: 0,
    );

    // 2. Export database
    final payload = await BackupService.exportDatabase(db);

    // Verify payload content
    final categories = payload['categories'] as List<dynamic>;
    expect(categories.length, 1);
    expect(categories.first['name'], 'My Custom Cat');

    final subjects = payload['subjects'] as List<dynamic>;
    expect(subjects.length, 1);
    expect(subjects.first['name'], 'Custom Subject 1');
    expect(subjects.first['completedVideos'], 7);

    // 3. Clear database & Restore
    await db.transaction(() async {
      await db.delete(db.subjects).go();
      await db.delete(db.categories).go();
    });

    final emptySubjects = await db.select(db.subjects).get();
    expect(emptySubjects.isEmpty, true);

    await BackupService.restoreDatabase(db, payload);

    // 4. Verify restored state
    final restoredCategories = await db.select(db.categories).get();
    expect(restoredCategories.length, 1);
    expect(restoredCategories.first.name, 'My Custom Cat');

    final restoredSubjects = await db.select(db.subjects).get();
    expect(restoredSubjects.length, 1);
    expect(restoredSubjects.first.name, 'Custom Subject 1');
    expect(restoredSubjects.first.completedVideos, 7);
  });

  test('Backup and restore preserves syllabus progress, categories, topics, and tasks', () async {
    // 1. Seed custom syllabus data
    final catId = await db.addSyllabusCategory('Syllabus Cat 1', 0xFF0000FF, position: 0);
    final topicId = await db.addSyllabusTopic(catId, 'Syllabus Topic 1', position: 0);
    final taskId1 = await db.addSyllabusTask(topicId, 'Task 1', position: 0);
    final taskId2 = await db.addSyllabusTask(topicId, 'Task 2', position: 1);

    await db.updateSyllabusTaskCompletion(taskId1, true);
    await db.updateSyllabusTaskCompletion(taskId2, false);

    // 2. Export database
    final payload = await BackupService.exportDatabase(db);

    // Verify payload content
    final categories = payload['syllabusCategories'] as List<dynamic>;
    expect(categories.length, 1);
    expect(categories.first['name'], 'Syllabus Cat 1');

    final topics = payload['syllabusTopics'] as List<dynamic>;
    expect(topics.length, 1);
    expect(topics.first['name'], 'Syllabus Topic 1');

    final tasks = payload['syllabusTasks'] as List<dynamic>;
    expect(tasks.length, 2);
    expect(tasks[0]['name'], 'Task 1');
    expect(tasks[0]['isCompleted'], true);
    expect(tasks[1]['name'], 'Task 2');
    expect(tasks[1]['isCompleted'], false);

    // 3. Clear database & Restore
    await db.transaction(() async {
      await db.delete(db.syllabusTasks).go();
      await db.delete(db.syllabusTopics).go();
      await db.delete(db.syllabusCategories).go();
    });

    final emptyTasks = await db.select(db.syllabusTasks).get();
    expect(emptyTasks.isEmpty, true);

    await BackupService.restoreDatabase(db, payload);

    // 4. Verify restored state
    final restoredCategories = await db.select(db.syllabusCategories).get();
    expect(restoredCategories.length, 1);
    expect(restoredCategories.first.name, 'Syllabus Cat 1');

    final restoredTopics = await db.select(db.syllabusTopics).get();
    expect(restoredTopics.length, 1);
    expect(restoredTopics.first.name, 'Syllabus Topic 1');

    final restoredTasks = await db.select(db.syllabusTasks).get();
    expect(restoredTasks.length, 2);
    expect(restoredTasks[0].name, 'Task 1');
    expect(restoredTasks[0].isCompleted, true);
    expect(restoredTasks[1].name, 'Task 2');
    expect(restoredTasks[1].isCompleted, false);
  });
}
