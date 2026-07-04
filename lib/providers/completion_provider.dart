import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'completion_type_provider.dart';
import 'subject_provider.dart';
import 'syllabus_provider.dart';

final completionPercentageProvider = Provider<AsyncValue<double>>((ref) {
  final type = ref.watch(completionTypeProvider);
  if (type == CompletionType.syllabus) {
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
  } else {
    final categoriesAsync = ref.watch(categoriesWithSubjectsProvider);
    return categoriesAsync.when(
      data: (categoriesWithSubs) {
        int totalCompleted = 0, totalVideos = 0;
        for (final cat in categoriesWithSubs) {
          for (final s in cat.subjects) {
            if (s.isActive) {
              totalCompleted += s.completedVideos;
              totalVideos += s.totalVideos;
            }
          }
        }
        return AsyncValue.data(totalVideos == 0 ? 0.0 : (totalCompleted / totalVideos) * 100);
      },
      loading: () => const AsyncValue.loading(),
      error: (e, st) => AsyncValue.error(e, st),
    );
  }
});
