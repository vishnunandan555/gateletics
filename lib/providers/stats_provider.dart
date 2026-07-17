
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import 'syllabus_provider.dart';

class CategoryStudyTime {
  final int? id;
  final String name;
  final int colorValue;
  final double hours;
  final double percentage;

  CategoryStudyTime({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.hours,
    required this.percentage,
  });
}

final progressLogsProvider = FutureProvider<List<SyllabusProgressLog>>((ref) async {
  // Watch syllabusProvider to trigger reactivity when any syllabus update happens
  ref.watch(syllabusProvider);
  final db = ref.read(appDatabaseProvider);
  // Get all active logs across time
  return db.getProgressLogsForPeriod(DateTime(2020, 1, 1), DateTime(2030, 12, 31));
});


