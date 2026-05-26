import 'package:flutter/material.dart';
import '../database/models/subject.dart';
import 'progress_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class SubjectCard extends StatelessWidget {
  final Subject subject;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final Function(int) onEdit;
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
    if (subject.playlistLink.isEmpty) return;
    try {
      final url = Uri.parse(subject.playlistLink);
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      // Silently ignore malformed URLs
    }
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(
      text: subject.completedVideos.toString(),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Edit Progress',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Videos (Max: ${subject.totalVideos})',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null) onEdit(val);
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
    final link = subject.playlistLink.toLowerCase();
    if (link.contains('goclasses')) return 'GoClasses';
    if (link.contains('youtube') || link.contains('youtu.be')) return 'YouTube';
    return 'Link';
  }

  @override
  Widget build(BuildContext context) {
    final bool isNotReady = subject.totalVideos == 0;
    final percentage = isNotReady
        ? 0.0
        : (subject.completedVideos / subject.totalVideos) * 100;

    // Card content: Row without IntrinsicHeight (incompatible with LayoutBuilder in ProgressBar)
    final cardContent = Material(
      color: Colors.transparent,
      child: InkWell(
        onLongPress: isNotReady ? null : () => _showEditDialog(context),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 15,
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
                        if (subject.playlistLink.isNotEmpty)
                          _PillButton(
                            label: _getSourceLabel(),
                            color: color,
                            onTap: isNotReady ? null : _launchUrl,
                          ),
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

              // ── RIGHT: big % ────────────────────────────
              Container(
                width: 80,
                alignment: Alignment.centerRight,
                child: Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 34,
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
              ),
            ],
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
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Text(
                      'NOT READY',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        fontSize: 12,
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
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color.withValues(alpha: 0.9),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
