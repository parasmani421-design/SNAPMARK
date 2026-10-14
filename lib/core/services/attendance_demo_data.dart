/// Shared CSE (AI) sample figures used until teacher-submitted records exist.
class AttendanceDemoSubject {
  final String name;
  final int present;
  final int total;
  final List<String> aliases;

  const AttendanceDemoSubject(
    this.name,
    this.present,
    this.total, {
    this.aliases = const [],
  });

  double get rate => total == 0 ? 0 : present / total;
}

class AttendanceDemoData {
  AttendanceDemoData._();

  static const subjects = <AttendanceDemoSubject>[
    AttendanceDemoSubject(
      'Multivariable Calculus and Differential Equations',
      18,
      20,
    ),
    AttendanceDemoSubject(
      'Data Structures and Algorithms (DSA)',
      17,
      18,
      aliases: ['Data Structures', 'DSA'],
    ),
    AttendanceDemoSubject('Advanced Aptitude Skill', 15, 16),
    AttendanceDemoSubject('Java Programming', 12, 14),
    AttendanceDemoSubject(
      'Database Management System (DBMS)',
      14,
      16,
      aliases: ['Data Base Management System', 'DBMS'],
    ),
    AttendanceDemoSubject('Python Programming', 10, 16),
    AttendanceDemoSubject('Basic Electrical and Electronics (BEEE)', 10, 15),
    AttendanceDemoSubject('Computer Organization', 13, 18),
    AttendanceDemoSubject('Design Thinking', 15, 18),
  ];

  static int get attended =>
      subjects.fold(0, (sum, subject) => sum + subject.present);
  static int get delivered =>
      subjects.fold(0, (sum, subject) => sum + subject.total);
  static double get rate => delivered == 0 ? 0 : attended / delivered;

  static bool hasCompleteSubjectCoverage(Iterable<String> subjectNames) {
    final available = subjectNames
        .map((name) => name.trim().toLowerCase())
        .toSet();
    return subjects.every(
      (subject) => [
        subject.name,
        ...subject.aliases,
      ].any((name) => available.contains(name.toLowerCase())),
    );
  }
}
