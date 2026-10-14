import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/services/campus_location_service.dart';
import '../../core/services/attendance_demo_data.dart';
import '../../core/services/device_access_request_store.dart';
import '../../core/services/attendance_record_store.dart';
import '../../core/services/student_directory_store.dart';
import '../../core/services/academic_calendar_service.dart';
import '../../core/theme/theme_mode_controller.dart';
import '../attendance/attendance_screen.dart';
import '../attendance/attendance_history_screen.dart';
import '../fees/fees_screen.dart';
import '../profile/profile_content.dart';
import '../qr/qr_scanner_screen.dart';
import '../timetable/timetable_screen.dart';
import '../timetable/academic_calendar_screen.dart';
import 'mentor_screen.dart';
import 'request_center_screen.dart';
import 'teacher_feedback_screen.dart';
import '../skill/skill_career_screen.dart';
import '../skill/snapmark_ai_screen.dart';
import '../auth/login_screen.dart';

// Teacher QR temporarily disabled.
// import '../teacher/teacher_qr_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  bool _isCheckingLocation = false;
  int _selectedTab = 0;
  late final AnimationController _attendanceIconController;
  late final Animation<double> _attendanceIconPulse;
  late final AnimationController _entranceController;
  Timer? _timelineCollapseTimer;
  int? _expandedTimelineIndex;
  String _studentDisplayName = 'Paras';
  String _studentProgram = 'CSE (AI)';
  String _studentSection = '';
  FacultyRecord? _mentorFaculty;
  String _mentorEmail = '';
  List<AttendanceEntry> _attendanceRecords = [];

  @override
  void initState() {
    super.initState();
    _attendanceIconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    _attendanceIconPulse = Tween<double>(begin: .9, end: 1.12).animate(
      CurvedAnimation(
        parent: _attendanceIconController,
        curve: Curves.easeInOut,
      ),
    );
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
    _loadStudentDirectoryProfile();
  }

  @override
  void dispose() {
    _attendanceIconController.dispose();
    _entranceController.dispose();
    _timelineCollapseTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadStudentDirectoryProfile() async {
    final email = await StudentDirectoryStore.activeEmail();
    if (email == null) return;
    final record = await StudentDirectoryStore.findByEmail(email);
    final attendance = await AttendanceRecordStore.forStudent(email);
    final mentorEmail = record?.value('mentor_email') ?? '';
    final mentor = mentorEmail.isEmpty
        ? null
        : await StudentDirectoryStore.findFacultyByEmail(mentorEmail);
    if (!mounted) return;
    setState(() {
      _attendanceRecords = attendance;
      _mentorEmail = mentorEmail;
      _mentorFaculty = mentor;
      final name = record?.value('full_name') ?? '';
      final program = record?.value('program') ?? '';
      _studentSection = _normalizeSection(record?.value('section') ?? '');
      if (name.isNotEmpty) _studentDisplayName = name;
      if (program.isNotEmpty) _studentProgram = program;
    });
  }

  void _openAssistant() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SnapMarkAiScreen()),
    );
  }

  void _openAcademicCalendar({bool reminders = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AcademicCalendarScreen(showReminders: reminders),
      ),
    );
  }

  void _openMentor() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentMentorScreen(
          mentor: _mentorFaculty,
          mentorEmail: _mentorEmail,
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await StudentDirectoryStore.clearActiveEmail();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _checkCampusAndOpenScanner() async {
    if (_isCheckingLocation) return;

    final email = await StudentDirectoryStore.activeEmail();
    if (!mounted) return;
    final deviceApproved =
        email != null && await DeviceAccessRequestStore.isApproved(email);
    if (!mounted) return;
    if (!deviceApproved) {
      await _showDeviceApprovalRequired();
      return;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() => _isCheckingLocation = true);
    String? message;
    try {
      message = await const CampusLocationService().checkCampusLocation();
    } finally {
      if (mounted) setState(() => _isCheckingLocation = false);
    }
    if (!mounted) return;

    if (message != null) {
      if (defaultTargetPlatform == TargetPlatform.android &&
          (message.startsWith('Developer options are enabled') ||
              message.startsWith('A mock location was detected') ||
              message.startsWith(
                'SnapMark could not verify Developer options',
              ))) {
        await _showDeviceIntegrityDialog(message);
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 4),
          ),
        );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QRScannerScreen()),
    );
  }

  Future<void> _showDeviceApprovalRequired() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.phonelink_lock_rounded,
          color: Color(0xffFFB454),
        ),
        title: const Text('Device approval required'),
        content: const Text(
          'This device must be approved by an admin before you can scan an attendance QR code.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Later'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RequestCenterScreen()),
              );
            },
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Open Request Center'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeviceIntegrityDialog(String message) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xffF5A623).withValues(alpha: .13),
            borderRadius: BorderRadius.circular(17),
          ),
          child: const Icon(
            Icons.verified_user_outlined,
            color: Color(0xffF5A623),
            size: 28,
          ),
        ),
        title: const Text('Device settings need attention'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  dialogContext,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: .55),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.qr_code_scanner_rounded, size: 18),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'QR attendance will be available after Developer options and mock-location apps are turned off.',
                      style: TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Not now'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await const CampusLocationService()
                    .openDeveloperOptionsSettings();
              } catch (_) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Could not open Settings. Open Developer options manually and turn them off.',
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.settings_rounded),
            label: const Text('Open Developer Options'),
          ),
        ],
      ),
    );
  }

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

  List<_TimelineClass> _timelineClasses(DateTime now) {
    final scheduled = <_ScheduledClass>[];
    for (var offset = 0; offset < 8; offset++) {
      final date = DateTime(now.year, now.month, now.day + offset);
      final dayClasses = _classesForStudent(date.weekday - 1);
      for (final item in dayClasses) {
        final times = item['time']?.split(' - ');
        if (times == null || times.length != 2) continue;
        final start = _parseClassTime(date, times[0]);
        final end = _parseClassTime(date, times[1]);
        if (start == null || end == null) continue;
        if (offset == 0 && end.isBefore(now)) continue;
        scheduled.add(
          _ScheduledClass(
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
      _TimelineClass(
        label: 'ONGOING',
        color: const Color(0xff54D6A0),
        item: ongoing,
        emptyMessage: 'No class in progress right now',
      ),
      _TimelineClass(
        label: 'NEXT',
        color: const Color(0xff6F9DFF),
        item: nextClasses.isNotEmpty ? nextClasses[0] : null,
        emptyMessage: 'No next class on the timetable',
      ),
      _TimelineClass(
        label: 'UPCOMING',
        color: const Color(0xffAE88FF),
        item: nextClasses.length > 1 ? nextClasses[1] : null,
        emptyMessage: 'No other upcoming class found',
      ),
    ];
  }

  List<Map<String, String>> _classesForStudent(int day) =>
      (timetableSchedule[day] ?? const []).where((lesson) {
        final section = lesson['section']?.trim() ?? '';
        return section.isEmpty ||
            _studentSection.isEmpty ||
            _normalizeSection(section) == _studentSection;
      }).toList();

  String _normalizeSection(String value) =>
      RegExp(r'\d+').firstMatch(value)?.group(0) ?? value.trim();

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

  bool _isClassComplete(Map<String, String> item, DateTime now) {
    final times = item['time']?.split(' - ');
    if (times == null || times.length != 2) return false;
    final end = _parseClassTime(now, times[1]);
    return end != null && !now.isBefore(end);
  }

  void _showAttendanceWarning() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: Color(0xffff7777),
          size: 30,
        ),
        title: const Text('Attendance below 70%'),
        content: const Text(
          'Debarment risk: your overall attendance is below 70%. Attend upcoming classes and contact your faculty.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showAttendanceDemo = !AttendanceDemoData.hasCompleteSubjectCoverage(
      _attendanceRecords.map((record) => record.subject),
    );
    final attended = showAttendanceDemo
        ? AttendanceDemoData.attended
        : _attendanceRecords.where((record) => record.present).length;
    final total = showAttendanceDemo
        ? AttendanceDemoData.delivered
        : _attendanceRecords.length;
    final attendanceRate = total == 0 ? 0.0 : attended / total;
    final now = DateTime.now();
    final classesToday = _classesForStudent(now.weekday - 1);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : const Color(0xff172033);
    final secondaryText = isDark ? Colors.white70 : const Color(0xff596579);
    final pageTitle = switch (_selectedTab) {
      1 => 'Scan',
      2 => 'Attendance History',
      3 => 'Profile',
      _ => 'SnapMark',
    };
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // APP BAR
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            if (_selectedTab == 0) ...[
              Container(
                width: 31,
                height: 31,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: [Color(0xff3977FF), Color(0xff925BFF)],
                  ),
                ),
                child: const Icon(Icons.auto_awesome_rounded, size: 17),
              ),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Text(
                pageTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: primaryText,
                  fontWeight: FontWeight.w700,
                  letterSpacing: _selectedTab == 0 ? -.3 : 0,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<ThemeMode>(
            tooltip: 'Choose theme',
            icon: Icon(
              isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              color: primaryText,
            ),
            onSelected: ThemeModeScope.of(context).setMode,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: ThemeMode.light,
                child: Row(
                  children: [
                    Icon(Icons.light_mode),
                    SizedBox(width: 12),
                    Text('Light theme'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: ThemeMode.dark,
                child: Row(
                  children: [
                    Icon(Icons.dark_mode),
                    SizedBox(width: 12),
                    Text('Dark theme'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: ThemeMode.system,
                child: Row(
                  children: [
                    Icon(Icons.settings_brightness),
                    SizedBox(width: 12),
                    Text('Use device setting'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            tooltip: 'Academic notifications',
            onPressed: () => _openAcademicCalendar(reminders: true),
            icon: Icon(Icons.notifications_none, color: primaryText),
          ),
          IconButton(
            tooltip: 'Academic calendar',
            onPressed: _openAcademicCalendar,
            icon: Icon(Icons.calendar_month_rounded, color: primaryText),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
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
                width: 42,
                height: 42,
                child: IconButton(
                  tooltip: 'Ask SnapMark AI',
                  onPressed: _openAssistant,
                  icon: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Log out',
            onPressed: _logout,
            icon: Icon(Icons.logout_rounded, color: primaryText),
          ),
        ],
      ),

      // BODY
      body: _selectedTab == 0
          ? FadeTransition(
              opacity: CurvedAnimation(
                parent: _entranceController,
                curve: Curves.easeOut,
              ),
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, .025),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _entranceController,
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
                        'Good ${DateTime.now().hour < 12
                            ? 'Morning'
                            : DateTime.now().hour < 17
                            ? 'Afternoon'
                            : 'Evening'}',
                        style: TextStyle(
                          color: secondaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$_studentDisplayName 👋',
                        style: TextStyle(
                          color: primaryText,
                          fontSize: 27,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Student  ·  $_studentProgram',
                        style: TextStyle(color: secondaryText, fontSize: 12),
                      ),
                      const SizedBox(height: 18),

                      // Compact semester overview keeps both existing metrics
                      // and the career roadmap action available at a glance.
                      _compactProgressCard(
                        context,
                        attendanceRate: attendanceRate,
                        attended: attended,
                        total: total,
                      ),
                      const SizedBox(height: 10),
                      _ClassStatusTimeline(
                        items: _timelineClasses(now),
                        expandedIndex: _expandedTimelineIndex,
                        onTap: _toggleTimelineCard,
                      ),

                      const SizedBox(height: 12),
                      _studentExamReminder(context),

                      const SizedBox(height: 20),
                      InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: _isCheckingLocation
                            ? null
                            : _checkCampusAndOpenScanner,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 17,
                            vertical: 15,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xff277BFF), Color(0xff5148D9)],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xff3977FF,
                                ).withValues(alpha: .20),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              ScaleTransition(
                                scale: _attendanceIconPulse,
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: .15),
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: Icon(
                                    _isCheckingLocation
                                        ? Icons.location_searching_rounded
                                        : Icons.qr_code_scanner_rounded,
                                    color: Colors.white,
                                    size: 23,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 13),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isCheckingLocation
                                          ? 'Checking campus location…'
                                          : 'Mark attendance',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _isCheckingLocation
                                          ? 'Please wait for GPS verification'
                                          : 'Scan class QR to continue',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),
                      _sectionTitle(
                        'University ERP',
                        '11 services',
                        primaryText,
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.12,
                        children: [
                          _erpCard(
                            icon: Icons.fact_check_rounded,
                            title: 'Attendance',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AttendanceScreen(),
                              ),
                            ),
                          ),
                          _erpCard(
                            icon: Icons.calendar_month_rounded,
                            title: 'Timetable',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TimetableScreen(),
                              ),
                            ),
                          ),
                          _erpCard(
                            icon: Icons.event_available_rounded,
                            title: 'Academic Calendar',
                            onTap: _openAcademicCalendar,
                          ),
                          _erpCard(
                            icon: Icons.support_agent_rounded,
                            title: 'Mentor',
                            onTap: _openMentor,
                          ),
                          _erpCard(
                            icon: Icons.rate_review_rounded,
                            title: 'Teacher Feedback',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TeacherFeedbackScreen(),
                              ),
                            ),
                          ),
                          _erpCard(
                            icon: Icons.account_balance_wallet_rounded,
                            title: 'Fees',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const FeesScreen(),
                              ),
                            ),
                          ),
                          _erpCard(
                            icon: Icons.assignment_turned_in_rounded,
                            title: 'Exam Form',
                            onTap: () {},
                          ),
                          _erpCard(
                            icon: Icons.credit_card_rounded,
                            title: 'Admit Card',
                            onTap: () {},
                          ),
                          _erpCard(
                            icon: Icons.event_seat_rounded,
                            title: 'Seating Plan',
                            onTap: () {},
                          ),
                          _erpCard(
                            icon: Icons.query_stats_rounded,
                            title: 'Results',
                            onTap: () {},
                          ),
                          _erpCard(
                            icon: Icons.campaign_rounded,
                            title: 'Notices',
                            onTap: () {},
                          ),
                          _erpCard(
                            icon: Icons.phonelink_lock_rounded,
                            title: 'Request Center',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RequestCenterScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),
                      _sectionTitle(
                        'SnapMark services',
                        'Explore',
                        primaryText,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _serviceCard(
                            icon: Icons.face_retouching_natural_rounded,
                            title: 'Face Verify',
                            onTap: () {},
                          ),
                          _serviceCard(
                            icon: Icons.history_rounded,
                            title: 'History',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AttendanceHistoryScreen(),
                              ),
                            ),
                          ),
                          _serviceCard(
                            icon: Icons.person_outline_rounded,
                            title: 'Profile',
                            onTap: () => setState(() => _selectedTab = 3),
                          ),
                          _serviceCard(
                            icon: Icons.support_agent_rounded,
                            title: 'Student Help',
                            onTap: () {},
                          ),
                          _serviceCard(
                            icon: Icons.auto_awesome_rounded,
                            title: 'Skill & Career',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SkillCareerScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),
                      _sectionTitle(
                        "Today's classes",
                        'View timetable',
                        primaryText,
                      ),
                      const SizedBox(height: 12),
                      for (final item in classesToday.take(3))
                        _classCard(
                          item['subject'] ?? 'Class',
                          item['time']?.split(' - ').first ?? '',
                          item['room'] ?? '',
                          _isClassComplete(item, now),
                        ),
                      if (classesToday.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'No classes scheduled today',
                            style: TextStyle(
                              color: secondaryText,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 5),

                      InkWell(
                        onTap: _openAssistant,
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xff101827)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.blueAccent.withValues(alpha: .20),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xff347EFF),
                                      Color(0xff965BFF),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Colors.white,
                                  size: 21,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ask SnapMark AI',
                                      style: TextStyle(
                                        color: primaryText,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Academic help and study insights',
                                      style: TextStyle(
                                        color: secondaryText,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: secondaryText,
                                size: 19,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            )
          : _selectedTab == 1
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_searching,
                    color: Colors.blueAccent,
                    size: 42,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isCheckingLocation
                        ? 'Checking campus location…'
                        : 'Opening QR scanner…',
                    style: TextStyle(color: primaryText),
                  ),
                ],
              ),
            )
          : _selectedTab == 2
          ? const AttendanceHistoryScreen(embedded: true)
          : const ProfileContent(),

      // BOTTOM NAVIGATION
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xff101827) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: .06)
                  : const Color(0xffe5e9f1),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? .12 : .04),
              blurRadius: 16,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 68,
            child: Row(
              children: [
                Expanded(
                  child: _bottomNavItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    selected: _selectedTab == 0,
                    onTap: () => setState(() => _selectedTab = 0),
                    isDark: isDark,
                  ),
                ),
                SizedBox(width: 82, child: _centerScanButton(isDark)),
                Expanded(
                  child: _bottomNavItem(
                    icon: Icons.person_rounded,
                    label: 'Profile',
                    selected: _selectedTab == 3,
                    onTap: () => setState(() => _selectedTab = 3),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _studentExamReminder(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final reminders = upcomingAcademicReminders(now);
    final todayWish = reminders
        .where(
          (item) =>
              item.isExamDay &&
              item.date.year == now.year &&
              item.date.month == now.month &&
              item.date.day == now.day,
        )
        .firstOrNull;
    final nextReminder = reminders.where((item) => !item.isExamDay).firstOrNull;
    final reminder = todayWish ?? nextReminder;
    if (reminder == null) return const SizedBox.shrink();
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _openAcademicCalendar,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.primary.withValues(alpha: .18)),
        ),
        child: Row(
          children: [
            Icon(
              todayWish == null
                  ? Icons.auto_awesome_rounded
                  : Icons.celebration_rounded,
              color: colors.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todayWish == null
                        ? 'Start exam preparation'
                        : 'All the best today!',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    reminder.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onSurface.withValues(alpha: .72),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: colors.onSurface.withValues(alpha: .45),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomNavItem({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required bool isDark,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 22,
          color: selected
              ? const Color(0xff9DB4FF)
              : (isDark ? Colors.white54 : Colors.black45),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? const Color(0xffAFC2FF)
                : (isDark ? Colors.white54 : Colors.black45),
          ),
        ),
      ],
    ),
  );

  Widget _centerScanButton(bool isDark) => InkWell(
    onTap: () async {
      setState(() => _selectedTab = 1);
      await _checkCampusAndOpenScanner();
      if (mounted) setState(() => _selectedTab = 0);
    },
    borderRadius: BorderRadius.circular(24),
    child: SizedBox(
      height: 68,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _attendanceIconPulse,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xff2D86FF),
                    Color(0xff7257F5),
                    Color(0xffA553F4),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff6B6CFF).withValues(alpha: .38),
                    blurRadius: 17,
                    spreadRadius: 1,
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: .45),
                  width: 1.2,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    _isCheckingLocation
                        ? Icons.location_searching_rounded
                        : Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                    size: 23,
                  ),
                  Positioned(
                    top: 7,
                    right: 8,
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white.withValues(alpha: .88),
                      size: 9,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Scan',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _sectionTitle(String title, String trailing, Color color) => Row(
    children: [
      Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: -.2,
        ),
      ),
      const Spacer(),
      Text(
        trailing,
        style: const TextStyle(
          color: Color(0xff8EA8FF),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );

  Widget _compactProgressCard(
    BuildContext context, {
    required double attendanceRate,
    required int attended,
    required int total,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xff172033);
    final muted = isDark ? Colors.white60 : const Color(0xff667085);
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 13),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff111827) : Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: .075)
              : const Color(0xffe2e7f0),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Your progress',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.auto_awesome_rounded,
                color: isDark ? const Color(0xff9BAEFF) : Colors.indigo,
                size: 15,
              ),
              const SizedBox(width: 5),
              Text(
                'THIS SEMESTER',
                style: TextStyle(
                  color: muted,
                  fontSize: 8,
                  letterSpacing: .8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniProgressMetric(
                  title: 'Attendance',
                  value: attendanceRate,
                  icon: Icons.fact_check_rounded,
                  color: attendanceRate < .70
                      ? const Color(0xffff7777)
                      : const Color(0xff7f9bff),
                  onWarningTap: attendanceRate < .70
                      ? _showAttendanceWarning
                      : null,
                ),
              ),
              Container(
                width: 1,
                height: 37,
                margin: const EdgeInsets.symmetric(horizontal: 13),
                color: isDark ? Colors.white12 : const Color(0xffe5e9f1),
              ),
              Expanded(
                child: _MiniProgressMetric(
                  title: 'Career readiness',
                  value: .68,
                  icon: Icons.rocket_launch_rounded,
                  color: const Color(0xffb18aff),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SkillCareerScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                '$attended/$total',
                style: TextStyle(
                  color: muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ERP CARD
  Widget _erpCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _featureAccent(title);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 9),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xff101827) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: .07)
                : const Color(0xffdce3ed),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isDark ? .15 : .10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 19),
            ),

            const SizedBox(height: 6),

            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xff172033),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // SERVICE CARD
  Widget _serviceCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _featureAccent(title);
    final width = (MediaQuery.sizeOf(context).width - 50) / 2;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: width,
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xff101827) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: .07)
                : const Color(0xffdce3ed),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: accent, size: 19),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xff172033),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.arrow_outward_rounded,
              color: isDark ? Colors.white38 : Colors.black38,
              size: 13,
            ),
          ],
        ),
      ),
    );
  }

  Color _featureAccent(String title) => switch (title) {
    'Attendance' || 'Face Verify' => const Color(0xff6f9dff),
    'Timetable' || 'Admit Card' => const Color(0xffbc91ff),
    'Fees' || 'Requests' => const Color(0xff5ed6b3),
    'Exam Form' || 'Seating Plan' => const Color(0xffffba68),
    'Results' => const Color(0xff55c9e8),
    'Notices' || 'Student Help' => const Color(0xffff8b9f),
    'History' => const Color(0xff83a0ff),
    _ => const Color(0xffa98bff),
  };

  // CLASS CARD
  Widget _classCard(String subject, String time, String room, bool completed) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff111827) : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
        leading: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: Colors.blueAccent.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.menu_book, color: Colors.blueAccent),
        ),
        title: Text(
          subject,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xff172033),
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '$time • $room',
          style: TextStyle(
            color: isDark ? Colors.white54 : const Color(0xff596579),
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          completed ? Icons.check_circle : Icons.schedule,
          color: completed ? Colors.greenAccent : Colors.orangeAccent,
        ),
      ),
    );
  }
}

