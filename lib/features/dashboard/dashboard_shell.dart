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
import 'widgets/future_feature_screen.dart';
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
          KeepAliveWrapper(child: FutureFeatureScreen(progressColor: progressColor)),
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
                _buildNavItem(
                  index: 1,
                  icon: Icons.auto_awesome_rounded,
                  label: 'Future',
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

  Future<void> _checkDesktopWarning() async {
    if (!kIsWeb) return;

    final width = MediaQuery.of(context).size.width;
    if (width <= 600) return;

    final prefs = await SharedPreferences.getInstance();
    final hasSeenWarning = prefs.getBool('has_seen_desktop_warning') ?? false;

    if (!hasSeenWarning && mounted) {
      _showDesktopWarningDialog();
    }
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
                  await prefs.setBool('has_seen_desktop_warning', true);
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
                  await prefs.setBool('has_seen_desktop_warning', true);
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
