import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/models/subject.dart';
import '../database/isar_service.dart';

final overallProgressColorProvider = StateProvider<Color>((ref) {
  const colors = [
    Color(0xFF00F0FF), // Neon cyan
    Color(0xFF39FF14), // Neon green
    Color(0xFFFF073A), // Neon scarlet red
    Color(0xFFFFAD00), // Neon golden amber
    Color(0xFFE040FB), // Neon magenta/purple
    Color(0xFFFF5E00), // Neon orange
    Color(0xFF00B0FF), // Neon electric blue
    Color(0xFF00FFCC), // Neon mint/teal
  ];
  return colors[math.Random().nextInt(colors.length)];
});

// NOTE: This provider is always overridden in main.dart with the singleton
// instance created before runApp. The factory body here acts as a fallback
// (e.g. in widget tests that don't set up the full ProviderScope override).
final isarServiceProvider = Provider<IsarService>((ref) => IsarService());

final subjectsProvider = StreamProvider<List<Subject>>((ref) {
  final isarService = ref.watch(isarServiceProvider);
  return isarService.listenToSubjects();
});

class SubjectController extends StateNotifier<AsyncValue<void>> {
  final IsarService _isarService;

  SubjectController(this._isarService) : super(const AsyncValue.data(null));

  Future<void> updateProgress(Subject subject, int newProgress) async {
    if (newProgress < 0) newProgress = 0;
    if (newProgress > subject.totalVideos) newProgress = subject.totalVideos;

    subject.completedVideos = newProgress;
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
    if (completed < 0) completed = 0;
    if (total < 0) total = 0;
    if (total > 0 && completed > total) completed = total;

    subject.completedVideos = completed;
    subject.totalVideos = total;
    subject.sourceName = sourceName;
    subject.playlistLink = playlistLink;
    subject.isActive = isActive;

    await _isarService.updateSubject(subject);
  }

  Future<void> resetTrackingData() async {
    state = const AsyncValue.loading();
    try {
      await _isarService.resetTrackingData();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> resetEverything() async {
    state = const AsyncValue.loading();
    try {
      await _isarService.hardResetEverything();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> applyPreset() async {
    state = const AsyncValue.loading();
    try {
      await _isarService.applyDefaultPreset();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> increment(Subject subject) async {
    await updateProgress(subject, subject.completedVideos + 1);
  }

  Future<void> decrement(Subject subject) async {
    await updateProgress(subject, subject.completedVideos - 1);
  }
}

final subjectControllerProvider =
    StateNotifierProvider<SubjectController, AsyncValue<void>>((ref) {
      final isarService = ref.watch(isarServiceProvider);
      return SubjectController(isarService);
    });
