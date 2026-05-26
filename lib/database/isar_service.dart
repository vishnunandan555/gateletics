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
      _subject(
        'Engineering Mathematics',
        'Mathematical Foundation',
        111,
        'https://www.goclasses.in/courses/Engineering-Mathematics-60fdd8530cf2c7989e1f109d#tableofcontents',
      ),
      _subject(
        'Discrete Mathematics',
        'Mathematical Foundation',
        550,
        'https://www.goclasses.in/courses/Discrete-Mathematics-Course-63f9aa9be4b0a8a370cfb0ad#tableofcontents',
      ),
      _subject('C Programming', 'Programming Foundation', 0, ''),
      _subject('Data Structures', 'Programming Foundation', 0, ''),
      _subject('Algorithms', 'Programming Foundation', 0, ''),
      _subject('Digital Logic', 'System Depth', 0, ''),
      _subject(
        'COA',
        'System Depth',
        70,
        'https://www.youtube.com/playlist?list=PLG9aCp4uE-s0xddCBjwMDnEVyc523WbA2',
      ),
      _subject(
        'Operating Systems',
        'System Depth',
        62,
        'https://www.youtube.com/playlist?list=PLG9aCp4uE-s17rFjWM8KchGlffXgOzzVP',
      ),
      _subject(
        'DBMS',
        'Rest of the Stuff',
        225,
        'https://www.youtube.com/playlist?list=PLC36xJgs4dxGcz7nZaxGxxmbJrcgDXhFk',
      ),
      _subject('Computer Networks', 'Rest of the Stuff', 0, ''),
      _subject(
        'Theory of Computation',
        'Rest of the Stuff',
        157,
        'https://www.youtube.com/playlist?list=PLC36xJgs4dxGvebewU4z2CZYo-8nB93E7',
      ),
      _subject('GATE Apti', 'Rest of the Stuff', 0, ''),
      _subject('Compiler Design', 'Rest of the Stuff', 0, ''),
    ];

    await isar.writeTxn(() async {
      await isar.subjects.putAll(defaults);
    });
  }

  Subject _subject(String name, String category, int total, String link) {
    return Subject()
      ..name = name
      ..category = category
      ..totalVideos = total
      ..playlistLink = link;
  }

  // Migrates existing data to match current subject definitions
  Future<void> _runMigration(Isar isar) async {
    const targetData = {
      'Engineering Mathematics': (
        total: 111,
        link:
            'https://www.goclasses.in/courses/Engineering-Mathematics-60fdd8530cf2c7989e1f109d#tableofcontents',
      ),
      'Discrete Mathematics': (
        total: 550,
        link:
            'https://www.goclasses.in/courses/Discrete-Mathematics-Course-63f9aa9be4b0a8a370cfb0ad#tableofcontents',
      ),
      'COA': (
        total: 70,
        link:
            'https://www.youtube.com/playlist?list=PLG9aCp4uE-s0xddCBjwMDnEVyc523WbA2',
      ),
      'Operating Systems': (
        total: 62,
        link:
            'https://www.youtube.com/playlist?list=PLG9aCp4uE-s17rFjWM8KchGlffXgOzzVP',
      ),
      'DBMS': (
        total: 225,
        link:
            'https://www.youtube.com/playlist?list=PLC36xJgs4dxGcz7nZaxGxxmbJrcgDXhFk',
      ),
      'Theory of Computation': (
        total: 157,
        link:
            'https://www.youtube.com/playlist?list=PLC36xJgs4dxGvebewU4z2CZYo-8nB93E7',
      ),
    };

    await isar.writeTxn(() async {
      final all = await isar.subjects.where().findAll();
      final toUpdate = <Subject>[];

      for (final s in all) {
        final target = targetData[s.name];
        if (target != null) {
          if (s.totalVideos != target.total || s.playlistLink != target.link) {
            s.totalVideos = target.total;
            s.playlistLink = target.link;
            toUpdate.add(s);
          }
        } else if (s.totalVideos != 0) {
          s.totalVideos = 0;
          s.playlistLink = '';
          toUpdate.add(s);
        }
      }

      if (toUpdate.isNotEmpty) {
        await isar.subjects.putAll(toUpdate);
      }
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
