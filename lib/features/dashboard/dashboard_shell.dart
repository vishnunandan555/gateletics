import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sync_provider.dart';
import '../../providers/subject_provider.dart';
import '../../providers/syllabus_provider.dart';
import 'dashboard_screen.dart';
import 'widgets/future_feature_screen.dart';
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
        _showSyncConflictDialog(context, ref, progressColor);
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

  void _showSyncConflictDialog(BuildContext context, WidgetRef ref, Color accentColor) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Sync Conflict Detected",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Both your local device and cloud backup contain study tracking progress. How would you like to resolve this conflict?",
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 20),
              _buildDialogOption(
                context: context,
                title: "Merge Progress (Recommended)",
                subtitle: "Combine local and cloud progress (no data lost)",
                icon: Icons.merge_type_rounded,
                color: Colors.cyanAccent,
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(syncProvider.notifier).mergeCloudAndLocal();
                },
              ),
              const SizedBox(height: 12),
              _buildDialogOption(
                context: context,
                title: "Use Cloud Backup",
                subtitle: "Overwrite local data with your cloud backup",
                icon: Icons.cloud_download_rounded,
                color: Colors.greenAccent,
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(syncProvider.notifier).downloadCloudToLocal();
                },
              ),
              const SizedBox(height: 12),
              _buildDialogOption(
                context: context,
                title: "Keep Local Progress",
                subtitle: "Overwrite cloud data with your local progress",
                icon: Icons.cloud_upload_rounded,
                color: Colors.orangeAccent,
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(syncProvider.notifier).uploadLocalToCloud();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(8)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      color: Colors.white30,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class KeepAliveWrapper extends StatefulWidget {
  final Widget child;

  const KeepAliveWrapper({super.key, required this.child});

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}
