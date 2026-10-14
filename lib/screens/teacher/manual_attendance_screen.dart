import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/services/attendance_record_store.dart';
import '../../core/services/student_directory_store.dart';
import '../timetable/timetable_screen.dart';

class ManualAttendanceScreen extends StatefulWidget {
  const ManualAttendanceScreen({
    this.initiallyShowingHistory = false,
    super.key,
  });

  final bool initiallyShowingHistory;

  @override
  State<ManualAttendanceScreen> createState() => _ManualAttendanceScreenState();
}

class _ManualAttendanceScreenState extends State<ManualAttendanceScreen> {
  static const _storage = FlutterSecureStorage();
  static const _storageKey = 'snapmark_teacher_manual_registers';
  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  late final List<_ClassOption> _classes = _createClassOptions();
  final List<_ManualStudent> _students = [];
  final _newRollController = TextEditingController();
  final _newNameController = TextEditingController();
  final _newEmailController = TextEditingController();
  List<Map<String, dynamic>> _savedRegisters = [];
  int _selectedClass = 0;
  late bool _showHistory = widget.initiallyShowingHistory;
  bool _loading = true;
  bool _saving = false;
  bool _addingStudent = false;

  @override
  void dispose() {
    _newRollController.dispose();
    _newNameController.dispose();
    _newEmailController.dispose();
    super.dispose();
  }

  List<_ClassOption> _createClassOptions() {
    final today = DateTime.now();
    final todaysClasses = timetableSchedule[today.weekday - 1] ?? const [];
    final entries = <_ClassOption>[];
    final source = todaysClasses.isNotEmpty
        ? [(today.weekday - 1, todaysClasses)]
        : timetableSchedule.entries
              .map((entry) => (entry.key, entry.value))
              .toList();
    for (final (dayIndex, dayClasses) in source) {
      for (final item in dayClasses) {
        final option = _ClassOption(
          subject: item['subject'] ?? 'Class',
          teacher: item['teacher'] ?? '',
          time: item['time'] ?? '',
          room: item['room'] ?? '',
          type: item['type'] ?? 'Class',
          section: item['section'] ?? '',
          day: _weekdays[dayIndex],
        );
        if (!entries.any((existing) => existing.label == option.label)) {
          entries.add(option);
        }
      }
    }
    return entries;
  }

  @override
  void initState() {
    super.initState();
    _loadRegisters();
  }

