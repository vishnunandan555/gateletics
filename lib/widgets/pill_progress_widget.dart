import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/subject_provider.dart';

class PillProgressWidget extends ConsumerStatefulWidget {
  final double percentage;
  final int totalCompleted;
  final int totalVideos;

  const PillProgressWidget({
    super.key,
    required this.percentage,
    required this.totalCompleted,
    required this.totalVideos,
  });

  @override
  ConsumerState<PillProgressWidget> createState() => _PillProgressWidgetState();
}

class _PillProgressWidgetState extends ConsumerState<PillProgressWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _anim = Tween<double>(
      begin: 0,
      end: widget.percentage / 100,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(PillProgressWidget old) {
    super.didUpdateWidget(old);
    if (old.percentage != widget.percentage) {
      _anim = Tween<double>(
        begin: _anim.value,
        end: widget.percentage / 100,
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _cycleColor() {
    ref.read(overallProgressColorProvider.notifier).next();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _cycleColor,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          final screenWidth = MediaQuery.of(context).size.width;
          final w = (screenWidth * 0.75).clamp(240.0, 400.0);
          const h = 140.0;
          const fontSize = 42.0;
          final color = ref.watch(overallProgressColorProvider);
          final progress = _anim.value;

          return Center(
            child: SizedBox(
              width: w,
              height: h,
              child: CustomPaint(
                painter: _SquircleRingPainter(
                  progress: progress,
                  color: color,
                  trackColor: Colors.white.withValues(alpha: 0.07),
                  strokeWidth: 10,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(progress * 100).toStringAsFixed(2)}%',
                        style: TextStyle(
                          fontFamily: 'BatmanForever',
                          fontSize: fontSize,
                          fontWeight: FontWeight.w900,
                          color: color,
                          letterSpacing: -1,
                          shadows: [
                            Shadow(
                              color: color.withValues(alpha: 0.9),
                              blurRadius: 20,
                            ),
                            Shadow(
                              color: color.withValues(alpha: 0.5),
                              blurRadius: 40,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Total Completion',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SquircleRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  _SquircleRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  Path _bottomCenterStartRoundedRectPath(Rect rect, double radius) {
    final path = Path();
    final left = rect.left;
    final top = rect.top;
    final width = rect.width;
    final height = rect.height;

    // Start at bottom center
    final startX = left + width / 2;
    final startY = top + height;

    path.moveTo(startX, startY);

    // 1. Line left to bottom-left start
    path.lineTo(left + radius, top + height);

    // 2. Arc to bottom-left end
    path.arcToPoint(
      Offset(left, top + height - radius),
      radius: Radius.circular(radius),
      clockwise: true,
    );

    // 3. Line up to top-left start
    path.lineTo(left, top + radius);

    // 4. Arc to top-left end
    path.arcToPoint(
      Offset(left + radius, top),
      radius: Radius.circular(radius),
      clockwise: true,
    );

    // 5. Line right to top-right start
    path.lineTo(left + width - radius, top);

    // 6. Arc to top-right end
    path.arcToPoint(
      Offset(left + width, top + radius),
      radius: Radius.circular(radius),
      clockwise: true,
    );

    // 7. Line down to bottom-right start
    path.lineTo(left + width, top + height - radius);

    // 8. Arc to bottom-right end
    path.arcToPoint(
      Offset(left + width - radius, top + height),
      radius: Radius.circular(radius),
      clockwise: true,
    );

    // 9. Line back to bottom center
    path.lineTo(startX, startY);

    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final inset = strokeWidth / 2 + 1;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );

    final fullPath = _bottomCenterStartRoundedRectPath(rect, 24);

    // Track (full dim ring)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(fullPath, trackPaint);

    if (progress < 0.005) return;

    // Measure and extract progress portion
    final metric = fullPath.computeMetrics().first;
    final progressPath = metric.extractPath(0, metric.length * progress);

    // Progress ring — clean, no glow
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(progressPath, progressPaint);
  }

  @override
  bool shouldRepaint(_SquircleRingPainter old) =>
      old.progress != progress || old.color != color;
}
