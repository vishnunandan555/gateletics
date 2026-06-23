import 'package:go_router/go_router.dart';
import '../../features/dashboard/dashboard_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const DashboardShell()),
  ],
);
