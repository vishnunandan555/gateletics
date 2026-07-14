import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/subject_provider.dart';
import '../../providers/package_info_provider.dart';
import '../../widgets/settings/about_dialog.dart';
import '../../utils/ui_scaling.dart';

// Modular settings widgets imports
import 'widgets/settings/profile_settings.dart';
import 'widgets/settings/layout_settings.dart';
import 'widgets/settings/sync_settings.dart';
import 'widgets/settings/danger_zone_settings.dart';
import 'widgets/settings/customization_settings.dart';
import 'widgets/settings/timer_settings.dart';
import 'widgets/settings/advanced_beta_settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packageInfo = ref.watch(packageInfoProvider);
    final accentColor = ref.watch(overallProgressColorProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth > 900;

    final titleStyle = GoogleFonts.outfit(
      color: Colors.white,
      fontSize: context.s(13),
      fontWeight: FontWeight.bold,
    );

    final subtitleStyle = GoogleFonts.outfit(
      color: Colors.white30,
      fontSize: context.s(11),
    );

    Widget buildHeader(String title, {Color? color}) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: context.s(16), vertical: context.s(8)),
        child: Text(
          title,
          style: TextStyle(
            color: (color ?? accentColor).withValues(alpha: 0.7),
            fontWeight: FontWeight.bold,
            fontSize: context.s(11),
            letterSpacing: context.s(1.2),
          ),
        ),
      );
    }

    Widget buildSettingsGroup(Widget child) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: context.s(16), vertical: context.s(6)),
        decoration: BoxDecoration(
          color: const Color(0xFF131316),
          borderRadius: BorderRadius.circular(context.s(16)),
          border: Border.all(color: Colors.white.withAlpha(8)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(context.s(16)),
          child: Material(
            color: Colors.transparent,
            child: child,
          ),
        ),
      );
    }

    final cloudSyncHeader = buildHeader('CLOUD SYNC');
    final cloudSyncContent = SyncSettingsSection(
      titleStyle: titleStyle,
      subtitleStyle: subtitleStyle,
      accentColor: accentColor,
    );

    final profileSettingsHeader = buildHeader('PROFILE SETTINGS');
    final profileSettingsContent = buildSettingsGroup(
      ProfileSettingsSection(
        titleStyle: titleStyle,
        subtitleStyle: subtitleStyle,
        accentColor: accentColor,
      ),
    );

    final uiSwitchHeader = buildHeader('LAYOUT');
    final uiSwitchContent = buildSettingsGroup(
      LayoutSettingsSection(
        titleStyle: titleStyle,
        subtitleStyle: subtitleStyle,
      ),
    );

    final appSettingsHeader = buildHeader('TIMER & SYLLABUS GOALS');
    final appSettingsContent = buildSettingsGroup(
      TimerSettingsSection(
        titleStyle: titleStyle,
        subtitleStyle: subtitleStyle,
        accentColor: accentColor,
      ),
    );

    final customizationSettingsHeader = buildHeader('CUSTOMIZATION');
    final customizationSettingsContent = buildSettingsGroup(
      CustomizationSettingsSection(
        titleStyle: titleStyle,
        subtitleStyle: subtitleStyle,
        accentColor: accentColor,
      ),
    );

    final localBackupsHeader = buildHeader('LOCAL BACKUPS & DATA');
    final localBackupsContent = buildSettingsGroup(
      DangerZoneSettingsSection(
        titleStyle: titleStyle,
        subtitleStyle: subtitleStyle,
        accentColor: accentColor,
      ),
    );

    final aboutAppContent = ListTile(
      leading: Icon(Icons.info_outline_rounded, color: accentColor),
      title: Text('About GATEletics', style: titleStyle),
      subtitle: Text(
        'View app details, credits, developer info, and source code',
        style: subtitleStyle,
      ),
      onTap: () {
        showAboutTrackerDialog(context, ref);
      },
    );

    final systemOptionsHeader = buildHeader('ADVANCED');
    final systemOptionsContent = buildSettingsGroup(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          aboutAppContent,
          const Divider(color: Colors.white10, height: 1),
          AdvancedSettingsSection(
            titleStyle: titleStyle,
            subtitleStyle: subtitleStyle,
            accentColor: accentColor,
          ),
          const Divider(color: Colors.white10, height: 1),
          BetaSettingsSection(
            titleStyle: titleStyle,
            subtitleStyle: subtitleStyle,
            accentColor: accentColor,
          ),
        ],
      ),
    );

    final versionText = Center(
      child: Text(
        'GATEletics v${packageInfo.version}',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.3),
          fontSize: 10,
        ),
      ),
    );

    return Theme(
      data: Theme.of(context).copyWith(
        listTileTheme: ListTileThemeData(
          dense: true,
          titleTextStyle: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: context.s(13),
            fontWeight: FontWeight.bold,
          ),
          subtitleTextStyle: GoogleFonts.outfit(
            color: Colors.white30,
            fontSize: context.s(11),
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'SETTINGS',
            style: GoogleFonts.orbitron(
              fontSize: context.s(20),
              fontWeight: FontWeight.w900,
              letterSpacing: context.s(1.5),
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: isDesktop
              ? SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                cloudSyncHeader,
                                cloudSyncContent,
                                const SizedBox(height: 12),
                                profileSettingsHeader,
                                profileSettingsContent,
                                if ((kIsWeb || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux) &&
                                    defaultTargetPlatform != TargetPlatform.android &&
                                    defaultTargetPlatform != TargetPlatform.iOS) ...[
                                  const SizedBox(height: 12),
                                  uiSwitchHeader,
                                  uiSwitchContent,
                                ],
                                const SizedBox(height: 12),
                                localBackupsHeader,
                                localBackupsContent,
                                const SizedBox(height: 12),
                                systemOptionsHeader,
                                systemOptionsContent,
                              ],
                            ),
                          ),
                          const SizedBox(width: 32),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                appSettingsHeader,
                                appSettingsContent,
                                const SizedBox(height: 12),
                                customizationSettingsHeader,
                                customizationSettingsContent,
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 12),
                      versionText,
                      const SizedBox(height: 16),
                    ],
                  ),
                )
              : ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: context.s(16), vertical: context.s(8)),
                  children: [
                    cloudSyncHeader,
                    cloudSyncContent,
                    profileSettingsHeader,
                    profileSettingsContent,
                    if ((kIsWeb || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux) &&
                        defaultTargetPlatform != TargetPlatform.android &&
                        defaultTargetPlatform != TargetPlatform.iOS) ...[
                      uiSwitchHeader,
                      uiSwitchContent,
                    ],
                    appSettingsHeader,
                    appSettingsContent,
                    customizationSettingsHeader,
                    customizationSettingsContent,
                    localBackupsHeader,
                    localBackupsContent,
                    systemOptionsHeader,
                    systemOptionsContent,
                    SizedBox(height: context.s(12)),
                    versionText,
                    SizedBox(height: context.s(16)),
                  ],
                ),
        ),
      ),
    );
  }
}
