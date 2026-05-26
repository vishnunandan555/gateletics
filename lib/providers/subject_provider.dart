import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../database/models/subject.dart';
import '../database/isar_service.dart';
import '../core/theme/colors.dart';

part 'subject_provider.g.dart';

@riverpod
class OverallProgressColor extends _$OverallProgressColor {
  @override
  Color build() {
    return AppColors.neonCycle[math.Random().nextInt(AppColors.neonCycle.length)];
  }

  void randomize() {
    state = build();
  }

  void next() {
    final currentIdx = AppColors.neonCycle.indexOf(state);
    final nextIdx = (currentIdx + 1) % AppColors.neonCycle.length;
    state = AppColors.neonCycle[nextIdx];
  }
}

// NOTE: This provider is always overridden in main.dart with the singleton
// instance created before runApp. The factory body here acts as a fallback
// (e.g. in widget tests that don't set up the full ProviderScope override).
@Riverpod(keepAlive: true)
IsarService isarService(Ref ref) => IsarService();

@riverpod
Stream<List<Subject>> subjects(Ref ref) {
  final service = ref.watch(isarServiceProvider);
  return service.listenToSubjects();
}

@riverpod
class SubjectController extends _$SubjectController {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  IsarService get _isarService => ref.read(isarServiceProvider);

  Future<void> updateProgress(Subject subject, int newProgress) async {
    final clampedProgress = newProgress.clamp(0, subject.totalVideos);
    if (subject.completedVideos == clampedProgress) return;

    subject.completedVideos = clampedProgress;
    await _isarService.updateSubject(subject);
  }

  Future<void> updateSubjectDetails(
    Subject subject, {
    required int completed,
    required int total,
    required String sourceName,
    required String playlistLink,
    required bool isActive,
  }) async {
    final safeTotal = total.clamp(0, 9999); // Reasonable upper bound
    final safeCompleted = completed.clamp(0, safeTotal);

    subject.completedVideos = safeCompleted;
    subject.totalVideos = safeTotal;
    subject.sourceName = sourceName;
    subject.playlistLink = playlistLink;
    subject.isActive = isActive;

    await _isarService.updateSubject(subject);
  }

  Future<void> resetTrackingData() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _isarService.resetTrackingData());
  }

  Future<void> resetEverything() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _isarService.hardResetEverything());
  }

  Future<void> applyPreset() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _isarService.applyDefaultPreset());
  }

  Future<void> increment(Subject subject) async {
    await updateProgress(subject, subject.completedVideos + 1);
  }

  Future<void> decrement(Subject subject) async {
    await updateProgress(subject, subject.completedVideos - 1);
  }
}
