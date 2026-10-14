import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CampusConfigurationStore {
  CampusConfigurationStore._();

  static const _scheduleKey = 'snapmark.campus.schedule.v1';
  static const _sectionsKey = 'snapmark.campus.sections.v1';
  static const defaultSections = ['47', '48', '49'];
  static List<String> sections = [...defaultSections];

  /// Loads saved admin changes into the shared timetable map before the app UI.
  static Future<void> initialize(
    Map<int, List<Map<String, String>>> schedule,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final savedSchedule = preferences.getString(_scheduleKey);
    if (savedSchedule != null && savedSchedule.isNotEmpty) {
      try {
        final decoded = jsonDecode(savedSchedule) as Map<String, dynamic>;
        schedule
          ..clear()
          ..addAll({
            for (final entry in decoded.entries)
              int.parse(entry.key): (entry.value as List<dynamic>)
                  .whereType<Map>()
                  .map(
                    (lesson) => Map<String, String>.from(
                      lesson.map(
                        (key, value) =>
                            MapEntry(key.toString(), value.toString()),
                      ),
                    ),
                  )
                  .toList(),
          });
      } catch (_) {
        // Keep the bundled timetable if the saved configuration is unreadable.
      }
    }

    var repairedLegacyTime = false;
    for (final dayLessons in schedule.values) {
      for (final lesson in dayLessons) {
        final time = lesson['time'];
        if (time == '08:30 AM - 90:20 AM') {
          lesson['time'] = '08:30 AM - 09:20 AM';
          repairedLegacyTime = true;
        } else if (time == '11:20 PM - 012:010 PM') {
          lesson['time'] = '11:20 AM - 12:10 PM';
          repairedLegacyTime = true;
        }
      }
    }
    if (repairedLegacyTime) await _saveSchedule(schedule);

    final savedSections = preferences.getString(_sectionsKey);
    if (savedSections != null && savedSections.isNotEmpty) {
      try {
        final decoded = (jsonDecode(savedSections) as List<dynamic>)
            .whereType<String>()
            .map((section) => section.trim())
            .where((section) => section.isNotEmpty)
            .toSet()
            .toList();
        if (decoded.isNotEmpty) sections = decoded;
      } catch (_) {
        sections = [...defaultSections];
      }
    }
  }

  static Future<void> saveLesson({
    required Map<int, List<Map<String, String>>> schedule,
    required int day,
    required Map<String, String> lesson,
    int? existingDay,
    int? existingIndex,
  }) async {
    if (existingDay != null && existingIndex != null) {
      final oldDayLessons = List<Map<String, String>>.of(
        schedule[existingDay] ?? const <Map<String, String>>[],
      );
      if (existingIndex < oldDayLessons.length) {
        oldDayLessons.removeAt(existingIndex);
        schedule[existingDay] = oldDayLessons;
      }
    }
    final dayLessons = List<Map<String, String>>.of(
      schedule[day] ?? const <Map<String, String>>[],
    );
    dayLessons.add(lesson);
    dayLessons.sort(
      (a, b) => _timeOrder(a['time']).compareTo(_timeOrder(b['time'])),
    );
    schedule[day] = dayLessons;
    await _saveSchedule(schedule);
  }

  static Future<void> deleteLesson({
    required Map<int, List<Map<String, String>>> schedule,
    required int day,
    required int index,
  }) async {
    final dayLessons = List<Map<String, String>>.of(
      schedule[day] ?? const <Map<String, String>>[],
    );
    if (index < 0 || index >= dayLessons.length) return;
    dayLessons.removeAt(index);
    schedule[day] = dayLessons;
    await _saveSchedule(schedule);
  }

  static Future<void> addSection(String section) async {
    final normalized = section.trim();
    if (normalized.isEmpty || sections.contains(normalized)) return;
    sections = [...sections, normalized]..sort(_sectionSort);
    await _saveSections();
  }

  static Future<void> renameSection({
    required String oldName,
    required String newName,
    required Map<int, List<Map<String, String>>> schedule,
  }) async {
    final normalized = newName.trim();
    if (normalized.isEmpty ||
        sections.contains(normalized) && normalized != oldName) {
      return;
    }
    final index = sections.indexOf(oldName);
    if (index < 0) return;
    sections[index] = normalized;
    sections.sort(_sectionSort);
    await _saveSections();
    for (final day in schedule.keys.toList()) {
      schedule[day] = [
        for (final lesson in schedule[day]!)
          if (lesson['section'] == oldName)
            {...lesson, 'section': normalized}
          else
            lesson,
      ];
    }
    await _saveSchedule(schedule);
  }

  static bool sectionHasScheduledClasses(
    Map<int, List<Map<String, String>>> schedule,
    String section,
  ) => schedule.values.any(
    (lessons) => lessons.any((lesson) => lesson['section'] == section),
  );

  static Future<void> removeSection(String section) async {
    if (sections.length <= 1) return;
    sections = sections.where((item) => item != section).toList();
    await _saveSections();
  }

  static Future<void> _saveSections() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_sectionsKey, jsonEncode(sections));
  }

  static Future<void> _saveSchedule(
    Map<int, List<Map<String, String>>> schedule,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _scheduleKey,
      jsonEncode({
        for (final entry in schedule.entries) entry.key.toString(): entry.value,
      }),
    );
  }

  static int _sectionSort(String a, String b) {
    final aNumber = int.tryParse(a);
    final bNumber = int.tryParse(b);
    if (aNumber != null && bNumber != null) return aNumber.compareTo(bNumber);
    return a.toLowerCase().compareTo(b.toLowerCase());
  }

  static int _timeOrder(String? value) {
    if (value == null) return 24 * 60;
    final match = RegExp(
      r'(\d{1,2}):(\d{2})\s*(AM|PM)',
      caseSensitive: false,
    ).firstMatch(value);
    if (match == null) return 24 * 60;
    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour < 1 || hour > 12 || minute > 59) return 24 * 60;
    final period = match.group(3)!.toUpperCase();
    hour %= 12;
    if (period == 'PM') hour += 12;
    return hour * 60 + minute;
  }
}
