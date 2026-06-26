import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/app_database.dart';
import '../providers/subject_provider.dart';
import 'progress_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class SubjectCard extends ConsumerWidget {
  final Subject subject;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final Function({
    required int completed,
    required int total,
    required String sourceName,
    required String playlistLink,
    required bool isActive,
  }) onEdit;
  final Color color;

  const SubjectCard({
    super.key,
    required this.subject,
    required this.onIncrement,
    required this.onDecrement,
    required this.onEdit,
    this.color = Colors.cyanAccent,
  });

  Future<void> _launchUrl() async {
    String link = subject.playlistLink.trim();
    if (link.isEmpty) return;

    // Add https if missing
    if (!link.startsWith('http://') && !link.startsWith('https://')) {
      link = 'https://$link';
    }

    try {
      final url = Uri.parse(link);
      final bool launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // Fallback or just ignore if it couldn't be launched
        debugPrint('Could not launch $link');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final completedController = TextEditingController(
      text: subject.completedVideos.toString(),
    );
    final totalController = TextEditingController(
      text: subject.totalVideos.toString(),
    );
    final sourceNameController = TextEditingController(
      text: subject.sourceName,
    );
    final playlistLinkController = TextEditingController(
      text: subject.playlistLink,
    );
    bool isActive = subject.isActive;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF18181B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Edit Subject',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: sourceNameController,
                  decoration: InputDecoration(
                    labelText: 'Source Name',
                    hintText: 'e.g. YouTube, GoClasses',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: playlistLinkController,
                  decoration: InputDecoration(
                    labelText: 'Source Link',
                    hintText: 'URL of the playlist',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: totalController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Total',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: completedController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Current',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            completedController.text = totalController.text;
                          });
                        },
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                        label: const Text('Mark Full'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: color,
                          side: BorderSide(color: color.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            completedController.text = '0';
                          });
                        },
                        icon: const Icon(Icons.replay_rounded, size: 18),
                        label: const Text('Reset'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Is Active',
                      style: TextStyle(color: Colors.white)),
                  subtitle: Text(
                    isActive ? 'ENABLED' : 'DISABLED',
                    style: TextStyle(
                      color: isActive ? Colors.greenAccent : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  value: isActive,
                  onChanged: (val) => setState(() => isActive = val),
                  activeThumbColor: color,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _confirmDeleteSubject(context, ref);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            FilledButton(
              onPressed: () {
                final comp = int.tryParse(completedController.text) ?? 0;
                final tot = int.tryParse(totalController.text) ?? 0;
                onEdit(
                  completed: comp,
                  total: tot,
                  sourceName: sourceNameController.text,
                  playlistLink: playlistLinkController.text,
                  isActive: isActive,
                );
                Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.black,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteSubject(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'DELETE SUBJECT?',
          style: GoogleFonts.jersey15(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.redAccent,
            letterSpacing: 0.8,
          ),
        ),
        content: Text(
          'Are you sure you want to permanently delete "${subject.name}"? This cannot be undone.',
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(subjectControllerProvider.notifier).deleteSubject(subject.id);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('DELETE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  IconData _getIconForSubject(String name) {
    if (name.contains('Engineering Math')) {
      return Icons.functions;
    }
    if (name.contains('Discrete')) {
      return Icons.grid_on;
    }
    if (name.contains('Programming')) {
      return Icons.terminal;
    }
    if (name.contains('Data Struct')) {
      return Icons.account_tree;
    }
    if (name.contains('Algorithm')) {
      return Icons.route;
    }
    if (name.contains('Digital Logic')) {
      return Icons.memory;
    }
    if (name.contains('COA')) {
      return Icons.developer_board;
    }
    if (name.contains('Operating System')) {
      return Icons.settings_system_daydream;
    }
    if (name.contains('DBMS')) {
      return Icons.storage;
    }
    if (name.contains('Network')) {
      return Icons.router;
    }
    if (name.contains('Computation')) {
      return Icons.precision_manufacturing;
    }
    if (name.contains('Apti')) {
      return Icons.psychology;
    }
    if (name.contains('Compiler')) {
      return Icons.code;
    }
    if (name.contains('Math')) {
      return Icons.functions;
    }
    return Icons.book;
  }

  String _getSourceLabel() {
    if (subject.sourceName.toLowerCase() != 'source' &&
        subject.sourceName.isNotEmpty) {
      return subject.sourceName;
    }

    final link = subject.playlistLink.toLowerCase();
    if (link.contains('goclasses')) return 'GoClasses';
    if (link.contains('youtube') || link.contains('youtu.be')) return 'YouTube';
    return subject.sourceName.isEmpty ? 'Source' : subject.sourceName;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isNotReady = !subject.isActive;
    final percentage = isNotReady
        ? 0.0
        : (subject.totalVideos == 0
            ? 0.0
            : (subject.completedVideos / subject.totalVideos) * 100);

    final screenWidth = MediaQuery.of(context).size.width;

    // Card content: Row without IntrinsicHeight (incompatible with LayoutBuilder in ProgressBar)
    final cardContent = Material(
      color: Colors.transparent,
      child: InkWell(
        onLongPress: () => _showEditDialog(context, ref),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Opacity(
            opacity: isNotReady ? 0.4 : 1.0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── LEFT: main content ─────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Row 1: icon + name + link icon
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            _getIconForSubject(subject.name),
                            color: color,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              subject.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: (screenWidth * 0.038).clamp(12.0, 15.0),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Row 2: progress bar
                      ProgressBar(
                        percentage: percentage,
                        height: 10,
                        color: color,
                        showTicks: true,
                        tickCount: 10,
                      ),

                      const SizedBox(height: 16),

                      // Row 3: source label (left) + counter buttons (right)
                      Row(
                        children: [
                          if (subject.isActive) ...[
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: _PillButton(
                                  label: _getSourceLabel(),
                                  color: color,
                                  onTap: subject.playlistLink.trim().isEmpty
                                      ? null
                                      : _launchUrl,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ] else
                            const Spacer(),
                          _CircleButton(
                            icon: Icons.remove_rounded,
                            onTap: isNotReady ? null : onDecrement,
                            bgColor: Colors.white.withValues(alpha: 0.06),
                            iconColor: Colors.white54,
                          ),
                          const SizedBox(width: 8),
                          _CircleButton(
                            icon: Icons.add_rounded,
                            onTap: isNotReady ? null : onIncrement,
                            bgColor: color.withValues(alpha: 0.18),
                            iconColor: color,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // ── RIGHT: big % + completion info ──────────
                Container(
                  width: 80,
                  alignment: Alignment.centerRight,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: (screenWidth * 0.08).clamp(24.0, 34.0),
                          fontWeight: FontWeight.w900,
                          color: color,
                          letterSpacing: -1.5,
                          height: 1,
                          shadows: [
                            Shadow(
                              color: color.withValues(alpha: 0.55),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${subject.completedVideos}/${subject.totalVideos}',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: (screenWidth * 0.028).clamp(9.0, 11.0),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          cardContent,
          if (isNotReady)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.35),
                        ),
                      ),
                      child: const Text(
                        'DISABLED',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Animated Scale Button Wrapper ────────────────────────────

class AnimatedScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const AnimatedScaleButton({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  State<AnimatedScaleButton> createState() => _AnimatedScaleButtonState();
}

class _AnimatedScaleButtonState extends State<AnimatedScaleButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _scale = 0.92) : null,
      onTapUp: enabled ? (_) => setState(() => _scale = 1.0) : null,
      onTapCancel: enabled ? () => setState(() => _scale = 1.0) : null,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color bgColor;
  final Color iconColor;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    required this.bgColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScaleButton(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 22),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _PillButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScaleButton(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color.withValues(alpha: 0.9),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
