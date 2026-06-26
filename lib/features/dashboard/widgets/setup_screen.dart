import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/sync_provider.dart';
import '../../../providers/completion_type_provider.dart';
import '../../../providers/setup_provider.dart';
import '../../../providers/subject_provider.dart';
import '../../../providers/syllabus_provider.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  int _currentStep = 1;
  CompletionType _selectedType = CompletionType.syllabus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForCloudBackup();
    });
  }

  Future<bool> _checkIfLocalDataExists() async {
    final db = ref.read(appDatabaseProvider);
    final cats = await db.select(db.categories).get();
    if (cats.isNotEmpty) return true;
    final sylCats = await db.select(db.syllabusCategories).get();
    if (sylCats.isNotEmpty) return true;
    return false;
  }

  Future<void> _checkForCloudBackup() async {
    final authState = ref.read(authProvider).value;
    if (authState?.user == null) return;

    setState(() => _isLoading = true);
    try {
      final needsAction = await ref.read(syncProvider.notifier).initializeSync();
      if (needsAction) {
        if (mounted) {
          _showSyncConflictDialog();
        }
      } else {
        final hasData = await _checkIfLocalDataExists();
        if (hasData) {
          await ref.read(setupCompletedProvider.notifier).completeSetup();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✓ Cloud data loaded successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Error checking for cloud backup: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSyncConflictDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
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
                title: "Merge Progress (Recommended)",
                subtitle: "Combine local and cloud progress (no data lost)",
                icon: Icons.merge_type_rounded,
                color: Colors.cyanAccent,
                onTap: () async {
                  Navigator.pop(ctx);
                  setState(() => _isLoading = true);
                  try {
                    await ref.read(syncProvider.notifier).mergeCloudAndLocal();
                    await ref.read(setupCompletedProvider.notifier).completeSetup();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✓ Cloud data merged successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Merge failed: $e')),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildDialogOption(
                title: "Use Cloud Backup",
                subtitle: "Overwrite local data with your cloud backup",
                icon: Icons.cloud_download_rounded,
                color: Colors.greenAccent,
                onTap: () async {
                  Navigator.pop(ctx);
                  setState(() => _isLoading = true);
                  try {
                    await ref.read(syncProvider.notifier).downloadCloudToLocal();
                    await ref.read(setupCompletedProvider.notifier).completeSetup();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✓ Cloud data loaded successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Restore failed: $e')),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildDialogOption(
                title: "Keep Local Progress",
                subtitle: "Overwrite cloud data with your local progress",
                icon: Icons.cloud_upload_rounded,
                color: Colors.orangeAccent,
                onTap: () async {
                  Navigator.pop(ctx);
                  setState(() => _isLoading = true);
                  try {
                    await ref.read(syncProvider.notifier).uploadLocalToCloud();
                    await ref.read(setupCompletedProvider.notifier).completeSetup();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✓ Local progress kept and uploaded successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Upload failed: $e')),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogOption({
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white10),
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withAlpha(5),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(color: Colors.white30, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectType(CompletionType type) {
    setState(() {
      _selectedType = type;
      _currentStep = 2;
    });
  }

  Future<void> _handlePreset() async {
    setState(() => _isLoading = true);
    try {
      // 1. Set the completion type
      await ref.read(completionTypeProvider.notifier).setCompletionType(_selectedType);
      
      // 2. Load the corresponding preset
      if (_selectedType == CompletionType.syllabus) {
        await ref.read(syllabusControllerProvider.notifier).applyPreset();
      } else {
        await ref.read(subjectControllerProvider.notifier).applyPreset();
      }

      // 3. Mark setup as completed
      await ref.read(setupCompletedProvider.notifier).completeSetup();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading preset: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCustomGoAhead() async {
    setState(() => _isLoading = true);
    try {
      // 1. Set the completion type
      await ref.read(completionTypeProvider.notifier).setCompletionType(_selectedType);

      // 2. Clear out any existing database structures for the selected type to ensure clean state
      if (_selectedType == CompletionType.syllabus) {
        await ref.read(syllabusControllerProvider.notifier).resetEverything();
      } else {
        await ref.read(subjectControllerProvider.notifier).resetEverything();
      }

      // 3. Mark setup as completed
      await ref.read(setupCompletedProvider.notifier).completeSetup();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing database: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressColor = ref.watch(overallProgressColorProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent),
              )
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                      child: _buildCurrentStepWidget(progressColor),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildCurrentStepWidget(Color accentColor) {
    switch (_currentStep) {
      case 1:
        return _buildStep1(accentColor);
      case 2:
        return _buildStep2(accentColor);
      case 3:
        return _buildStep3(accentColor);
      default:
        return _buildStep1(accentColor);
    }
  }

  Widget _buildStep1(Color accentColor) {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withAlpha(20), width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'icon.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "PREPARATION STYLE",
          style: GoogleFonts.jersey15(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          "How would you like to track your GATE preparation progress?",
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: Colors.white38,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildCardOption(
                  title: "Syllabus Based",
                  description: "Track your progress topic-by-topic matching the official GATE CSE syllabus checklist. Best if you have a predefined, structured study path.",
                  icon: Icons.checklist_rtl_rounded,
                  color: const Color(0xFF00F0FF), // Cyan
                  onTap: () => _selectType(CompletionType.syllabus),
                ),
                const SizedBox(height: 16),
                _buildCardOption(
                  title: "Resource Based",
                  description: "Track progress based on video lectures, playlist lengths, and custom course sources. Best for tracking individual playlists/channels.",
                  icon: Icons.video_library_rounded,
                  color: const Color(0xFFE040FB), // Magenta
                  onTap: () => _selectType(CompletionType.resource),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2(Color accentColor) {
    final modeLabel = _selectedType == CompletionType.syllabus ? "Syllabus-Based" : "Resource-Based";

    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white54, size: 20),
              onPressed: () {
                setState(() {
                  _currentStep = 1;
                });
              },
            ),
            const SizedBox(width: 8),
            Text(
              "BACK",
              style: GoogleFonts.outfit(
                color: Colors.white54,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          "GETTING STARTED",
          style: GoogleFonts.jersey15(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          "Do you want to initialize $modeLabel tracking with our default preset, or create your own custom system?",
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: Colors.white38,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildCardOption(
                  title: "Use Preset",
                  description: "Loads our pre-configured categories and items. Highly recommended so you can start tracking and studying immediately.",
                  icon: Icons.auto_awesome_rounded,
                  color: accentColor,
                  onTap: _handlePreset,
                ),
                const SizedBox(height: 16),
                _buildCardOption(
                  title: "Create Custom",
                  description: "Start with a clean, empty state. You will have to manually add your own categories, subjects, and study tracks.",
                  icon: Icons.dashboard_customize_rounded,
                  color: Colors.white70,
                  onTap: () {
                    setState(() {
                      _currentStep = 3;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3(Color accentColor) {
    return Column(
      key: const ValueKey(3),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withAlpha(20),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.amber.withAlpha(40), width: 2),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.amberAccent,
              size: 48,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "ARE YOU SURE?",
          style: GoogleFonts.jersey15(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.amberAccent,
            letterSpacing: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          "Creating a custom tracking system from scratch can be very hard and tedious. You will have to manually enter all categories and subjects yourself.\n\nWe highly recommend loading our curated presets first, which you can easily edit, rename, or delete later to fit your needs.",
          style: GoogleFonts.outfit(
            color: Colors.white70,
            fontSize: 14,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentStep = 2;
                  });
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: accentColor.withAlpha(120), width: 1.5),
                  foregroundColor: accentColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  "GO BACK",
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton(
                onPressed: _handleCustomGoAhead,
                style: FilledButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  "GO AHEAD",
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCardOption({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: GoogleFonts.outfit(
                      color: Colors.white54,
                      fontSize: 12.5,
                      height: 1.5,
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
