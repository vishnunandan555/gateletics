import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/subject_provider.dart';

class EmptyStateView extends ConsumerStatefulWidget {
  const EmptyStateView({super.key});

  @override
  ConsumerState<EmptyStateView> createState() => _EmptyStateViewState();
}

class _EmptyStateViewState extends ConsumerState<EmptyStateView> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    int selectedColor = 0xFFFF073A; // Default Neon Red
    
    final neonPalette = [
      0xFFFF073A, // Neon Red
      0xFF00F0FF, // Neon Cyan
      0xFF39FF14, // Neon Green
      0xFFD500F9, // Neon Purple
      0xFFFFE500, // Neon Yellow
      0xFFFF6C00, // Neon Orange
      0xFFFF1493, // Deep Pink
      0xFF00FFFF, // Teal/Aqua
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF18181B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'NEW CATEGORY',
            style: GoogleFonts.outfit(
              textStyle: const TextStyle(
                fontFamily: 'BatmanForever',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.8,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                style: GoogleFonts.outfit(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Category Name',
                  labelStyle: GoogleFonts.outfit(color: Colors.white60),
                  filled: true,
                  fillColor: const Color(0xFF27272A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Accent Color',
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: neonPalette.map((colorVal) {
                  final isSelected = selectedColor == colorVal;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedColor = colorVal;
                      });
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(colorVal),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: Color(colorVal).withAlpha(150),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ] : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'CANCEL',
                style: GoogleFonts.outfit(color: Colors.white60, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  ref.read(subjectControllerProvider.notifier).addCategory(name, selectedColor);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(selectedColor),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                'CREATE',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progressColor = ref.watch(overallProgressColorProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, child) => FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Glowing Neon Icon Holder
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: progressColor.withAlpha(20),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: progressColor.withAlpha(128),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: progressColor.withAlpha(51),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.track_changes_rounded,
                        size: 48,
                        color: progressColor,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Headings
                    Text(
                      'DESIGN YOUR JOURNEY',
                      style: GoogleFonts.outfit(
                        textStyle: const TextStyle(
                          fontFamily: 'BatmanForever',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Your syllabus tracker is empty. Build your custom study roadmap with categories, subjects, and custom neon colors, or instantly load our default GATE syllabus preset to begin!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.white60,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Action Buttons
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 320),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: progressColor.withAlpha(76),
                            blurRadius: 20,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: ElevatedButton.styleFrom(
                        backgroundColor: progressColor,
                        foregroundColor: Colors.black,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ).child(
                        InkWell(
                          onTap: () {
                            ref.read(subjectControllerProvider.notifier).applyPreset();
                          },
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.auto_awesome_rounded, size: 20, color: Colors.black),
                                const SizedBox(width: 8),
                                Text(
                                  'LOAD GATE SYLLABUS PRESET',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: OutlinedButton(
                        onPressed: () => _showAddCategoryDialog(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_rounded, size: 20, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'CREATE CUSTOM ROADMAP',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
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
}

// Extension to help build structured buttons with riverpod overlays
extension on ButtonStyle {
  Widget child(Widget child) => Builder(
    builder: (context) {
      final style = this;
      return ElevatedButton(
        style: style,
        onPressed: null, // Tap handler handled by internal InkWell for rich tactile feedback
        child: child,
      );
    },
  );
}
