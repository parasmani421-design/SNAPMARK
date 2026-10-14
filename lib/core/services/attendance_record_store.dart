import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AttendanceEntry {
  const AttendanceEntry({
    required this.studentEmail,
    required this.studentName,
    required this.roll,
    required this.subject,
    required this.date,
    required this.present,
  });

  final String studentEmail, studentName, roll, subject, date;
  final bool present;

  Map<String, dynamic> toJson() => {
    'studentEmail': studentEmail.toLowerCase(),
    'studentName': studentName,
    'roll': roll,
    'subject': subject,
    'date': date,
    'present': present,
  };

  factory AttendanceEntry.fromJson(Map<String, dynamic> json) =>
      AttendanceEntry(
        studentEmail: json['studentEmail'] as String? ?? '',
        studentName: json['studentName'] as String? ?? '',
        roll: json['roll'] as String? ?? '',
        subject: json['subject'] as String? ?? 'Class',
        date: json['date'] as String? ?? '',
        present: json['present'] == true,
      );
}

class AttendanceRecordStore {
  AttendanceRecordStore._();
  static const _storage = FlutterSecureStorage();
  static const _key = 'snapmark.attendance.records.v1';

  static Future<List<AttendanceEntry>> loadAll() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .whereType<Map>()
          .map(
            (item) => AttendanceEntry.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<AttendanceEntry>> forStudent(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return [];
    return (await loadAll())
        .where((entry) => entry.studentEmail.toLowerCase() == normalized)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static Future<void> saveSession(List<AttendanceEntry> session) async {
    if (session.isEmpty) return;
    final entries = await loadAll();
    for (final entry in session) {
      entries.removeWhere(
        (existing) =>
            existing.studentEmail.toLowerCase() ==
                entry.studentEmail.toLowerCase() &&
            existing.subject == entry.subject &&
            existing.date == entry.date,
      );
      entries.add(entry);
    }
    await _storage.write(
      key: _key,
      value: jsonEncode(entries.map((entry) => entry.toJson()).toList()),
    );
  }
}
