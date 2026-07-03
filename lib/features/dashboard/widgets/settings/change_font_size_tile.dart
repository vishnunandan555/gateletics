import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../providers/category_font_size_provider.dart';
import '../../../../providers/topic_font_size_provider.dart';

class ChangeFontSizeTile extends ConsumerWidget {
  final Color accentColor;

  const ChangeFontSizeTile({
    super.key,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentCategorySize = ref.watch(categoryFontSizeProvider);
    final currentTopicSize = ref.watch(topicFontSizeProvider);

    String getCategoryLabel(CategoryFontSize size) {
      switch (size) {
        case CategoryFontSize.level1:
          return 'XS';
        case CategoryFontSize.level2:
          return 'S';
        case CategoryFontSize.level3:
          return 'Normal';
        case CategoryFontSize.level4:
          return 'L';
        case CategoryFontSize.level5:
          return 'XL';
      }
    }

    String getTopicLabel(TopicFontSize size) {
      switch (size) {
        case TopicFontSize.level1:
          return 'XS';
        case TopicFontSize.level2:
          return 'S';
        case TopicFontSize.level3:
          return 'Normal';
        case TopicFontSize.level4:
          return 'L';
        case TopicFontSize.level5:
          return 'XL';
      }
    }

    final fontSizeHeader = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        'CATEGORY FONT SIZE',
        style: TextStyle(
          color: accentColor.withValues(alpha: 0.7),
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 1.2,
        ),
      ),
    );

    final fontSizeContent = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                getCategoryLabel(currentCategorySize),
                style: GoogleFonts.outfit(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (currentCategorySize == CategoryFontSize.level3)
                Text(
                  'DEFAULT',
                  style: GoogleFonts.outfit(
                    color: accentColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accentColor,
              inactiveTrackColor: Colors.white.withAlpha(20),
              thumbColor: accentColor,
              overlayColor: accentColor.withAlpha(40),
              valueIndicatorColor: accentColor,
              tickMarkShape: const RoundSliderTickMarkShape(),
              activeTickMarkColor: Colors.black,
              inactiveTickMarkColor: Colors.white30,
            ),
            child: Slider(
              value: CategoryFontSize.values.indexOf(currentCategorySize).toDouble(),
              min: 0,
              max: 4,
              divisions: 4,
              label: getCategoryLabel(currentCategorySize),
              onChanged: (val) {
                final newSize = CategoryFontSize.values[val.toInt()];
                ref.read(categoryFontSizeProvider.notifier).setFontSize(newSize);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('XS', style: GoogleFonts.outfit(color: Colors.white30, fontSize: 10)),
                Text('S', style: GoogleFonts.outfit(color: Colors.white30, fontSize: 10)),
                Text('Normal (Def)', style: GoogleFonts.outfit(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold)),
                Text('L', style: GoogleFonts.outfit(color: Colors.white30, fontSize: 10)),
                Text('XL', style: GoogleFonts.outfit(color: Colors.white30, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );

    final topicFontSizeHeader = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        'CARD/TOPIC FONT SIZE',
        style: TextStyle(
          color: accentColor.withValues(alpha: 0.7),
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 1.2,
        ),
      ),
    );

    final topicFontSizeContent = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                getTopicLabel(currentTopicSize),
                style: GoogleFonts.outfit(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (currentTopicSize == TopicFontSize.level3)
                Text(
                  'DEFAULT',
                  style: GoogleFonts.outfit(
                    color: accentColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accentColor,
              inactiveTrackColor: Colors.white.withAlpha(20),
              thumbColor: accentColor,
              overlayColor: accentColor.withAlpha(40),
              valueIndicatorColor: accentColor,
              tickMarkShape: const RoundSliderTickMarkShape(),
              activeTickMarkColor: Colors.black,
              inactiveTickMarkColor: Colors.white30,
            ),
            child: Slider(
              value: TopicFontSize.values.indexOf(currentTopicSize).toDouble(),
              min: 0,
              max: 4,
              divisions: 4,
              label: getTopicLabel(currentTopicSize),
              onChanged: (val) {
                final newSize = TopicFontSize.values[val.toInt()];
                ref.read(topicFontSizeProvider.notifier).setFontSize(newSize);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('XS', style: GoogleFonts.outfit(color: Colors.white30, fontSize: 10)),
                Text('S', style: GoogleFonts.outfit(color: Colors.white30, fontSize: 10)),
                Text('Normal (Def)', style: GoogleFonts.outfit(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold)),
                Text('L', style: GoogleFonts.outfit(color: Colors.white30, fontSize: 10)),
                Text('XL', style: GoogleFonts.outfit(color: Colors.white30, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        iconColor: accentColor,
        collapsedIconColor: Colors.white30,
        leading: Icon(Icons.format_size_rounded, color: accentColor),
        title: const Text(
          'Change Font Size',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        children: [
          fontSizeHeader,
          fontSizeContent,
          const SizedBox(height: 16),
          const Divider(color: Colors.white12),
          const SizedBox(height: 8),
          topicFontSizeHeader,
          topicFontSizeContent,
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
