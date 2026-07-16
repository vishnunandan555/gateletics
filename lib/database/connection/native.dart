import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite3;

QueryExecutor connect({required int schemaVersion}) {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    String targetPath = dbFolder.path;
    if (Platform.isWindows || Platform.isLinux) {
      final appDir = Directory('${dbFolder.path}/gateletics');
      if (!appDir.existsSync()) {
        await appDir.create(recursive: true);
      }
      targetPath = appDir.path;
    }
    final file = File(p.join(targetPath, 'gateletics.db'));

    if (await file.exists()) {
      final database = sqlite3.sqlite3.open(file.path);
      var shouldDelete = false;
      try {
        final result = database.select('PRAGMA user_version;');
        final currentVersion = result.isNotEmpty ? result.first.values.first as int : 0;
        shouldDelete = currentVersion > schemaVersion;
      } finally {
        database.close();
      }

      if (shouldDelete) {
        await _deleteDatabaseFiles(file);
      }
    }

    return NativeDatabase.createInBackground(file);
  });
}

Future<void> _deleteDatabaseFiles(File databaseFile) async {
  final directory = databaseFile.parent;
  final baseName = p.basename(databaseFile.path);
  await for (final entity in directory.list()) {
    if (entity is File && p.basename(entity.path).startsWith(baseName)) {
      await entity.delete();
    }
  }
}
