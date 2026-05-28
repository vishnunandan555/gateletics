import 'package:drift/drift.dart';
import 'connection/connection.dart' as conn;


part 'app_database.g.dart';

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get position => integer()();
  IntColumn get color => integer()();
}

class Subjects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get categoryId => integer().references(Categories, #id, onDelete: KeyAction.cascade)();
  IntColumn get completedVideos => integer().withDefault(const Constant(0))();
  IntColumn get totalVideos => integer()();
  TextColumn get playlistLink => text().withDefault(const Constant(''))();
  TextColumn get sourceName => text().withDefault(const Constant('Source'))();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
  IntColumn get position => integer()();
  IntColumn get color => integer().nullable()();
}

class CategoryWithSubjects {
  final Category category;
  final List<Subject> subjects;

  CategoryWithSubjects({
    required this.category,
    required this.subjects,
  });
}

@DriftDatabase(tables: [Categories, Subjects])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(conn.connect());

  @override
  int get schemaVersion => 1;

  // Streams all categories along with their matching subjects sorted by their respective position
  Stream<List<CategoryWithSubjects>> watchCategoriesWithSubjects() {
    final query = select(categories).join([
      leftOuterJoin(subjects, subjects.categoryId.equalsExp(categories.id)),
    ])..orderBy([
      OrderingTerm(expression: categories.position),
      OrderingTerm(expression: subjects.position),
    ]);

    return query.watch().map((rows) {
      final grouped = <Category, List<Subject>>{};
      for (final row in rows) {
        final cat = row.readTable(categories);
        final sub = row.readTableOrNull(subjects);
        grouped.putIfAbsent(cat, () => []);
        if (sub != null) {
          grouped[cat]!.add(sub);
        }
      }
      return grouped.entries.map((e) {
        return CategoryWithSubjects(
          category: e.key,
          subjects: e.value,
        );
      }).toList();
    });
  }

  // Stream raw list of subjects for things like progress calculation
  Stream<List<Subject>> watchSubjects() {
    return (select(subjects)..orderBy([(t) => OrderingTerm(expression: t.position)])).watch();
  }

  // ----------------------------------------------------
  // Category Operations
  // ----------------------------------------------------

  Future<int> addCategory(String name, int color, {int? position}) async {
    int pos = position ?? 0;
    if (position == null) {
      final existing = await select(categories).get();
      pos = existing.length;
    }
    return into(categories).insert(CategoriesCompanion.insert(
      name: name,
      color: color,
      position: pos,
    ));
  }

  Future<void> updateCategoryDetails(int id, String name, int color) async {
    await (update(categories)..where((t) => t.id.equals(id))).write(
      CategoriesCompanion(
        name: Value(name),
        color: Value(color),
      ),
    );
  }

  Future<void> deleteCategory(int id) async {
    // Cascade delete is handled at the database constraints level on supported engines,
    // but just to be safe and cross-platform clean, we'll manually ensure CASCADE delete
    await transaction(() async {
      await (delete(subjects)..where((t) => t.categoryId.equals(id))).go();
      await (delete(categories)..where((t) => t.id.equals(id))).go();
    });
  }

  Future<void> updateCategoryPositions(List<int> orderedCategoryIds) async {
    await transaction(() async {
      for (int i = 0; i < orderedCategoryIds.length; i++) {
        await (update(categories)..where((t) => t.id.equals(orderedCategoryIds[i]))).write(
          CategoriesCompanion(position: Value(i)),
        );
      }
    });
  }

  // ----------------------------------------------------
  // Subject Operations
  // ----------------------------------------------------

  Future<int> addSubject({
    required String name,
    required int categoryId,
    required int totalVideos,
    required String playlistLink,
    required String sourceName,
    required bool isActive,
    int? color,
    int? position,
  }) async {
    int pos = position ?? 0;
    if (position == null) {
      final existing = await (select(subjects)..where((t) => t.categoryId.equals(categoryId))).get();
      pos = existing.length;
    }
    return into(subjects).insert(SubjectsCompanion.insert(
      name: name,
      categoryId: categoryId,
      totalVideos: totalVideos,
      playlistLink: Value(playlistLink),
      sourceName: Value(sourceName),
      isActive: Value(isActive),
      position: pos,
      color: Value(color),
    ));
  }

  Future<void> updateSubjectProgress(int id, int completed) async {
    await (update(subjects)..where((t) => t.id.equals(id))).write(
      SubjectsCompanion(completedVideos: Value(completed)),
    );
  }

  Future<void> updateSubjectDetails({
    required int id,
    required String name,
    required int completed,
    required int total,
    required String sourceName,
    required String playlistLink,
    required bool isActive,
    int? color,
    int? categoryId,
  }) async {
    await (update(subjects)..where((t) => t.id.equals(id))).write(
      SubjectsCompanion(
        name: Value(name),
        completedVideos: Value(completed),
        totalVideos: Value(total),
        sourceName: Value(sourceName),
        playlistLink: Value(playlistLink),
        isActive: Value(isActive),
        color: Value(color),
        categoryId: categoryId != null ? Value(categoryId) : const Value.absent(),
      ),
    );
  }

  Future<void> deleteSubject(int id) async {
    await (delete(subjects)..where((t) => t.id.equals(id))).go();
  }

  Future<void> updateSubjectPositions(int categoryId, List<int> orderedSubjectIds) async {
    await transaction(() async {
      for (int i = 0; i < orderedSubjectIds.length; i++) {
        await (update(subjects)..where((t) => t.id.equals(orderedSubjectIds[i]))).write(
          SubjectsCompanion(
            position: Value(i),
            categoryId: Value(categoryId), // update category ID too in case they were moved
          ),
        );
      }
    });
  }

  // ----------------------------------------------------
  // Global / Preset Actions
  // ----------------------------------------------------

  Future<void> resetTrackingData() async {
    final all = await select(subjects).get();
    await transaction(() async {
      for (final s in all) {
        await (update(subjects)..where((t) => t.id.equals(s.id))).write(
          const SubjectsCompanion(completedVideos: Value(0)),
        );
      }
    });
  }

  Future<void> hardResetEverything() async {
    await transaction(() async {
      await delete(subjects).go();
      await delete(categories).go();
    });
  }

  Future<void> applyDefaultPreset() async {
    await transaction(() async {
      // Clear database first
      await delete(subjects).go();
      await delete(categories).go();

      // Seed categories
      final mathCatId = await into(categories).insert(CategoriesCompanion.insert(
        name: 'Mathematics',
        position: 0,
        color: 0xFFFF073A,
      ));

      final progCatId = await into(categories).insert(CategoriesCompanion.insert(
        name: 'Programming',
        position: 1,
        color: 0xFF00F0FF,
      ));

      final logicCatId = await into(categories).insert(CategoriesCompanion.insert(
        name: 'Machine Logic',
        position: 2,
        color: 0xFF39FF14,
      ));

      final systemsCatId = await into(categories).insert(CategoriesCompanion.insert(
        name: 'Core Systems',
        position: 3,
        color: 0xFFD500F9,
      ));

      final aptiCatId = await into(categories).insert(CategoriesCompanion.insert(
        name: 'Aptitude',
        position: 4,
        color: 0xFFFFE500,
      ));

      // Seed subjects under categories
      // Mathematics
      await into(subjects).insert(SubjectsCompanion.insert(
        name: 'Engineering Mathematics',
        categoryId: mathCatId,
        totalVideos: 111,
        playlistLink: const Value('https://www.goclasses.in/courses/Engineering-Mathematics-60fdd8530cf2c7989e1f109d#tableofcontents'),
        sourceName: const Value('GoClasses'),
        isActive: const Value(true),
        position: 0,
      ));
      await into(subjects).insert(SubjectsCompanion.insert(
        name: 'Discrete Mathematics',
        categoryId: mathCatId,
        totalVideos: 550,
        playlistLink: const Value('https://www.goclasses.in/courses/Discrete-Mathematics-Course-63f9aa9be4b0a8a370cfb0ad#tableofcontents'),
        sourceName: const Value('GoClasses'),
        isActive: const Value(true),
        position: 1,
      ));

      // Programming
      await into(subjects).insert(SubjectsCompanion.insert(
        name: 'C Programming',
        categoryId: progCatId,
        totalVideos: 88,
        playlistLink: const Value('https://youtube.com/playlist?list=PLC36xJgs4dxG-IqARhc23jYTDMYt7yvZP&si=6VlV1U-ZKheABCdk'),
        sourceName: const Value('Amit Khuarana [YT]'),
        isActive: const Value(true),
        position: 0,
      ));
      await into(subjects).insert(SubjectsCompanion.insert(
        name: 'Data Structures and Algorithms',
        categoryId: progCatId,
        totalVideos: 298,
        playlistLink: const Value('https://youtube.com/playlist?list=PLC36xJgs4dxFCQVvjMrrjcY3XrcMm2GHy&si=Tph-DUaw6MMVu1DR'),
        sourceName: const Value('Amit Khuarana'),
        isActive: const Value(true),
        position: 1,
      ));

      // Machine Logic
      await into(subjects).insert(SubjectsCompanion.insert(
        name: 'Theory of Computation',
        categoryId: logicCatId,
        totalVideos: 157,
        playlistLink: const Value('https://youtube.com/playlist?list=PLC36xJgs4dxGvebewU4z2CZYo-8nB93E7&si=1jOT-bXaKmaKMLJL'),
        sourceName: const Value('Amit Khuarana'),
        isActive: const Value(true),
        position: 0,
      ));
      await into(subjects).insert(SubjectsCompanion.insert(
        name: 'Digital Logic',
        categoryId: logicCatId,
        totalVideos: 176,
        playlistLink: const Value('https://youtube.com/playlist?list=PLC36xJgs4dxEErKQZ7xFxat8oh4OepU34&si=uVz1pzVjiHScbpQ8'),
        sourceName: const Value('Amit Khuarana'),
        isActive: const Value(true),
        position: 1,
      ));
      await into(subjects).insert(SubjectsCompanion.insert(
        name: 'Computer Organisation and Architecture',
        categoryId: logicCatId,
        totalVideos: 70,
        playlistLink: const Value('https://youtube.com/playlist?list=PLG9aCp4uE-s0xddCBjwMDnEVyc523WbA2&si=L42K61A9qxRmVXmk'),
        sourceName: const Value('Vishvadeep Gothi'),
        isActive: const Value(true),
        position: 2,
      ));

      // Core Systems
      await into(subjects).insert(SubjectsCompanion.insert(
        name: 'Operating Systems',
        categoryId: systemsCatId,
        totalVideos: 62,
        playlistLink: const Value('https://youtube.com/playlist?list=PLG9aCp4uE-s17rFjWM8KchGlffXgOzzVP&si=K8NLjYSO5UwWiRAC'),
        sourceName: const Value('Vishvadeep Gothi'),
        isActive: const Value(true),
        position: 0,
      ));
      await into(subjects).insert(SubjectsCompanion.insert(
        name: 'DBMS',
        categoryId: systemsCatId,
        totalVideos: 225,
        playlistLink: const Value('https://youtube.com/playlist?list=PLC36xJgs4dxGcz7nZaxGxxmbJrcgDXhFk&si=lcOcf4N0pQvdSh48'),
        sourceName: const Value('Amit Khuarana'),
        isActive: const Value(true),
        position: 1,
      ));
      await into(subjects).insert(SubjectsCompanion.insert(
        name: 'Computer Networks',
        categoryId: systemsCatId,
        totalVideos: 202,
        playlistLink: const Value('https://youtube.com/playlist?list=PLC36xJgs4dxHT-TxTy3U1slr5RaBJGaLd&si=QLAQ9Z5jJszsaA2i'),
        sourceName: const Value('Amit Khuarana'),
        isActive: const Value(true),
        position: 2,
      ));
      await into(subjects).insert(SubjectsCompanion.insert(
        name: 'Compiler Design',
        categoryId: systemsCatId,
        totalVideos: 39,
        playlistLink: const Value('https://youtube.com/playlist?list=PLxCzCOWd7aiEKtKSIHYusizkESC42diyc&si=R-YMyqDiSlwbN169'),
        sourceName: const Value('GATE Smashers'),
        isActive: const Value(true),
        position: 3,
      ));

      // Aptitude
      await into(subjects).insert(SubjectsCompanion.insert(
        name: 'Numerical Aptitude',
        categoryId: aptiCatId,
        totalVideos: 84,
        playlistLink: const Value('https://youtube.com/playlist?list=PLC36xJgs4dxE43Au1FGRQvwHTr7NbgDCS&si=aUlYagV9_09kY-UU'),
        sourceName: const Value('Amit Khurana'),
        isActive: const Value(true),
        position: 0,
      ));
      await into(subjects).insert(SubjectsCompanion.insert(
        name: 'Verbal Aptitude',
        categoryId: aptiCatId,
        totalVideos: 7,
        playlistLink: const Value('https://youtube.com/playlist?list=PLvTTv60o7qj8xhjIzJbRcr5d_hnm90Npv&si=mCxY1ZG4piJZAv1R'),
        sourceName: const Value('GATE Wallah'),
        isActive: const Value(true),
        position: 1,
      ));
    });
  }
}

