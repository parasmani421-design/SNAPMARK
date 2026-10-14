class AcademicCalendarEvent {
  const AcademicCalendarEvent({
    required this.title,
    required this.start,
    required this.end,
    required this.type,
    required this.details,
  });

  final String title;
  final DateTime start;
  final DateTime end;
  final AcademicEventType type;
  final String details;

  bool get isSingleDay => _sameDay(start, end);
}

enum AcademicEventType { exam, assessment, milestone, holiday, vacation }

class AcademicReminder {
  const AcademicReminder({
    required this.title,
    required this.message,
    required this.date,
    required this.isExamDay,
  });

  final String title;
  final String message;
  final DateTime date;
  final bool isExamDay;
}

DateTime _date(int month, int day) => DateTime(2026, month, day);

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

final List<AcademicCalendarEvent> academicCalendarEvents = [
  AcademicCalendarEvent(
    title: 'Course registration · Regular students',
    start: _date(8, 1),
    end: _date(8, 1),
    type: AcademicEventType.milestone,
    details: 'Regular-student course registration begins.',
  ),
  AcademicCalendarEvent(
    title: 'Change of programme window',
    start: _date(8, 1),
    end: _date(8, 6),
    type: AcademicEventType.milestone,
    details: 'Programme changes are scheduled during this window.',
  ),
  AcademicCalendarEvent(
    title: 'Course registration · Re-admitted students',
    start: _date(8, 10),
    end: _date(8, 20),
    type: AcademicEventType.milestone,
    details: 'Registration window for re-admitted students.',
  ),
  AcademicCalendarEvent(
    title: 'Last date of registration',
    start: _date(8, 10),
    end: _date(8, 10),
    type: AcademicEventType.milestone,
    details: 'Complete registration by this date.',
  ),
  AcademicCalendarEvent(
    title: 'CR selection · Year 2 onwards',
    start: _date(8, 10),
    end: _date(8, 10),
    type: AcademicEventType.milestone,
    details: 'Class representative selection date.',
  ),
  AcademicCalendarEvent(
    title: 'First-year student registration',
    start: _date(8, 17),
    end: _date(8, 19),
    type: AcademicEventType.milestone,
    details: 'Registration window for first-year students.',
  ),
  AcademicCalendarEvent(
    title: 'Last date of registration with fine',
    start: _date(8, 20),
    end: _date(8, 20),
    type: AcademicEventType.milestone,
    details: 'Last registration date with fine.',
  ),
  AcademicCalendarEvent(
    title: 'Registration for debarred classes',
    start: _date(8, 16),
    end: _date(8, 25),
    type: AcademicEventType.milestone,
    details: 'Registration window for debarred classes.',
  ),
  AcademicCalendarEvent(
    title: 'Classes commence · First year',
    start: _date(8, 20),
    end: _date(8, 20),
    type: AcademicEventType.milestone,
    details: 'First-year classes begin.',
  ),
  AcademicCalendarEvent(
    title: 'Classes commence · Year 2 onwards',
    start: _date(8, 6),
    end: _date(8, 6),
    type: AcademicEventType.milestone,
    details: 'Classes begin for students in year 2 and above.',
  ),
  AcademicCalendarEvent(
    title: 'CR selection · First year',
    start: _date(9, 1),
    end: _date(9, 1),
    type: AcademicEventType.milestone,
    details: 'Class representative selection date.',
  ),
  AcademicCalendarEvent(
    title: 'Internal Assessment Test 1',
    start: _date(10, 5),
    end: _date(10, 10),
    type: AcademicEventType.assessment,
    details: 'Review each subject daily and keep time for revision.',
  ),
  AcademicCalendarEvent(
    title: 'Mid-Term Examinations (MTE)',
    start: _date(10, 21),
    end: _date(10, 31),
    type: AcademicEventType.exam,
    details: 'Build a revision plan now; focus on one subject at a time.',
  ),
  AcademicCalendarEvent(
    title: 'Internal Assessment Test 2',
    start: _date(11, 17),
    end: _date(11, 21),
    type: AcademicEventType.assessment,
    details: 'Revise class notes and practice questions before each test.',
  ),
  AcademicCalendarEvent(
    title: 'Practical Examinations · Year 2 onwards',
    start: _date(12, 11),
    end: _date(12, 15),
    type: AcademicEventType.exam,
    details: 'Prepare lab records and rehearse practical steps.',
  ),
  AcademicCalendarEvent(
    title: 'Practical Examinations · First year',
    start: _date(12, 16),
    end: _date(12, 19),
    type: AcademicEventType.exam,
    details: 'Prepare lab records and rehearse practical steps.',
  ),
  AcademicCalendarEvent(
    title: 'End-Term Examinations (ETE) · Year 2 onwards',
    start: _date(12, 16),
    end: _date(12, 31),
    type: AcademicEventType.exam,
    details: 'Follow a steady revision routine and get enough rest.',
  ),
  AcademicCalendarEvent(
    title: 'End-Term Examinations (ETE) · First year',
    start: _date(12, 21),
    end: _date(12, 31),
    type: AcademicEventType.exam,
    details: 'Follow a steady revision routine and get enough rest.',
  ),
  AcademicCalendarEvent(
    title: 'Declaration of Results',
    start: DateTime(2027, 1, 31),
    end: DateTime(2027, 1, 31),
    type: AcademicEventType.milestone,
    details: 'Odd-semester results are scheduled to be declared.',
  ),
  AcademicCalendarEvent(
    title: 'Winter vacation',
    start: DateTime(2027, 1, 1),
    end: DateTime(2027, 1, 7),
    type: AcademicEventType.vacation,
    details: 'Winter vacation is marked for seven days in the calendar.',
  ),
  ..._holidays,
]..sort((a, b) => a.start.compareTo(b.start));

