import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../providers/sync_provider.dart';
import '../../../providers/package_info_provider.dart';

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

void showSyncConflictDialog(BuildContext context, WidgetRef ref, Color accentColor) {
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
            _SyncDialogOption(
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
            _SyncDialogOption(
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
            _SyncDialogOption(
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

class _SyncDialogOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SyncDialogOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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

Future<void> checkAppVersionUpdate(BuildContext context, WidgetRef ref) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final packageInfo = ref.read(packageInfoProvider);
    final currentVer = '${packageInfo.version}+${packageInfo.buildNumber}';
    final lastKnownVer = prefs.getString('last_known_app_version');

    if (lastKnownVer != null && lastKnownVer != currentVer) {
      if (context.mounted) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        final useWidth = screenWidth > 600;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF18181B),
            behavior: SnackBarBehavior.floating,
            width: useWidth ? 400 : null,
            margin: useWidth ? null : const EdgeInsets.all(16),
            duration: const Duration(seconds: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.white.withAlpha(20), width: 1),
            ),
            content: Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.cyanAccent,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "GATEletics updated to v${packageInfo.version}",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(30, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    "OK",
                    style: GoogleFonts.outfit(
                      color: Colors.cyanAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: "CHANGELOG",
              textColor: Colors.cyanAccent,
              onPressed: () async {
                final Uri url = Uri.parse('https://github.com/vishnunandan555/gateletics/releases');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ),
        );
      }
    }

    // Always update to current version to prevent duplicate updates or loops
    await prefs.setString('last_known_app_version', currentVer);
  } catch (e) {
    debugPrint("Error checking app version update: $e");
  }
}
