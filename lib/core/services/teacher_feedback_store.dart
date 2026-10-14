import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class TeacherFeedback {
  const TeacherFeedback({
    required this.id,
    required this.studentEmail,
    required this.facultyEmail,
    required this.facultyName,
    required this.section,
    required this.rating,
    required this.strengths,
    required this.improvements,
    required this.comment,
    required this.submittedAt,
  });

  final String id;
  final String studentEmail;
  final String facultyEmail;
  final String facultyName;
  final String section;
  final int rating;
  final List<String> strengths;
  final List<String> improvements;
  final String comment;
  final String submittedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentEmail': studentEmail,
    'facultyEmail': facultyEmail,
    'facultyName': facultyName,
    'section': section,
    'rating': rating,
    'strengths': strengths,
    'improvements': improvements,
    'comment': comment,
    'submittedAt': submittedAt,
  };

  factory TeacherFeedback.fromJson(Map<String, dynamic> json) =>
      TeacherFeedback(
        id: json['id'] as String? ?? '',
        studentEmail: json['studentEmail'] as String? ?? '',
        facultyEmail: json['facultyEmail'] as String? ?? '',
        facultyName: json['facultyName'] as String? ?? 'Faculty',
        section: json['section'] as String? ?? '',
        rating: (json['rating'] as num?)?.toInt() ?? 0,
        strengths: (json['strengths'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toList(),
        improvements: (json['improvements'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toList(),
        comment: json['comment'] as String? ?? '',
        submittedAt: json['submittedAt'] as String? ?? '',
      );
}

class TeacherFeedbackStore {
  TeacherFeedbackStore._();

  static const _key = 'snapmark.teacher_feedback.v1';

  static Future<List<TeacherFeedback>> loadAll() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .whereType<Map>()
          .map(
            (item) => TeacherFeedback.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList()
        ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    } catch (_) {
      return [];
    }
  }

  static Future<List<TeacherFeedback>> forFaculty(
    String facultyEmail, {
    String facultyName = '',
  }) async {
    final email = facultyEmail.trim().toLowerCase();
    final normalizedName = _normalizeName(facultyName);
    return (await loadAll())
        .where(
          (item) =>
              item.facultyEmail.toLowerCase() == email ||
              (normalizedName.isNotEmpty &&
                  _normalizeName(item.facultyName) == normalizedName),
        )
        .toList();
  }

  static String _normalizeName(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceFirst(RegExp(r'^(dr|prof|professor)\s+'), '')
      .replaceAll('gaurav agarwal', 'gaurav agrawal')
      .trim();

  static Future<TeacherFeedback?> fromStudentForFaculty({
    required String studentEmail,
    required String facultyEmail,
  }) async {
    final student = studentEmail.trim().toLowerCase();
    final faculty = facultyEmail.trim().toLowerCase();
    for (final item in await loadAll()) {
      if (item.studentEmail.toLowerCase() == student &&
          item.facultyEmail.toLowerCase() == faculty) {
        return item;
      }
    }
    return null;
  }

  static Future<void> save(TeacherFeedback feedback) async {
    final items = await loadAll();
    final index = items.indexWhere((item) => item.id == feedback.id);
    if (index < 0) {
      items.insert(0, feedback);
    } else {
      items[index] = feedback;
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _key,
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }
}
