import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/category_font_size_provider.dart';
import '../../../../providers/topic_font_size_provider.dart';
import '../../../../providers/task_font_size_provider.dart';
import '../../../../providers/overall_ui_scale_provider.dart';

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
    final currentTaskSize = ref.watch(taskFontSizeProvider);
    final currentScale = ref.watch(overallUiScaleProvider);

    final overallScaleTile = ListTile(
      title: const Text('Overall UI Scale'),
      subtitle: const Text(
        'Scale all texts, card margins, paddings, and buttons proportionally',
        style: TextStyle(color: Colors.grey, fontSize: 11),
      ),
      trailing: DropdownButton<OverallUiScale>(
        value: currentScale,
        dropdownColor: const Color(0xFF18181B),
        underline: const SizedBox(),
        items: OverallUiScale.values.map((scale) {
          String name = '';
          switch (scale) {
            case OverallUiScale.xs:
              name = 'XS (0.8x)';
              break;
            case OverallUiScale.s:
              name = 'S (0.9x)';
              break;
            case OverallUiScale.normal:
              name = 'Normal (1.0x)';
              break;
            case OverallUiScale.l:
              name = 'L (1.1x)';
              break;
            case OverallUiScale.xl:
              name = 'XL (1.2x)';
              break;
          }
          return DropdownMenuItem(
            value: scale,
            child: Text(
              name,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          );
        }).toList(),
        onChanged: (val) {
          if (val != null) {
            ref.read(overallUiScaleProvider.notifier).setScale(val);
          }
        },
      ),
    );

    final categoryFontTile = ListTile(
      title: const Text('Category Font Size'),
      subtitle: const Text(
        'Resize category titles and category completion percentages',
        style: TextStyle(color: Colors.grey, fontSize: 11),
      ),
      trailing: DropdownButton<CategoryFontSize>(
        value: currentCategorySize,
        dropdownColor: const Color(0xFF18181B),
        underline: const SizedBox(),
        items: CategoryFontSize.values.map((size) {
          String name = '';
          switch (size) {
            case CategoryFontSize.level1:
              name = 'XS';
              break;
            case CategoryFontSize.level2:
              name = 'S';
              break;
            case CategoryFontSize.level3:
              name = 'Normal';
              break;
            case CategoryFontSize.level4:
              name = 'L';
              break;
            case CategoryFontSize.level5:
              name = 'XL';
              break;
          }
          return DropdownMenuItem(
            value: size,
            child: Text(
              name,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          );
        }).toList(),
        onChanged: (val) {
          if (val != null) {
            ref.read(categoryFontSizeProvider.notifier).setFontSize(val);
          }
        },
      ),
    );

    final topicFontTile = ListTile(
      title: const Text('Card/Topic Font Size'),
      subtitle: const Text(
        'Resize subject card titles and card details',
        style: TextStyle(color: Colors.grey, fontSize: 11),
      ),
      trailing: DropdownButton<TopicFontSize>(
        value: currentTopicSize,
        dropdownColor: const Color(0xFF18181B),
        underline: const SizedBox(),
        items: TopicFontSize.values.map((size) {
          String name = '';
          switch (size) {
            case TopicFontSize.level1:
              name = 'XS';
              break;
            case TopicFontSize.level2:
              name = 'S';
              break;
            case TopicFontSize.level3:
              name = 'Normal';
              break;
            case TopicFontSize.level4:
              name = 'L';
              break;
            case TopicFontSize.level5:
              name = 'XL';
              break;
          }
          return DropdownMenuItem(
            value: size,
            child: Text(
              name,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          );
        }).toList(),
        onChanged: (val) {
          if (val != null) {
            ref.read(topicFontSizeProvider.notifier).setFontSize(val);
          }
        },
      ),
    );

    final taskFontTile = ListTile(
      title: const Text('Checklist Font Size'),
      subtitle: const Text(
        'Resize checklist task text inside expanded syllabus topics',
        style: TextStyle(color: Colors.grey, fontSize: 11),
      ),
      trailing: DropdownButton<TaskFontSize>(
        value: currentTaskSize,
        dropdownColor: const Color(0xFF18181B),
        underline: const SizedBox(),
        items: TaskFontSize.values.map((size) {
          String name = '';
          switch (size) {
            case TaskFontSize.level1:
              name = 'XS';
              break;
            case TaskFontSize.level2:
              name = 'S';
              break;
            case TaskFontSize.level3:
              name = 'Normal';
              break;
            case TaskFontSize.level4:
              name = 'L';
              break;
            case TaskFontSize.level5:
              name = 'XL';
              break;
          }
          return DropdownMenuItem(
            value: size,
            child: Text(
              name,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          );
        }).toList(),
        onChanged: (val) {
          if (val != null) {
            ref.read(taskFontSizeProvider.notifier).setFontSize(val);
          }
        },
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
          overallScaleTile,
          categoryFontTile,
          topicFontTile,
          taskFontTile,
        ],
      ),
    );
  }
}
