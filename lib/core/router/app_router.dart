import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../../features/dashboard/dashboard_shell.dart';
import '../../features/desk/desk_dashboard_shell.dart';
import 'route_resolver.dart';

final appRouter = GoRouter(
  initialLocation: resolveInitialRoute(),
  redirect: (context, state) {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      if (state.uri.path.startsWith('/desk')) {
        return '/';
      }
    }
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const DashboardShell()),
    GoRoute(path: '/desk', builder: (context, state) => const DeskDashboardShell()),
  ],
);
