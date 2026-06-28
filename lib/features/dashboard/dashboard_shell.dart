import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sync_provider.dart';
import '../../providers/subject_provider.dart';
import '../../providers/syllabus_provider.dart';
import 'dashboard_screen.dart';
import 'widgets/focus_screen.dart';
import '../../providers/focus_provider.dart';
import 'widgets/shell_common.dart';
import 'settings_screen.dart';
import '../../providers/package_info_provider.dart';

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
          height: 72,
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
        : (sessionState.status == FocusStatus.breakTime
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
    if (!kIsWeb) return;

    final width = MediaQuery.of(context).size.width;
    if (width <= 600) return;

    final prefs = await SharedPreferences.getInstance();

    // Check version upgrade and time-based expiration
    final packageInfo = ref.read(packageInfoProvider);
    final currentVer = '${packageInfo.version}+${packageInfo.buildNumber}';
    final lastSeenVer = prefs.getString('last_seen_desktop_warning_version');

    final lastSeenTimeMs = prefs.getInt('desktop_warning_seen_time_ms');
    final now = DateTime.now().millisecondsSinceEpoch;

    // 30 days expiration (in milliseconds)
    const thirtyDaysMs = 30 * 24 * 60 * 60 * 1000;

    bool isExpired = false;
    if (lastSeenTimeMs != null && (now - lastSeenTimeMs) > thirtyDaysMs) {
      isExpired = true;
    }

    if (lastSeenVer != currentVer || isExpired) {
      await prefs.setBool('has_seen_desktop_warning', false);
      if (lastSeenVer != currentVer) {
        await prefs.setString('last_seen_desktop_warning_version', currentVer);
      }
    }

    final hasSeenWarning = prefs.getBool('has_seen_desktop_warning') ?? false;

    if (!hasSeenWarning && mounted) {
      _showDesktopWarningDialog();
    }
  }

  Future<void> _markDesktopWarningSeen(SharedPreferences prefs) async {
    final packageInfo = ref.read(packageInfoProvider);
    final currentVer = '${packageInfo.version}+${packageInfo.buildNumber}';
    final now = DateTime.now().millisecondsSinceEpoch;

    await prefs.setBool('has_seen_desktop_warning', true);
    await prefs.setString('last_seen_desktop_warning_version', currentVer);
    await prefs.setInt('desktop_warning_seen_time_ms', now);
  }

  void _showDesktopWarningDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: const Icon(
          Icons.phonelink_setup_rounded,
          color: Colors.cyanAccent,
          size: 32,
        ),
        title: Text(
          "Optimized for Mobile",
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
          textAlign: TextAlign.center,
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "GATEletics is built primarily with a mobile-first user interface. While all features function perfectly on desktop, the visual layout is optimized for narrower aspect ratios.",
                style: GoogleFonts.outfit(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    "We also offer a desktop UI ",
                    style: GoogleFonts.outfit(
                      color: Colors.cyanAccent.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4), width: 1),
                    ),
                    child: Text(
                      'BETA',
                      style: GoogleFonts.outfit(
                        color: Colors.cyanAccent,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Text(
                    " designed for wider screens. Try it for a layout that makes better use of your screen space.",
                    style: GoogleFonts.outfit(
                      color: Colors.cyanAccent.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  final prefs = await SharedPreferences.getInstance();
                  await _markDesktopWarningSeen(prefs);
                  if (mounted) {
                    context.go('/desk');
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.cyanAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "TRY DESKTOP UI",
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.black.withValues(alpha: 0.4), width: 1),
                      ),
                      child: Text(
                        'BETA',
                        style: GoogleFonts.outfit(
                          color: Colors.black,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  final prefs = await SharedPreferences.getInstance();
                  await _markDesktopWarningSeen(prefs);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white54,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  "STAY ON MOBILE UI",
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
