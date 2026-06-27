import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/app_database.dart';
import '../database/backup_service.dart';
import 'auth_provider.dart';
import 'subject_provider.dart';
import 'syllabus_provider.dart';
import 'completion_type_provider.dart';
import '../database/syllabus_preset.dart';

enum SyncStatus {
  idle,
  syncing,
  success,
  error,
  requiresAction, // When both local and cloud data exist on first sign-in
}

class SyncState {
  final SyncStatus status;
  final DateTime? lastSyncedAt;
  final String? errorMessage;
  final Map<String, dynamic>? pendingCloudData; // Saved during initial conflict

  SyncState({
    required this.status,
    this.lastSyncedAt,
    this.errorMessage,
    this.pendingCloudData,
  });

  SyncState copyWith({
    SyncStatus? status,
    DateTime? lastSyncedAt,
    String? errorMessage,
    Map<String, dynamic>? pendingCloudData,
  }) {
    return SyncState(
      status: status ?? this.status,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      pendingCloudData: pendingCloudData ?? this.pendingCloudData,
    );
  }
}

class SyncNotifier extends Notifier<SyncState> with WidgetsBindingObserver {
  bool _hasPendingChanges = false;
  Timer? _syncTimer;

  bool get hasPendingChanges => _hasPendingChanges;

