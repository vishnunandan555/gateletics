import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../database/app_database.dart';
import '../../../providers/subject_provider.dart';

final neonPalette = [
  0xFFFF073A, // Neon Red
  0xFF00F0FF, // Neon Cyan
  0xFF39FF14, // Neon Green
  0xFFD500F9, // Neon Purple
  0xFFFFE500, // Neon Yellow
  0xFFFF6C00, // Neon Orange
  0xFFFF1493, // Deep Pink
  0xFF2979FF, // Vibrant Blue
];

void showCategoryOptionsSheet(BuildContext context, Category category, WidgetRef ref) {
  final color = Color(category.color);
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF18181B),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    category.name.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white10),
            ListTile(
              leading: Icon(Icons.add_circle_outline_rounded, color: color),
              title: Text('Add Subject', style: GoogleFonts.outfit(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                showAddSubjectDialog(context, category, ref);
              },
            ),
            ListTile(
              leading: Icon(Icons.edit_rounded, color: color),
              title: Text('Edit Category Details', style: GoogleFonts.outfit(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                showEditCategoryDialog(context, category, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_vert_rounded, color: Colors.white70),
              title: Text('Reorder Categories', style: GoogleFonts.outfit(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final list = ref.read(categoriesWithSubjectsProvider).value;
                if (list != null) {
                  final cats = list.map((e) => e.category).toList();
                  showReorderCategoriesDialog(context, cats, ref);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              title: Text('Delete Category', style: GoogleFonts.outfit(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteCategoryConfirm(context, category, ref);
              },
            ),
          ],
        ),
      ),
    ),
  );
}

void showEditCategoryDialog(BuildContext context, Category category, WidgetRef ref) {
  final nameController = TextEditingController(text: category.name);
  int selectedColor = category.color;

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'EDIT CATEGORY',
          style: GoogleFonts.outfit(
            textStyle: TextStyle(
              fontFamily: 'BatmanForever',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(selectedColor),
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
                ref.read(subjectControllerProvider.notifier).updateCategory(category.id, name, selectedColor);
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
              'SAVE',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ),
  );
}

void _showDeleteCategoryConfirm(BuildContext context, Category category, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF18181B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'DELETE CATEGORY?',
        style: GoogleFonts.outfit(
          textStyle: const TextStyle(
            fontFamily: 'BatmanForever',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.redAccent,
            letterSpacing: 0.8,
          ),
        ),
      ),
      content: Text(
        'Are you sure you want to delete "${category.name}"? This will permanently delete ALL subjects under this category. This cannot be undone.',
        style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('CANCEL', style: GoogleFonts.outfit(color: Colors.white60, fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          onPressed: () {
            ref.read(subjectControllerProvider.notifier).deleteCategory(category.id);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text('DELETE', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}

void showAddSubjectDialog(BuildContext context, Category category, WidgetRef ref) {
  final nameController = TextEditingController();
  final sourceController = TextEditingController(text: 'YouTube');
  final totalController = TextEditingController(text: '50');
  final linkController = TextEditingController();

  final color = Color(category.color);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF18181B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'ADD SUBJECT',
        style: GoogleFonts.outfit(
          textStyle: TextStyle(
            fontFamily: 'BatmanForever',
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 0.8,
          ),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: GoogleFonts.outfit(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Subject Name',
                labelStyle: GoogleFonts.outfit(color: Colors.white60),
                filled: true,
                fillColor: const Color(0xFF27272A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: sourceController,
              style: GoogleFonts.outfit(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Source Name',
                labelStyle: GoogleFonts.outfit(color: Colors.white60),
                filled: true,
                fillColor: const Color(0xFF27272A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: totalController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.outfit(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Total Videos',
                labelStyle: GoogleFonts.outfit(color: Colors.white60),
                filled: true,
                fillColor: const Color(0xFF27272A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: linkController,
              style: GoogleFonts.outfit(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Playlist Link (Optional)',
                labelStyle: GoogleFonts.outfit(color: Colors.white60),
                filled: true,
                fillColor: const Color(0xFF27272A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('CANCEL', style: GoogleFonts.outfit(color: Colors.white60, fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          onPressed: () {
            final name = nameController.text.trim();
            final source = sourceController.text.trim();
            final total = int.tryParse(totalController.text.trim()) ?? 0;
            final link = linkController.text.trim();

            if (name.isNotEmpty && total > 0) {
              ref.read(subjectControllerProvider.notifier).addSubject(
                name: name,
                categoryId: category.id,
                total: total,
                sourceName: source.isEmpty ? 'Source' : source,
                playlistLink: link,
                isActive: true,
              );
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text('ADD', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}

void showReorderCategoriesDialog(BuildContext context, List<Category> categories, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          backgroundColor: const Color(0xFF18181B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'REORDER CATEGORIES',
            style: GoogleFonts.outfit(
              textStyle: const TextStyle(
                fontFamily: 'BatmanForever',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.8,
              ),
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                return ReorderableDragStartListener(
                  key: ValueKey(cat.id),
                  index: index,
                  child: ListTile(
                    leading: const Icon(Icons.drag_handle_rounded, color: Colors.white54),
                    title: Text(
                      cat.name,
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                    trailing: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(color: Color(cat.color), shape: BoxShape.circle),
                    ),
                  ),
                );
              },
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final item = categories.removeAt(oldIndex);
                  categories.insert(newIndex, item);
                });
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CANCEL', style: GoogleFonts.outfit(color: Colors.white60, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                final orderedIds = categories.map((e) => e.id).toList();
                ref.read(subjectControllerProvider.notifier).reorderCategories(orderedIds);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF27272A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('SAVE', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    ),
  );
}

void showCreateCategoryDialog(BuildContext context, WidgetRef ref) {
  final nameController = TextEditingController();
  int selectedColor = 0xFFFF073A; // Default Neon Red

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
