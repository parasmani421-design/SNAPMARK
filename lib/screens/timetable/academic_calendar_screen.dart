import 'package:flutter/material.dart';

import '../../core/services/academic_calendar_service.dart';

class AcademicCalendarScreen extends StatefulWidget {
  const AcademicCalendarScreen({super.key, this.showReminders = false});

  final bool showReminders;

  @override
  State<AcademicCalendarScreen> createState() => _AcademicCalendarScreenState();
}

class _AcademicCalendarScreenState extends State<AcademicCalendarScreen> {
  bool _firstYear = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final events = academicCalendarEvents.where((event) {
      if (event.title.contains('First year')) return _firstYear;
      if (event.title.contains('Year 2 onwards')) return !_firstYear;
      return true;
    }).toList();
    final reminders = upcomingAcademicReminders(now);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.showReminders ? 'Academic notifications' : 'Academic calendar',
        ),
        actions: [
          if (!widget.showReminders)
            IconButton(
              tooltip: 'Academic notifications',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const AcademicCalendarScreen(showReminders: true),
                ),
              ),
              icon: const Icon(Icons.notifications_active_outlined),
            ),
        ],
      ),
      body: widget.showReminders
          ? _remindersList(context, reminders)
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
              children: [
                _semesterBanner(context, now, isDark),
                const SizedBox(height: 14),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Year 2 onwards')),
                    ButtonSegment(value: true, label: Text('First year')),
                  ],
                  selected: {_firstYear},
                  onSelectionChanged: (value) =>
                      setState(() => _firstYear = value.first),
                ),
                const SizedBox(height: 18),
                _reminderPreview(context, reminders),
                const SizedBox(height: 22),
                Text(
                  'Semester events',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                for (final event in events) _eventTile(context, event, now),
                const SizedBox(height: 10),
                Text(
                  'Dates are transcribed from the university calendar PDF. Holiday and examination schedules may be revised by the university.',
                  style: TextStyle(
                    color: colors.onSurface.withValues(alpha: .55),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _semesterBanner(BuildContext context, DateTime now, bool isDark) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xff245FCA), Color(0xff664BC2)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xff3977FF,
            ).withValues(alpha: isDark ? .18 : .12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.event_available_rounded,
            color: Colors.white,
            size: 34,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ODD SEMESTER · 2026–27',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .7,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Today · ${academicDateLabel(now, includeYear: true)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${academicCalendarEvents.where((e) => e.type == AcademicEventType.exam || e.type == AcademicEventType.assessment).length} exam periods · smart study reminders',
                  style: TextStyle(
                    color: colors.onPrimary.withValues(alpha: .78),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reminderPreview(
    BuildContext context,
    List<AcademicReminder> reminders,
  ) {
    final colors = Theme.of(context).colorScheme;
    final next = reminders.where((item) => !item.isExamDay).firstOrNull;
    final todayWish = reminders
        .where((item) => item.isExamDay && _sameDay(item.date, DateTime.now()))
        .firstOrNull;
    final title =
        todayWish?.title ?? next?.title ?? 'No upcoming exam reminders';
    final body =
        todayWish?.message ??
        next?.message ??
        'Your academic calendar is up to date.';
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: colors.primary.withValues(alpha: .18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            todayWish == null
                ? Icons.auto_awesome_rounded
                : Icons.celebration_rounded,
            color: colors.primary,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  todayWish == null ? 'Study plan reminder' : 'Exam-day wishes',
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    color: colors.onSurface.withValues(alpha: .72),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventTile(
    BuildContext context,
    AcademicCalendarEvent event,
    DateTime now,
  ) {
    final colors = Theme.of(context).colorScheme;
    final tint = _eventColor(event.type);
    final startText = academicDateLabel(event.start, includeYear: true);
    final dateText = event.isSingleDay
        ? startText
        : '$startText – ${academicDateLabel(event.end, includeYear: true)}';
    final today = DateTime(now.year, now.month, now.day);
    final isPast = event.end.isBefore(today);
    final festivalPassed = event.type == AcademicEventType.holiday && isPast;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: .42),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: .28),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_eventIcon(event.type), color: tint, size: 20),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: TextStyle(
                            color: colors.onSurface.withValues(
                              alpha: isPast ? .58 : 1,
                            ),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (festivalPassed)
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 15,
                              color: Color(0xff4DCBA5),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Done',
                              style: TextStyle(
                                color: Color(0xff4DCBA5),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        )
                      else if (!isPast)
                        Icon(
                          Icons.notifications_active_outlined,
                          size: 15,
                          color: colors.primary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    dateText,
                    style: TextStyle(
                      color: tint,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.details,
                    style: TextStyle(
                      color: colors.onSurface.withValues(alpha: .60),
                      fontSize: 10,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _remindersList(
    BuildContext context,
    List<AcademicReminder> reminders,
  ) {
    final colors = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const SizedBox(height: 4),
        Text(
          'Exam preparation and exam-day wishes',
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Reminders are calculated from the semester dates in the calendar.',
          style: TextStyle(
            color: colors.onSurface.withValues(alpha: .60),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 16),
        if (reminders.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 38),
            child: Center(child: Text('No upcoming academic reminders.')),
          ),
        for (final reminder in reminders)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: .42),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    reminder.isExamDay
                        ? Icons.celebration_rounded
                        : Icons.auto_awesome_rounded,
                    color: reminder.isExamDay
                        ? const Color(0xffF5A623)
                        : colors.primary,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder.title,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          academicDateLabel(reminder.date, includeYear: true),
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reminder.message,
                          style: TextStyle(
                            color: colors.onSurface.withValues(alpha: .65),
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          'Calendar-based reminders appear in SnapMark when you open the app.',
          style: TextStyle(
            color: colors.onSurface.withValues(alpha: .5),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

Color _eventColor(AcademicEventType type) => switch (type) {
  AcademicEventType.exam => const Color(0xffFF8578),
  AcademicEventType.assessment => const Color(0xffF5A623),
  AcademicEventType.milestone => const Color(0xff6F9DFF),
  AcademicEventType.holiday => const Color(0xff4DCBA5),
  AcademicEventType.vacation => const Color(0xffAE88FF),
};

IconData _eventIcon(AcademicEventType type) => switch (type) {
  AcademicEventType.exam => Icons.edit_note_rounded,
  AcademicEventType.assessment => Icons.quiz_rounded,
  AcademicEventType.milestone => Icons.flag_rounded,
  AcademicEventType.holiday => Icons.celebration_outlined,
  AcademicEventType.vacation => Icons.beach_access_rounded,
};

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
