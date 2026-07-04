import 'package:drift/drift.dart';
import 'app_database.dart';

class BackupService {
  // Export local database to a standard serialized Map payload
  static Future<Map<String, dynamic>> exportDatabase(AppDatabase db) async {
    final syllabusCats = await db.select(db.syllabusCategories).get();
    final syllabusTops = await db.select(db.syllabusTopics).get();
    final syllabusTsks = await db.select(db.syllabusTasks).get();
    final focusSess = await db.select(db.focusSessions).get();
    final dailyHist = await db.select(db.dailyHistory).get();

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

    final exportedFocusSessions = focusSess.map((fs) => {
      'id': fs.id,
      'method': fs.method,
      'startTime': fs.startTime.toIso8601String(),
      'durationSeconds': fs.durationSeconds,
      'accomplishments': fs.accomplishments,
      'progressDelta': fs.progressDelta,
    }).toList();

    final exportedDailyHistory = dailyHist.map((dh) => {
      'dateStr': dh.dateStr,
      'totalFocusSeconds': dh.totalFocusSeconds,
      'targetGoalSeconds': dh.targetGoalSeconds,
      'isGoalCompleted': dh.isGoalCompleted,
      'syllabusProgressPct': dh.syllabusProgressPct,
    }).toList();

    return {
      'version': 6,
      'syllabusCategories': exportedSyllabusCats,
      'syllabusTopics': exportedSyllabusTops,
      'syllabusTasks': exportedSyllabusTsks,
      'focusSessions': exportedFocusSessions,
      'dailyHistory': exportedDailyHistory,
      'lastInteractedAt': DateTime.now().toIso8601String(),
    };
  }

  // Restore database tables from a serialized Map payload
  static Future<void> restoreDatabase(AppDatabase db, Map<String, dynamic> payload) async {
    final syllabusCategoriesData = payload['syllabusCategories'] as List<dynamic>?;
    final syllabusTopicsData = payload['syllabusTopics'] as List<dynamic>?;
    final syllabusTasksData = payload['syllabusTasks'] as List<dynamic>?;
    final focusSessionsData = payload['focusSessions'] as List<dynamic>?;
    final dailyHistoryData = payload['dailyHistory'] as List<dynamic>?;

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

      // Restore Focus Sessions if present in backup
      if (focusSessionsData != null) {
        await db.delete(db.focusSessions).go();
        for (final fs in focusSessionsData) {
          final method = fs['method'] as String;
          final startTime = DateTime.parse(fs['startTime'] as String);
          final durationSeconds = (fs['durationSeconds'] as num).toInt();
          final accomplishments = fs['accomplishments'] as String?;
          final progressDelta = (fs['progressDelta'] as num?)?.toDouble() ?? 0.0;

          await db.addFocusSession(FocusSessionsCompanion.insert(
            method: method,
            startTime: startTime,
            durationSeconds: durationSeconds,
            accomplishments: Value(accomplishments),
            progressDelta: Value(progressDelta),
          ));
        }
      }

      // Restore Daily History if present in backup
      if (dailyHistoryData != null) {
        await db.delete(db.dailyHistory).go();
        for (final dh in dailyHistoryData) {
          final dateStr = dh['dateStr'] as String;
          final totalFocusSeconds = (dh['totalFocusSeconds'] as num).toInt();
          final targetGoalSeconds = (dh['targetGoalSeconds'] as num).toInt();
          final isGoalCompleted = dh['isGoalCompleted'] as bool;
          final syllabusProgressPct = (dh['syllabusProgressPct'] as num).toDouble();

          await db.upsertDailyHistory(
            dateStr: dateStr,
            totalFocusSeconds: totalFocusSeconds,
            targetGoalSeconds: targetGoalSeconds,
            isGoalCompleted: isGoalCompleted,
            syllabusProgressPct: syllabusProgressPct,
          );
        }
      }
    });
  }
}
