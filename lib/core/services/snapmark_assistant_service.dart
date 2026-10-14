import 'attendance_demo_data.dart';
import 'campus_help_service.dart';

class SnapMarkAssistantService {
  const SnapMarkAssistantService();

  // Demo values currently shown by the Attendance screen. Replace these with
  // the signed-in student's API records when the college backend is connected.
  static int get attendedClasses => AttendanceDemoData.attended;
  static int get deliveredClasses => AttendanceDemoData.delivered;
  static List<AttendanceDemoSubject> get subjects =>
      AttendanceDemoData.subjects;

  String replyTo(String question) {
    final campusReply = CampusHelpService.replyTo(question);
    if (campusReply != null) return campusReply;
    final query = question.toLowerCase().trim();
    if (query.isEmpty) return 'Type a question and I’ll try to help.';

    final subject = subjects.cast<AttendanceDemoSubject?>().firstWhere(
      (item) => [
        item!.name,
        ...item.aliases,
      ].any((name) => query.contains(name.toLowerCase())),
      orElse: () => null,
    );
    if (subject != null) return _subjectReply(subject);

    if (_hasAny(query, [
      '75%',
      '75 percent',
      'subject',
      'classes to',
      'how many class',
    ])) {
      return _allSubjectReply();
    }
    if (_hasAny(query, ['debar', 'risk', 'below 70', '70%', '70 percent'])) {
      final rate = attendedClasses / deliveredClasses;
      return rate < .70
          ? 'Your sample overall attendance is ${(rate * 100).round()}%, below 70%. This can put you at risk of exam debarment under your college rules. Attend every upcoming class and contact your faculty. Confirm the exact rule with your college.'
          : 'Your sample overall attendance is ${(rate * 100).round()}%, which is not below 70%. Keep attending classes and check your college’s official attendance policy.';
    }
    if (_hasAny(query, ['overall', 'attendance', 'present', 'absent'])) {
      final rate = attendedClasses / deliveredClasses;
      return 'Sample overall attendance: ${(rate * 100).toStringAsFixed(1)}% ($attendedClasses of $deliveredClasses classes attended). These are demo figures; live student records are not connected yet.';
    }
    if (_hasAny(query, ['fee', 'fees', 'payment', 'due', 'balance'])) {
      return 'The Fees page currently shows sample figures: ₹40,000 remaining out of ₹1,20,000. Please confirm your actual balance in the official college ERP; live fee records are not connected yet.';
    }
    if (_hasAny(query, ['timetable', 'today class', 'schedule', 'lecture'])) {
      return 'Open the Timetable section on your dashboard to view the sample weekly schedule. Live timetable sync is not connected yet.';
    }
    if (_hasAny(query, ['study', 'plan', 'exam', 'revision', 'tips'])) {
      return 'Try a simple plan: choose one topic, study for 25 minutes, take a 5-minute break, then solve a few questions without notes. Repeat this for two or three focused rounds and review mistakes at the end.';
    }
    if ([
      'hi',
      'hello',
      'hey',
      'namaste',
    ].any((greeting) => query == greeting || query.startsWith('$greeting '))) {
      return 'Hi Paras! You can ask me about overall attendance, the classes needed to reach 75% in a subject, fees, timetable, or study planning.';
    }
    return 'I can help with attendance risk, 75% subject targets, fees, timetable, and study planning. Try one of the suggestions below. My current answers use demo data, not a live AI service or college database.';
  }

  String _subjectReply(AttendanceDemoSubject subject) {
    final percentage = subject.present / subject.total;
    if (percentage >= .75) {
      return '${subject.name}: ${subject.present}/${subject.total} classes (${(percentage * 100).toStringAsFixed(1)}%). You have met the 75% target; keep attending to maintain it.';
    }
    final classesNeeded = (3 * subject.total - 4 * subject.present).clamp(
      0,
      1 << 31,
    );
    return '${subject.name}: ${subject.present}/${subject.total} classes (${(percentage * 100).toStringAsFixed(1)}%). Attend the next $classesNeeded classes consecutively to reach 75%, assuming no more absences. This is based on sample figures.';
  }

  String _allSubjectReply() {
    return subjects
        .map((subject) {
          final percentage = subject.present / subject.total;
          if (percentage >= .75) {
            return '• ${subject.name}: ${(percentage * 100).toStringAsFixed(1)}% — target met; keep attending.';
          }
          final needed = (3 * subject.total - 4 * subject.present).clamp(
            0,
            1 << 31,
          );
          return '• ${subject.name}: ${(percentage * 100).toStringAsFixed(1)}% — attend next $needed classes consecutively to reach 75%.';
        })
        .join('\n');
  }

  bool _hasAny(String value, List<String> terms) => terms.any(value.contains);
}
