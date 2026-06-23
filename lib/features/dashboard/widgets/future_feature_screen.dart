import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_bar_title.dart';

class FutureFeatureScreen extends StatelessWidget {
  final Color progressColor;

  const FutureFeatureScreen({
    super.key,
    required this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF18181B),
      appBar: AppBar(
        toolbarHeight: 112,
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const AppBarTitle(),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: progressColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: progressColor.withAlpha(60), width: 1.5),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: progressColor,
                  size: 36,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Future Feature',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This screen is a placeholder for future features. Design and additions will be implemented per your instructions.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: Colors.white54,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
