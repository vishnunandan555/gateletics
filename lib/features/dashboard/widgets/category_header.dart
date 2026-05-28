import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../database/app_database.dart';
import 'customization_sheets.dart';

class CategoryHeader extends ConsumerWidget {
  final Category category;
  final double progress;

  const CategoryHeader({
    super.key,
    required this.category,
    required this.progress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = category.name;
    final color = Color(category.color);
    final normalized = (progress / 100).clamp(0.0, 1.0);
    const baseStyle = TextStyle(
      fontFamily: 'Legend',
      fontSize: 26,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.2,
      color: Colors.white54,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: normalized),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, animValue, _) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  // Measure the actual rendered text width so the fill
                  // is proportional to the text, not the container.
                  final textPainter = TextPainter(
                    text: TextSpan(text: title.toUpperCase(), style: baseStyle),
                    textDirection: TextDirection.ltr,
                    maxLines: 1,
                    ellipsis: '...',
                  )..layout(maxWidth: constraints.maxWidth);

                  final fillWidth = textPainter.width * animValue;

                  return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onLongPress: () => showCreateCategoryDialog(context, ref),
                    child: Stack(
                      children: [
                        Text(title.toUpperCase(), style: baseStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ClipRect(
                          clipper: _ProgressClipper(fillWidth),
                          child: Text(
                            title.toUpperCase(),
                            style: baseStyle.copyWith(color: color),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${progress.toStringAsFixed(1)}%',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(width: 6),
        IconButton(
          icon: const Icon(Icons.more_vert_rounded, size: 26, color: Colors.white54),
          onPressed: () => showCategoryOptionsSheet(context, category, ref),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          splashRadius: 16,
          tooltip: 'Category Settings',
        ),
      ],
    );
  }
}

class _ProgressClipper extends CustomClipper<Rect> {
  const _ProgressClipper(this.width);

  final double width;

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, width, size.height);
  }

  @override
  bool shouldReclip(_ProgressClipper oldClipper) {
    return oldClipper.width != width;
  }
}
