import 'package:flutter/material.dart';

import '../../core/services/campus_configuration_store.dart';
import '../../core/services/student_directory_store.dart';
import '../../core/services/teacher_feedback_store.dart';
import '../timetable/timetable_screen.dart';

class TeacherFeedbackScreen extends StatefulWidget {
  const TeacherFeedbackScreen({super.key});

  @override
  State<TeacherFeedbackScreen> createState() => _TeacherFeedbackScreenState();
}

class _TeacherFeedbackScreenState extends State<TeacherFeedbackScreen> {
  static const _strengthOptions = [
    'Explains clearly',
    'Answers doubts',
    'On time',
    'Uses examples',
    'Engages the class',
    'Fair and respectful',
    'Useful practicals',
  ];
  static const _improvementOptions = [
    'More real examples',
    'Slower pace',
    'More doubt time',
    'Share notes earlier',
    'More practical work',
    'Clearer assessment criteria',
  ];

  final _commentController = TextEditingController();
  List<_FacultyChoice> _faculty = [];
  String? _studentEmail;
  String? _studentSection;
  String? _selectedFacultyId;
  int _rating = 0;
  final Set<String> _strengths = {};
  final Set<String> _improvements = {};
  bool _loading = true;
  bool _saving = false;
  bool _hasExistingFeedback = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final email = await StudentDirectoryStore.activeEmail();
    final profile = email == null
        ? null
        : await StudentDirectoryStore.findByEmail(email);
    final facultyRecords = await StudentDirectoryStore.loadAllFaculty();
    final choicesByName = <String, _FacultyChoice>{};
    for (final record in facultyRecords) {
      final email = record.value('email').trim();
      final name = record.value('full_name').trim();
      if (email.isEmpty || name.isEmpty) continue;
      choicesByName[_normalizeName(name)] = _FacultyChoice(
        id: email.toLowerCase(),
        name: name,
        facultyKey: email.toLowerCase(),
        detail: record.value('department'),
      );
    }
    final scheduleTeachers = <String, _FacultyChoice>{};
    for (final lessons in timetableSchedule.values) {
      for (final lesson in lessons) {
        final name = lesson['teacher']?.trim() ?? '';
        if (name.isEmpty) continue;
        final normalized = _normalizeName(name);
        final current = scheduleTeachers[normalized];
        final subjects = <String>{
          if (current?.detail.isNotEmpty == true)
            ...current!.detail.split(' · '),
          if (lesson['subject']?.trim().isNotEmpty == true)
            lesson['subject']!.trim(),
        };
        scheduleTeachers[normalized] = _FacultyChoice(
          id: 'timetable:$normalized',
          name: name,
          facultyKey: 'name:$normalized',
          detail: subjects.join(' · '),
        );
        final substituteName = lesson['substituteTeacher']?.trim() ?? '';
        if (substituteName.isNotEmpty) {
          final substituteNormalized = _normalizeName(substituteName);
          final currentSubstitute = scheduleTeachers[substituteNormalized];
          final substituteSubjects = <String>{
            if (currentSubstitute?.detail.isNotEmpty == true)
              ...currentSubstitute!.detail.split(' · '),
            if (lesson['subject']?.trim().isNotEmpty == true)
              lesson['subject']!.trim(),
          };
          scheduleTeachers[substituteNormalized] = _FacultyChoice(
            id: 'timetable:$substituteNormalized',
            name: substituteName,
            facultyKey: 'name:$substituteNormalized',
            detail: substituteSubjects.join(' · '),
          );
        }
      }
    }
    for (final entry in scheduleTeachers.entries) {
      final existing = choicesByName[entry.key];
      if (existing == null) {
        choicesByName[entry.key] = entry.value;
      } else {
        choicesByName[entry.key] = _FacultyChoice(
          id: existing.id,
          name: existing.name,
          facultyKey: existing.facultyKey,
          detail: entry.value.detail,
        );
      }
    }
    final faculty = choicesByName.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    if (!mounted) return;
    setState(() {
      _studentEmail = email;
      _studentSection = _knownSection(profile?.value('section') ?? '');
      _faculty = faculty;
      _loading = false;
    });
  }

  String? _knownSection(String value) {
    for (final section in CampusConfigurationStore.sections) {
      if (value.trim() == section ||
          RegExp(
            '(?<![A-Za-z0-9])${RegExp.escape(section)}(?![A-Za-z0-9])',
            caseSensitive: false,
          ).hasMatch(value)) {
        return section;
      }
    }
    return null;
  }

  String _normalizeName(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll('gaurav agarwal', 'gaurav agrawal')
      .trim();

  Future<void> _selectFaculty(String? id) async {
    if (id == null) return;
    setState(() {
      _selectedFacultyId = id;
      _rating = 0;
      _strengths.clear();
      _improvements.clear();
      _commentController.clear();
      _hasExistingFeedback = false;
    });
    final studentEmail = _studentEmail;
    if (studentEmail == null) return;
    final existing = await TeacherFeedbackStore.fromStudentForFaculty(
      studentEmail: studentEmail,
      facultyEmail: _faculty.firstWhere((item) => item.id == id).facultyKey,
    );
    if (!mounted || _selectedFacultyId != id || existing == null) return;
    setState(() {
      _rating = existing.rating;
      _strengths.addAll(existing.strengths);
      _improvements.addAll(existing.improvements);
      _commentController.text = existing.comment;
      _hasExistingFeedback = true;
    });
  }

  Future<void> _submit() async {
    final studentEmail = _studentEmail;
    final section = _studentSection;
    final facultyId = _selectedFacultyId;
    if (studentEmail == null || facultyId == null || _rating == 0) return;
    if (section == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select your section to continue.')),
      );
      return;
    }
    final faculty = _faculty.firstWhere((item) => item.id == facultyId);
    setState(() => _saving = true);
    try {
      final feedback = TeacherFeedback(
        id: '${studentEmail.toLowerCase()}::${faculty.facultyKey}',
        studentEmail: studentEmail.toLowerCase(),
        facultyEmail: faculty.facultyKey,
        facultyName: faculty.name,
        section: section,
        rating: _rating,
        strengths: _strengths.toList(),
        improvements: _improvements.toList(),
        comment: _commentController.text.trim(),
        submittedAt: DateTime.now().toIso8601String(),
      );
      await TeacherFeedbackStore.save(feedback);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _hasExistingFeedback = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your feedback has been saved.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save feedback. Please retry.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Teacher feedback')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xff155EEF), Color(0xff4527A0)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.rate_review_rounded,
                        color: Colors.white,
                        size: 27,
                      ),
                      SizedBox(height: 11),
                      Text(
                        'Help improve your classes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Share specific, respectful feedback about a faculty member.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                if (_studentEmail == null)
                  _messageCard(
                    context,
                    'Sign in as a student to submit feedback.',
                  )
                else if (_faculty.isEmpty)
                  _messageCard(
                    context,
                    'No faculty names are available yet. Add teachers to the faculty directory or timetable first.',
                  )
                else ...[
                  _sectionLabel(context, 'Choose faculty'),
                  const SizedBox(height: 7),
                  DropdownButtonFormField<String>(
                    key: ValueKey(_selectedFacultyId),
                    initialValue: _selectedFacultyId,
                    isExpanded: true,
                    itemHeight: 64,
                    decoration: _inputDecoration(context, 'Faculty member'),
                    items: [
                      for (final faculty in _faculty)
                        DropdownMenuItem(
                          value: faculty.id,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                faculty.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (faculty.detail.isNotEmpty)
                                Text(
                                  faculty.detail,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: colors.onSurface.withValues(
                                      alpha: .55,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                    onChanged: _selectFaculty,
                  ),
                  const SizedBox(height: 15),
                  _sectionLabel(context, 'Your section'),
                  const SizedBox(height: 7),
                  if (_studentSection != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: _fieldDecoration(context),
                      child: Text(
                        'Section $_studentSection',
                        style: TextStyle(color: colors.onSurface),
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      initialValue: _studentSection,
                      decoration: _inputDecoration(context, 'Select section'),
                      items: [
                        for (final section in CampusConfigurationStore.sections)
                          DropdownMenuItem(
                            value: section,
                            child: Text('Section $section'),
                          ),
                      ],
                      onChanged: (section) =>
                          setState(() => _studentSection = section),
                    ),
                  const SizedBox(height: 17),
                  _sectionLabel(context, 'Overall rating'),
                  const SizedBox(height: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: _fieldDecoration(context),
                    child: Row(
                      children: [
                        for (var star = 1; star <= 5; star++)
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () => setState(() => _rating = star),
                            icon: Icon(
                              star <= _rating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: const Color(0xffFFB454),
                              size: 31,
                            ),
                          ),
                        const SizedBox(width: 5),
                        Text(
                          _rating == 0 ? 'Tap to rate' : '$_rating / 5',
                          style: TextStyle(
                            color: colors.onSurface.withValues(alpha: .65),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 17),
                  _sectionLabel(context, 'What is working well?'),
                  const SizedBox(height: 7),
                  _choiceChips(
                    options: _strengthOptions,
                    selected: _strengths,
                    selectedColor: const Color(0xff35C995),
                  ),
                  const SizedBox(height: 15),
                  _sectionLabel(context, 'What could improve?'),
                  const SizedBox(height: 7),
                  _choiceChips(
                    options: _improvementOptions,
                    selected: _improvements,
                    selectedColor: const Color(0xffFFB454),
                  ),
                  const SizedBox(height: 15),
                  _sectionLabel(context, 'Write your feedback'),
                  const SizedBox(height: 7),
                  TextField(
                    controller: _commentController,
                    maxLines: 4,
                    maxLength: 600,
                    decoration: _inputDecoration(
                      context,
                      'Describe what happened or what would help...',
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest.withValues(
                        alpha: .42,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Your name and email are hidden from the teacher. Teachers see section-level ratings and feedback comments. Please keep comments respectful and avoid personal or sensitive details.',
                      style: TextStyle(
                        color: colors.onSurface.withValues(alpha: .68),
                        fontSize: 10,
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed:
                        _rating == 0 ||
                            _selectedFacultyId == null ||
                            _studentSection == null ||
                            _saving
                        ? null
                        : _submit,
                    icon: _saving
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(
                      _saving
                          ? 'Saving...'
                          : _hasExistingFeedback
                          ? 'Update feedback'
                          : 'Submit feedback',
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'You can update your feedback later. One response per student and faculty member is kept.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.onSurface.withValues(alpha: .48),
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Demo mode: feedback is stored on this app installation until a campus backend is connected.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.onSurface.withValues(alpha: .42),
                      fontSize: 9,
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) => Text(
    text,
    style: TextStyle(
      color: Theme.of(context).colorScheme.onSurface,
      fontSize: 13,
      fontWeight: FontWeight.w700,
    ),
  );

  Widget _messageCard(BuildContext context, String text) => Container(
    padding: const EdgeInsets.all(17),
    decoration: _fieldDecoration(context),
    child: Text(text, style: const TextStyle(fontSize: 12, height: 1.4)),
  );

  Widget _choiceChips({
    required List<String> options,
    required Set<String> selected,
    required Color selectedColor,
  }) => Wrap(
    spacing: 7,
    runSpacing: 2,
    children: [
      for (final option in options)
        FilterChip(
          label: Text(option),
          selected: selected.contains(option),
          selectedColor: selectedColor.withValues(alpha: .2),
          showCheckmark: true,
          onSelected: (value) => setState(() {
            if (value) {
              selected.add(option);
            } else {
              selected.remove(option);
            }
          }),
        ),
    ],
  );

  InputDecoration _inputDecoration(BuildContext context, String label) =>
      InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: .12),
          ),
        ),
      );

  BoxDecoration _fieldDecoration(BuildContext context) => BoxDecoration(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .10),
    ),
  );
}

class _FacultyChoice {
  const _FacultyChoice({
    required this.id,
    required this.name,
    required this.facultyKey,
    required this.detail,
  });

  final String id;
  final String name;
  final String facultyKey;
  final String detail;
}
