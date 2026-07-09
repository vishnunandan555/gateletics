import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../database/app_database.dart';

import 'category_autosort_provider.dart';
import 'sync_provider.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

// Stream of categories
final syllabusCategoriesProvider = StreamProvider<List<SyllabusCategory>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchSyllabusCategories();
});

// Stream of topics
final syllabusTopicsProvider = StreamProvider<List<SyllabusTopic>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchSyllabusTopics();
});

// Stream of tasks
final syllabusTasksProvider = StreamProvider<List<SyllabusTask>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchSyllabusTasks();
});

final syllabusCategoriesOrderProvider = NotifierProvider<SyllabusCategoriesOrderNotifier, List<int>>(() {
  return SyllabusCategoriesOrderNotifier();
});

class SyllabusCategoriesOrderNotifier extends Notifier<List<int>> {
  @override
  List<int> build() => [];

  void setOrder(List<int> ids) => state = ids;
  void clear() => state = [];
}

int _compareSyllabusCategories(SyllabusCategory a, SyllabusCategory b) {
  final aTime = a.lastInteractedAt;
  final bTime = b.lastInteractedAt;
  if (aTime == null && bTime == null) {
    return a.position.compareTo(b.position);
  }
  if (aTime == null) return 1;
  if (bTime == null) return -1;
  return bTime.compareTo(aTime);
}

// Combined syllabus provider
final syllabusProvider = Provider<AsyncValue<List<SyllabusCategoryWithTopics>>>((ref) {
  final catsAsync = ref.watch(syllabusCategoriesProvider);
  final topicsAsync = ref.watch(syllabusTopicsProvider);
  final tasksAsync = ref.watch(syllabusTasksProvider);
  final autoSort = ref.watch(categoryAutoSortProvider);

  if (catsAsync.hasError) return AsyncValue.error(catsAsync.error!, catsAsync.stackTrace!);
  if (topicsAsync.hasError) return AsyncValue.error(topicsAsync.error!, topicsAsync.stackTrace!);
  if (tasksAsync.hasError) return AsyncValue.error(tasksAsync.error!, tasksAsync.stackTrace!);

  if (!catsAsync.hasValue || !topicsAsync.hasValue || !tasksAsync.hasValue) {
    return const AsyncValue.loading();
  }

  final cats = List<SyllabusCategory>.from(catsAsync.value!);
  final tops = topicsAsync.value!;
  final tsks = tasksAsync.value!;

  if (autoSort) {
    final lockedOrder = ref.watch(syllabusCategoriesOrderProvider);
    if (lockedOrder.isEmpty) {
      cats.sort((a, b) => _compareSyllabusCategories(a, b));
      final ids = cats.map((e) => e.id).toList();
      Future.microtask(() {
        ref.read(syllabusCategoriesOrderProvider.notifier).setOrder(ids);
      });
    } else {
      cats.sort((a, b) {
        final indexA = lockedOrder.indexOf(a.id);
        final indexB = lockedOrder.indexOf(b.id);
        if (indexA != -1 && indexB != -1) {
          return indexA.compareTo(indexB);
        }
        if (indexA != -1) return -1;
        if (indexB != -1) return 1;
        return _compareSyllabusCategories(a, b);
      });
    }
  }

  // Group tasks by topicId
  final tasksByTopic = <int, List<SyllabusTask>>{};
  for (final t in tsks) {
    tasksByTopic.putIfAbsent(t.topicId, () => []).add(t);
  }

  // Group topics by categoryId
  final topicsByCat = <int, List<SyllabusTopicWithTasks>>{};
  for (final t in tops) {
    final topicTasks = tasksByTopic[t.id] ?? [];
    final topicWithTasks = SyllabusTopicWithTasks(topic: t, tasks: topicTasks);
    topicsByCat.putIfAbsent(t.categoryId, () => []).add(topicWithTasks);
  }

  // Build category hierarchy
  final result = cats.map((c) {
    final catTopics = topicsByCat[c.id] ?? [];
    return SyllabusCategoryWithTopics(category: c, topics: catTopics);
  }).toList();

  return AsyncValue.data(result);
});

// Topic expanded/collapsed in-memory state provider
final expandedTopicsProvider = NotifierProvider<ExpandedTopicsNotifier, Set<int>>(() {
  return ExpandedTopicsNotifier();
});

class ExpandedTopicsNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() {
    return {};
  }

  void toggle(int id) {
    if (state.contains(id)) {
      state = {...state}..remove(id);
    } else {
      state = {...state, id};
    }
  }

  bool isExpanded(int id) => state.contains(id);

  void clear() => state = {};
}

// Controller for syllabus mutations
final syllabusControllerProvider = NotifierProvider<SyllabusController, AsyncValue<void>>(() {
  return SyllabusController();
});