class _MiniProgressMetric extends StatelessWidget {
  const _MiniProgressMetric({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
    this.onWarningTap,
  });

  final String title;
  final double value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final VoidCallback? onWarningTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white60
                        : const Color(0xff667085),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value),
                duration: const Duration(milliseconds: 850),
                curve: Curves.easeOutCubic,
                builder: (context, animated, _) => Text(
                  '${(animated * 100).round()}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (onWarningTap != null)
                Tooltip(
                  message: 'Attendance is below 70%',
                  child: InkWell(
                    onTap: onWarningTap,
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.only(left: 3),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xffff7777),
                        size: 15,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (context, animated, _) => LinearProgressIndicator(
                value: animated,
                minHeight: 4,
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white12
                    : const Color(0xffe9edf4),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ScheduledClass {
  const _ScheduledClass({
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

class _TimelineClass {
  const _TimelineClass({
    required this.label,
    required this.color,
    required this.item,
    required this.emptyMessage,
  });

  final String label;
  final Color color;
  final _ScheduledClass? item;
  final String emptyMessage;
}

class _ClassStatusTimeline extends StatelessWidget {
  const _ClassStatusTimeline({
    required this.items,
    required this.expandedIndex,
    required this.onTap,
  });

  final List<_TimelineClass> items;
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
                _TimelineDot(
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
                    child: _ClassDetailCard(item: items[expandedIndex!]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TimelineDot extends StatelessWidget {
  const _TimelineDot({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _TimelineClass item;
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

class _ClassDetailCard extends StatelessWidget {
  const _ClassDetailCard({required this.item});
  final _TimelineClass item;

  String _timeLabel(DateTime start, DateTime end) =>
      '${_formatTime(start)} – ${_formatTime(end)}';

  String _formatTime(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${value.hour < 12 ? 'AM' : 'PM'}';
  }

  @override
  Widget build(BuildContext context) {
    final lesson = item.item;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: .62);
    final dayNames = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayLabel = lesson == null
        ? ''
        : lesson.start.day == DateTime.now().day &&
              lesson.start.month == DateTime.now().month
        ? 'Today'
        : dayNames[lesson.start.weekday - 1];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff151e2d) : Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: item.color.withValues(alpha: .22)),
      ),
      child: lesson == null
          ? Row(
              children: [
                Icon(Icons.event_busy_rounded, color: item.color, size: 17),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.emptyMessage,
                    style: TextStyle(
                      color: muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            )
          : Row(
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
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${lesson.type}  ·  ${lesson.room}  ·  $dayLabel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: muted, fontSize: 9),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _timeLabel(lesson.start, lesson.end),
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