final List<AcademicCalendarEvent> _holidays =
    [
          ("Sawan Shivratri", 8, 11),
          ("Independence Day", 8, 15),
          ("Milad un-Nabi / Id-e-Milad", 8, 26),
          ("Raksha Bandhan", 8, 28),
          ("Janmashtami", 9, 4),
          ("Mahatma Gandhi Jayanti", 10, 2),
          ("Ram Navami", 10, 19),
          ("Dussehra", 10, 20),
          ("Maharishi Valmiki Jayanti", 10, 26),
          ("Diwali", 11, 8),
          ("Govardhan Puja", 11, 9),
          ("Bhai Dooj", 11, 11),
          ("Chhath Puja", 11, 15),
          ("Guru Nanak Jayanti / Teg Bahadur Shaheedi Diwas", 11, 24),
          ("Christmas", 12, 25),
        ]
        .map(
          (holiday) => AcademicCalendarEvent(
            title: holiday.$1,
            start: _date(holiday.$2, holiday.$3),
            end: _date(holiday.$2, holiday.$3),
            type: AcademicEventType.holiday,
            details: 'University holiday listed in the academic calendar.',
          ),
        )
        .toList();

List<AcademicReminder> academicRemindersFor(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final reminders = <AcademicReminder>[];
  for (final event in academicCalendarEvents.where(
    (item) =>
        item.type == AcademicEventType.exam ||
        item.type == AcademicEventType.assessment,
  )) {
    final start = DateTime(
      event.start.year,
      event.start.month,
      event.start.day,
    );
    final daysUntil = start.difference(today).inDays;
    if (daysUntil == 14 || daysUntil == 7 || daysUntil == 3 || daysUntil == 1) {
      reminders.add(
        AcademicReminder(
          title: '${event.title} in $daysUntil days',
          message:
              'Start preparing today. Make a short revision plan, practise questions, and ask your teacher about topics you find difficult.',
          date: start.subtract(Duration(days: daysUntil)),
          isExamDay: false,
        ),
      );
    }
    if (_sameDay(today, start)) {
      reminders.add(
        AcademicReminder(
          title: 'All the best for ${event.title}',
          message:
              'You have prepared for this. Stay calm, read each question carefully, and do your best. Good luck! ✨',
          date: today,
          isExamDay: true,
        ),
      );
    }
  }
  reminders.sort((a, b) => a.date.compareTo(b.date));
  return reminders;
}

List<AcademicReminder> upcomingAcademicReminders(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final result = <AcademicReminder>[];
  for (final event in academicCalendarEvents.where(
    (item) =>
        item.type == AcademicEventType.exam ||
        item.type == AcademicEventType.assessment,
  )) {
    final start = DateTime(
      event.start.year,
      event.start.month,
      event.start.day,
    );
    for (final days in [14, 7, 3, 1]) {
      final reminderDate = start.subtract(Duration(days: days));
      if (!reminderDate.isBefore(today)) {
        result.add(
          AcademicReminder(
            title: '${event.title} in $days days',
            message:
                'Begin preparation now: revise a little each day, practise questions, and get help with difficult topics.',
            date: reminderDate,
            isExamDay: false,
          ),
        );
      }
    }
    if (!start.isBefore(today)) {
      result.add(
        AcademicReminder(
          title: 'Exam-day wishes · ${event.title}',
          message:
              'On the first day: stay calm, trust your preparation, and do your best. Good luck! ✨',
          date: start,
          isExamDay: true,
        ),
      );
    }
  }
  result.sort((a, b) => a.date.compareTo(b.date));
  return result;
}

String academicDateLabel(DateTime date, {bool includeYear = false}) {
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final label =
      '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  return includeYear ? '$label ${date.year}' : label;
}
