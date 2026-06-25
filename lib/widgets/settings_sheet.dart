import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import '../providers/subject_provider.dart';
import '../providers/completion_type_provider.dart';
import '../providers/syllabus_provider.dart';
import '../providers/package_info_provider.dart';

import 'settings/about_dialog.dart';

void showSettingsSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withAlpha(180),
    builder: (context) => const SettingsSheet(),
  );
}

class SettingsSheet extends ConsumerWidget {
  const SettingsSheet({super.key});

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    try {
      final db = ref.read(appDatabaseProvider);
      
      final categoriesList = await db.select(db.categories).get();
      final subjectsList = await db.select(db.subjects).get();
      final syllabusCats = await db.select(db.syllabusCategories).get();
      final syllabusTops = await db.select(db.syllabusTopics).get();
      final syllabusTsks = await db.select(db.syllabusTasks).get();

      final categoryMap = {for (var c in categoriesList) c.id: c.name};

      final exportedCategories = categoriesList.map((c) => {
        'name': c.name,
        'color': c.color,
        'position': c.position,
      }).toList();

      final exportedSubjects = subjectsList.map((s) => {
        'name': s.name,
        'categoryName': categoryMap[s.categoryId] ?? 'General',
        'completedVideos': s.completedVideos,
        'totalVideos': s.totalVideos,
        'playlistLink': s.playlistLink,
        'sourceName': s.sourceName,
        'isActive': s.isActive,
        'position': s.position,
        'color': s.color,
      }).toList();

      final exportedSyllabusCats = syllabusCats.map((c) => {
        'id': c.id,
        'name': c.name,
        'position': c.position,
        'color': c.color,
      }).toList();

      final exportedSyllabusTops = syllabusTops.map((t) => {
        'id': t.id,
        'categoryId': t.categoryId,
        'name': t.name,
        'position': t.position,
      }).toList();

      final exportedSyllabusTsks = syllabusTsks.map((k) => {
        'id': k.id,
        'topicId': k.topicId,
        'name': k.name,
        'isCompleted': k.isCompleted,
        'position': k.position,
      }).toList();

      final exportPayload = {
        'version': 2,
        'categories': exportedCategories,
        'subjects': exportedSubjects,
        'syllabusCategories': exportedSyllabusCats,
        'syllabusTopics': exportedSyllabusTops,
        'syllabusTasks': exportedSyllabusTsks,
      };

      final json = const JsonEncoder.withIndent('  ').convert(exportPayload);

      String? path;
      if (kIsWeb) {
        final bytes = Uint8List.fromList(utf8.encode(json));
        path = await FilePicker.saveFile(
          dialogTitle: 'Save backup to device',
          fileName: 'gateletics_backup.json',
          bytes: bytes,
          type: FileType.custom,
          allowedExtensions: ['json'],
        );
      } else if (defaultTargetPlatform == TargetPlatform.android ||
                 defaultTargetPlatform == TargetPlatform.iOS) {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/gateletics_backup.json');
        await tempFile.writeAsString(json);

        final params = SaveFileDialogParams(
          sourceFilePath: tempFile.path,
          fileName: 'gateletics_backup.json',
        );
        path = await FlutterFileDialog.saveFile(params: params);
      } else {
        final bytes = Uint8List.fromList(utf8.encode(json));
        path = await FilePicker.saveFile(
          dialogTitle: 'Save backup to device',
          fileName: 'gateletics_backup.json',
          bytes: bytes,
          type: FileType.custom,
          allowedExtensions: ['json'],
        );
        if (path != null) {
          final file = File(path);
          await file.writeAsBytes(bytes);
        }
      }

      if (path != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data exported successfully!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    try {
      Uint8List? bytes;
      if (kIsWeb ||
          (defaultTargetPlatform != TargetPlatform.android &&
           defaultTargetPlatform != TargetPlatform.iOS)) {
        final result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['json'],
        );
        if (result == null || result.files.isEmpty) return;
        bytes = await result.files.single.readAsBytes();
      } else {
        final params = OpenFileDialogParams(
          dialogType: OpenFileDialogType.document,
          fileExtensionsFilter: ['json'],
        );
        final filePath = await FlutterFileDialog.pickFile(params: params);
        if (filePath == null) return;
        bytes = await File(filePath).readAsBytes();
      }

      final raw = utf8.decode(bytes);

      final payload = jsonDecode(raw);
      final db = ref.read(appDatabaseProvider);

      if (payload is List || (payload is Map && !payload.containsKey('categories'))) {
        // Fallback: old style progress restoration by subject name
        final list = (payload is List ? payload : payload['subjects'] as List<dynamic>);
        final existingSubjects = await db.select(db.subjects).get();
        final subjectMap = {for (var s in existingSubjects) s.name.trim(): s};

        int importedCount = 0;
        await db.transaction(() async {
          for (final item in list) {
            final name = item['name'] as String?;
            if (name == null) continue;

            final s = subjectMap[name.trim()];
            if (s != null) {
              await db.updateSubjectDetails(
                id: s.id,
                name: s.name,
                completed: (item['completedVideos'] as int?) ?? s.completedVideos,
                total: (item['totalVideos'] as int?) ?? s.totalVideos,
                sourceName: (item['sourceName'] as String?) ?? s.sourceName,
                playlistLink: (item['playlistLink'] as String?) ?? s.playlistLink,
                isActive: (item['isActive'] as bool?) ?? s.isActive,
                color: item['color'] as int?,
                categoryId: s.categoryId,
              );
              importedCount++;
            }
          }
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✓ Restored progress for $importedCount matching subjects!')),
          );
        }
      } else {
        // Premium new style: complete restore
        final categoriesData = payload['categories'] as List<dynamic>;
        final subjectsData = payload['subjects'] as List<dynamic>;
        final syllabusCategoriesData = payload['syllabusCategories'] as List<dynamic>?;
        final syllabusTopicsData = payload['syllabusTopics'] as List<dynamic>?;
        final syllabusTasksData = payload['syllabusTasks'] as List<dynamic>?;

        await db.transaction(() async {
          // 1. Restore resource-based tables
          await db.delete(db.subjects).go();
          await db.delete(db.categories).go();

          final categoryNameToNewId = <String, int>{};
          for (final c in categoriesData) {
            final name = c['name'] as String;
            final color = c['color'] as int;
            final position = c['position'] as int;
            
            final id = await db.addCategory(name, color, position: position);
            categoryNameToNewId[name] = id;
          }

          for (final s in subjectsData) {
            final categoryName = s['categoryName'] as String;
            final catId = categoryNameToNewId[categoryName];
            if (catId == null) continue; // Skip if category is missing

            await db.addSubject(
              name: s['name'] as String,
              categoryId: catId,
              totalVideos: s['totalVideos'] as int,
              sourceName: s['sourceName'] as String,
              playlistLink: s['playlistLink'] as String,
              isActive: s['isActive'] as bool,
              color: s['color'] as int?,
              position: s['position'] as int? ?? 0,
            );
          }

          // 2. Restore syllabus-based tables if present in backup
          if (syllabusCategoriesData != null && syllabusTopicsData != null && syllabusTasksData != null) {
            await db.delete(db.syllabusTasks).go();
            await db.delete(db.syllabusTopics).go();
            await db.delete(db.syllabusCategories).go();

            final oldCatIdToNewId = <int, int>{};
            for (final c in syllabusCategoriesData) {
              final oldId = c['id'] as int;
              final name = c['name'] as String;
              final color = c['color'] as int;
              final position = c['position'] as int;

              final newId = await db.addSyllabusCategory(name, color, position: position);
              oldCatIdToNewId[oldId] = newId;
            }

            final oldTopicIdToNewId = <int, int>{};
            for (final t in syllabusTopicsData) {
              final oldId = t['id'] as int;
              final oldCatId = t['categoryId'] as int;
              final name = t['name'] as String;
              final position = t['position'] as int;

              final newCatId = oldCatIdToNewId[oldCatId];
              if (newCatId != null) {
                final newId = await db.addSyllabusTopic(newCatId, name, position: position);
                oldTopicIdToNewId[oldId] = newId;
              }
            }

            for (final k in syllabusTasksData) {
              final oldTopicId = k['topicId'] as int;
              final name = k['name'] as String;
              final isCompleted = k['isCompleted'] as bool;
              final position = k['position'] as int;

              final newTopicId = oldTopicIdToNewId[oldTopicId];
              if (newTopicId != null) {
                final taskId = await db.addSyllabusTask(newTopicId, name, position: position);
                await db.updateSyllabusTaskCompletion(taskId, isCompleted);
              }
            }
          }
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✓ Backup data successfully restored!')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  Future<void> _performReset(BuildContext context, WidgetRef ref,
      {required bool everything}) async {
    final title = everything ? 'Reset Everything' : 'Reset Tracking Data';
    final content = everything
        ? 'This will clear ALL your sources, links, and progress. This cannot be undone.'
        : 'This will reset all your progress counts to zero but keep your sources and links.';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title),
        content: Text(
          content,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      if (everything) {
        await ref.read(subjectControllerProvider.notifier).resetEverything();
        await ref.read(syllabusControllerProvider.notifier).resetEverything();
      } else {
        final currentType = ref.read(completionTypeProvider);
        if (currentType == CompletionType.syllabus) {
          await ref.read(syllabusControllerProvider.notifier).resetTrackingData();
        } else {
          await ref
              .read(subjectControllerProvider.notifier)
              .resetTrackingData();
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(everything ? 'System reset!' : 'Progress reset!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reset failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packageInfo = ref.watch(packageInfoProvider);
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.25,
      maxChildSize: 0.95,
      expand: false,
      snap: true,
      builder: (context, scrollController) {
        return Material(
          color: const Color(0xFF18181B),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Settings',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.upload_file, color: Color(0xFF00E5FF)),
                    title: const Text('Export Data'),
                    subtitle: const Text(
                      'Save progress to JSON',
                      style: TextStyle(color: Colors.grey),
                    ),
                    onTap: () async {
                      await _exportData(context, ref);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.download, color: Color(0xFF69F0AE)),
                    title: const Text('Import Data'),
                    subtitle: const Text(
                      'Restore from JSON file',
                      style: TextStyle(color: Colors.grey),
                    ),
                    onTap: () async {
                      await _importData(context, ref);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                  const Divider(color: Colors.white12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'COMPLETION TYPE',
                      style: TextStyle(
                        color: ref.watch(overallProgressColorProvider).withAlpha(178),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Consumer(
                      builder: (context, ref, _) {
                        final currentType = ref.watch(completionTypeProvider);
                        final accentColor = ref.watch(overallProgressColorProvider);

                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => ref
                                        .read(completionTypeProvider.notifier)
                                        .setCompletionType(CompletionType.resource),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: currentType == CompletionType.resource
                                            ? accentColor.withAlpha(51)
                                            : Colors.white10,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: currentType == CompletionType.resource
                                              ? accentColor
                                              : Colors.transparent,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Resource Based',
                                          style: TextStyle(
                                            color: currentType == CompletionType.resource
                                                ? accentColor
                                                : Colors.white70,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => ref
                                        .read(completionTypeProvider.notifier)
                                        .setCompletionType(CompletionType.syllabus),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: currentType == CompletionType.syllabus
                                            ? accentColor.withAlpha(51)
                                            : Colors.white10,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: currentType == CompletionType.syllabus
                                              ? accentColor
                                              : Colors.transparent,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Syllabus Based',
                                          style: TextStyle(
                                            color: currentType == CompletionType.syllabus
                                                ? accentColor
                                                : Colors.white70,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.auto_awesome, color: Colors.amberAccent),
                              title: Text(currentType == CompletionType.resource
                                  ? 'Apply Resource Preset'
                                  : 'Apply Syllabus Preset'),
                              subtitle: Text(
                                currentType == CompletionType.resource
                                    ? 'Apply default GoClasses/YouTube sources'
                                    : 'Restore the default GATE CSE checklist',
                                style: const TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                              onTap: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: const Color(0xFF18181B),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    title: Text(currentType == CompletionType.resource
                                        ? 'Apply Resource Preset'
                                        : 'Apply Syllabus Preset'),
                                    content: Text(
                                      currentType == CompletionType.resource
                                          ? 'This will overwrite current sources and counts for some subjects. Continue?'
                                          : 'This will reset and overwrite all current syllabus categories and checklist progress. Continue?',
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Cancel',
                                            style: TextStyle(color: Colors.grey)),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.amberAccent,
                                          foregroundColor: Colors.black,
                                        ),
                                        child: const Text('Apply'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmed == true) {
                                  if (context.mounted) Navigator.pop(context);
                                  if (currentType == CompletionType.resource) {
                                    await ref
                                        .read(subjectControllerProvider.notifier)
                                        .applyPreset();
                                  } else {
                                    await ref
                                        .read(syllabusControllerProvider.notifier)
                                        .applyPreset();
                                  }
                                }
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: Colors.white12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'RESET DATA',
                      style: TextStyle(
                        color: Colors.redAccent.withValues(alpha: 0.7),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.history_rounded, color: Colors.redAccent),
                    title: const Text('Reset Tracking Data'),
                    subtitle: const Text(
                      'Set all progress counts to zero',
                      style: TextStyle(color: Colors.grey),
                    ),
                    onTap: () async {
                      await _performReset(context, ref, everything: false);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                    title: const Text('Reset Everything'),
                    subtitle: const Text(
                      'Clear sources, links, and progress',
                      style: TextStyle(color: Colors.grey),
                    ),
                    onTap: () async {
                      await _performReset(context, ref, everything: true);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: Colors.white10),
                  ListTile(
                    leading: Icon(Icons.info_outline_rounded, color: ref.watch(overallProgressColorProvider)),
                    title: const Text('About App'),
                    subtitle: const Text(
                      'Show Info about App, Developer and Repository',
                      style: TextStyle(color: Colors.grey),
                    ),
                    onTap: () {
                      showAboutTrackerDialog(context, ref);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'GATEletics v${packageInfo.version}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