  @override
  SyncState build() {
    _load();
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
      _syncTimer?.cancel();
    });
    return SyncState(status: SyncStatus.idle);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      final freq = ref.read(syncFrequencyProvider);
      if (freq == SyncFrequency.appClose && _hasPendingChanges) {
        autoSync();
      }
    }
  }

  void triggerAutoSync() {
    _hasPendingChanges = true;
    final freq = ref.read(syncFrequencyProvider);
    switch (freq) {
      case SyncFrequency.instant:
        autoSync();
        break;
      case SyncFrequency.fiveMinutes:
        _scheduleFiveMinuteSync();
        break;
      case SyncFrequency.appClose:
      case SyncFrequency.manual:
        // Do nothing automatically, wait for app close or manual sync
        break;
    }
  }

  void _scheduleFiveMinuteSync() {
    if (_syncTimer != null && _syncTimer!.isActive) return;
    _syncTimer = Timer(const Duration(minutes: 5), () async {
      if (_hasPendingChanges) {
        await autoSync();
      }
      _syncTimer = null;
    });
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncedStr = prefs.getString('last_synced_at');
      final lastStatusStr = prefs.getString('last_sync_status');
      final lastErrorStr = prefs.getString('last_sync_error');

      DateTime? lastSyncedAt;
      if (lastSyncedStr != null) {
        lastSyncedAt = DateTime.tryParse(lastSyncedStr);
      }

      SyncStatus status = SyncStatus.idle;
      if (lastStatusStr != null) {
        status = SyncStatus.values.firstWhere(
          (e) => e.name == lastStatusStr,
          orElse: () => SyncStatus.idle,
        );
      }

      state = SyncState(
        status: status,
        lastSyncedAt: lastSyncedAt,
        errorMessage: lastErrorStr,
      );
    } catch (e) {
      debugPrint("Error loading sync state from prefs: $e");
    }
  }

  Future<void> _updateSyncState({
    required SyncStatus status,
    DateTime? lastSyncedAt,
    String? errorMessage,
    Map<String, dynamic>? pendingCloudData,
  }) async {
    state = SyncState(
      status: status,
      lastSyncedAt: lastSyncedAt ?? state.lastSyncedAt,
      errorMessage: errorMessage,
      pendingCloudData: pendingCloudData,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_sync_status', status.name);
      if (lastSyncedAt != null) {
        await prefs.setString('last_synced_at', lastSyncedAt.toIso8601String());
      }
      if (errorMessage != null) {
        await prefs.setString('last_sync_error', errorMessage);
      } else {
        await prefs.remove('last_sync_error');
      }
    } catch (e) {
      debugPrint("Error saving sync state to prefs: $e");
    }
  }

  Future<void> clearSyncState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_sync_status');
      await prefs.remove('last_synced_at');
      await prefs.remove('last_sync_error');
    } catch (e) {
      debugPrint("Error clearing sync state: $e");
    }
    state = SyncState(status: SyncStatus.idle);
  }

  AppDatabase get _db => ref.read(appDatabaseProvider);

  // Helper: Export local database to backup JSON format
  Future<Map<String, dynamic>> _exportLocalData() {
    return BackupService.exportDatabase(_db);
  }

  // Helper: Restore database from backup JSON format
  Future<void> _restoreLocalData(Map<String, dynamic> payload) async {
    await BackupService.restoreDatabase(_db, payload);
    clearDatabaseCaches();
  }

  void clearDatabaseCaches() {
    ref.read(resourceCategoriesOrderProvider.notifier).clear();
    ref.read(syllabusCategoriesOrderProvider.notifier).clear();
    ref.read(manuallyExpandedCompletedCategoriesProvider.notifier).clear();
    ref.read(expandedTopicsProvider.notifier).clear();
    ref.read(manuallyExpandedCompletedSyllabusCategoriesProvider.notifier).clear();
  }

  // Intelligent Merge local data with cloud data
  Future<Map<String, dynamic>> _mergeData(Map<String, dynamic> local, Map<String, dynamic> cloud) async {
    // 1. Merge Resource Categories & Subjects
    final localCats = List<Map<String, dynamic>>.from(local['categories'] ?? []);
    final cloudCats = List<Map<String, dynamic>>.from(cloud['categories'] ?? []);
    final localSubjs = List<Map<String, dynamic>>.from(local['subjects'] ?? []);
    final cloudSubjs = List<Map<String, dynamic>>.from(cloud['subjects'] ?? []);

    // Merge Categories by name
    final mergedCats = <String, Map<String, dynamic>>{};
    for (final c in [...localCats, ...cloudCats]) {
      final name = c['name'] as String;
      if (!mergedCats.containsKey(name)) {
        mergedCats[name] = c;
      } else {
        // Keep the one with the newer interaction date
        final currentIntStr = mergedCats[name]!['lastInteractedAt'] as String?;
        final nextIntStr = c['lastInteractedAt'] as String?;
        if (nextIntStr != null && (currentIntStr == null || nextIntStr.compareTo(currentIntStr) > 0)) {
          mergedCats[name] = c;
        }
      }
    }

    // Merge Subjects by name & categoryName
    final mergedSubjs = <String, Map<String, dynamic>>{};
    for (final s in [...localSubjs, ...cloudSubjs]) {
      final key = "${s['categoryName']}_${s['name']}";
      if (!mergedSubjs.containsKey(key)) {
        mergedSubjs[key] = s;
      } else {
        final existing = mergedSubjs[key]!;
        // Choose higher progress/completed videos
        final completed = (s['completedVideos'] as int).clamp(0, s['totalVideos'] as int);
        final existingCompleted = (existing['completedVideos'] as int).clamp(0, existing['totalVideos'] as int);
        if (completed > existingCompleted) {
          mergedSubjs[key] = s;
        }
      }
    }

    // 2. Merge Syllabus Categories, Topics & Tasks
    final localSylCats = List<Map<String, dynamic>>.from(local['syllabusCategories'] ?? []);
    final cloudSylCats = List<Map<String, dynamic>>.from(cloud['syllabusCategories'] ?? []);
    final localSylTops = List<Map<String, dynamic>>.from(local['syllabusTopics'] ?? []);
    final cloudSylTops = List<Map<String, dynamic>>.from(cloud['syllabusTopics'] ?? []);
    final localSylTsks = List<Map<String, dynamic>>.from(local['syllabusTasks'] ?? []);
    final cloudSylTsks = List<Map<String, dynamic>>.from(cloud['syllabusTasks'] ?? []);

    // Merge Syllabus Categories by name
    final mergedSylCats = <String, Map<String, dynamic>>{};
    for (final c in [...localSylCats, ...cloudSylCats]) {
      final name = c['name'] as String;
      if (!mergedSylCats.containsKey(name)) {
        mergedSylCats[name] = c;
      }
    }

    // Build Maps for Topic resolution (old categoryId mapped to Category name)
    String getSylCatName(int catId, List<Map<String, dynamic>> catsList) {
      final match = catsList.firstWhere((c) => c['id'] == catId, orElse: () => {});
      return match['name'] as String? ?? 'General';
    }

    // Merge Syllabus Topics by Category Name & Topic Name
    final mergedSylTops = <String, Map<String, dynamic>>{};
    for (final t in localSylTops) {
      final catName = t.containsKey('categoryName')
          ? t['categoryName'] as String
          : getSylCatName(t['categoryId'] as int, localSylCats);
      final key = "${catName}_${t['name']}";
      mergedSylTops[key] = {
        ...t,
        'categoryName': catName,
      };
    }
    for (final t in cloudSylTops) {
      final catName = t.containsKey('categoryName')
          ? t['categoryName'] as String
          : getSylCatName(t['categoryId'] as int, cloudSylCats);
      final key = "${catName}_${t['name']}";
      if (!mergedSylTops.containsKey(key)) {
        mergedSylTops[key] = {
          ...t,
          'categoryName': catName,
        };
      }
    }

    // Helper to find Topic Name
    String getTopicKeyForSource(int topicId, List<Map<String, dynamic>> topsList, List<Map<String, dynamic>> catsList) {
      final match = topsList.firstWhere((t) => t['id'] == topicId, orElse: () => {});
      final name = match['name'] as String? ?? 'Unknown';
      final catId = match['categoryId'] as int? ?? 0;
      final catName = getSylCatName(catId, catsList);
      return "${catName}_$name";
    }

    // Merge Syllabus Tasks by Topic name & Task name
    final mergedSylTsks = <String, Map<String, dynamic>>{};
    for (final k in localSylTsks) {
      final topicKey = k.containsKey('topicKey')
          ? k['topicKey'] as String
          : getTopicKeyForSource(k['topicId'] as int, localSylTops, localSylCats);
      final key = "${topicKey}_${k['name']}";
      mergedSylTsks[key] = {
        ...k,
        'topicKey': topicKey,
      };
    }
    for (final k in cloudSylTsks) {
      final topicKey = k.containsKey('topicKey')
          ? k['topicKey'] as String
          : getTopicKeyForSource(k['topicId'] as int, cloudSylTops, cloudSylCats);
      final key = "${topicKey}_${k['name']}";
      if (!mergedSylTsks.containsKey(key)) {
        mergedSylTsks[key] = {
          ...k,
          'topicKey': topicKey,
        };
      } else {
        // If either completed, keep completed as true
        final existing = mergedSylTsks[key]!;
        if (k['isCompleted'] == true) {
          existing['isCompleted'] = true;
        }
      }
    }

    // Re-index merged syllabus items back to sequential integer IDs
    final finalSylCats = <Map<String, dynamic>>[];
    final finalSylTops = <Map<String, dynamic>>[];
    final finalSylTsks = <Map<String, dynamic>>[];

    int catCounter = 1;
    final catNameToId = <String, int>{};
    mergedSylCats.forEach((name, c) {
      final id = catCounter++;
      catNameToId[name] = id;
      finalSylCats.add({
        'id': id,
        'name': name,
        'position': c['position'],
        'color': c['color'],
      });
    });

    int topCounter = 1;
    final topKeyToId = <String, int>{};
    mergedSylTops.forEach((key, t) {
      final id = topCounter++;
      topKeyToId[key] = id;
      final catId = catNameToId[t['categoryName']] ?? 1;
      finalSylTops.add({
        'id': id,
        'categoryId': catId,
        'name': t['name'],
        'position': t['position'],
      });
    });

    int taskCounter = 1;
    mergedSylTsks.forEach((key, k) {
      final id = taskCounter++;
      final topicId = topKeyToId[k['topicKey']] ?? 1;
      finalSylTsks.add({
        'id': id,
        'topicId': topicId,
        'name': k['name'],
        'isCompleted': k['isCompleted'],
        'position': k['position'],
      });
    });

    return {
      'version': 3,
      'categories': mergedCats.values.toList(),
      'subjects': mergedSubjs.values.toList(),
      'syllabusCategories': finalSylCats,
      'syllabusTopics': finalSylTops,
      'syllabusTasks': finalSylTsks,
      'lastInteractedAt': DateTime.now().toIso8601String(),
    };
  }

  // ----------------------------------------------------
  // Sync Operations
  // ----------------------------------------------------

  Future<bool> _hasLocalUserModifications() async {
    try {
      // 1. Check if there is any progress in resource-based subjects
      final subjects = await _db.select(_db.subjects).get();
      if (subjects.any((s) => s.completedVideos > 0)) return true;

      // 2. Check if there is any progress in syllabus tasks
      final tasks = await _db.select(_db.syllabusTasks).get();
      if (tasks.any((t) => t.isCompleted)) return true;

      // 3. Check if there are custom resource categories or missing default categories
      final categories = await _db.select(_db.categories).get();
      final defaultCatNames = {'Mathematics', 'Programming', 'Machine Logic', 'Core Systems', 'Aptitude'};
      final currentCatNames = categories.map((c) => c.name).toSet();
      if (currentCatNames.length != defaultCatNames.length || !currentCatNames.containsAll(defaultCatNames)) {
        return true;
      }

      // 4. Check if there are custom syllabus categories or missing default syllabus categories
      final sylCategories = await _db.select(_db.syllabusCategories).get();
      final defaultSylCatNames = defaultSyllabusPreset.map((e) => e.name).toSet();
      final currentSylCatNames = sylCategories.map((c) => c.name).toSet();
      if (currentSylCatNames.length != defaultSylCatNames.length || !currentSylCatNames.containsAll(defaultSylCatNames)) {
        return true;
      }
    } catch (e) {
      debugPrint("Error checking local modifications: $e");
      return true;
    }
    return false;
  }

  // Call on Startup or after sign-in. Returns true if sync conflicts require user choice.
  Future<bool> initializeSync() async {
    if (!isFirebaseSupported()) return false;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    await _updateSyncState(status: SyncStatus.syncing);
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get(const GetOptions(source: Source.server));
      
      final hasLocalData = await _hasLocalUserModifications();

      if (!doc.exists || doc.data()?['data'] == null) {
        // Cloud is empty. If local has data, upload it.
        if (hasLocalData) {
          await uploadLocalToCloud();
        } else {
          await _updateSyncState(status: SyncStatus.success, lastSyncedAt: DateTime.now());
        }
        return false;
      }

      // Cloud database exists
      final cloudData = doc.data()!['data'] as Map<String, dynamic>;

      // Get lastSyncedAt from the cloud document
      DateTime? cloudLastSynced;
      final ts = doc.data()?['lastSyncedAt'];
      if (ts is Timestamp) {
        cloudLastSynced = ts.toDate();
      }

      // Deep data comparison: if local and cloud are identical, bypass conflict check
      if (hasLocalData) {
        final localData = await _exportLocalData();
        localData['completionType'] = ref.read(completionTypeProvider).name;
        if (_areDataEqual(localData, cloudData)) {
          await _updateSyncState(status: SyncStatus.success, lastSyncedAt: cloudLastSynced);
          return false;
        }
      }

      if (!hasLocalData) {
        // Local is empty (e.g., fresh install). Auto-download.
        await _restoreLocalData(cloudData);

        // Restore completionType
        final compTypeStr = cloudData['completionType'] as String?;
        if (compTypeStr != null) {
          final compType = CompletionType.values.firstWhere(
            (e) => e.name == compTypeStr,
            orElse: () => CompletionType.syllabus,
          );
          await ref.read(completionTypeProvider.notifier).setCompletionType(compType);
        }

        await _updateSyncState(status: SyncStatus.success, lastSyncedAt: cloudLastSynced);
        return false;
      }

      // Conflict: Both local and cloud have progress entries. Requires user action.
      await _updateSyncState(
        status: SyncStatus.requiresAction,
        lastSyncedAt: cloudLastSynced,
        pendingCloudData: cloudData,
      );
      return true;
    } catch (e) {
      await _updateSyncState(status: SyncStatus.error, errorMessage: e.toString());
      return false;
    }
  }

  // Action: Overwrite Cloud with Local Data
  Future<void> uploadLocalToCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _hasPendingChanges = false;
    _syncTimer?.cancel();
    _syncTimer = null;

    await _updateSyncState(status: SyncStatus.syncing);
    try {
      final localData = await _exportLocalData();
      localData['completionType'] = ref.read(completionTypeProvider).name;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'data': localData,
        'lastSyncedAt': FieldValue.serverTimestamp(),
      });
      await _updateSyncState(status: SyncStatus.success, lastSyncedAt: DateTime.now());
    } catch (e) {
      await _updateSyncState(status: SyncStatus.error, errorMessage: e.toString());
    }
  }

  // Action: Overwrite Local Data with Cloud Data
  Future<void> downloadCloudToLocal() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _updateSyncState(status: SyncStatus.syncing);
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get(const GetOptions(source: Source.server));
      if (doc.exists && doc.data()?['data'] != null) {
        final cloudData = doc.data()!['data'] as Map<String, dynamic>;
        await _restoreLocalData(cloudData);

        // Restore completionType
        final compTypeStr = cloudData['completionType'] as String?;
        if (compTypeStr != null) {
          final compType = CompletionType.values.firstWhere(
            (e) => e.name == compTypeStr,
            orElse: () => CompletionType.syllabus,
          );
          await ref.read(completionTypeProvider.notifier).setCompletionType(compType);
        }
        // Get lastSyncedAt from the cloud document
        DateTime? cloudLastSynced;
        final ts = doc.data()?['lastSyncedAt'];
        if (ts is Timestamp) {
          cloudLastSynced = ts.toDate();
        }
        await _updateSyncState(status: SyncStatus.success, lastSyncedAt: cloudLastSynced);
      } else {
        await _updateSyncState(status: SyncStatus.success);
      }
    } catch (e) {
      await _updateSyncState(status: SyncStatus.error, errorMessage: e.toString());
    }
  }

  // Action: Merge cloud data with local data
  Future<void> mergeCloudAndLocal() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final cloudData = state.pendingCloudData;
    await _updateSyncState(status: SyncStatus.syncing);

    try {
      Map<String, dynamic>? dataToMerge = cloudData;
      if (dataToMerge == null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get(const GetOptions(source: Source.server));
        if (doc.exists && doc.data()?['data'] != null) {
          dataToMerge = doc.data()!['data'] as Map<String, dynamic>;
        }
      }

      if (dataToMerge != null) {
        final localData = await _exportLocalData();
        final merged = await _mergeData(localData, dataToMerge);
        
        // Restore local DB with merged data
        await _restoreLocalData(merged);

        // Restore completionType
        final compTypeStr = dataToMerge['completionType'] as String?;
        if (compTypeStr != null) {
          final compType = CompletionType.values.firstWhere(
            (e) => e.name == compTypeStr,
            orElse: () => CompletionType.syllabus,
          );
          await ref.read(completionTypeProvider.notifier).setCompletionType(compType);
        }
        
        // Write merged data back to Cloud
        merged['completionType'] = ref.read(completionTypeProvider).name;
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'data': merged,
          'lastSyncedAt': FieldValue.serverTimestamp(),
        });
      }
      await _updateSyncState(status: SyncStatus.success, lastSyncedAt: DateTime.now());
    } catch (e) {
      await _updateSyncState(status: SyncStatus.error, errorMessage: e.toString());
    }
  }

  // Triggers an auto-sync check (can be called silently after database writes)
  Future<void> autoSync() async {
    if (!isFirebaseSupported()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _hasPendingChanges = false;
    _syncTimer?.cancel();
    _syncTimer = null;

    try {
      final localData = await _exportLocalData();
      localData['completionType'] = ref.read(completionTypeProvider).name;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'data': localData,
        'lastSyncedAt': FieldValue.serverTimestamp(),
      });
      // Silent success: keep previous status but update lastSyncedAt.
      await _updateSyncState(status: state.status, lastSyncedAt: DateTime.now());
    } catch (_) {
      // Fail silently on auto-sync (likely internet is down)
    }
  }

  bool _areDataEqual(Map<String, dynamic> local, Map<String, dynamic> cloud) {
    try {
      // Compare completionType
      if (local['completionType'] != cloud['completionType']) return false;

      // Compare categories count and names
      final localCats = local['categories'] as List?;
      final cloudCats = cloud['categories'] as List?;
      if (localCats?.length != cloudCats?.length) return false;

      // Compare subjects progress
      final localSubjs = local['subjects'] as List?;
      final cloudSubjs = cloud['subjects'] as List?;
      if (localSubjs?.length != cloudSubjs?.length) return false;
      
      // Map local subjects by name for comparison
      final localSubjMap = {
        for (var s in (localSubjs ?? [])) 
          "${s['categoryName'] ?? ''}_${s['name'] ?? ''}": s
      };
      for (final cs in (cloudSubjs ?? [])) {
        final key = "${cs['categoryName'] ?? ''}_${cs['name'] ?? ''}";
        final ls = localSubjMap[key];
        if (ls == null) return false;
        if (ls['completedVideos'] != cs['completedVideos']) return false;
        if (ls['totalVideos'] != cs['totalVideos']) return false;
      }

      // Compare syllabus tasks progress
      final localTasks = local['syllabusTasks'] as List?;
      final cloudTasks = cloud['syllabusTasks'] as List?;
      if (localTasks?.length != cloudTasks?.length) return false;

      // Map local syllabus tasks by topicKey and name
      final localTaskMap = {
        for (var t in (localTasks ?? []))
          "${t['topicKey'] ?? t['topicId']}_${t['name'] ?? ''}": t
      };
      for (final ct in (cloudTasks ?? [])) {
        final key = "${ct['topicKey'] ?? ct['topicId']}_${ct['name'] ?? ''}";
        final lt = localTaskMap[key];
        if (lt == null) return false;
        if (lt['isCompleted'] != ct['isCompleted']) return false;
      }

      return true;
    } catch (_) {
      return false;
    }
  }
}

