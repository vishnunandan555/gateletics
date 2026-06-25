import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'database/app_database.dart';
import 'providers/subject_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appDb = AppDatabase();

  runApp(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(appDb)],
      child: const GateTrackerApp(),
    ),
  );
}

class GateTrackerApp extends ConsumerWidget {
  const GateTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'GATE Tracker',
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
