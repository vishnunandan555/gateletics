import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'syllabus_provider.dart';

final completionPercentageProvider = Provider<AsyncValue<double>>((ref) {
  final syllabusAsync = ref.watch(syllabusProvider);
  return syllabusAsync.when(
    data: (syllabusData) {
      int totalCompleted = 0, totalTasks = 0;
      for (final cat in syllabusData) {
        for (final topic in cat.topics) {
          totalCompleted += topic.tasks.where((t) => t.isCompleted).length;
          totalTasks += topic.tasks.length;
        }
      }
      return AsyncValue.data(totalTasks == 0 ? 0.0 : (totalCompleted / totalTasks) * 100);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});
