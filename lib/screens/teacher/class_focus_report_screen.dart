import 'package:flutter/material.dart';

import '../timetable/timetable_screen.dart';

class ClassFocusReportScreen extends StatefulWidget {
  const ClassFocusReportScreen({super.key});

  @override
  State<ClassFocusReportScreen> createState() => _ClassFocusReportScreenState();
}

class _ClassFocusReportScreenState extends State<ClassFocusReportScreen> {
  late final List<_ClassFocusSession> _sessions = _buildSessions();
  late _ClassFocusSession _selected = _sessions.first;

  static List<_ClassFocusSession> _buildSessions() {
    final sessions = <_ClassFocusSession>[];
    for (final entry in timetableSchedule.entries) {
      for (final lesson in entry.value) {
        final subject = lesson['subject'] ?? 'Class';
        final timeRange = lesson['time'] ?? '';
        final room = lesson['room'] ?? 'Room not listed';
        if (sessions.any(
          (session) =>
              session.dayIndex == entry.key &&
              session.subject == subject &&
              session.timeRange == timeRange &&
              session.room == room,
        )) {
          continue;
        }
        sessions.add(
          _ClassFocusSession(
            subject: subject,
            dayIndex: entry.key,
            timeRange: timeRange,
            room: room,
            durationMinutes: _durationFor(timeRange),
            sampleIndex: sessions.length,
          ),
        );
      }
    }
    if (sessions.isEmpty) {
      sessions.add(
        const _ClassFocusSession(
          subject: 'Data Structures',
          dayIndex: 0,
          timeRange: '10:00 AM - 10:50 AM',
          room: 'GU_AI_208',
          durationMinutes: 50,
          sampleIndex: 0,
        ),
      );
    }
    return sessions;
  }

  static int _durationFor(String range) {
    final parts = range.split(' - ');
    if (parts.length != 2) return 50;
    final start = _minutesOfDay(parts[0]);
    final end = _minutesOfDay(parts[1]);
    if (start == null || end == null || end <= start) return 50;
    return end - start;
  }

  static int? _minutesOfDay(String input) {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(input.trim());
    if (match == null) return null;
    var hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    if (hour == null ||
        minute == null ||
        hour < 1 ||
        hour > 12 ||
        minute > 59) {
      return null;
    }
    final period = match.group(3)!.toUpperCase();
    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return hour * 60 + minute;
  }

