import 'dart:math';

String getCategoryShortName(String name) {
  if (name.isEmpty) return "";
  final parts = name.trim().split(RegExp(r'[^a-zA-Z0-9]+')).where((p) => p.isNotEmpty);
  if (parts.isEmpty) return "";
  if (parts.length == 1) {
    final word = parts.first;
    if (word.length <= 3) return word.toUpperCase();
    return word.substring(0, min(3, word.length)).toUpperCase();
  }
  return parts.map((p) => p[0].toUpperCase()).join("");
}

String formatTimeOfDay(DateTime dateTime) {
  final hour = dateTime.hour;
  final minute = dateTime.minute;
  final ampm = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;
  final displayMinute = minute.toString().padLeft(2, '0');
  return "$displayHour:$displayMinute $ampm";
}
