import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sync_provider.dart';
import '../../providers/subject_provider.dart';
import '../../providers/syllabus_provider.dart';
import '../dashboard/settings_screen.dart';
import '../dashboard/widgets/future_feature_screen.dart';
import '../dashboard/widgets/shell_common.dart';
import 'desk_dashboard_screen.dart';

class DeskDashboardShell extends ConsumerStatefulWidget {
  const DeskDashboardShell({super.key});

  @override
  ConsumerState<DeskDashboardShell> createState() => _DeskDashboardShellState();
}

class _DeskDashboardShellState extends ConsumerState<DeskDashboardShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndInitSync());
  }

  void _checkAndInitSync() {
    final authState = ref.read(authProvider).value;
    if (authState != null && authState.user != null) {
      final syncState = ref.read(syncProvider);
      if (syncState.status == SyncStatus.idle) {
        ref.read(syncProvider.notifier).initializeSync();
      }
    }
  }

  void _onTabSelected(int index) {
    if (index == 0 && _currentIndex != 0) {
      ref.read(resourceCategoriesOrderProvider.notifier).clear();
      ref.read(syllabusCategoriesOrderProvider.notifier).clear();
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final progressColor = ref.watch(overallProgressColorProvider);

    ref.listen<SyncState>(syncProvider, (previous, next) {
      if (next.status == SyncStatus.requiresAction && next.pendingCloudData != null) {
        showSyncConflictDialog(context, ref, progressColor);
      }
    });

    return Scaffold(
      body: Row(
        children: [
          _DeskSidebar(
            currentIndex: _currentIndex,
            progressColor: progressColor,
            onTabSelected: _onTabSelected,
            onMobileUiTap: () => context.go('/'),
          ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                const KeepAliveWrapper(child: DeskDashboardScreen()),
                KeepAliveWrapper(child: FutureFeatureScreen(progressColor: progressColor)),
                const KeepAliveWrapper(child: SettingsScreen()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeskSidebar extends StatelessWidget {
  final int currentIndex;
  final Color progressColor;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onMobileUiTap;

  const _DeskSidebar({
    required this.currentIndex,
    required this.progressColor,
    required this.onTabSelected,
    required this.onMobileUiTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 768;

    return Container(
      width: isCompact ? 76 : 220,
      decoration: BoxDecoration(
        color: const Color(0xFF131316),
        border: Border(
          right: BorderSide(color: Colors.white.withAlpha(12)),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: isCompact
                ? const EdgeInsets.symmetric(vertical: 24)
                : const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: Row(
              mainAxisAlignment: isCompact ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(Icons.school_rounded, color: progressColor, size: 28),
                if (!isCompact) ...[
                  const SizedBox(width: 10),
                  Text(
                    'GATEletics',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _SidebarNavItem(
            index: 0,
            currentIndex: currentIndex,
            icon: Icons.percent_rounded,
            label: 'Completion',
            color: progressColor,
            isCompact: isCompact,
            onTap: onTabSelected,
          ),
          _SidebarNavItem(
            index: 1,
            currentIndex: currentIndex,
            icon: Icons.auto_awesome_rounded,
            label: 'Future',
            color: progressColor,
            isCompact: isCompact,
            onTap: onTabSelected,
          ),
          _SidebarNavItem(
            index: 2,
            currentIndex: currentIndex,
            icon: Icons.settings_rounded,
            label: 'Settings',
            color: progressColor,
            isCompact: isCompact,
            onTap: onTabSelected,
          ),
          const Spacer(),
          Padding(
            padding: isCompact
                ? const EdgeInsets.fromLTRB(8, 0, 8, 24)
                : const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: InkWell(
              onTap: onMobileUiTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: isCompact
                    ? const EdgeInsets.symmetric(vertical: 12)
                    : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withAlpha(8)),
                ),
                child: Row(
                  mainAxisAlignment: isCompact ? MainAxisAlignment.center : MainAxisAlignment.start,
                  children: [
                    Icon(Icons.phone_android_rounded, color: Colors.white38, size: 18),
                    if (!isCompact) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Mobile UI',
                          style: GoogleFonts.outfit(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward_rounded, color: Colors.white24, size: 16),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final String label;
  final Color color;
  final bool isCompact;
  final ValueChanged<int> onTap;

  const _SidebarNavItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.label,
    required this.color,
    required this.isCompact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentIndex == index;
    return Padding(
      padding: isCompact
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: isCompact
                ? const EdgeInsets.symmetric(vertical: 14)
                : const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? color.withAlpha(25) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: color.withAlpha(60))
                  : null,
            ),
            child: Row(
              mainAxisAlignment: isCompact ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color: isSelected ? color : Colors.white30,
                  size: 22,
                ),
                if (!isCompact) ...[
                  const SizedBox(width: 14),
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      color: isSelected ? color : Colors.white30,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
