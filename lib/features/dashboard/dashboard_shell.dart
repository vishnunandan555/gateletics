import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sync_provider.dart';
import '../../providers/subject_provider.dart';
import '../../providers/syllabus_provider.dart';
import 'dashboard_screen.dart';
import 'widgets/focus_screen.dart';
import '../../providers/focus_provider.dart';
import 'widgets/shell_common.dart';
import 'settings_screen.dart';

class DashboardShell extends ConsumerStatefulWidget {
  const DashboardShell({super.key});

  @override
  ConsumerState<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends ConsumerState<DashboardShell> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndInitSync();
      _checkDesktopWarning();
      checkAppVersionUpdate(context, ref);
    });
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 0) {
            ref.read(resourceCategoriesOrderProvider.notifier).clear();
            ref.read(syllabusCategoriesOrderProvider.notifier).clear();
          }
        },
        children: [
          const KeepAliveWrapper(child: DashboardScreen()),
          KeepAliveWrapper(child: FocusScreen(progressColor: progressColor)),
          const KeepAliveWrapper(child: SettingsScreen()),
        ],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: Container(
          height: 64 + MediaQuery.of(context).padding.bottom,
          decoration: BoxDecoration(
            color: const Color(0xFF131316),
            border: Border(
              top: BorderSide(
                color: Colors.white.withAlpha(12),
                width: 1.0,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: Icons.percent_rounded,
                    label: 'Completion',
                    color: progressColor,
                  ),
                  _buildFocusNavItem(
                    index: 1,
                    color: progressColor,
                  ),
                  _buildNavItem(
                    index: 2,
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    color: progressColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () {
        if (index == 0 && _currentIndex != 0) {
          ref.read(resourceCategoriesOrderProvider.notifier).clear();
          ref.read(syllabusCategoriesOrderProvider.notifier).clear();
        }
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 250),
          curve: Curves.fastOutSlowIn,
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? color : Colors.white30,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: isSelected ? color : Colors.white30,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusNavItem({
    required int index,
    required Color color,
  }) {
    final sessionState = ref.watch(focusProvider);
    final isSelected = _currentIndex == index;
    final hasActiveSession = sessionState.status != FocusStatus.idle;

    Color itemColor = isSelected ? color : Colors.white30;
    if (hasActiveSession) {
      if (sessionState.status == FocusStatus.focusing) {
        itemColor = color;
      } else {
        itemColor = Colors.white;
      }
    }

    final isCountUp = sessionState.details.isCountUp;
    final displaySeconds = isCountUp
        ? sessionState.totalSecondsFocused
        : (sessionState.isBreakActive
            ? max(0, sessionState.currentTargetSeconds - sessionState.elapsedSeconds)
            : max(0, sessionState.currentTargetSeconds - sessionState.elapsedSeconds));

    final timeStr = formatNavDuration(displaySeconds, isCountUp);

    return InkWell(
      onTap: () {
        if (index == 0 && _currentIndex != 0) {
          ref.read(resourceCategoriesOrderProvider.notifier).clear();
          ref.read(syllabusCategoriesOrderProvider.notifier).clear();
        }
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 250),
          curve: Curves.fastOutSlowIn,
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.hourglass_empty_rounded,
                color: itemColor,
                size: 26,
              ),
              if (hasActiveSession) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: itemColor, width: 1),
                  ),
                  child: Text(
                    timeStr,
                    style: GoogleFonts.outfit(
                      color: itemColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Focus',
            style: GoogleFonts.outfit(
              color: isSelected ? (hasActiveSession ? itemColor : color) : Colors.white30,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String formatNavDuration(int seconds, bool isCountUp) {
    if (isCountUp) {
      final h = (seconds / 3600).floor();
      final m = ((seconds % 3600) / 60).floor();
      final s = seconds % 60;
      if (h > 0) {
        return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}";
      }
      return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
    } else {
      final m = (seconds / 60).floor();
      final s = seconds % 60;
      return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
    }
  }

  Future<void> _checkDesktopWarning() async {
    // Prompting dialog removed. Auto-routing based on preference / screen size is active.
  }

}
