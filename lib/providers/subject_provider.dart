import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/app_database.dart';
import '../core/theme/colors.dart';

import 'category_autosort_provider.dart';
import 'sync_provider.dart';

// Database Provider
final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

// Stream provider for flat list of subjects
final subjectsProvider = StreamProvider<List<Subject>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchSubjects();
});

final resourceCategoriesOrderProvider = NotifierProvider<ResourceCategoriesOrderNotifier, List<int>>(() {
  return ResourceCategoriesOrderNotifier();
});

class ResourceCategoriesOrderNotifier extends Notifier<List<int>> {
  @override
  List<int> build() => [];

  void setOrder(List<int> ids) => state = ids;
  void clear() => state = [];
}

int _compareCategories(Category a, Category b) {
  final aTime = a.lastInteractedAt;
  final bTime = b.lastInteractedAt;
  if (aTime == null && bTime == null) {
    return a.position.compareTo(b.position);
  }
  if (aTime == null) return 1;
  if (bTime == null) return -1;
  return bTime.compareTo(aTime);
}

// Stream provider for nested categories with their subjects
final categoriesWithSubjectsProvider = StreamProvider<List<CategoryWithSubjects>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final autoSort = ref.watch(categoryAutoSortProvider);
  final lockedOrder = ref.watch(resourceCategoriesOrderProvider);

  return db.watchCategoriesWithSubjects().map((list) {
    if (!autoSort) return list;
    final sorted = List<CategoryWithSubjects>.from(list);

    if (lockedOrder.isEmpty) {
      sorted.sort((a, b) => _compareCategories(a.category, b.category));
      final ids = sorted.map((e) => e.category.id).toList();
      Future.microtask(() {
        ref.read(resourceCategoriesOrderProvider.notifier).setOrder(ids);
      });
      return sorted;
    }

    sorted.sort((a, b) {
      final indexA = lockedOrder.indexOf(a.category.id);
      final indexB = lockedOrder.indexOf(b.category.id);
      if (indexA != -1 && indexB != -1) {
        return indexA.compareTo(indexB);
      }
      if (indexA != -1) return -1;
      if (indexB != -1) return 1;
      return _compareCategories(a.category, b.category);
    });

    return sorted;
  });
});

// Progress Color Provider using standard Notifier
final overallProgressColorProvider = NotifierProvider<OverallProgressColorNotifier, Color>(() {
  return OverallProgressColorNotifier();
});

class OverallProgressColorNotifier extends Notifier<Color> {
  String _mode = 'auto'; // 'auto' or 'frozen'
  Color? _frozenColor;

  String get mode => _mode;
  Color? get frozenColor => _frozenColor;

  @override
  Color build() {
    _load();
    return AppColors.neonCycle[math.Random().nextInt(AppColors.neonCycle.length)];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _mode = prefs.getString('accent_color_mode') ?? 'auto';
    final colorHex = prefs.getString('frozen_accent_color');
    if (colorHex != null) {
      final value = int.tryParse(colorHex, radix: 16);
      if (value != null) {
        _frozenColor = Color(value);
      }
    }
    if (_mode == 'frozen' && _frozenColor != null) {
      state = _frozenColor!;
    }
  }

  Future<void> setAutoMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accent_color_mode', 'auto');
    await prefs.remove('frozen_accent_color');
    _mode = 'auto';
    _frozenColor = null;
    randomize();
  }

  Future<void> setFrozenColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accent_color_mode', 'frozen');
    await prefs.setString('frozen_accent_color', color.toARGB32().toRadixString(16));
    _mode = 'frozen';
    _frozenColor = color;
    state = color;
  }

  void randomize() {
    if (_mode == 'frozen') return;
    state = AppColors.neonCycle[math.Random().nextInt(AppColors.neonCycle.length)];
  }

  void next() {
    if (_mode == 'frozen') return;
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

  void _triggerSync() {
    ref.read(syncProvider.notifier).triggerAutoSync();
  }

  Future<void> updateProgress(Subject subject, int newProgress) async {
    final clampedProgress = newProgress.clamp(0, subject.totalVideos);
    if (subject.completedVideos == clampedProgress) return;
    await _db.updateSubjectProgress(subject.id, clampedProgress);
    await _db.updateCategoryInteraction(subject.categoryId);
    _triggerSync();
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
    await _db.updateCategoryInteraction(categoryId);
    _triggerSync();
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
    await _db.updateCategoryInteraction(categoryId ?? subject.categoryId);
    _triggerSync();
  }

  Future<void> deleteSubject(int id) async {
    final subject = await (_db.select(_db.subjects)..where((t) => t.id.equals(id))).getSingleOrNull();
    final catId = subject?.categoryId;
    await _db.deleteSubject(id);
    if (catId != null) {
      await _db.updateCategoryInteraction(catId);
    }
    _triggerSync();
  }

  // ----------------------------------------------------
  // Category CRUD
  // ----------------------------------------------------

  Future<void> addCategory(String name, int color) async {
    await _db.addCategory(name, color);
    ref.read(resourceCategoriesOrderProvider.notifier).clear();
    _triggerSync();
  }

  Future<void> updateCategory(int id, String name, int color) async {
    await _db.updateCategoryDetails(id, name, color);
    ref.read(resourceCategoriesOrderProvider.notifier).clear();
    _triggerSync();
  }

  Future<void> deleteCategory(int id) async {
    await _db.deleteCategory(id);
    ref.read(resourceCategoriesOrderProvider.notifier).clear();
    _triggerSync();
  }

  Future<void> markCategoryCompleted(int id) async {
    await _db.markCategoryCompleted(id);
    _triggerSync();
  }

  Future<void> resetCategoryStats(int id) async {
    await _db.resetCategoryStats(id);
    _triggerSync();
  }

  // ----------------------------------------------------
  // Reordering
  // ----------------------------------------------------

  Future<void> reorderCategories(List<int> orderedIds) async {
    await _db.updateCategoryPositions(orderedIds);
    ref.read(resourceCategoriesOrderProvider.notifier).clear();
    _triggerSync();
  }

  Future<void> reorderSubjects(int categoryId, List<int> orderedIds) async {
    await _db.updateSubjectPositions(categoryId, orderedIds);
    _triggerSync();
  }

  // ----------------------------------------------------
  // Reset / Presets
  // ----------------------------------------------------

  Future<void> resetTrackingData() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _db.resetTrackingData());
    _triggerSync();
  }

  Future<void> resetEverything() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _db.hardResetEverything());
    _triggerSync();
  }

  Future<void> applyPreset() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _db.applyDefaultPreset());
    _triggerSync();
  }

  Future<void> increment(Subject subject) async {
    await updateProgress(subject, subject.completedVideos + 1);
  }

  Future<void> decrement(Subject subject) async {
    await updateProgress(subject, subject.completedVideos - 1);
  }
}

class ManuallyExpandedCompletedCategoriesNotifier extends Notifier<Set<int>> {
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

final manuallyExpandedCompletedCategoriesProvider =
    NotifierProvider<ManuallyExpandedCompletedCategoriesNotifier, Set<int>>(() {
  return ManuallyExpandedCompletedCategoriesNotifier();
});