class SyllabusController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  AppDatabase get _db => ref.read(appDatabaseProvider);

  void _triggerSync() {
    ref.read(syncProvider.notifier).triggerAutoSync();
  }

  // Task methods
  Future<void> toggleTask(int taskId, bool isCompleted) async {
    await _db.transaction(() async {
      await _db.updateSyllabusTaskCompletion(taskId, isCompleted);
      await _db.updateSyllabusCategoryInteractionByTaskId(taskId);
    });
    _triggerSync();
  }

  Future<void> addTask(int topicId, String name) async {
    await _db.transaction(() async {
      await _db.addSyllabusTask(topicId, name);
      await _db.updateSyllabusCategoryInteractionByTopicId(topicId);
    });
    _triggerSync();
  }

  Future<void> renameTask(int id, String name, bool isCompleted) async {
    await _db.transaction(() async {
      await _db.updateSyllabusTaskDetails(id, name, isCompleted);
      await _db.updateSyllabusCategoryInteractionByTaskId(id);
    });
    _triggerSync();
  }

  Future<void> deleteTask(int id) async {
    await _db.deleteSyllabusTask(id);
    _triggerSync();
  }

  Future<void> reorderTasks(int topicId, List<int> orderedIds) async {
    await _db.transaction(() async {
      await _db.updateSyllabusTaskPositions(topicId, orderedIds);
      await _db.updateSyllabusCategoryInteractionByTopicId(topicId);
    });
    _triggerSync();
  }

  // Topic methods
  Future<void> addTopic(int categoryId, String name) async {
    await _db.transaction(() async {
      await _db.addSyllabusTopic(categoryId, name);
      await _db.updateSyllabusCategoryInteraction(categoryId);
    });
    _triggerSync();
  }

  Future<void> renameTopic(int id, String name) async {
    await _db.transaction(() async {
      await _db.updateSyllabusTopicDetails(id, name);
      await _db.updateSyllabusCategoryInteractionByTopicId(id);
    });
    _triggerSync();
  }

  Future<void> deleteTopic(int id) async {
    await _db.deleteSyllabusTopic(id);
    _triggerSync();
  }

  Future<void> reorderTopics(int categoryId, List<int> orderedIds) async {
    await _db.transaction(() async {
      await _db.updateSyllabusTopicPositions(categoryId, orderedIds);
      await _db.updateSyllabusCategoryInteraction(categoryId);
    });
    _triggerSync();
  }

  // Category methods
  Future<void> addCategory(String name, int color) async {
    await _db.addSyllabusCategory(name, color);
    ref.read(syllabusCategoriesOrderProvider.notifier).clear();
    _triggerSync();
  }

  Future<void> renameCategory(int id, String name, int color) async {
    await _db.updateSyllabusCategoryDetails(id, name, color);
    ref.read(syllabusCategoriesOrderProvider.notifier).clear();
    _triggerSync();
  }

  Future<void> deleteCategory(int id) async {
    await _db.deleteSyllabusCategory(id);
    ref.read(syllabusCategoriesOrderProvider.notifier).clear();
    _triggerSync();
  }

  Future<void> reorderCategories(List<int> orderedIds) async {
    await _db.updateSyllabusCategoryPositions(orderedIds);
    ref.read(syllabusCategoriesOrderProvider.notifier).clear();
    _triggerSync();
  }

  // Bulk operations
  Future<void> markCategoryCompleted(int id) async {
    await _db.markSyllabusCategoryCompleted(id);
    _triggerSync();
  }

  Future<void> resetCategoryStats(int id) async {
    await _db.resetSyllabusCategoryStats(id);
    _triggerSync();
  }

  Future<void> markTopicCompleted(int id) async {
    await _db.markSyllabusTopicCompleted(id);
    _triggerSync();
  }

  Future<void> resetTopicStats(int id) async {
    await _db.resetSyllabusTopicStats(id);
    _triggerSync();
  }

  // Reset / Presets
  Future<void> resetTrackingData() async {
    await _db.resetSyllabusTrackingData();
    _triggerSync();
  }

  Future<void> applyPreset() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _db.seedSyllabus());
    _triggerSync();
  }

  Future<void> resetEverything() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _db.resetSyllabusEverything());
    _triggerSync();
  }
}

extension SyllabusReset on AppDatabase {
  Future<void> resetSyllabusTrackingData() async {
    await (update(syllabusTasks)).write(
      const SyllabusTasksCompanion(
        isCompleted: Value(false),
        completedAt: Value(null),
      ),
    );
  }

  Future<void> resetSyllabusEverything() async {
    await transaction(() async {
      await delete(syllabusTasks).go();
      await delete(syllabusTopics).go();
      await delete(syllabusCategories).go();
    });
  }
}

class ManuallyExpandedCompletedSyllabusCategoriesNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => {};

  void toggle(int categoryId) {
    if (state.contains(categoryId)) {
      state = {...state}..remove(categoryId);
    } else {
      state = {...state, categoryId};
    }
  }

  void collapse(int categoryId) {
    if (state.contains(categoryId)) {
      state = {...state}..remove(categoryId);
    }
  }

  void clear() => state = {};
}

final manuallyExpandedCompletedSyllabusCategoriesProvider =
    NotifierProvider<ManuallyExpandedCompletedSyllabusCategoriesNotifier, Set<int>>(() {
  return ManuallyExpandedCompletedSyllabusCategoriesNotifier();
});
