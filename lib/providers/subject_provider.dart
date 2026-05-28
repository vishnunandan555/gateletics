import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../core/theme/colors.dart';

// Database Provider
final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

// Stream provider for flat list of subjects
final subjectsProvider = StreamProvider<List<Subject>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchSubjects();
});

// Stream provider for nested categories with their subjects
final categoriesWithSubjectsProvider = StreamProvider<List<CategoryWithSubjects>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchCategoriesWithSubjects();
});

// Progress Color Provider using standard Notifier
final overallProgressColorProvider = NotifierProvider<OverallProgressColorNotifier, Color>(() {
  return OverallProgressColorNotifier();
});

class OverallProgressColorNotifier extends Notifier<Color> {
  @override
  Color build() {
    return AppColors.neonCycle[math.Random().nextInt(AppColors.neonCycle.length)];
  }

  void randomize() {
    state = AppColors.neonCycle[math.Random().nextInt(AppColors.neonCycle.length)];
  }

  void next() {
    final currentIdx = AppColors.neonCycle.indexOf(state);
    final nextIdx = (currentIdx + 1) % AppColors.neonCycle.length;
    state = AppColors.neonCycle[nextIdx];
  }
}

// Controller using standard Notifier
final subjectControllerProvider = NotifierProvider<SubjectController, AsyncValue<void>>(() {
  return SubjectController();
});

class SubjectController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  AppDatabase get _db => ref.read(appDatabaseProvider);

  Future<void> updateProgress(Subject subject, int newProgress) async {
    final clampedProgress = newProgress.clamp(0, subject.totalVideos);
    if (subject.completedVideos == clampedProgress) return;
    await _db.updateSubjectProgress(subject.id, clampedProgress);
  }

  Future<void> addSubject({
    required String name,
    required int categoryId,
    required int total,
    required String sourceName,
    required String playlistLink,
    required bool isActive,
    int? color,
  }) async {
    await _db.addSubject(
      name: name,
      categoryId: categoryId,
      totalVideos: total,
      sourceName: sourceName,
      playlistLink: playlistLink,
      isActive: isActive,
      color: color,
    );
  }

  Future<void> updateSubjectDetails(
    Subject subject, {
    required int completed,
    required int total,
    required String sourceName,
    required String playlistLink,
    required bool isActive,
    int? color,
    int? categoryId,
  }) async {
    final safeTotal = total.clamp(0, 9999);
    final safeCompleted = completed.clamp(0, safeTotal);
    await _db.updateSubjectDetails(
      id: subject.id,
      name: subject.name,
      completed: safeCompleted,
      total: safeTotal,
      sourceName: sourceName,
      playlistLink: playlistLink,
      isActive: isActive,
      color: color,
      categoryId: categoryId,
    );
  }

  Future<void> deleteSubject(int id) async {
    await _db.deleteSubject(id);
  }

  // ----------------------------------------------------
  // Category CRUD
  // ----------------------------------------------------

  Future<void> addCategory(String name, int color) async {
    await _db.addCategory(name, color);
  }

  Future<void> updateCategory(int id, String name, int color) async {
    await _db.updateCategoryDetails(id, name, color);
  }

  Future<void> deleteCategory(int id) async {
    await _db.deleteCategory(id);
  }

  // ----------------------------------------------------
  // Reordering
  // ----------------------------------------------------

  Future<void> reorderCategories(List<int> orderedIds) async {
    await _db.updateCategoryPositions(orderedIds);
  }

  Future<void> reorderSubjects(int categoryId, List<int> orderedIds) async {
    await _db.updateSubjectPositions(categoryId, orderedIds);
  }

  // ----------------------------------------------------
  // Reset / Presets
  // ----------------------------------------------------

  Future<void> resetTrackingData() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _db.resetTrackingData());
  }

  Future<void> resetEverything() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _db.hardResetEverything());
  }

  Future<void> applyPreset() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _db.applyDefaultPreset());
  }

  Future<void> increment(Subject subject) async {
    await updateProgress(subject, subject.completedVideos + 1);
  }

  Future<void> decrement(Subject subject) async {
    await updateProgress(subject, subject.completedVideos - 1);
  }
}
