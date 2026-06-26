import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'database/app_database.dart';
import 'providers/subject_provider.dart';
import 'providers/agreement_provider.dart';
import 'providers/setup_provider.dart';
import 'providers/auth_provider.dart';
import 'features/dashboard/widgets/agreement_screen.dart';
import 'features/dashboard/widgets/auth_screen.dart';
import 'features/dashboard/widgets/setup_screen.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'providers/package_info_provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (isFirebaseSupported()) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint("Firebase initialization failed: $e");
    }
  }

  final packageInfo = await PackageInfo.fromPlatform();
  final appDb = AppDatabase();

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(appDb),
        packageInfoProvider.overrideWithValue(packageInfo),
      ],
      child: const GateTrackerApp(),
    ),
  );
}

class GateTrackerApp extends ConsumerWidget {
  const GateTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agreementAsync = ref.watch(agreementProvider);
    final authAsync = ref.watch(authProvider);
    final setupAsync = ref.watch(setupCompletedProvider);

    if (agreementAsync.isLoading || authAsync.isLoading || setupAsync.isLoading) {
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

    if (agreementAsync.hasError || authAsync.hasError || setupAsync.hasError) {
      final error = agreementAsync.error ?? authAsync.error ?? setupAsync.error;
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
    final authState = authAsync.value;
    final hasSetup = setupAsync.value ?? false;

    if (!hasAgreed) {
      return MaterialApp(
        title: 'GATEletics',
        theme: AppTheme.darkTheme,
        home: const AgreementScreen(),
        debugShowCheckedModeBanner: false,
      );
    }

    if (authState != null && !authState.isOfflineMode && authState.user == null) {
      return MaterialApp(
        title: 'GATEletics',
        theme: AppTheme.darkTheme,
        home: const AuthScreen(),
        debugShowCheckedModeBanner: false,
      );
    }

    if (!hasSetup) {
      return MaterialApp(
        title: 'GATEletics',
        theme: AppTheme.darkTheme,
        home: const SetupScreen(),
        debugShowCheckedModeBanner: false,
      );
    }

    return MaterialApp.router(
      title: 'GATEletics',
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
