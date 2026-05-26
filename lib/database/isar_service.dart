import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'models/subject.dart';

class IsarService {
  static final IsarService _instance = IsarService._internal();
  factory IsarService() => _instance;
  IsarService._internal();

  Isar? _db;
  // Guards against concurrent calls to _initDB
  Completer<Isar>? _initCompleter;

  Future<Isar> get db async {
    if (_db != null) return _db!;
    if (_initCompleter != null) return _initCompleter!.future;
    _initCompleter = Completer<Isar>();
    try {
      _db = await _initDB();
      _initCompleter!.complete(_db!);
    } catch (e, st) {
      _initCompleter!.completeError(e, st);
      _initCompleter = null;
      rethrow;
    }
    return _db!;
  }

  Future<Isar> _initDB() async {
    final dir = await getApplicationDocumentsDirectory();
    if (Isar.instanceNames.isEmpty) {
      Isar isar;
      try {
        isar = await Isar.open(
          [SubjectSchema],
          directory: dir.path,
          inspector: kDebugMode,
        );
      } catch (e) {
        debugPrint('Isar initialization failed ($e). Recreating database...');
        try {
          final dbDir = Directory(dir.path);
          if (dbDir.existsSync()) {
            final files = dbDir.listSync();
            for (final file in files) {
              if (file is File &&
                  (file.path.endsWith('.isar') || file.path.contains('isar'))) {
                file.deleteSync();
              }
            }
          }
        } catch (delErr) {
          debugPrint('Failed to delete old Isar files: $delErr');
        }
        // Retry opening a fresh instance
        isar = await Isar.open(
          [SubjectSchema],
          directory: dir.path,
          inspector: kDebugMode,
        );
      }
      await _initializeDefaultSubjects(isar);
      await _runMigration(isar);
      return isar;
    }
    return Isar.getInstance()!;
  }

  // Seed only runs when the DB is empty (first install)
  Future<void> _initializeDefaultSubjects(Isar isar) async {
    final count = await isar.subjects.count();
    if (count > 0) return;

    final defaults = [
      _subject('Engineering Mathematics', Subject.categories[0]),
      _subject('Discrete Mathematics', Subject.categories[0]),
      _subject('C Programming', Subject.categories[1]),
      _subject('Data Structures', Subject.categories[1]),
      _subject('Algorithms', Subject.categories[1]),
      _subject('Digital Logic', Subject.categories[2]),
      _subject('COA', Subject.categories[2]),
      _subject('Operating Systems', Subject.categories[2]),
      _subject('DBMS', Subject.categories[3]),
      _subject('Computer Networks', Subject.categories[3]),
      _subject('Theory of Computation', Subject.categories[3]),
      _subject('GATE Apti', Subject.categories[3]),
      _subject('Compiler Design', Subject.categories[3]),
    ];

    await isar.writeTxn(() async {
      await isar.subjects.putAll(defaults);
    });
  }

  Subject _subject(String name, String category) {
    return Subject()
      ..name = name
      ..category = category
      ..totalVideos = 0
      ..playlistLink = ''
      ..sourceName = 'Source'
      ..isActive = false;
  }

  Future<void> resetTrackingData() async {
    final isar = await db;
    await isar.writeTxn(() async {
      final all = await isar.subjects.where().findAll();
      for (final s in all) {
        s.completedVideos = 0;
      }
      await isar.subjects.putAll(all);
    });
  }

  Future<void> hardResetEverything() async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.subjects.clear();
    });
    // This will seed the empty DB back to original empty-subject state
    await _initializeDefaultSubjects(isar);
  }

  Future<void> applyDefaultPreset() async {
    final isar = await db;
    final preset = {
      'Engineering Mathematics': (
        total: 111,
        link:
            'https://www.goclasses.in/courses/Engineering-Mathematics-60fdd8530cf2c7989e1f109d#tableofcontents',
        source: 'GoClasses',
      ),
      'Discrete Mathematics': (
        total: 550,
        link:
            'https://www.goclasses.in/courses/Discrete-Mathematics-Course-63f9aa9be4b0a8a370cfb0ad#tableofcontents',
        source: 'GoClasses',
      ),
      'COA': (
        total: 70,
        link:
            'https://www.youtube.com/playlist?list=PLG9aCp4uE-s0xddCBjwMDnEVyc523WbA2',
        source: 'YouTube',
      ),
      'Operating Systems': (
        total: 62,
        link:
            'https://www.youtube.com/playlist?list=PLG9aCp4uE-s17rFjWM8KchGlffXgOzzVP',
        source: 'YouTube',
      ),
      'DBMS': (
        total: 225,
        link:
            'https://www.youtube.com/playlist?list=PLC36xJgs4dxGcz7nZaxGxxmbJrcgDXhFk',
        source: 'YouTube',
      ),
      'Theory of Computation': (
        total: 157,
        link:
            'https://www.youtube.com/playlist?list=PLC36xJgs4dxGvebewU4z2CZYo-8nB93E7',
        source: 'YouTube',
      ),
    };

    await isar.writeTxn(() async {
      final all = await isar.subjects.where().findAll();
      for (final s in all) {
        final data = preset[s.name];
        if (data != null) {
          s.totalVideos = data.total;
          s.playlistLink = data.link;
          s.sourceName = data.source;
          s.isActive = true;
        }
      }
      await isar.subjects.putAll(all);
    });
  }

  // Migrates existing data to match current subject definitions
  Future<void> _runMigration(Isar isar) async {
    await isar.writeTxn(() async {
      final all = await isar.subjects.where().findAll();
      for (final s in all) {
        // Isar handles basic type defaults, but we can nudge them if needed.
        if (s.sourceName.isEmpty) {
          s.sourceName = 'Source';
        }
      }
      await isar.subjects.putAll(all);
    });
  }

  Stream<List<Subject>> listenToSubjects() async* {
    final isar = await db;
    yield* isar.subjects.where().watch(fireImmediately: true);
  }

  Future<void> updateSubject(Subject subject) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.subjects.put(subject);
    });
  }
}
