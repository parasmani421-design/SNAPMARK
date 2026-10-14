import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StudentDirectoryField {
  const StudentDirectoryField(this.keyName, this.label);
  final String keyName;
  final String label;
}

class StudentRecord {
  const StudentRecord({required this.id, required this.profile});

  final String id;
  final Map<String, String> profile;

  String value(String key) => profile[key]?.trim() ?? '';

  StudentRecord copyWith({String? id, Map<String, String>? profile}) =>
      StudentRecord(id: id ?? this.id, profile: profile ?? this.profile);

  Map<String, Object?> toJson() => {'id': id, 'profile': profile};

  factory StudentRecord.fromJson(Map<String, dynamic> json) {
    final rawProfile = json['profile'];
    return StudentRecord(
      id: (json['id'] as String?) ?? '',
      profile: rawProfile is Map
          ? rawProfile.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            )
          : <String, String>{},
    );
  }
}

class FacultyRecord {
  const FacultyRecord({required this.id, required this.profile});

  final String id;
  final Map<String, String> profile;

  String value(String key) => profile[key]?.trim() ?? '';

  Map<String, Object?> toJson() => {'id': id, 'profile': profile};

  factory FacultyRecord.fromJson(Map<String, dynamic> json) {
    final rawProfile = json['profile'];
    return FacultyRecord(
      id: (json['id'] as String?) ?? '',
      profile: rawProfile is Map
          ? rawProfile.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            )
          : <String, String>{},
    );
  }
}

class StudentDirectoryStore {
  StudentDirectoryStore._();
  static const _storage = FlutterSecureStorage();
  static const _directoryKey = 'snapmark.admin.student_directory.v1';
  static const _activeEmailKey = 'snapmark.active_student_email';
  static const _removedEmailsKey = 'snapmark.admin.removed_student_emails';
  static const _facultyKey = 'snapmark.admin.faculty_directory.v1';
  static const _activeFacultyEmailKey = 'snapmark.active_faculty_email';
  static const _removedFacultyEmailsKey =
      'snapmark.admin.removed_faculty_emails';
  static const facultyFields = <StudentDirectoryField>[
    StudentDirectoryField('full_name', 'Full name'),
    StudentDirectoryField('email', 'Faculty email'),
    StudentDirectoryField('employee_id', 'Employee ID'),
    StudentDirectoryField('department', 'Department'),
    StudentDirectoryField('designation', 'Designation'),
    StudentDirectoryField('phone', 'Mobile number'),
  ];

  static const profileFields = <StudentDirectoryField>[
    StudentDirectoryField('full_name', 'Full name'),
    StudentDirectoryField('email', 'Email address'),
    StudentDirectoryField('enrollment_number', 'Enrollment number'),
    StudentDirectoryField('admission_number', 'Admission number'),
    StudentDirectoryField('roll_number', 'Roll number'),
    StudentDirectoryField('phone', 'Mobile number'),
    StudentDirectoryField('program', 'Course / program'),
    StudentDirectoryField('section', 'Section'),
    StudentDirectoryField('mentor_email', 'Assigned mentor faculty email'),
    StudentDirectoryField('academic_year', 'Academic year'),
    StudentDirectoryField('semester', 'Current semester'),
    StudentDirectoryField('date_of_birth', 'Date of birth'),
    StudentDirectoryField('gender', 'Gender'),
    StudentDirectoryField('abc_id', 'ABC ID'),
    StudentDirectoryField('address', 'House / street address'),
    StudentDirectoryField('city', 'City'),
    StudentDirectoryField('state', 'State'),
    StudentDirectoryField('pin_code', 'PIN code'),
    StudentDirectoryField('father_name', 'Father’s name'),
    StudentDirectoryField('father_phone', 'Father’s phone'),
    StudentDirectoryField('mother_name', 'Mother’s name'),
    StudentDirectoryField('mother_phone', 'Mother’s phone'),
    StudentDirectoryField('guardian_name', 'Guardian name'),
    StudentDirectoryField('guardian_phone', 'Guardian phone'),
  ];

