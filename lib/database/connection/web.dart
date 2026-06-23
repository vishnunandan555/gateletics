import 'package:drift/drift.dart';
import 'package:drift/web.dart';

QueryExecutor connect({required int schemaVersion}) {
  return WebDatabase('gate_tracker', logStatements: false);
}
