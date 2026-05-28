import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

QueryExecutor connect() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    String targetPath = dbFolder.path;
    if (Platform.isWindows || Platform.isLinux) {
      final appDir = Directory('${dbFolder.path}/gate_tracker');
      if (!appDir.existsSync()) {
        await appDir.create(recursive: true);
      }
      targetPath = appDir.path;
    }
    final file = File(p.join(targetPath, 'gate_tracker.db'));
    return NativeDatabase.createInBackground(file);
  });
}
