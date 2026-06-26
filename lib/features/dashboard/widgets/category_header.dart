import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../database/app_database.dart';
import '../../../providers/progress_font_provider.dart';
import '../../../providers/subject_provider.dart';
import '../../../providers/category_font_size_provider.dart';
import 'customization_sheets.dart';

class CategoryHeader extends ConsumerWidget {
  final Category category;
  final double progress;
  final bool isCollapsed;

  const CategoryHeader({
    super.key,
    required this.category,
    required this.progress,
    this.isCollapsed = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = category.name;
    final color = Color(category.color);
    final normalized = (progress / 100).clamp(0.0, 1.0);
    final selectedFont = ref.watch(progressFontProvider);
    final sizeOpt = ref.watch(categoryFontSizeProvider);
    final categoryFontSize = sizeOpt.size;
    final categoryBase = TextStyle(
      fontSize: categoryFontSize,
      fontWeight: FontWeight.w900,
      letterSpacing: 1.2,
      color: Colors.white54,
    );

    TextStyle getCategoryStyle() {
      switch (selectedFont) {
        case ProgressFont.jersey15:
          return GoogleFonts.jersey15(
            textStyle: categoryBase.copyWith(fontSize: categoryFontSize - -15),
          );
        case ProgressFont.jersey10:
          return GoogleFonts.jersey10(
            textStyle: categoryBase.copyWith(fontSize: categoryFontSize - -15),
          );
        case ProgressFont.tektur:
          return GoogleFonts.tektur(
            textStyle: categoryBase.copyWith(fontSize: categoryFontSize - -5),
          );
        case ProgressFont.odibeeSans:
          return GoogleFonts.odibeeSans(
            textStyle: categoryBase.copyWith(fontSize: categoryFontSize - -10),
          );
        case ProgressFont.pressStart2P:
          return GoogleFonts.pressStart2p(
            textStyle: categoryBase.copyWith(fontSize: categoryFontSize - 7),
          );
        case ProgressFont.boldonse:
          return GoogleFonts.boldonse(
            textStyle: categoryBase.copyWith(
              fontSize: categoryFontSize - 1,
              height: 1.6,
            ),
          );
        case ProgressFont.orbitron:
          return GoogleFonts.orbitron(textStyle: categoryBase);
      }
    }

    final baseStyle = getCategoryStyle();

    Widget headerContent = Row(
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
                    onTap: isCollapsed
                        ? null
                        : () {
                            if (progress >= 100.0) {
                              ref.read(manuallyExpandedCompletedCategoriesProvider.notifier).toggle(category.id);
                            }
                          },
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

    if (isCollapsed) {
      headerContent = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          ref.read(manuallyExpandedCompletedCategoriesProvider.notifier).toggle(category.id);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.8),
              width: 1.5,
            ),
          ),
          child: headerContent,
        ),
      );
    }

    return headerContent;
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
