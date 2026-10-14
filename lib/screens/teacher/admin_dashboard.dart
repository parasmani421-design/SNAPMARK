import 'package:flutter/material.dart';

import '../timetable/timetable_screen.dart';
import '../timetable/academic_calendar_screen.dart';
import '../auth/login_screen.dart';
import '../../core/services/student_directory_store.dart';
import '../../core/services/device_access_request_store.dart';
import '../../core/services/campus_configuration_store.dart';
import '../../core/services/campus_info_store.dart';
import '../../widgets/teacher_assignment_text.dart';
import 'admin_device_requests_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedTab = 0;
  String _studentQuery = '';
  String _facultyQuery = '';
  List<StudentRecord> _students = [];
  List<FacultyRecord> _faculty = [];
  List<DeviceAccessRequest> _deviceRequests = [];
  int _scheduleDay = 0;
  bool _loadingStudents = true;
  bool _loadingFaculty = true;

  List<_SubstituteSuggestion> _findAvailableSubstitutes({
    required List<String> teacherNames,
    required int day,
    required String time,
    required String regularTeacher,
    int? existingDay,
    int? existingIndex,
  }) {
    final requested = _parseTimeRange(time);
    if (requested == null) return const [];
    final suggestions = <_SubstituteSuggestion>[];
    for (final name in teacherNames.toSet()) {
      if (name.trim().isEmpty ||
          name.trim().toLowerCase() == regularTeacher.trim().toLowerCase()) {
        continue;
      }
      var busy = false;
      final otherClasses = <String>[];
      final lessons = timetableSchedule[day] ?? const [];
      for (var index = 0; index < lessons.length; index++) {
        if (day == existingDay && index == existingIndex) continue;
        final lesson = lessons[index];
        final substitute = lesson['substituteTeacher']?.trim() ?? '';
        final assignedTeacher = substitute.isNotEmpty
            ? substitute
            : lesson['teacher']?.trim() ?? '';
        if (assignedTeacher.toLowerCase() != name.trim().toLowerCase()) {
          continue;
        }
        otherClasses.add(
          '${lesson['subject'] ?? 'Class'} · ${lesson['time'] ?? 'time TBA'}',
        );
        final occupied = _parseTimeRange(lesson['time'] ?? '');
        if (occupied == null ||
            occupied.$1 < requested.$2 && requested.$1 < occupied.$2) {
          busy = true;
          break;
        }
      }
      if (!busy) {
        suggestions.add(
          _SubstituteSuggestion(name: name, otherClasses: otherClasses),
        );
      }
    }
    suggestions.sort((a, b) {
      final byClassCount = a.otherClasses.length.compareTo(
        b.otherClasses.length,
      );
      return byClassCount != 0 ? byClassCount : a.name.compareTo(b.name);
    });
    return suggestions;
  }

  (int, int)? _parseTimeRange(String value) {
    final pieces = value.split('-');
    if (pieces.length != 2) return null;
    final start = _parseClockTime(pieces[0]);
    final end = _parseClockTime(pieces[1]);
    if (start == null || end == null || end <= start) return null;
    return (start, end);
  }

  int? _parseClockTime(String value) {
    final match = RegExp(
      r'^\s*(\d{1,2}):(\d{2})\s*(AM|PM)\s*$',
      caseSensitive: false,
    ).firstMatch(value);
    if (match == null) return null;
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour < 1 || hour > 12 || minute > 59) return null;
    final period = match.group(3)!.toUpperCase();
    final normalizedHour = hour % 12 + (period == 'PM' ? 12 : 0);
    return normalizedHour * 60 + minute;
  }

  @override
  void initState() {
    super.initState();
    _scheduleDay = DateTime.now().weekday - 1;
    if (_scheduleDay > 5) _scheduleDay = 0;
    _loadStudents();
    _loadFaculty();
    _loadDeviceRequests();
  }

  Future<void> _loadStudents() async {
    final records = await StudentDirectoryStore.loadAll();
    if (!mounted) return;
    setState(() {
      _students = records;
      _loadingStudents = false;
    });
  }

  Future<void> _loadFaculty() async {
    final records = await StudentDirectoryStore.loadAllFaculty();
    if (!mounted) return;
    setState(() {
      _faculty = records;
      _loadingFaculty = false;
    });
  }

  Future<void> _loadDeviceRequests() async {
    final requests = await DeviceAccessRequestStore.loadAll();
    if (!mounted) return;
    setState(() => _deviceRequests = requests);
  }

  Future<void> _openDeviceRequests() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const AdminDeviceRequestsScreen()),
    );
    await _loadDeviceRequests();
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Image.asset(
                'assets/images/snapmark_logo.png',
                width: 34,
                height: 34,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 9),
            Flexible(
              child: Text(
                'SnapMark Admin',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Academic calendar',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AcademicCalendarScreen()),
            ),
            icon: const Icon(Icons.event_available_rounded),
          ),
          IconButton(
            tooltip: 'Academic notifications',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const AcademicCalendarScreen(showReminders: true),
              ),
            ),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          IconButton(
            tooltip: 'Log out',
            onPressed: _logout,
            icon: Icon(Icons.logout_rounded, color: colors.onSurface),
          ),
          const SizedBox(width: 5),
        ],
      ),
      body: IndexedStack(
        index: _selectedTab,
        children: [
          _overview(context),
          _studentsPage(context),
          _facultyPage(context),
          _classesPage(context),
          _reportsPage(context),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) => setState(() => _selectedTab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard_rounded),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Students',
          ),
          NavigationDestination(
            icon: Icon(Icons.badge_outlined),
            selectedIcon: Icon(Icons.badge_rounded),
            label: 'Faculty',
          ),
          NavigationDestination(
            icon: Icon(Icons.meeting_room_outlined),
            selectedIcon: Icon(Icons.meeting_room_rounded),
            label: 'Classes',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics_rounded),
            label: 'Reports',
          ),
        ],
      ),
    );
  }

  Widget _overview(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final muted = colors.onSurface.withValues(alpha: .60);
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Campus overview',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _dateLabel(DateTime.now()),
                    style: TextStyle(color: muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            const _SampleBadge(),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.55,
          children: [
            _AdminStat(
              icon: Icons.school_rounded,
              label: 'Saved students',
              value: _students.length.toString(),
              tint: const Color(0xff6F9DFF),
            ),
            _AdminStat(
              icon: Icons.groups_rounded,
              label: 'Saved faculty',
              value: _faculty.length.toString(),
              tint: const Color(0xffB18AFF),
            ),
            const _AdminStat(
              icon: Icons.fact_check_rounded,
              label: 'Attendance today',
              value: '89%',
              tint: Color(0xff4DCBA5),
            ),
            _AdminStat(
              icon: Icons.phonelink_lock_rounded,
              label: 'Device requests',
              value: _deviceRequests
                  .where((request) => request.status == 'pending')
                  .length
                  .toString(),
              tint: const Color(0xffFFB454),
            ),
          ],
        ),
        const SizedBox(height: 21),
        _sectionTitle(context, 'Attendance trend', 'This week'),
        const SizedBox(height: 10),
        _attendanceChart(context),
        const SizedBox(height: 21),
        _sectionTitle(context, 'Needs attention', '3 items'),
        const SizedBox(height: 10),
        _reviewItem(
          context,
          Icons.phonelink_lock_rounded,
          'Device approval requests',
          '${_deviceRequests.where((request) => request.status == 'pending').length} requests waiting for review',
          const Color(0xffFFB454),
          onTap: _openDeviceRequests,
        ),
        const SizedBox(height: 8),
        _reviewItem(
          context,
          Icons.fact_check_outlined,
          'Attendance exceptions',
          '11 records need a quick check',
          const Color(0xffFFB454),
        ),
        const SizedBox(height: 21),
        Text(
          'Admin tools',
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _adminQuickAction(
                context,
                Icons.person_add_alt_1_rounded,
                'Invite faculty',
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _adminQuickAction(
                context,
                Icons.meeting_room_rounded,
                'Manage rooms',
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _adminQuickAction(
                context,
                Icons.file_download_outlined,
                'Export',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Saved student profiles are local. Attendance and campus-wide counts remain sample values until an admin service is connected.',
          style: TextStyle(color: muted, fontSize: 9, height: 1.4),
        ),
      ],
    );
  }

  Future<void> _editStudent([StudentRecord? existing]) async {
    final controllers = <String, TextEditingController>{
      for (final field in StudentDirectoryStore.profileFields)
        field.keyName: TextEditingController(
          text: existing?.value(field.keyName) ?? '',
        ),
    };
    String? formError;
    final result = await showDialog<StudentRecord>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add student' : 'Edit student'),
          content: SizedBox(
            width: 440,
            height: MediaQuery.sizeOf(context).height * .58,
            child: ListView(
              children: [
                for (final field in StudentDirectoryStore.profileFields)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: field.keyName == 'section'
                        ? DropdownButtonFormField<String>(
                            initialValue:
                                CampusConfigurationStore.sections.contains(
                                  controllers['section']!.text.trim(),
                                )
                                ? controllers['section']!.text.trim()
                                : CampusConfigurationStore.sections.contains(
                                    RegExp(r'\d+')
                                        .firstMatch(
                                          controllers['section']!.text.trim(),
                                        )
                                        ?.group(0),
                                  )
                                ? RegExp(r'\d+')
                                      .firstMatch(
                                        controllers['section']!.text.trim(),
                                      )!
                                      .group(0)
                                : '',
                            decoration: InputDecoration(
                              labelText: field.label,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: '',
                                child: Text('Unassigned'),
                              ),
                              for (final section
                                  in CampusConfigurationStore.sections)
                                DropdownMenuItem(
                                  value: section,
                                  child: Text('Section $section'),
                                ),
                            ],
                            onChanged: (value) =>
                                controllers['section']!.text = value ?? '',
                          )
                        : TextField(
                            controller: controllers[field.keyName],
                            keyboardType:
                                field.keyName.contains('phone') ||
                                    field.keyName == 'pin_code'
                                ? TextInputType.phone
                                : field.keyName == 'email'
                                ? TextInputType.emailAddress
                                : TextInputType.text,
                            maxLines: field.keyName == 'address' ? 2 : 1,
                            decoration: InputDecoration(
                              labelText: field.label,
                              helperText: field.keyName == 'mentor_email'
                                  ? 'Use the faculty email from the Faculty directory.'
                                  : null,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),
                          ),
                  ),
                if (formError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      formError!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                Text(
                  'Passwords and uploaded identity documents are not included in this directory.',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: .55),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = controllers['full_name']!.text.trim();
                final email = controllers['email']!.text.trim();
                final mentorEmail = controllers['mentor_email']!.text.trim();
                if (name.isEmpty || email.isEmpty || !email.contains('@')) {
                  setDialogState(
                    () => formError = 'Enter a name and valid email address.',
                  );
                  return;
                }
                if (mentorEmail.isNotEmpty && !mentorEmail.contains('@')) {
                  setDialogState(
                    () => formError = 'Enter a valid mentor faculty email.',
                  );
                  return;
                }
                final normalized = email.toLowerCase();
                final duplicate = _students.any(
                  (record) =>
                      record.id != existing?.id &&
                      record.value('email').toLowerCase() == normalized,
                );
                if (duplicate) {
                  setDialogState(
                    () =>
                        formError = 'A student with this email already exists.',
                  );
                  return;
                }
                final values = <String, String>{
                  for (final entry in controllers.entries)
                    entry.key: entry.value.text.trim(),
                };
                Navigator.pop(
                  dialogContext,
                  StudentRecord(
                    id: existing?.id ?? normalized,
                    profile: values,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    for (final controller in controllers.values) {
      controller.dispose();
    }
    if (result == null) return;
    await StudentDirectoryStore.save(result);
    await _loadStudents();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existing == null ? 'Student added.' : 'Student updated.',
          ),
        ),
      );
    }
  }

  Future<void> _removeStudent(StudentRecord student) async {
    final name = student.value('full_name').isEmpty
        ? student.value('email')
        : student.value('full_name');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove student?'),
        content: Text('Remove $name from this device’s admin directory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await StudentDirectoryStore.delete(student.id);
    await _loadStudents();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student removed from this device’s directory.'),
        ),
      );
    }
  }

  Widget _studentsPage(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final muted = colors.onSurface.withValues(alpha: .58);
    final query = _studentQuery.toLowerCase();
    final visible = _students
        .where(
          (record) => record.profile.values.any(
            (value) => value.toLowerCase().contains(query),
          ),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Student directory',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_students.length} saved student records',
                    style: TextStyle(color: muted, fontSize: 10),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () => _editStudent(),
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 17),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: (value) => setState(() => _studentQuery = value),
          decoration: InputDecoration(
            hintText: 'Search name, email, enrollment or course',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: colors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_loadingStudents)
          const Padding(
            padding: EdgeInsets.all(28),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (visible.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: _cardDecoration(context),
            child: Column(
              children: [
                const Icon(
                  Icons.people_outline_rounded,
                  color: Color(0xff8FA5FF),
                  size: 30,
                ),
                const SizedBox(height: 8),
                Text(
                  query.isEmpty
                      ? 'No student records yet'
                      : 'No matching students',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  query.isEmpty
                      ? 'Student registrations and saved profiles on this device will appear here. You can also add a record.'
                      : 'Try another name, email, enrollment number or course.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted, fontSize: 10, height: 1.4),
                ),
              ],
            ),
          )
        else
          for (final student in visible)
            Container(
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
              decoration: _cardDecoration(context),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(
                      0xff3977FF,
                    ).withValues(alpha: .18),
                    child: Text(
                      student.value('full_name').isEmpty
                          ? '?'
                          : student.value('full_name')[0].toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xff8DB2FF),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.value('full_name').isEmpty
                              ? 'Unnamed student'
                              : student.value('full_name'),
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
                          student.value('email'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: muted, fontSize: 9),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          [
                            student.value('enrollment_number'),
                            student.value('program'),
                          ].where((value) => value.isNotEmpty).join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xff9DAEFF),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Manage student',
                    onSelected: (action) {
                      if (action == 'edit') _editStudent(student);
                      if (action == 'remove') _removeStudent(student);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Edit details'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'remove',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline),
                          title: Text('Remove student'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        const SizedBox(height: 6),
        Text(
          'Directory data is encrypted on this device. It is not shared with other phones until a campus backend is connected.',
          style: TextStyle(color: muted, fontSize: 9, height: 1.4),
        ),
      ],
    );
  }

  Future<void> _editFaculty([FacultyRecord? existing]) async {
    final controllers = <String, TextEditingController>{
      for (final field in StudentDirectoryStore.facultyFields)
        field.keyName: TextEditingController(
          text: existing?.value(field.keyName) ?? '',
        ),
    };
    String? formError;
    final result = await showDialog<FacultyRecord>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            existing == null ? 'Add faculty member' : 'Edit faculty member',
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final field in StudentDirectoryStore.facultyFields)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextField(
                        controller: controllers[field.keyName],
                        keyboardType: field.keyName == 'email'
                            ? TextInputType.emailAddress
                            : field.keyName == 'phone'
                            ? TextInputType.phone
                            : TextInputType.text,
                        decoration: InputDecoration(
                          labelText: field.label,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  if (formError != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formError!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Faculty records are stored securely on this device. Login passwords are not stored here.',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: .55),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = controllers['full_name']!.text.trim();
                final email = controllers['email']!.text.trim();
                if (name.isEmpty || email.isEmpty || !email.contains('@')) {
                  setDialogState(
                    () => formError = 'Enter a name and valid faculty email.',
                  );
                  return;
                }
                final normalized = email.toLowerCase();
                final duplicate = _faculty.any(
                  (record) =>
                      record.id != existing?.id &&
                      record.value('email').toLowerCase() == normalized,
                );
                if (duplicate) {
                  setDialogState(
                    () => formError =
                        'A faculty member with this email already exists.',
                  );
                  return;
                }
                Navigator.pop(
                  dialogContext,
                  FacultyRecord(
                    id: existing?.id ?? normalized,
                    profile: {
                      for (final entry in controllers.entries)
                        entry.key: entry.value.text.trim(),
                    },
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    for (final controller in controllers.values) {
      controller.dispose();
    }
    if (result == null) return;
    await StudentDirectoryStore.saveFaculty(result);
    await _loadFaculty();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existing == null
                ? 'Faculty member added.'
                : 'Faculty details updated.',
          ),
        ),
      );
    }
  }

  Future<void> _removeFaculty(FacultyRecord faculty) async {
    final name = faculty.value('full_name').isEmpty
        ? faculty.value('email')
        : faculty.value('full_name');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove faculty member?'),
        content: Text('Remove $name from this device’s admin directory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await StudentDirectoryStore.deleteFaculty(faculty.id);
    await _loadFaculty();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Faculty member removed from this device’s directory.'),
        ),
      );
    }
  }

  Widget _facultyPage(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final muted = colors.onSurface.withValues(alpha: .58);
    final query = _facultyQuery.toLowerCase();
    final visible = _faculty
        .where(
          (record) => record.profile.values.any(
            (value) => value.toLowerCase().contains(query),
          ),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Faculty directory',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_faculty.length} saved faculty records',
                    style: TextStyle(color: muted, fontSize: 10),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () => _editFaculty(),
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 17),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: _cardDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Demo substitute candidates',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Included in the free-teacher suggestions; add their official details to create faculty accounts.',
                style: TextStyle(color: muted, fontSize: 9),
              ),
              const SizedBox(height: 7),
              const Wrap(
                spacing: 6,
                children: [
                  Chip(label: Text('Jyoti Ratna')),
                  Chip(label: Text('Dr. Vijay')),
                  Chip(label: Text('Dr. Ravi')),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: (value) => setState(() => _facultyQuery = value),
          decoration: InputDecoration(
            hintText: 'Search name, email, ID or department',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: colors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_loadingFaculty)
          const Padding(
            padding: EdgeInsets.all(28),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (visible.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: _cardDecoration(context),
            child: Column(
              children: [
                const Icon(
                  Icons.badge_outlined,
                  color: Color(0xffB18AFF),
                  size: 30,
                ),
                const SizedBox(height: 8),
                Text(
                  query.isEmpty
                      ? 'No faculty records yet'
                      : 'No matching faculty',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  query.isEmpty
                      ? 'Faculty members who log in on this device appear here. You can also add them manually.'
                      : 'Try another name, email, employee ID or department.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted, fontSize: 10, height: 1.4),
                ),
              ],
            ),
          )
        else
          for (final faculty in visible)
            Container(
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
              decoration: _cardDecoration(context),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(
                      0xffB18AFF,
                    ).withValues(alpha: .18),
                    child: Text(
                      faculty.value('full_name').isEmpty
                          ? '?'
                          : faculty.value('full_name')[0].toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xffC4A8FF),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          faculty.value('full_name').isEmpty
                              ? 'Unnamed faculty'
                              : faculty.value('full_name'),
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
                          faculty.value('email'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: muted, fontSize: 9),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          [
                            faculty.value('employee_id'),
                            faculty.value('department'),
                            faculty.value('designation'),
                          ].where((value) => value.isNotEmpty).join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xffC1A5FF),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Manage faculty member',
                    onSelected: (action) {
                      if (action == 'edit') _editFaculty(faculty);
                      if (action == 'remove') _removeFaculty(faculty);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Edit details'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'remove',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline),
                          title: Text('Remove faculty'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        const SizedBox(height: 6),
        Text(
          'Directory data is encrypted on this device. It is not shared with other phones until a campus backend is connected.',
          style: TextStyle(color: muted, fontSize: 9, height: 1.4),
        ),
      ],
    );
  }

  Future<void> _editScheduleClass({
    int? day,
    int? index,
    Map<String, String>? lesson,
  }) async {
    final subjectController = TextEditingController(
      text: lesson?['subject'] ?? '',
    );
    final teacherController = TextEditingController(
      text: lesson?['teacher'] ?? '',
    );
    final substituteController = TextEditingController(
      text: lesson?['substituteTeacher'] ?? '',
    );
    final timeController = TextEditingController(text: lesson?['time'] ?? '');
    final roomController = TextEditingController(text: lesson?['room'] ?? '');
    var selectedDay = day ?? _scheduleDay;
    var selectedSection = lesson?['section'] ?? '';
    var selectedType = lesson?['type'] ?? 'Lecture';
    final scheduledTeacherNames = timetableSchedule.values
        .expand((lessons) => lessons)
        .expand(
          (scheduledLesson) => [
            scheduledLesson['teacher'] ?? '',
            scheduledLesson['substituteTeacher'] ?? '',
          ],
        );
    final facultyNames = <String>{
      ..._faculty.map((faculty) => faculty.value('full_name').trim()),
      ...scheduledTeacherNames.map((name) => name.trim()),
      // Demo-only substitute candidates with no scheduled classes yet.
      'Jyoti Ratna',
      'Dr. Vijay',
      'Dr. Ravi',
    }.where((name) => name.isNotEmpty).toList()..sort();
    final existingTeacher = teacherController.text.trim();
    var selectedSubstitute = substituteController.text.trim();
    if (existingTeacher.isNotEmpty && !facultyNames.contains(existingTeacher)) {
      facultyNames.insert(0, existingTeacher);
    }
    if (selectedSubstitute.isNotEmpty &&
        !facultyNames.contains(selectedSubstitute)) {
      facultyNames.add(selectedSubstitute);
    }
    var selectedTeacher = existingTeacher.isNotEmpty
        ? existingTeacher
        : facultyNames.isNotEmpty
        ? facultyNames.first
        : '';
    if (selectedSubstitute == selectedTeacher) {
      selectedSubstitute = '';
      substituteController.clear();
    }
    if (teacherController.text.isEmpty && selectedTeacher.isNotEmpty) {
      teacherController.text = selectedTeacher;
    }
    final sections = CampusConfigurationStore.sections;
    if (selectedSection.isNotEmpty && !sections.contains(selectedSection)) {
      selectedSection = '';
    }
    var suggestionsChecked = false;
    var invalidSuggestionTime = false;
    var availabilitySuggestions = <_SubstituteSuggestion>[];

    final result = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(lesson == null ? 'Add class' : 'Edit class'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Subject / class',
                    ),
                  ),
                  if (facultyNames.isEmpty)
                    TextField(
                      controller: teacherController,
                      decoration: const InputDecoration(
                        labelText: 'Faculty / teacher',
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      initialValue: selectedTeacher,
                      decoration: const InputDecoration(
                        labelText: 'Faculty / teacher',
                      ),
                      items: [
                        for (final name in facultyNames)
                          DropdownMenuItem(value: name, child: Text(name)),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedTeacher = value;
                            teacherController.text = value;
                            if (selectedSubstitute == value) {
                              selectedSubstitute = '';
                              substituteController.clear();
                            }
                          });
                        }
                      },
                    ),
                  const SizedBox(height: 8),
                  if (facultyNames.isEmpty)
                    TextField(
                      controller: substituteController,
                      decoration: const InputDecoration(
                        labelText: 'Substitute faculty (optional)',
                        helperText: 'Leave blank when there is no substitute.',
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      initialValue: selectedSubstitute,
                      decoration: const InputDecoration(
                        labelText: 'Substitute faculty (optional)',
                        helperText: 'Leave blank when there is no substitute.',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text('No substitute'),
                        ),
                        for (final name in facultyNames)
                          if (name != selectedTeacher)
                            DropdownMenuItem(value: name, child: Text(name)),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedSubstitute = value ?? '';
                          substituteController.text = selectedSubstitute;
                        });
                      },
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        setDialogState(() {
                          suggestionsChecked = true;
                          invalidSuggestionTime =
                              _parseTimeRange(timeController.text) == null;
                          availabilitySuggestions = invalidSuggestionTime
                              ? []
                              : _findAvailableSubstitutes(
                                  teacherNames: facultyNames,
                                  day: selectedDay,
                                  time: timeController.text,
                                  regularTeacher: selectedTeacher,
                                  existingDay: day,
                                  existingIndex: index,
                                );
                        });
                      },
                      icon: const Icon(Icons.auto_awesome_rounded, size: 17),
                      label: const Text('Suggest available teachers'),
                    ),
                  ),
                  if (suggestionsChecked && invalidSuggestionTime)
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Enter a valid time range first, for example 09:00 AM - 09:50 AM.',
                        style: TextStyle(
                          color: Colors.deepOrange,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  if (suggestionsChecked &&
                      !invalidSuggestionTime &&
                      availabilitySuggestions.isEmpty)
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'No free teachers found for this time in the saved timetable.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  for (final suggestion in availabilitySuggestions)
                    Card(
                      margin: const EdgeInsets.only(bottom: 4),
                      child: ListTile(
                        dense: true,
                        leading: const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xff168A58),
                        ),
                        title: Text(suggestion.name),
                        subtitle: Text(
                          suggestion.otherClasses.isEmpty
                              ? 'Free at this time · No other classes today'
                              : 'Free at this time · ${suggestion.otherClasses.length} other class${suggestion.otherClasses.length == 1 ? '' : 'es'} today\n${suggestion.otherClasses.join('\n')}',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Text('Assign'),
                        onTap: () {
                          setDialogState(() {
                            selectedSubstitute = suggestion.name;
                            substituteController.text = suggestion.name;
                            suggestionsChecked = false;
                          });
                        },
                      ),
                    ),
                  TextField(
                    controller: timeController,
                    decoration: const InputDecoration(
                      labelText: 'Time',
                      hintText: '09:00 AM - 09:50 AM',
                    ),
                  ),
                  TextField(
                    controller: roomController,
                    decoration: const InputDecoration(
                      labelText: 'Room / class',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: selectedDay,
                    decoration: const InputDecoration(labelText: 'Day'),
                    items: [
                      for (var i = 0; i < 6; i++)
                        DropdownMenuItem(value: i, child: Text(_dayName(i))),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedDay = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedSection,
                    decoration: const InputDecoration(labelText: 'Section'),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('All sections'),
                      ),
                      for (final section in sections)
                        DropdownMenuItem(
                          value: section,
                          child: Text('Section $section'),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedSection = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(labelText: 'Class type'),
                    items: const [
                      DropdownMenuItem(
                        value: 'Lecture',
                        child: Text('Lecture'),
                      ),
                      DropdownMenuItem(value: 'Lab', child: Text('Lab')),
                      DropdownMenuItem(
                        value: 'Practical',
                        child: Text('Practical'),
                      ),
                      DropdownMenuItem(
                        value: 'Tutorial',
                        child: Text('Tutorial'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedType = value);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (subjectController.text.trim().isEmpty ||
                    teacherController.text.trim().isEmpty ||
                    timeController.text.trim().isEmpty ||
                    roomController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fill in all class details.')),
                  );
                  return;
                }
                Navigator.pop(dialogContext, {
                  'day': selectedDay,
                  'lesson': <String, String>{
                    'subject': subjectController.text.trim(),
                    'teacher': teacherController.text.trim(),
                    'substituteTeacher': substituteController.text.trim(),
                    'time': timeController.text.trim(),
                    'room': roomController.text.trim(),
                    'type': selectedType,
                    'section': selectedSection,
                  },
                });
              },
              child: const Text('Save class'),
            ),
          ],
        ),
      ),
    );
    subjectController.dispose();
    teacherController.dispose();
    substituteController.dispose();
    timeController.dispose();
    roomController.dispose();
    if (result == null) return;
    // Let the modal route finish its reverse transition before mutating the
    // IndexedStack-backed admin screen. Rebuilding it while the dialog is
    // deactivating can leave inherited dependents attached on slower devices.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    await CampusConfigurationStore.saveLesson(
      schedule: timetableSchedule,
      day: result['day']! as int,
      lesson: result['lesson']! as Map<String, String>,
      existingDay: day,
      existingIndex: index,
    );
    if (!mounted) return;
    setState(() => _scheduleDay = result['day']! as int);
  }

  Future<void> _deleteScheduleClass(int day, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this class?'),
        content: const Text(
          'It will be removed from the student and teacher timetable.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await CampusConfigurationStore.deleteLesson(
      schedule: timetableSchedule,
      day: day,
      index: index,
    );
    if (mounted) setState(() {});
  }

  Future<void> _editSection([String? oldSection]) async {
    final controller = TextEditingController(text: oldSection ?? '');
    final newSection = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(oldSection == null ? 'Add section' : 'Rename section'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Section name',
            hintText: '47',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(context, value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newSection == null || newSection.trim().isEmpty) return;
    if (oldSection == null) {
      await CampusConfigurationStore.addSection(newSection);
    } else {
      await CampusConfigurationStore.renameSection(
        oldName: oldSection,
        newName: newSection,
        schedule: timetableSchedule,
      );
      for (final student in await StudentDirectoryStore.loadAll()) {
        if (student.value('section').trim() == oldSection) {
          await StudentDirectoryStore.save(
            student.copyWith(
              profile: {...student.profile, 'section': newSection.trim()},
            ),
          );
        }
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _deleteSection(String section) async {
    if (CampusConfigurationStore.sectionHasScheduledClasses(
      timetableSchedule,
      section,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Move classes out of section $section before removing it.',
          ),
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove section $section?'),
        content: const Text(
          'Students currently assigned to this section will need to be reassigned in their profiles.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove section'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await CampusConfigurationStore.removeSection(section);
    for (final student in await StudentDirectoryStore.loadAll()) {
      if (student.value('section').trim() == section) {
        await StudentDirectoryStore.save(
          student.copyWith(profile: {...student.profile, 'section': ''}),
        );
      }
    }
    if (mounted) setState(() {});
  }

  static String _dayName(int day) => const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ][day];

  Widget _classesPage(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final muted = colors.onSurface.withValues(alpha: .6);
    final lessons = timetableSchedule[_scheduleDay] ?? const [];
    final dayLabels = const ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Timetable & classes',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Changes appear across student and teacher screens',
                    style: TextStyle(color: muted, fontSize: 10),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () => _editScheduleClass(day: _scheduleDay),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 6,
          children: [
            for (var day = 0; day < dayLabels.length; day++)
              ChoiceChip(
                label: Text(dayLabels[day]),
                selected: _scheduleDay == day,
                onSelected: (_) => setState(() => _scheduleDay = day),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '${_dayName(_scheduleDay)} · ${lessons.length} classes',
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 9),
        if (lessons.isEmpty)
          _reviewItem(
            context,
            Icons.event_busy_rounded,
            'No classes scheduled',
            'Add a class to this day',
            const Color(0xff8FA5FF),
          )
        else
          for (var index = 0; index < lessons.length; index++)
            Builder(
              builder: (context) {
                final lesson = lessons[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.fromLTRB(12, 11, 4, 11),
                  decoration: _cardDecoration(context),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xff8E7AFF).withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: Color(0xffB29AFF),
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lesson['subject'] ?? 'Class',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.onSurface,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Expanded(
                                  child: TeacherAssignmentText(
                                    teacher: lesson['teacher'] ?? 'Teacher',
                                    substituteTeacher:
                                        lesson['substituteTeacher'] ?? '',
                                    maxLines: 1,
                                    style: TextStyle(color: muted, fontSize: 9),
                                  ),
                                ),
                                Text(
                                  '  ·  ${lesson['time'] ?? 'Time TBA'}',
                                  style: TextStyle(color: muted, fontSize: 9),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${lesson['room'] ?? 'Room TBA'}  ·  ${lesson['section']?.isNotEmpty == true ? 'Section ${lesson['section']}' : 'All sections'}  ·  ${lesson['type'] ?? 'Lecture'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: muted, fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (action) {
                          if (action == 'edit') {
                            _editScheduleClass(
                              day: _scheduleDay,
                              index: index,
                              lesson: lesson,
                            );
                          } else {
                            _deleteScheduleClass(_scheduleDay, index);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit class'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Remove class'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        const SizedBox(height: 17),
        Row(
          children: [
            Expanded(
              child: Text(
                'Sections',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => _editSection(),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add section'),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 8,
          runSpacing: 1,
          children: [
            for (final section in CampusConfigurationStore.sections)
              InputChip(
                label: Text(section),
                onPressed: () => _editSection(section),
                onDeleted: () => _deleteSection(section),
                deleteIcon: const Icon(Icons.close_rounded, size: 16),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Teachers are managed in the Faculty tab. Editing this schedule updates shared timetable data on this installation.',
          style: TextStyle(color: muted, fontSize: 9, height: 1.4),
        ),
      ],
    );
  }

  Widget _reportsPage(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final muted = colors.onSurface.withValues(alpha: .60);
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      children: [
        Text(
          'Reports & analytics',
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Campus-level snapshot',
          style: TextStyle(color: muted, fontSize: 11),
        ),
        const SizedBox(height: 15),
        Card(
          child: ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Campus information for AI'),
            subtitle: const Text(
              'Edit stationery, medical room and ERP office locations',
            ),
            trailing: const Icon(Icons.edit_outlined),
            onTap: _editCampusInfo,
          ),
        ),
        const SizedBox(height: 9),
        _reportTile(
          context,
          'Attendance',
          '89% average today',
          Icons.fact_check_rounded,
          const Color(0xff4DCBA5),
        ),
        const SizedBox(height: 9),
        _reportTile(
          context,
          'Student engagement',
          'Weekly participation snapshot',
          Icons.insights_rounded,
          const Color(0xff8FA5FF),
        ),
        const SizedBox(height: 9),
        _reportTile(
          context,
          'Faculty activity',
          '64 faculty profiles',
          Icons.groups_rounded,
          const Color(0xffB18AFF),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xff8E7AFF).withValues(alpha: .09),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: const Color(0xff8E7AFF).withValues(alpha: .18),
            ),
          ),
          child: const Text(
            'Reports use sample values. Connect the admin analytics service to load official campus data.',
            style: TextStyle(
              color: Color(0xffC7C1E9),
              fontSize: 10,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _editCampusInfo() async {
    final controllers = <String, TextEditingController>{
      for (final entry in CampusInfoStore.labels.entries)
        entry.key: TextEditingController(
          text: CampusInfoStore.location(entry.key),
        ),
    };
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Campus information for AI'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final entry in CampusInfoStore.labels.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextField(
                      controller: controllers[entry.key],
                      decoration: InputDecoration(labelText: entry.value),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save locations'),
          ),
        ],
      ),
    );
    if (saved == true) {
      for (final entry in controllers.entries) {
        await CampusInfoStore.saveLocation(entry.key, entry.value.text);
      }
    }
    for (final controller in controllers.values) {
      controller.dispose();
    }
  }

  Widget _sectionTitle(BuildContext context, String title, String trailing) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Text(
          trailing,
          style: const TextStyle(
            color: Color(0xff9DAEFF),
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _attendanceChart(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final muted = colors.onSurface.withValues(alpha: .55);
    const values = [0.66, 0.78, 0.58, 0.88, 0.72, 0.94, 0.81];
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 10),
      decoration: _cardDecoration(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(
          values.length,
          (index) => Expanded(
            child: Column(
              children: [
                Text(
                  '${(values[index] * 100).round()}%',
                  style: TextStyle(color: muted, fontSize: 8),
                ),
                const SizedBox(height: 5),
                Container(
                  width: 17,
                  height: 66 * values[index],
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    gradient: const LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xff3977FF), Color(0xffA45BFF)],
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(days[index], style: TextStyle(color: muted, fontSize: 8)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _reviewItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color tint, {
    VoidCallback? onTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    final muted = colors.onSurface.withValues(alpha: .6);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: _cardDecoration(context),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: tint, size: 18),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(subtitle, style: TextStyle(color: muted, fontSize: 9)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: muted, size: 19),
            ],
          ),
        ),
      ),
    );
  }

  Widget _adminQuickAction(BuildContext context, IconData icon, String label) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$label will be available when admin services are connected.',
          ),
        ),
      ),
      borderRadius: BorderRadius.circular(13),
      child: Container(
        height: 77,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: _cardDecoration(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xff9DAEFF), size: 19),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color tint,
  ) {
    final colors = Theme.of(context).colorScheme;
    final muted = colors.onSurface.withValues(alpha: .6);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(context),
      child: Row(
        children: [
          Icon(icon, color: tint, size: 22),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(subtitle, style: TextStyle(color: muted, fontSize: 9)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: muted, size: 18),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) => BoxDecoration(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .07),
    ),
  );

  String _dateLabel(DateTime value) =>
      '${_weekday(value.weekday)}, ${value.day} ${_month(value.month)} ${value.year}';

  String _weekday(int value) => const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ][value - 1];
  String _month(int value) => const [
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
  ][value - 1];
}

class _SubstituteSuggestion {
  const _SubstituteSuggestion({required this.name, required this.otherClasses});

  final String name;
  final List<String> otherClasses;
}

class _AdminStat extends StatelessWidget {
  const _AdminStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final muted = colors.onSurface.withValues(alpha: .58);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colors.onSurface.withValues(alpha: .07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 29,
                height: 29,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: tint, size: 16),
              ),
              const Spacer(),
              const Icon(
                Icons.trending_up_rounded,
                color: Color(0xff4DCBA5),
                size: 15,
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: muted, fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SampleBadge extends StatelessWidget {
  const _SampleBadge();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xff9D86FF).withValues(alpha: .13),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Text(
      'SAMPLE DATA',
      style: TextStyle(
        color: Color(0xffB8A5FF),
        fontSize: 8,
        letterSpacing: .6,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}