  List<_StudentPhoneActivity> _activitiesFor(_ClassFocusSession session) {
    const names = ['Aarav Sharma', 'Kabir Singh', 'Riya Verma', 'Dev Patel'];
    const sampleRatios = [.54, .36, .20, .12];
    return List.generate(names.length, (index) {
      final ratioIndex = (index + session.sampleIndex) % sampleRatios.length;
      final minutes = (session.durationMinutes * sampleRatios[ratioIndex])
          .round()
          .clamp(0, session.durationMinutes);
      return _StudentPhoneActivity(names[index], minutes);
    })..sort((a, b) => b.minutes.compareTo(a.minutes));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final muted = colors.onSurface.withValues(alpha: .62);
    final activities = _activitiesFor(_selected);
    final normalLimit = (_selected.durationMinutes * .2).round();
    final mediumLimit = (_selected.durationMinutes * .4).round();
    final normal = activities.where((s) => s.minutes <= normalLimit).toList();
    final medium = activities
        .where((s) => s.minutes > normalLimit && s.minutes <= mediumLimit)
        .toList();
    final high = activities.where((s) => s.minutes > mediumLimit).toList();
    final highest = activities.first;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Class Focus Report',
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: colors.onSurface),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colors.onSurface.withValues(alpha: .07),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.filter_list_rounded,
                    color: Color(0xffA88AFF),
                    size: 20,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Select a subject/class to see its student-wise report.',
                      style: TextStyle(
                        color: muted,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const Text(
                    'SAMPLE',
                    style: TextStyle(
                      color: Color(0xffB8A5FF),
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'SUBJECT / CLASS',
              style: TextStyle(
                color: muted,
                fontSize: 9,
                letterSpacing: .8,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            DropdownButtonFormField<_ClassFocusSession>(
              initialValue: _selected,
              isExpanded: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: colors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: colors.onSurface.withValues(alpha: .08),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: colors.onSurface.withValues(alpha: .08),
                  ),
                ),
              ),
              items: _sessions
                  .map(
                    (session) => DropdownMenuItem(
                      value: session,
                      child: Text(
                        '${session.subject} · ${_dayShort(session.dayIndex)} · ${_startTime(session.timeRange)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.onSurface, fontSize: 11),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (session) {
                if (session != null) setState(() => _selected = session);
              },
            ),
            const SizedBox(height: 9),
            Text(
              '${_selected.durationMinutes} min class  ·  ${_selected.room}',
              style: TextStyle(color: muted, fontSize: 10),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xffFF6878).withValues(alpha: .09),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xffFF6878).withValues(alpha: .2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.priority_high_rounded,
                    color: Color(0xffFF6878),
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'HIGHEST PHONE USE',
                          style: TextStyle(
                            color: Color(0xffFF8290),
                            fontSize: 8,
                            letterSpacing: .6,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          highest.name,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${highest.minutes} min',
                    style: const TextStyle(
                      color: Color(0xffFF8290),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _StudentActivityGroup(
              title: 'NORMAL · UP TO $normalLimit MIN',
              students: normal,
              color: const Color(0xff4DCBA5),
              muted: muted,
              textColor: colors.onSurface,
            ),
            const SizedBox(height: 14),
            _StudentActivityGroup(
              title: 'MEDIUM · ${normalLimit + 1}–$mediumLimit MIN',
              students: medium,
              color: const Color(0xffFFB454),
              muted: muted,
              textColor: colors.onSurface,
            ),
            const SizedBox(height: 14),
            _StudentActivityGroup(
              title: 'HIGH · OVER $mediumLimit MIN',
              students: high,
              color: const Color(0xffFF6878),
              muted: muted,
              textColor: colors.onSurface,
            ),
            const SizedBox(height: 13),
            Text(
              'Sample values only. Normal is up to 20% of class time; medium is up to 40%; higher activity appears red. Real phone activity needs student-side tracking and a live data connection.',
              style: TextStyle(color: muted, fontSize: 9, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  static String _dayShort(int index) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][index];

  static String _startTime(String timeRange) {
    final start = timeRange.split(' - ').first.trim();
    return _minutesOfDay(start) == null ? 'Time TBA' : start;
  }
}

class _ClassFocusSession {
  const _ClassFocusSession({
    required this.subject,
    required this.dayIndex,
    required this.timeRange,
    required this.room,
    required this.durationMinutes,
    required this.sampleIndex,
  });
  final String subject;
  final int dayIndex;
  final String timeRange;
  final String room;
  final int durationMinutes;
  final int sampleIndex;
}

class _StudentPhoneActivity {
  const _StudentPhoneActivity(this.name, this.minutes);
  final String name;
  final int minutes;
}

class _StudentActivityGroup extends StatelessWidget {
  const _StudentActivityGroup({
    required this.title,
    required this.students,
    required this.color,
    required this.muted,
    required this.textColor,
  });
  final String title;
  final List<_StudentPhoneActivity> students;
  final Color color;
  final Color muted;
  final Color textColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withValues(alpha: .16)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 9,
                letterSpacing: .5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              '${students.length} students',
              style: TextStyle(color: muted, fontSize: 9),
            ),
          ],
        ),
        if (students.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 9),
            child: Text(
              'No students in this group',
              style: TextStyle(color: muted, fontSize: 10),
            ),
          )
        else
          ...students.map(
            (student) => Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Icon(Icons.person_rounded, color: color, size: 17),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      student.name,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${student.minutes} min',
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
