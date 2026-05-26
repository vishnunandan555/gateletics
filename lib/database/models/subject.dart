import 'package:isar_community/isar.dart';

part 'subject.g.dart';

@collection
class Subject {
  Id id = Isar.autoIncrement;

  late String name;

  late String category;

  int completedVideos = 0;

  late int totalVideos;

  String playlistLink = '';

  String sourceName = 'Source';

  bool isActive = false;
}
