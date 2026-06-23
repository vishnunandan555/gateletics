import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/subject_provider.dart';

void showAboutTrackerDialog(BuildContext context, WidgetRef ref) {
  final size = MediaQuery.of(context).size;
  final accentColor = ref.read(overallProgressColorProvider);

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
                          color: accentColor.withAlpha(15),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: accentColor.withAlpha(50), width: 1.5),
                        ),
                        child: Icon(
                          Icons.track_changes_rounded,
                          color: accentColor,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // App Title (no shadows)
                    const Center(
                      child: Text(
                        "GATE TRACKER",
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
                          "v1.0.0 (Stable)",
                          style: GoogleFonts.outfit(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Clean subtle divider
                    const Divider(color: Colors.white10, height: 32),

                    // App Description
                    Text(
                      "A syllabus tracker for tracking syllabus completion of GATE Exam.",
                      style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 13.5,
                        height: 1.55,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),

                    // Creator Profile Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withAlpha(8)),
                      ),
                      child: Row(
                        children: [
                          // Initial avatar (clean, no glow)
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(8),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white12, width: 1),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "VN",
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "DEVELOPED BY",
                                  style: GoogleFonts.outfit(
                                    color: Colors.white30,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Vishnu Nandan",
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  "Lead Architect & Developer",
                                  style: GoogleFonts.outfit(
                                    color: Colors.white54,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Love / Country Badge (flat)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("🇮🇳", style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 8),
                            Text(
                              "Made in India with Love",
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text("❤️", style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final Uri url = Uri.parse('https://github.com/vishnunandan555/gate-tracker');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: const BorderSide(color: Colors.white24, width: 1),
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.code_rounded, size: 18, color: Colors.white70),
                            label: Text(
                              "GITHUB",
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.pop(context),
                            style: FilledButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
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