  Future<void> _loadRegisters() async {
    try {
      final raw = await _storage.read(key: _storageKey);
      final directory = await StudentDirectoryStore.loadAll();
      final selectedSection = _classes.isEmpty
          ? ''
          : _classes[_selectedClass].section.trim().toLowerCase();
      final tagged = directory
          .where(
            (student) =>
                student.value('section').isNotEmpty ||
                student.value('class_section').isNotEmpty ||
                student.value('section_name').isNotEmpty,
          )
          .toList();
      final roster = tagged.isEmpty || selectedSection.isEmpty
          ? directory
          : directory.where((student) {
              final section = student.value('section').isNotEmpty
                  ? student.value('section')
                  : student.value('class_section').isNotEmpty
                  ? student.value('class_section')
                  : student.value('section_name');
              final studentSection =
                  RegExp(r'\d+').firstMatch(section)?.group(0) ??
                  section.toLowerCase().replaceAll('section', '').trim();
              final classSection =
                  RegExp(r'\d+').firstMatch(selectedSection)?.group(0) ??
                  selectedSection.replaceAll('section', '').trim();
              return studentSection == classSection;
            }).toList();
      final decoded = raw == null
          ? <dynamic>[]
          : jsonDecode(raw) as List<dynamic>;
      if (mounted) {
        setState(() {
          _savedRegisters = decoded
              .whereType<Map>()
              .map((entry) => Map<String, dynamic>.from(entry))
              .toList()
              .reversed
              .toList();
          _students
            ..clear()
            ..addAll(
              roster.map((student) {
                final roll = student.value('roll_number').isNotEmpty
                    ? student.value('roll_number')
                    : student.value('enrollment_number').isNotEmpty
                    ? student.value('enrollment_number')
                    : student.value('admission_number');
                return _ManualStudent(
                  id: student.id,
                  email: student.value('email'),
                  roll: roll.isEmpty ? student.id : roll,
                  name: student.value('full_name').isEmpty
                      ? student.value('email')
                      : student.value('full_name'),
                );
              }),
            );
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _addStudent() => setState(() => _addingStudent = true);

  void _confirmAddStudent() {
    final roll = _newRollController.text.trim().toUpperCase();
    final name = _newNameController.text.trim();
    final email = _newEmailController.text.trim();
    if (roll.isEmpty || name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter the student name, roll number, and email.'),
        ),
      );
      return;
    }
    if (_students.any(
      (item) => item.roll.toLowerCase() == roll.toLowerCase(),
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('That roll number is already on this register'),
        ),
      );
      return;
    }
    setState(() {
      _students.add(_ManualStudent(roll: roll, name: name, email: email));
      _newRollController.clear();
      _newNameController.clear();
      _newEmailController.clear();
      _addingStudent = false;
    });
  }

  Future<void> _saveRegister() async {
    if (_classes.isEmpty || _students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _classes.isEmpty
                ? 'No timetable classes are available'
                : 'Add students before saving',
          ),
        ),
      );
      return;
    }
    if (_students.any((student) => student.email.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Every student needs an email in the directory to sync attendance to their student account.',
          ),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final selected = _classes[_selectedClass];
    final record = <String, dynamic>{
      'class': selected.label,
      'savedAt': DateTime.now().toIso8601String(),
      'present': _students.where((student) => student.present).length,
      'absent': _students.where((student) => !student.present).length,
      'students': _students.map((student) => student.toJson()).toList(),
    };
    try {
      final attendanceDate = DateTime.now().toIso8601String().substring(0, 10);
      await AttendanceRecordStore.saveSession(
        _students
            .where((student) => student.email.trim().isNotEmpty)
            .map(
              (student) => AttendanceEntry(
                studentEmail: student.email,
                studentName: student.name,
                roll: student.roll,
                subject: selected.subject,
                date: attendanceDate,
                present: student.present,
              ),
            )
            .toList(),
      );
      final raw = await _storage.read(key: _storageKey);
      final previous = raw == null
          ? <dynamic>[]
          : jsonDecode(raw) as List<dynamic>;
      final updated = [...previous, record];
      await _storage.write(key: _storageKey, value: jsonEncode(updated));
      if (mounted) {
        setState(() {
          _savedRegisters = [record, ..._savedRegisters];
          _students.clear();
          _showHistory = true;
          _saving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Manual register saved securely on this device'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save this register. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final muted = colors.onSurface.withValues(alpha: .62);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_showHistory ? 'Manual registers' : 'Manual attendance'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          _ModeButton(
                            label: 'Take attendance',
                            selected: !_showHistory,
                            onTap: () => setState(() => _showHistory = false),
                          ),
                          _ModeButton(
                            label: 'Saved registers',
                            count: _savedRegisters.length,
                            selected: _showHistory,
                            onTap: () => setState(() => _showHistory = true),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: _showHistory
                        ? _buildHistory(colors, muted)
                        : _buildRegisterForm(colors, muted),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildRegisterForm(ColorScheme colors, Color muted) => Column(
    children: [
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          children: [
            Text(
              'Choose class',
              style: TextStyle(
                color: muted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 2),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: colors.onSurface.withValues(alpha: .07),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _classes.isEmpty ? null : _selectedClass,
                  isExpanded: true,
                  hint: const Text('No classes available'),
                  items: [
                    for (var index = 0; index < _classes.length; index++)
                      DropdownMenuItem(
                        value: index,
                        child: Text(
                          _classes[index].label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: _classes.isEmpty
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() => _selectedClass = value);
                          _loadRegisters();
                        },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Students',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${_students.length} students · Section 47',
                  style: TextStyle(color: muted, fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Section 47 · Tap the box beside a student who is present. Unchecked students are marked absent when you submit.',
              style: TextStyle(color: muted, fontSize: 11, height: 1.4),
            ),
            const SizedBox(height: 12),
            if (_addingStudent)
              _studentEntryForm(colors)
            else if (_students.isEmpty)
              _EmptyRoster(onAdd: _addStudent)
            else
              for (var index = 0; index < _students.length; index++)
                _StudentRow(
                  student: _students[index],
                  onPresentChanged: (present) =>
                      setState(() => _students[index].present = present),
                  onRemove: () => setState(() => _students.removeAt(index)),
                ),
            const SizedBox(height: 8),
            if (!_addingStudent)
              OutlinedButton.icon(
                onPressed: _addStudent,
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('Add student'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
        child: SizedBox(
          width: double.infinity,
          height: 49,
          child: FilledButton.icon(
            onPressed: _saving ? null : _saveRegister,
            icon: _saving
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.lock_outline_rounded, size: 18),
            label: Text(_saving ? 'Submitting…' : 'Submit attendance'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xff627FFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _studentEntryForm(ColorScheme colors) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: colors.surface,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: colors.onSurface.withValues(alpha: .08)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add student',
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _newNameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Student name'),
        ),
        TextField(
          controller: _newRollController,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(labelText: 'Roll number / ID'),
        ),
        TextField(
          controller: _newEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Student email (for attendance sync)',
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => setState(() => _addingStudent = false),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _confirmAddStudent,
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 17),
              label: const Text('Add'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildHistory(ColorScheme colors, Color muted) {
    if (_savedRegisters.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.assignment_outlined, color: muted, size: 34),
              const SizedBox(height: 11),
              Text(
                'No saved registers yet',
                style: TextStyle(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Manual attendance you save will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, fontSize: 11),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () => setState(() => _showHistory = false),
                child: const Text('Take attendance'),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      itemCount: _savedRegisters.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final entry = _savedRegisters[index];
        final students = (entry['students'] as List<dynamic>? ?? const []);
        final savedAt = DateTime.tryParse(entry['savedAt'] as String? ?? '');
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.onSurface.withValues(alpha: .06)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xff6B83FF).withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.fact_check_rounded,
                  color: Color(0xff91A6FF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry['class'] as String? ?? 'Class register',
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
                      '${students.length} students  ·  ${entry['present'] ?? 0} present  ·  ${entry['absent'] ?? 0} absent',
                      style: TextStyle(color: muted, fontSize: 9),
                    ),
                  ],
                ),
              ),
              if (savedAt != null)
                Text(
                  '${savedAt.day}/${savedAt.month}',
                  style: TextStyle(color: muted, fontSize: 9),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ClassOption {
  const _ClassOption({
    required this.subject,
    required this.teacher,
    required this.time,
    required this.room,
    required this.type,
    required this.section,
    required this.day,
  });
  final String subject;
  final String teacher;
  final String time;
  final String room;
  final String type;
  final String section;
  final String day;
  String get label =>
      '$subject · $time · $room${section.isEmpty ? '' : ' · Section $section'}';
}

class _ManualStudent {
  _ManualStudent({
    required this.roll,
    required this.name,
    this.email = '',
    this.id = '',
  }) : present = false;
  final String id;
  final String email;
  final String roll;
  final String name;
  bool present;
  Map<String, dynamic> toJson() => {
    'roll': roll,
    'name': name,
    'email': email,
    'id': id,
    'present': present,
  };
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });
  final String label;
  final bool selected;
  final int? count;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 5),
        decoration: BoxDecoration(
          color: selected ? const Color(0xff637FFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: .65),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 5),
              Text(
                '$count',
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: .65),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _EmptyRoster extends StatelessWidget {
  const _EmptyRoster({required this.onAdd});
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: .58);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.people_alt_outlined, color: muted, size: 28),
          const SizedBox(height: 8),
          Text(
            'Start the paper register',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add each student, then mark their attendance.',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 10),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 17),
            label: const Text('Add first student'),
          ),
        ],
      ),
    );
  }
}

class _StudentRow extends StatelessWidget {
  const _StudentRow({
    required this.student,
    required this.onPresentChanged,
    required this.onRemove,
  });
  final _ManualStudent student;
  final ValueChanged<bool> onPresentChanged;
  final VoidCallback onRemove;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(11, 9, 6, 9),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xff7089FF).withValues(alpha: .15),
            child: Text(
              student.name.isEmpty ? '?' : student.name[0].toUpperCase(),
              style: const TextStyle(
                color: Color(0xffA9BAFF),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  student.roll,
                  style: TextStyle(
                    color: colors.onSurface.withValues(alpha: .56),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          Checkbox.adaptive(
            value: student.present,
            activeColor: const Color(0xff42C995),
            onChanged: (value) => onPresentChanged(value ?? false),
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onRemove,
            icon: Icon(
              Icons.close_rounded,
              color: colors.onSurface.withValues(alpha: .45),
              size: 17,
            ),
          ),
        ],
      ),
    );
  }
}
