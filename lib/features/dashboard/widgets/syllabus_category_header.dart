import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../database/app_database.dart';
import '../../../providers/progress_font_provider.dart';
import '../../../providers/syllabus_provider.dart';
import '../../../providers/category_font_size_provider.dart';
import 'syllabus_customization_sheets.dart';
import '../../../utils/string_utils.dart';
import '../../../utils/ui_scaling.dart';

class SyllabusCategoryHeader extends ConsumerWidget {
  final SyllabusCategory category;
  final double progress;
  final List<SyllabusTopic> topics;
  final bool isCollapsed;

  const SyllabusCategoryHeader({
    super.key,
    required this.category,
    required this.progress,
    required this.topics,
    this.isCollapsed = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = category.name;
    final color = Color(category.color);
    final normalized = (progress / 100).clamp(0.0, 1.0);
    final selectedFont = ref.watch(progressFontProvider);
    final sizeOpt = ref.watch(categoryFontSizeProvider);
    final categoryFontSize = context.s(sizeOpt.size);
    final scaleFactor = sizeOpt.scaleFactor;
    
    final iconSize = context.s((26.0 * scaleFactor).clamp(14.0, 26.0));

    final categoryBase = TextStyle(
      fontSize: categoryFontSize,
      fontWeight: FontWeight.w900,
      letterSpacing: context.s(1.2),
      color: Colors.white54,
    );

    TextStyle getCategoryStyle() {
      switch (selectedFont) {
        case ProgressFont.jersey15:
          return GoogleFonts.jersey15(
            textStyle: categoryBase.copyWith(fontSize: categoryFontSize + context.s(15)),
          );
        case ProgressFont.jersey10:
          return GoogleFonts.jersey10(
            textStyle: categoryBase.copyWith(fontSize: categoryFontSize + context.s(15)),
          );
        case ProgressFont.tektur:
          return GoogleFonts.tektur(
            textStyle: categoryBase.copyWith(fontSize: categoryFontSize + context.s(10)),
          );
        case ProgressFont.odibeeSans:
          return GoogleFonts.odibeeSans(
            textStyle: categoryBase.copyWith(fontSize: categoryFontSize + context.s(10)),
          );
        case ProgressFont.pressStart2P:
          return GoogleFonts.pressStart2p(
            textStyle: categoryBase.copyWith(fontSize: categoryFontSize - context.s(10)),
          );
        case ProgressFont.boldonse:
          return GoogleFonts.boldonse(
            textStyle: categoryBase.copyWith(
              fontSize: categoryFontSize - context.s(1),
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
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              if (progress >= 100.0) {
                ref.read(manuallyExpandedCompletedSyllabusCategoriesProvider.notifier).toggle(category.id);
              }
            },
            onLongPress: () => showSyllabusCategoryOptionsSheet(context, category, ref, topics),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: normalized),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          builder: (context, animValue, _) {
                            return LayoutBuilder(
                              builder: (context, constraints) {
                                final shortName = getCategoryShortName(title);

                                // 1. Measure the full name
                                var textPainter = TextPainter(
                                  text: TextSpan(text: title.toUpperCase(), style: baseStyle),
                                  textDirection: TextDirection.ltr,
                                  maxLines: 1,
                                )..layout(maxWidth: double.infinity);

                                String actualName = title;
                                // If the full name's width exceeds constraints.maxWidth, use the shortName!
                                if (textPainter.width > constraints.maxWidth) {
                                  actualName = shortName;
                                  // Re-measure with short name
                                  textPainter = TextPainter(
                                    text: TextSpan(text: shortName.toUpperCase(), style: baseStyle),
                                    textDirection: TextDirection.ltr,
                                    maxLines: 1,
                                  )..layout(maxWidth: constraints.maxWidth);
                                } else {
                                  textPainter.layout(maxWidth: constraints.maxWidth);
                                }

                                final fillWidth = textPainter.width * animValue;

                                return Stack(
                                  children: [
                                    Text(actualName.toUpperCase(), style: baseStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ClipRect(
                                      clipper: _ProgressClipper(fillWidth),
                                      child: Text(
                                        actualName.toUpperCase(),
                                        style: baseStyle.copyWith(color: color),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),
                      if (progress >= 100.0) ...[
                        SizedBox(width: context.s(6)),
                        Icon(
                          Icons.check_circle_rounded,
                          color: color,
                          size: baseStyle.fontSize ?? categoryFontSize,
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: context.s(12)),
                Text(
                  '${progress.toStringAsFixed(1)}%',
                  style: baseStyle.copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: () => showSyllabusCategoryOptionsSheet(context, category, ref, topics),
          behavior: HitTestBehavior.translucent,
          child: Padding(
            padding: EdgeInsets.fromLTRB(context.s(2), context.s(8), 0, context.s(8)),
            child: Icon(
              Icons.more_vert_rounded,
              size: iconSize,
              color: Colors.white54,
            ),
          ),
        ),
      ],
    );

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