  static Future<List<FacultyRecord>> loadAllFaculty() async {
    final raw = await _storage.read(key: _facultyKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(FacultyRecord.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<FacultyRecord?> findFacultyByEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    for (final record in await loadAllFaculty()) {
      if (record.value('email').toLowerCase() == normalized) return record;
    }
    return null;
  }

  static Future<void> saveFaculty(FacultyRecord record) async {
    final records = await loadAllFaculty();
    final index = records.indexWhere((item) => item.id == record.id);
    if (index < 0) {
      records.add(record);
    } else {
      records[index] = record;
    }
    await _storage.write(
      key: _facultyKey,
      value: jsonEncode(records.map((item) => item.toJson()).toList()),
    );
    await _clearRemovedFacultyEmail(record.value('email'));
  }

  static Future<void> saveFacultyProfileForEmail(
    String email,
    Map<String, String> values,
  ) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return;
    final records = await loadAllFaculty();
    final index = records.indexWhere(
      (record) => record.value('email').toLowerCase() == normalized,
    );
    final profile = <String, String>{
      if (index >= 0) ...records[index].profile,
      ...values,
      'email': email.trim(),
    };
    final record = FacultyRecord(
      id: index >= 0 ? records[index].id : normalized,
      profile: profile,
    );
    if (index >= 0) {
      records[index] = record;
    } else {
      records.add(record);
    }
    await _storage.write(
      key: _facultyKey,
      value: jsonEncode(records.map((item) => item.toJson()).toList()),
    );
    await _clearRemovedFacultyEmail(email);
  }

  static Future<void> deleteFaculty(String id) async {
    final records = await loadAllFaculty();
    final index = records.indexWhere((record) => record.id == id);
    if (index < 0) return;
    final email = records[index].value('email').toLowerCase();
    records.removeAt(index);
    await _storage.write(
      key: _facultyKey,
      value: jsonEncode(records.map((item) => item.toJson()).toList()),
    );
    if (email.isNotEmpty) {
      final removed = await _removedFacultyEmails();
      if (!removed.contains(email)) removed.add(email);
      await _storage.write(
        key: _removedFacultyEmailsKey,
        value: jsonEncode(removed),
      );
    }
  }

  static Future<bool> isDeletedFacultyEmail(String email) async =>
      (await _removedFacultyEmails()).contains(email.trim().toLowerCase());

  static Future<List<String>> _removedFacultyEmails() async {
    final raw = await _storage.read(key: _removedFacultyEmailsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .whereType<String>()
          .map((email) => email.toLowerCase())
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _clearRemovedFacultyEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    final removed = await _removedFacultyEmails();
    if (removed.remove(normalized)) {
      await _storage.write(
        key: _removedFacultyEmailsKey,
        value: jsonEncode(removed),
      );
    }
  }

  static Future<void> setActiveFacultyEmail(String email) => _storage.write(
    key: _activeFacultyEmailKey,
    value: email.trim().toLowerCase(),
  );

  static Future<String?> activeFacultyEmail() =>
      _storage.read(key: _activeFacultyEmailKey);

  static Future<void> clearActiveFacultyEmail() =>
      _storage.delete(key: _activeFacultyEmailKey);

  static Future<void> clearActiveIdentity() async {
    await clearActiveEmail();
    await clearActiveFacultyEmail();
  }

  static Future<List<StudentRecord>> loadAll() async {
    final raw = await _storage.read(key: _directoryKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(StudentRecord.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(StudentRecord record) async {
    final records = await loadAll();
    final index = records.indexWhere((item) => item.id == record.id);
    if (index == -1) {
      records.add(record);
    } else {
      records[index] = record;
    }
    await _writeAll(records);
    await _clearRemovedEmail(record.value('email'));
  }

  static Future<void> saveProfileForEmail(
    String email,
    Map<String, String> values,
  ) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) return;
    final records = await loadAll();
    final index = records.indexWhere(
      (record) => record.value('email').toLowerCase() == normalizedEmail,
    );
    final merged = <String, String>{
      if (index >= 0) ...records[index].profile,
      ...values,
      'email': email.trim(),
    };
    final id = index >= 0 ? records[index].id : normalizedEmail;
    final record = StudentRecord(id: id, profile: merged);
    if (index >= 0) {
      records[index] = record;
    } else {
      records.add(record);
    }
    await _writeAll(records);
    await _clearRemovedEmail(email);
  }

  static Future<void> syncActiveProfile(Map<String, String> values) async {
    final active = await activeEmail();
    final records = await loadAll();
    final index = active == null
        ? -1
        : records.indexWhere(
            (record) =>
                record.value('email').toLowerCase() == active.toLowerCase(),
          );
    if (index >= 0) {
      records[index] = records[index].copyWith(
        profile: <String, String>{...records[index].profile, ...values},
      );
      await _writeAll(records);
      return;
    }
    if (active != null && await isDeletedEmail(active)) return;
    final email = values['email']?.trim().isNotEmpty == true
        ? values['email']!.trim()
        : active ?? '';
    await saveProfileForEmail(email, values);
  }

  static Future<void> delete(String id) async {
    final records = await loadAll();
    final index = records.indexWhere((record) => record.id == id);
    if (index < 0) return;
    final removedEmail = records[index].value('email').toLowerCase();
    records.removeAt(index);
    await _writeAll(records);
    if (removedEmail.isNotEmpty) {
      final removed = await _removedEmails();
      if (!removed.contains(removedEmail)) removed.add(removedEmail);
      await _storage.write(key: _removedEmailsKey, value: jsonEncode(removed));
    }
  }

  static Future<bool> isDeletedEmail(String email) async =>
      (await _removedEmails()).contains(email.trim().toLowerCase());

  static Future<List<String>> _removedEmails() async {
    final raw = await _storage.read(key: _removedEmailsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .whereType<String>()
          .map((email) => email.toLowerCase())
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _clearRemovedEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return;
    final removed = await _removedEmails();
    if (removed.remove(normalized)) {
      await _storage.write(key: _removedEmailsKey, value: jsonEncode(removed));
    }
  }

  static Future<StudentRecord?> findByEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    for (final record in await loadAll()) {
      if (record.value('email').toLowerCase() == normalizedEmail) return record;
    }
    return null;
  }

  static Future<void> setActiveEmail(String email) =>
      _storage.write(key: _activeEmailKey, value: email.trim().toLowerCase());

  static Future<String?> activeEmail() => _storage.read(key: _activeEmailKey);

  static Future<void> clearActiveEmail() =>
      _storage.delete(key: _activeEmailKey);

  static Future<void> _writeAll(List<StudentRecord> records) => _storage.write(
    key: _directoryKey,
    value: jsonEncode(records.map((record) => record.toJson()).toList()),
  );
}
