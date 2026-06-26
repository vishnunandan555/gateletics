import 'app_database.dart';

class BackupService {
  // Export local database to a standard serialized Map payload
  static Future<Map<String, dynamic>> exportDatabase(AppDatabase db) async {
    final categoriesList = await db.select(db.categories).get();
    final subjectsList = await db.select(db.subjects).get();
    final syllabusCats = await db.select(db.syllabusCategories).get();
    final syllabusTops = await db.select(db.syllabusTopics).get();
    final syllabusTsks = await db.select(db.syllabusTasks).get();

    final categoryMap = {for (var c in categoriesList) c.id: c.name};

    final exportedCategories = categoriesList.map((c) => {
      'name': c.name,
      'color': c.color,
      'position': c.position,
      'lastInteractedAt': c.lastInteractedAt?.toIso8601String(),
    }).toList();

    final exportedSubjects = subjectsList.map((s) => {
      'name': s.name,
      'categoryName': categoryMap[s.categoryId] ?? 'General',
      'completedVideos': s.completedVideos,
      'totalVideos': s.totalVideos,
      'playlistLink': s.playlistLink,
      'sourceName': s.sourceName,
      'isActive': s.isActive,
      'position': s.position,
      'color': s.color,
    }).toList();

    final exportedSyllabusCats = syllabusCats.map((c) => {
      'id': c.id,
      'name': c.name,
      'position': c.position,
      'color': c.color,
      'lastInteractedAt': c.lastInteractedAt?.toIso8601String(),
    }).toList();

    final exportedSyllabusTops = syllabusTops.map((t) => {
      'id': t.id,
      'categoryId': t.categoryId,
      'name': t.name,
      'position': t.position,
    }).toList();

    final exportedSyllabusTsks = syllabusTsks.map((k) => {
      'id': k.id,
      'topicId': k.topicId,
      'name': k.name,
      'isCompleted': k.isCompleted,
      'position': k.position,
    }).toList();

    return {
      'version': 3,
      'categories': exportedCategories,
      'subjects': exportedSubjects,
      'syllabusCategories': exportedSyllabusCats,
      'syllabusTopics': exportedSyllabusTops,
      'syllabusTasks': exportedSyllabusTsks,
      'lastInteractedAt': DateTime.now().toIso8601String(),
    };
  }

  // Restore database tables from a serialized Map payload
  static Future<void> restoreDatabase(AppDatabase db, Map<String, dynamic> payload) async {
    final categoriesData = payload['categories'] as List<dynamic>;
    final subjectsData = payload['subjects'] as List<dynamic>;
    final syllabusCategoriesData = payload['syllabusCategories'] as List<dynamic>?;
    final syllabusTopicsData = payload['syllabusTopics'] as List<dynamic>?;
    final syllabusTasksData = payload['syllabusTasks'] as List<dynamic>?;

    await db.transaction(() async {
      // 1. Restore resource-based tables
      await db.delete(db.subjects).go();
      await db.delete(db.categories).go();

      final categoryNameToNewId = <String, int>{};
      for (final c in categoriesData) {
        final name = c['name'] as String;
        final color = c['color'] as int;
        final position = c['position'] as int;
        final lastIntStr = c['lastInteractedAt'] as String?;
        final lastInteracted = lastIntStr != null ? DateTime.tryParse(lastIntStr) : null;
        
        final id = await db.addCategory(name, color, position: position, lastInteractedAt: lastInteracted);
        categoryNameToNewId[name] = id;
      }

      for (final s in subjectsData) {
        final categoryName = s['categoryName'] as String;
        final catId = categoryNameToNewId[categoryName];
        if (catId == null) continue;

        await db.addSubject(
          name: s['name'] as String,
          categoryId: catId,
          totalVideos: s['totalVideos'] as int,
          sourceName: s['sourceName'] as String,
          playlistLink: s['playlistLink'] as String,
          isActive: s['isActive'] as bool,
          color: s['color'] as int?,
          position: s['position'] as int? ?? 0,
        );
      }

      // 2. Restore syllabus-based tables if present in backup
      if (syllabusCategoriesData != null && syllabusTopicsData != null && syllabusTasksData != null) {
        await db.delete(db.syllabusTasks).go();
        await db.delete(db.syllabusTopics).go();
        await db.delete(db.syllabusCategories).go();

        final oldCatIdToNewId = <int, int>{};
        for (final c in syllabusCategoriesData) {
          final oldId = c['id'] as int;
          final name = c['name'] as String;
          final color = c['color'] as int;
          final position = c['position'] as int;

          final newId = await db.addSyllabusCategory(name, color, position: position);
          oldCatIdToNewId[oldId] = newId;
        }

        final oldTopicIdToNewId = <int, int>{};
        for (final t in syllabusTopicsData) {
          final oldId = t['id'] as int;
          final oldCatId = t['categoryId'] as int;
          final name = t['name'] as String;
          final position = t['position'] as int;

          final newCatId = oldCatIdToNewId[oldCatId];
          if (newCatId != null) {
            final newId = await db.addSyllabusTopic(newCatId, name, position: position);
            oldTopicIdToNewId[oldId] = newId;
          }
        }

        for (final k in syllabusTasksData) {
          final oldTopicId = k['topicId'] as int;
          final name = k['name'] as String;
          final isCompleted = k['isCompleted'] as bool;
          final position = k['position'] as int;

          final newTopicId = oldTopicIdToNewId[oldTopicId];
          if (newTopicId != null) {
            final taskId = await db.addSyllabusTask(newTopicId, name, position: position);
            await db.updateSyllabusTaskCompletion(taskId, isCompleted);
          }
        }
      }
    });
  }
}
