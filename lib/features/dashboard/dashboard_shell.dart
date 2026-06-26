import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progressColor = ref.watch(overallProgressColorProvider);

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
