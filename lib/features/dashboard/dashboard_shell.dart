import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sync_provider.dart';
import '../../providers/subject_provider.dart';
import '../../providers/notice_board_provider.dart';
import 'dashboard_screen.dart';
import 'home_screen.dart';
import 'progress_history_screen.dart';
import 'widgets/focus_screen.dart';
import '../../providers/focus_provider.dart';
import 'widgets/shell_common.dart';
import 'settings_screen.dart';
import 'widgets/app_bar_title.dart';
import 'widgets/countdown_widget.dart';
import '../../providers/overall_ui_scale_provider.dart';
import '../../providers/syllabus_provider.dart';

class DashboardShell extends ConsumerStatefulWidget {
  const DashboardShell({super.key});

  @override
  ConsumerState<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends ConsumerState<DashboardShell> {
  late PageController _pageController;
  int _currentIndex = 2;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 2);
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

    final overallScale = ref.watch(overallUiScaleProvider).scaleFactor;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(overallScale),
      ),
      child: Scaffold(
        body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
              if (index != 2) {
                ref.read(noticeBoardModeProvider.notifier).state = false;
              }
              ref.read(syllabusCategoriesOrderProvider.notifier).clear();
              ref.read(syncProvider.notifier).syncIfPending();
            },
            children: [
              const KeepAliveWrapper(child: ProgressHistoryScreen()),
              const KeepAliveWrapper(child: DashboardScreen()),
              KeepAliveWrapper(child: HomeScreen(shellPageController: _pageController)),
              KeepAliveWrapper(child: FocusScreen(progressColor: progressColor)),
              const KeepAliveWrapper(child: SettingsScreen()),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _SharedShellHeader(
              pageController: _pageController,
              currentIndex: _currentIndex,
            ),
          ),
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
              padding: const EdgeInsets.only(top: 0.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: Icons.analytics_rounded,
                    label: 'Stats',
                    color: progressColor,
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.percent_rounded,
                    label: 'Completion',
                    color: progressColor,
                  ),
                  _buildNavItem(
                    index: 2,
                    icon: Icons.home_rounded,
                    label: 'Home',
                    color: progressColor,
                  ),
                  _buildFocusNavItem(
                    index: 3,
                    color: progressColor,
                  ),
                  _buildNavItem(
                    index: 4,
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
    return Expanded(
      child: InkWell(
        onTap: () {
          _pageController.jumpToPage(index);
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

    return Expanded(
      child: InkWell(
        onTap: () {
          _pageController.jumpToPage(index);
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

class _SharedShellHeader extends ConsumerWidget {
  final PageController pageController;
  final int currentIndex;

  const _SharedShellHeader({
    required this.pageController,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPadding = MediaQuery.of(context).padding.top;
    final isScrolled = ref.watch(completionIsScrolledProvider);

    return AnimatedBuilder(
      animation: pageController,
      builder: (context, child) {
        double page = 0.0;
        if (pageController.hasClients && pageController.position.hasContentDimensions) {
          page = pageController.page ?? 0.0;
        } else {
          page = currentIndex.toDouble();
        }

        // Header opacity: 0.0 at page 0 (Stats), 1.0 at page 1 (Completion) and page 2 (Home), 0.0 at page 3 (Focus) and page 4 (Settings)
        double headerOpacity = 0.0;
        if (page <= 1.0) {
          headerOpacity = page.clamp(0.0, 1.0);
        } else if (page > 1.0 && page <= 2.0) {
          headerOpacity = 1.0;
        } else if (page > 2.0 && page <= 3.0) {
          headerOpacity = (3.0 - page).clamp(0.0, 1.0);
        }

        // Background transition from transparent to solid black when scrolled down in Completion screen (page 1)
        Color headerBgColor = Colors.transparent;
        if (isScrolled) {
          if (page <= 1.0) {
            headerBgColor = Colors.black.withValues(alpha: page.clamp(0.0, 1.0));
          } else if (page > 1.0 && page <= 2.0) {
            headerBgColor = Colors.black.withValues(alpha: (2.0 - page).clamp(0.0, 1.0));
          }
        }

        // Countdown widget opacity: 0.0 at page 0 (Stats), 1.0 at page 1 (Completion), 0.0 at page 2 (Home) and page 3+
        double countdownOpacity = 0.0;
        if (page <= 1.0) {
          countdownOpacity = page.clamp(0.0, 1.0);
        } else if (page > 1.0 && page <= 2.0) {
          countdownOpacity = (2.0 - page).clamp(0.0, 1.0);
        }

        // Notice Board button opacity: 1.0 at page 2 (Home), 0.0 at page 1 (Completion) and page 3 (Focus)
        double noticeBoardOpacity = 0.0;
        if (page > 1.0 && page <= 2.0) {
          noticeBoardOpacity = (page - 1.0).clamp(0.0, 1.0);
        } else if (page > 2.0 && page <= 3.0) {
          noticeBoardOpacity = (3.0 - page).clamp(0.0, 1.0);
        }

        final ignorePointer = headerOpacity < 0.5;

        return IgnorePointer(
          ignoring: ignorePointer,
          child: Opacity(
            opacity: headerOpacity,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 72 + topPadding,
              padding: EdgeInsets.fromLTRB(20, topPadding, 20, 0),
              color: headerBgColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AppBarTitle(
                    onTap: () {
                      pageController.animateToPage(
                        1, // Navigate to Completion screen (index 1)
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.fastOutSlowIn,
                      );
                    },
                  ),
                  Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      IgnorePointer(
                        ignoring: countdownOpacity < 0.5,
                        child: Opacity(
                          opacity: countdownOpacity,
                          child: const CountdownWidget(),
                        ),
                      ),
                      IgnorePointer(
                        ignoring: noticeBoardOpacity < 0.5,
                        child: Opacity(
                          opacity: noticeBoardOpacity,
                          child: const _NoticeBoardHeaderButton(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NoticeBoardHeaderButton extends ConsumerWidget {
  const _NoticeBoardHeaderButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isNoticeBoard = ref.watch(noticeBoardModeProvider);
    final accentColor = ref.watch(overallProgressColorProvider);
    final tasks = ref.watch(customTasksProvider).value ?? [];

    Widget iconWidget;
    if (isNoticeBoard) {
      iconWidget = const Icon(
        Icons.close_rounded,
        color: Colors.white60,
        size: 24,
      );
    } else if (tasks.isNotEmpty) {
      iconWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.assignment_outlined, color: accentColor, size: 32),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              "${tasks.length}",
              style: GoogleFonts.orbitron(
                color: Colors.black,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    } else {
      iconWidget = Icon(
        Icons.assignment_outlined,
        color: accentColor,
        size: 28,
      );
    }

    return Material(
      color: Colors.transparent,
      child: IconButton(
        icon: iconWidget,
        onPressed: () {
          ref.read(noticeBoardModeProvider.notifier).state = !isNoticeBoard;
        },
        tooltip: isNoticeBoard ? 'Back to Dashboard' : 'Open Notice Board',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        splashRadius: 20,
      ),
    );
  }
}
