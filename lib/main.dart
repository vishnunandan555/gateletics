import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'database/app_database.dart';
import 'providers/subject_provider.dart';
import 'providers/agreement_provider.dart';
import 'providers/setup_provider.dart';
import 'features/dashboard/widgets/agreement_screen.dart';
import 'features/dashboard/widgets/setup_screen.dart';

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
    final agreementAsync = ref.watch(agreementProvider);
    final setupAsync = ref.watch(setupCompletedProvider);

    if (agreementAsync.isLoading || setupAsync.isLoading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFF09090B),
          body: Center(
            child: CircularProgressIndicator(color: Colors.cyanAccent),
          ),
        ),
      );
    }

    if (agreementAsync.hasError || setupAsync.hasError) {
      final error = agreementAsync.error ?? setupAsync.error;
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Text('Initialization Error: $error'),
          ),
        ),
      );
    }

    final hasAgreed = agreementAsync.value ?? false;
    final hasSetup = setupAsync.value ?? false;

    if (!hasAgreed) {
      return MaterialApp(
        title: 'GATE Tracker',
        theme: AppTheme.darkTheme,
        home: const AgreementScreen(),
        debugShowCheckedModeBanner: false,
      );
    }

    if (!hasSetup) {
      return MaterialApp(
        title: 'GATE Tracker',
        theme: AppTheme.darkTheme,
        home: const SetupScreen(),
        debugShowCheckedModeBanner: false,
      );
    }

    return MaterialApp.router(
      title: 'GATE Tracker',
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