final syncProvider = NotifierProvider<SyncNotifier, SyncState>(() {
  return SyncNotifier();
});

enum SyncFrequency {
  instant,
  fiveMinutes,
  appClose,
  manual,
}

class SyncFrequencyNotifier extends Notifier<SyncFrequency> {
  @override
  SyncFrequency build() {
    _load();
    return SyncFrequency.instant;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString('sync_frequency');
    if (val != null) {
      state = SyncFrequency.values.firstWhere(
        (e) => e.name == val,
        orElse: () => SyncFrequency.instant,
      );
    }
  }

  Future<void> setFrequency(SyncFrequency val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sync_frequency', val.name);
    state = val;

    final syncNotifier = ref.read(syncProvider.notifier);
    if (val == SyncFrequency.instant) {
      if (syncNotifier.hasPendingChanges) {
        syncNotifier.autoSync();
      }
      syncNotifier._syncTimer?.cancel();
      syncNotifier._syncTimer = null;
    } else if (val == SyncFrequency.fiveMinutes) {
      if (syncNotifier.hasPendingChanges) {
        syncNotifier._scheduleFiveMinuteSync();
      }
    } else {
      syncNotifier._syncTimer?.cancel();
      syncNotifier._syncTimer = null;
    }
  }
}

final syncFrequencyProvider = NotifierProvider<SyncFrequencyNotifier, SyncFrequency>(() {
  return SyncFrequencyNotifier();
});
