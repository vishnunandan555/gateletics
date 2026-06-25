import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/subject_provider.dart';
import '../../providers/package_info_provider.dart';

void showAboutTrackerDialog(BuildContext context, WidgetRef ref) {
  final size = MediaQuery.of(context).size;
  final accentColor = ref.read(overallProgressColorProvider);
  final packageInfo = ref.read(packageInfoProvider);

  showDialog(
    context: context,
    barrierColor: Colors.black.withAlpha(200),
    builder: (context) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: (size.width * 0.85).clamp(280.0, 420.0),
            maxHeight: size.height * 0.8,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF131316),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withAlpha(12), width: 1.5),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // App Icon squircle (professional, no glow)
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withAlpha(20), width: 1.5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'icon.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // App Title (no shadows)
                    const Center(
                      child: Text(
                        "GATELETICS",
                        style: TextStyle(
                          fontFamily: 'BatmanForever',
                          fontSize: 18,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Version Badge
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white12, width: 1),
                        ),
                        child: Text(
                          "v${packageInfo.version} (Stable)",
                          style: GoogleFonts.outfit(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Clean subtle divider
                    const Divider(color: Colors.white10, height: 16),

                    // App Description
                    Text(
                      "GATE Exam Preparation and Progress Tracking App",
                      style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 13.5,
                        height: 1.55,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    Center(
                      child: Text(
                        "Developed by Vishnu Nandan",
                        style: GoogleFonts.outfit(
                          color: Colors.white54,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Disclaimer text
                    Text(
                      "Disclaimer: GATEletics is an independent educational tool. This app is not affiliated with, authorized by, endorsed by, or associated with the Graduate Aptitude Test in Engineering (GATE) or its official organizing institutes (IISc, IITs, or NCB-GATE).",
                      style: GoogleFonts.outfit(
                        color: Colors.white30,
                        fontSize: 10.5,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // External Links for ToS and Privacy Policy
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () async {
                            final Uri url = Uri.parse('https://github.com/vishnunandan555/gateletics/blob/main/TERMS_OF_SERVICE.md');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            }
                          },
                          style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            "Terms of Service",
                            style: GoogleFonts.outfit(
                              color: Colors.cyanAccent,
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.cyanAccent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "•",
                          style: GoogleFonts.outfit(color: Colors.white24, fontSize: 12),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: () async {
                            final Uri url = Uri.parse('https://github.com/vishnunandan555/gateletics/blob/main/PRIVACY_POLICY.md');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            }
                          },
                          style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            "Privacy Policy",
                            style: GoogleFonts.outfit(
                              color: Colors.cyanAccent,
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.cyanAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        FilledButton(
                          onPressed: () async {
                            final Uri url = Uri.parse('https://github.com/vishnunandan555/gateletics');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Image.asset(
                            'github.png',
                            width: 24,
                            height: 24,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.pop(context),
                            style: FilledButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              "CLOSE",
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
