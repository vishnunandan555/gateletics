import 'package:drift/drift.dart';
// ignore: deprecated_member_use
import 'package:drift/web.dart';

QueryExecutor connect({required int schemaVersion}) {
  // ignore: deprecated_member_use
  return WebDatabase('gateletics', logStatements: false);
}
