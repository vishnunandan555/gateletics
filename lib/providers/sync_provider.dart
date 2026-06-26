import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../database/backup_service.dart';
import 'auth_provider.dart';
import 'subject_provider.dart';

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

class SyncNotifier extends Notifier<SyncState> {
  @override
  SyncState build() {
    return SyncState(status: SyncStatus.idle);
  }

  AppDatabase get _db => ref.read(appDatabaseProvider);

  // Helper: Export local database to backup JSON format
  Future<Map<String, dynamic>> _exportLocalData() {
    return BackupService.exportDatabase(_db);
  }

  // Helper: Restore database from backup JSON format
  Future<void> _restoreLocalData(Map<String, dynamic> payload) {
    return BackupService.restoreDatabase(_db, payload);
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
    for (final t in [...localSylTops, ...cloudSylTops]) {
      final catName = t.containsKey('categoryName')
          ? t['categoryName'] as String
          : getSylCatName(t['categoryId'] as int, t['categoryId'] < 1000 ? localSylCats : cloudSylCats);
      final key = "${catName}_${t['name']}";
      if (!mergedSylTops.containsKey(key)) {
        mergedSylTops[key] = {
          ...t,
          'categoryName': catName,
        };
      }
    }

    // Helper to find Topic Name
    String getTopicKey(int topicId, List<Map<String, dynamic>> topsList, List<Map<String, dynamic>> catsList) {
      final match = topsList.firstWhere((t) => t['id'] == topicId, orElse: () => {});
      final name = match['name'] as String? ?? 'Unknown';
      final catId = match['categoryId'] as int? ?? 0;
      final catName = getSylCatName(catId, catsList);
      return "${catName}_$name";
    }

    // Merge Syllabus Tasks by Topic name & Task name
    final mergedSylTsks = <String, Map<String, dynamic>>{};
    for (final k in [...localSylTsks, ...cloudSylTsks]) {
      final topicKey = k.containsKey('topicKey')
          ? k['topicKey'] as String
          : getTopicKey(k['topicId'] as int, k['topicId'] < 1000 ? localSylTops : cloudSylTops, k['topicId'] < 1000 ? localSylCats : cloudSylCats);
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

  // Call on Startup or after sign-in. Returns true if sync conflicts require user choice.
  Future<bool> initializeSync() async {
    if (!isFirebaseSupported()) return false;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    state = SyncState(status: SyncStatus.syncing);
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      
      final localData = await _exportLocalData();
      final hasLocalData = (localData['categories'] as List).isNotEmpty || 
                           (localData['syllabusCategories'] as List).isNotEmpty;

      if (!doc.exists || doc.data()?['data'] == null) {
        // Cloud is empty. If local has data, upload it.
        if (hasLocalData) {
          await uploadLocalToCloud();
        } else {
          state = SyncState(status: SyncStatus.success, lastSyncedAt: DateTime.now());
        }
        return false;
      }

      // Cloud database exists
      final cloudData = doc.data()!['data'] as Map<String, dynamic>;

      if (!hasLocalData) {
        // Local is empty (e.g., fresh install). Auto-download.
        await _restoreLocalData(cloudData);
        state = SyncState(status: SyncStatus.success, lastSyncedAt: DateTime.now());
        return false;
      }

      // Conflict: Both local and cloud have progress entries. Requires user action.
      state = SyncState(
        status: SyncStatus.requiresAction,
        pendingCloudData: cloudData,
      );
      return true;
    } catch (e) {
      state = SyncState(status: SyncStatus.error, errorMessage: e.toString());
      return false;
    }
  }

  // Action: Overwrite Cloud with Local Data
  Future<void> uploadLocalToCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    state = SyncState(status: SyncStatus.syncing);
    try {
      final localData = await _exportLocalData();
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'data': localData,
        'lastSyncedAt': FieldValue.serverTimestamp(),
      });
      state = SyncState(status: SyncStatus.success, lastSyncedAt: DateTime.now());
    } catch (e) {
      state = SyncState(status: SyncStatus.error, errorMessage: e.toString());
    }
  }

  // Action: Overwrite Local Data with Cloud Data
  Future<void> downloadCloudToLocal() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    state = SyncState(status: SyncStatus.syncing);
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data()?['data'] != null) {
        final cloudData = doc.data()!['data'] as Map<String, dynamic>;
        await _restoreLocalData(cloudData);
      }
      state = SyncState(status: SyncStatus.success, lastSyncedAt: DateTime.now());
    } catch (e) {
      state = SyncState(status: SyncStatus.error, errorMessage: e.toString());
    }
  }

  // Action: Merge cloud data with local data
  Future<void> mergeCloudAndLocal() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final cloudData = state.pendingCloudData;
    state = SyncState(status: SyncStatus.syncing);

    try {
      Map<String, dynamic>? dataToMerge = cloudData;
      if (dataToMerge == null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data()?['data'] != null) {
          dataToMerge = doc.data()!['data'] as Map<String, dynamic>;
        }
      }

      if (dataToMerge != null) {
        final localData = await _exportLocalData();
        final merged = await _mergeData(localData, dataToMerge);
        
        // Restore local DB with merged data
        await _restoreLocalData(merged);
        
        // Write merged data back to Cloud
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'data': merged,
          'lastSyncedAt': FieldValue.serverTimestamp(),
        });
      }
      state = SyncState(status: SyncStatus.success, lastSyncedAt: DateTime.now());
    } catch (e) {
      state = SyncState(status: SyncStatus.error, errorMessage: e.toString());
    }
  }

  // Triggers an auto-sync check (can be called silently after database writes)
  Future<void> autoSync() async {
    if (!isFirebaseSupported()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final localData = await _exportLocalData();
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'data': localData,
        'lastSyncedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Fail silently on auto-sync (likely internet is down)
    }
  }
}

final syncProvider = NotifierProvider<SyncNotifier, SyncState>(() {
  return SyncNotifier();
});
