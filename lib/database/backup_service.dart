import 'app_database.dart';

class BackupService {
  // Export local database to a standard serialized Map payload
  static Future<Map<String, dynamic>> exportDatabase(AppDatabase db) async {
    final syllabusCats = await db.select(db.syllabusCategories).get();
    final syllabusTops = await db.select(db.syllabusTopics).get();
    final syllabusTsks = await db.select(db.syllabusTasks).get();

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
      'syllabusCategories': exportedSyllabusCats,
      'syllabusTopics': exportedSyllabusTops,
      'syllabusTasks': exportedSyllabusTsks,
      'lastInteractedAt': DateTime.now().toIso8601String(),
    };
  }

  // Restore database tables from a serialized Map payload
  static Future<void> restoreDatabase(AppDatabase db, Map<String, dynamic> payload) async {
    final syllabusCategoriesData = payload['syllabusCategories'] as List<dynamic>?;
    final syllabusTopicsData = payload['syllabusTopics'] as List<dynamic>?;
    final syllabusTasksData = payload['syllabusTasks'] as List<dynamic>?;

    await db.transaction(() async {
      // Restore syllabus-based tables if present in backup
      if (syllabusCategoriesData != null && syllabusTopicsData != null && syllabusTasksData != null) {
        await db.delete(db.syllabusTasks).go();
        await db.delete(db.syllabusTopics).go();
        await db.delete(db.syllabusCategories).go();

        final oldCatIdToNewId = <int, int>{};
        for (final c in syllabusCategoriesData) {
          final oldId = (c['id'] as num).toInt();
          final name = c['name'] as String;
          final color = (c['color'] as num).toInt();
          final position = (c['position'] as num).toInt();
          final lastIntStr = c['lastInteractedAt'] as String?;
          final lastInteracted = lastIntStr != null ? DateTime.tryParse(lastIntStr) : null;

          final newId = await db.addSyllabusCategory(name, color, position: position, lastInteractedAt: lastInteracted);
          oldCatIdToNewId[oldId] = newId;
        }

        final oldTopicIdToNewId = <int, int>{};
        for (final t in syllabusTopicsData) {
          final oldId = (t['id'] as num).toInt();
          final oldCatId = (t['categoryId'] as num).toInt();
          final name = t['name'] as String;
          final position = (t['position'] as num).toInt();

          final newCatId = oldCatIdToNewId[oldCatId];
          if (newCatId != null) {
            final newId = await db.addSyllabusTopic(newCatId, name, position: position);
            oldTopicIdToNewId[oldId] = newId;
          }
        }

        for (final k in syllabusTasksData) {
          final oldTopicId = (k['topicId'] as num).toInt();
          final name = k['name'] as String;
          final isCompleted = k['isCompleted'] as bool;
          final position = (k['position'] as num).toInt();

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
