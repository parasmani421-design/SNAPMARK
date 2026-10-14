import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/theme_mode_controller.dart';
import '../../core/services/student_directory_store.dart';
import '../timetable/timetable_screen.dart';
import 'teacher_academic_hub.dart';
import 'class_focus_report_screen.dart';
import 'teacher_assistant_screen.dart';
import 'manual_attendance_screen.dart';
import 'teacher_progress_questions_screen.dart';
import 'teacher_qr_screen.dart';
import 'student_progress_screen.dart';
import 'student_progress_section.dart';
import 'teacher_feedback_insights_screen.dart';
import '../auth/login_screen.dart';
import '../timetable/academic_calendar_screen.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard>
    with TickerProviderStateMixin {
  late final AnimationController _entryController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  )..forward();
  String _teacherDisplayName = 'Teacher';

  Timer? _timelineCollapseTimer;
  int? _expandedTimelineIndex;

  @override
  void initState() {
    super.initState();
    _loadTeacherName();
  }

  Future<void> _loadTeacherName() async {
    final email = await StudentDirectoryStore.activeFacultyEmail();
    if (email == null) return;
    final record = await StudentDirectoryStore.findFacultyByEmail(email);
    final name = record?.value('full_name').trim() ?? '';
    if (!mounted || name.isEmpty) return;
    setState(() => _teacherDisplayName = name);
  }

  @override
  void dispose() {
    _entryController.dispose();
    _timelineCollapseTimer?.cancel();
    super.dispose();
  }

  void _open(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _openAssistant() => _open(const TeacherAssistantScreen());

  void _toggleTimelineCard(int index) {
    _timelineCollapseTimer?.cancel();
    setState(() {
      _expandedTimelineIndex = _expandedTimelineIndex == index ? null : index;
    });
    if (_expandedTimelineIndex != null) {
      _timelineCollapseTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) setState(() => _expandedTimelineIndex = null);
      });
    }
  }

  List<_TeacherTimelineClass> _timelineClasses(DateTime now) {
    final scheduled = <_TeacherScheduledClass>[];
    for (var offset = 0; offset < 8; offset++) {
      final date = DateTime(now.year, now.month, now.day + offset);
      final classes = timetableSchedule[date.weekday - 1] ?? const [];
      for (final item in classes) {
        final times = item['time']?.split(' - ');
        if (times == null || times.length != 2) continue;
        final start = _parseClassTime(date, times[0]);
        final end = _parseClassTime(date, times[1]);
        if (start == null || end == null) continue;
        if (offset == 0 && end.isBefore(now)) continue;
        scheduled.add(
          _TeacherScheduledClass(
            subject: item['subject'] ?? 'Class',
            teacher: item['teacher'] ?? '',
            room: item['room'] ?? '',
            type: item['type'] ?? 'Class',
            start: start,
            end: end,
          ),
        );
      }
    }
    scheduled.sort((a, b) => a.start.compareTo(b.start));
    final ongoing = scheduled
        .where((item) => !now.isBefore(item.start) && now.isBefore(item.end))
        .firstOrNull;
    final nextClasses = scheduled
        .where((item) => item.start.isAfter(now))
        .toList();
    return [
      _TeacherTimelineClass(
        label: 'ONGOING',
        color: const Color(0xff54D6A0),
        item: ongoing,
        emptyMessage: 'No class in progress right now',
      ),
      _TeacherTimelineClass(
        label: 'NEXT',
        color: const Color(0xff6F9DFF),
        item: nextClasses.isNotEmpty ? nextClasses.first : null,
        emptyMessage: 'No next class on the timetable',
      ),
      _TeacherTimelineClass(
        label: 'UPCOMING',
        color: const Color(0xffAE88FF),
        item: nextClasses.length > 1 ? nextClasses[1] : null,
        emptyMessage: 'No other upcoming class found',
      ),
    ];
  }

  DateTime? _parseClassTime(DateTime date, String raw) {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(raw.trim());
    if (match == null) return null;
    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final period = match.group(3)!.toUpperCase();
    if (hour < 1 || hour > 12 || minute > 59) return null;
    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  Future<void> _logout() async {
    await StudentDirectoryStore.clearActiveIdentity();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = colors.onSurface.withValues(alpha: .62);
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    final now = DateTime.now();
    final todayClasses = timetableSchedule[now.weekday - 1] ?? const [];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        titleSpacing: 18,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                gradient: const LinearGradient(
                  colors: [Color(0xff3977FF), Color(0xff925BFF)],
                ),
              ),
              child: const Icon(Icons.auto_awesome_rounded, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              'SnapMark',
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -.35,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xff778CFF).withValues(alpha: .14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'FACULTY',
                style: TextStyle(
                  color: Color(0xff9DAEFF),
                  fontSize: 8,
                  letterSpacing: .8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Academic notifications',
            onPressed: () =>
                _open(const AcademicCalendarScreen(showReminders: true)),
            icon: Icon(
              Icons.notifications_none_rounded,
              color: colors.onSurface,
            ),
          ),
          PopupMenuButton<ThemeMode>(
            tooltip: 'Choose theme',
            icon: Icon(
              isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              color: colors.onSurface,
            ),
            onSelected: ThemeModeScope.of(context).setMode,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: ThemeMode.light,
                child: Row(
                  children: [
                    Icon(Icons.light_mode),
                    SizedBox(width: 10),
                    Text('Light theme'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: ThemeMode.dark,
                child: Row(
                  children: [
                    Icon(Icons.dark_mode),
                    SizedBox(width: 10),
                    Text('Dark theme'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: ThemeMode.system,
                child: Row(
                  children: [
                    Icon(Icons.settings_brightness),
                    SizedBox(width: 10),
                    Text('Use device setting'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            tooltip: 'Log out',
            onPressed: _logout,
            icon: Icon(Icons.logout_rounded, color: colors.onSurface),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8, left: 3),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color(0xff16C7D9),
                    Color(0xff3977FF),
                    Color(0xffA45BFF),
                  ],
                ),
              ),
              child: SizedBox(
                width: 40,
                height: 40,
                child: IconButton(
                  tooltip: 'Ask SnapMark AI',
                  onPressed: _openAssistant,
                  icon: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: CurvedAnimation(
          parent: _entryController,
          curve: Curves.easeOut,
        ),
        child: SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(0, .025),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: _entryController,
                  curve: Curves.easeOutCubic,
                ),
              ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: TextStyle(
                    color: muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Welcome, $_teacherDisplayName 👋',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your classroom, attendance and registers',
                  style: TextStyle(color: muted, fontSize: 12),
                ),
                const SizedBox(height: 20),

                _TeacherClassStatusTimeline(
                  items: _timelineClasses(now),
                  expandedIndex: _expandedTimelineIndex,
                  onTap: _toggleTimelineCard,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _PrimaryActionCard(
                        icon: Icons.qr_code_scanner_rounded,
                        title: 'Start live QR',
                        subtitle: 'Dynamic classroom scan',
                        colors: const [Color(0xff277BFF), Color(0xff5148D9)],
                        onTap: () => _open(const TeacherQRScreen()),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: _PrimaryActionCard(
                        icon: Icons.edit_calendar_rounded,
                        title: 'Manual attendance',
                        subtitle: 'For paper registers',
                        colors: const [Color(0xff7457E8), Color(0xff9A55D7)],
                        onTap: () => _open(const ManualAttendanceScreen()),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                StudentProgressOverviewCard(
                  muted: muted,
                  onOpen: () => _open(const StudentProgressScreen()),
                ),

                const SizedBox(height: 25),
                Row(
                  children: [
                    Text(
                      'Teacher tools',
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Quick access',
                      style: TextStyle(color: muted, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.2,
                  children: [
                    _ToolTile(
                      icon: Icons.qr_code_2_rounded,
                      title: 'Teacher QR',
                      tint: const Color(0xff75A0FF),
                      onTap: () => _open(const TeacherQRScreen()),
                    ),
                    _ToolTile(
                      icon: Icons.fact_check_rounded,
                      title: 'Attendance register',
                      tint: const Color(0xff5ED6B3),
                      onTap: () => _open(
                        const ManualAttendanceScreen(
                          initiallyShowingHistory: true,
                        ),
                      ),
                    ),
                    _ToolTile(
                      icon: Icons.calendar_month_rounded,
                      title: 'Timetable',
                      tint: const Color(0xffB18AFF),
                      onTap: () => _open(const TimetableScreen()),
                    ),
                    _ToolTile(
                      icon: Icons.event_available_rounded,
                      title: 'Academic calendar',
                      tint: const Color(0xff6F9DFF),
                      onTap: () => _open(const AcademicCalendarScreen()),
                    ),
                    _ToolTile(
                      icon: Icons.quiz_rounded,
                      title: 'Progress questions',
                      tint: const Color(0xffffba68),
                      onTap: () =>
                          _open(const TeacherProgressQuestionsScreen()),
                    ),
                    _ToolTile(
                      icon: Icons.phonelink_ring_rounded,
                      title: 'Class Focus',
                      tint: const Color(0xffB18AFF),
                      onTap: () => _open(const ClassFocusReportScreen()),
                    ),
                    _ToolTile(
                      icon: Icons.add_task_rounded,
                      title: 'Assignments',
                      tint: const Color(0xffB18AFF),
                      onTap: () => _open(const TeacherAcademicHub()),
                    ),
                    _ToolTile(
                      icon: Icons.folder_copy_rounded,
                      title: 'PPT & PDF materials',
                      tint: const Color(0xff5ED6B3),
                      onTap: () =>
                          _open(const TeacherAcademicHub(openMaterials: true)),
                    ),
                    _ToolTile(
                      icon: Icons.rate_review_rounded,
                      title: 'Class feedback',
                      tint: const Color(0xffFFB454),
                      onTap: () => _open(const TeacherFeedbackInsightsScreen()),
                    ),
                  ],
                ),

                const SizedBox(height: 25),
                Row(
                  children: [
                    Text(
                      "Today's classes",
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _open(const TimetableScreen()),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                      child: const Text(
                        'View timetable',
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (todayClasses.isEmpty)
                  _EmptyClassesCard(muted: muted)
                else
                  for (final item in todayClasses.take(3))
                    _ClassRow(
                      subject: item['subject'] ?? 'Class',
                      time: item['time']?.split(' - ').first ?? '',
                      room: item['room'] ?? '',
                      type: item['type'] ?? 'Class',
                    ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TeacherScheduledClass {
  const _TeacherScheduledClass({
    required this.subject,
    required this.teacher,
    required this.room,
    required this.type,
    required this.start,
    required this.end,
  });

  final String subject;
  final String teacher;
  final String room;
  final String type;
  final DateTime start;
  final DateTime end;
}

class _TeacherTimelineClass {
  const _TeacherTimelineClass({
    required this.label,
    required this.color,
    required this.item,
    required this.emptyMessage,
  });

  final String label;
  final Color color;
  final _TeacherScheduledClass? item;
  final String emptyMessage;
}

class _TeacherClassStatusTimeline extends StatelessWidget {
  const _TeacherClassStatusTimeline({
    required this.items,
    required this.expandedIndex,
    required this.onTap,
  });

  final List<_TeacherTimelineClass> items;
  final int? expandedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff0e1522) : const Color(0xfff5f7fc),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: .055)
              : const Color(0xffe5e9f1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                if (index > 0)
                  Expanded(
                    child: Container(
                      height: 1,
                      margin: const EdgeInsets.only(bottom: 16),
                      color: isDark ? Colors.white24 : const Color(0xffd9dfeb),
                    ),
                  ),
                _TeacherTimelineDot(
                  item: items[index],
                  selected: expandedIndex == index,
                  onTap: () => onTap(index),
                ),
              ],
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: expandedIndex == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 11),
                    child: _TeacherClassDetail(item: items[expandedIndex!]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TeacherTimelineDot extends StatelessWidget {
  const _TeacherTimelineDot({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _TeacherTimelineClass item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: selected ? 16 : 12,
            height: selected ? 16 : 12,
            decoration: BoxDecoration(
              color: item.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: selected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: item.color.withValues(alpha: selected ? .45 : .2),
                  blurRadius: selected ? 9 : 5,
                  spreadRadius: selected ? 1 : 0,
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            item.label,
            style: TextStyle(
              color: selected
                  ? item.color
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: .65),
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: .55,
            ),
          ),
        ],
      ),
    ),
  );
}

class _TeacherClassDetail extends StatelessWidget {
  const _TeacherClassDetail({required this.item});

  final _TeacherTimelineClass item;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final lesson = item.item;
    if (lesson == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: item.color.withValues(alpha: .22)),
        ),
        child: Row(
          children: [
            Icon(Icons.event_busy_rounded, color: item.color, size: 17),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.emptyMessage,
                style: TextStyle(
                  color: colors.onSurface.withValues(alpha: .65),
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      );
    }
    final today = DateTime.now();
    final dayLabel =
        lesson.start.year == today.year &&
            lesson.start.month == today.month &&
            lesson.start.day == today.day
        ? 'Today'
        : const [
            'Mon',
            'Tue',
            'Wed',
            'Thu',
            'Fri',
            'Sat',
            'Sun',
          ][lesson.start.weekday - 1];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: item.color.withValues(alpha: .22)),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 39,
            decoration: BoxDecoration(
              color: item.color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${lesson.type} · ${lesson.room} · $dayLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurface.withValues(alpha: .6),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${_formatTeacherTime(lesson.start)} – ${_formatTeacherTime(lesson.end)}',
            style: TextStyle(
              color: item.color,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatTeacherTime(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${value.hour < 12 ? 'AM' : 'PM'}';
}

class _PrimaryActionCard extends StatelessWidget {
  const _PrimaryActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(17),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(17),
          boxShadow: [
            BoxShadow(
              color: colors.first.withValues(alpha: .18),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .75),
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.icon,
    required this.title,
    required this.tint,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: .06)
                  : const Color(0xffe2e7f0),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: tint, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: .45),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassRow extends StatelessWidget {
  const _ClassRow({
    required this.subject,
    required this.time,
    required this.room,
    required this.type,
  });
  final String subject;
  final String time;
  final String room;
  final String type;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colors.onSurface.withValues(alpha: .06)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xff8B78FF).withValues(alpha: .13),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Color(0xffA995FF),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$type  ·  $room',
                  style: TextStyle(
                    color: colors.onSurface.withValues(alpha: .58),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              color: Color(0xff9DB4FF),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyClassesCard extends StatelessWidget {
  const _EmptyClassesCard({required this.muted});
  final Color muted;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      children: [
        Icon(Icons.event_available_rounded, color: muted, size: 18),
        const SizedBox(width: 9),
        Text(
          'No classes scheduled today',
          style: TextStyle(color: muted, fontSize: 11),
        ),
      ],
    ),
  );
}
