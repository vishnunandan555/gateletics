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

  static const List<String> categories = [
    'Mathematical Foundation',
    'Programming Foundation',
    'System Depth',
    'Rest of the Stuff',
  ];

  static const Map<String, int> categoryColors = {
    'Mathematical Foundation': 0xFFFF073A,
    'Programming Foundation': 0xFFFF6C00,
    'System Depth': 0xFF00F0FF,
    'Rest of the Stuff': 0xFFD500F9,
  };
}
