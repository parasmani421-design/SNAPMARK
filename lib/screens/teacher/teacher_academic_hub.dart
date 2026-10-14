import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import '../timetable/timetable_screen.dart';

class TeacherAcademicHub extends StatefulWidget {
  const TeacherAcademicHub({super.key, this.openMaterials = false});

  final bool openMaterials;

  @override
  State<TeacherAcademicHub> createState() => _TeacherAcademicHubState();
}

class _TeacherAcademicHubState extends State<TeacherAcademicHub> {
  static const _storage = FlutterSecureStorage();
  static const _assignmentKey = 'snapmark_teacher_assignments';
  static const _materialKey = 'snapmark_teacher_materials';
  late final List<String> _courseNames =
      timetableSchedule.values
          .expand((day) => day)
          .map((item) => item['subject'])
          .whereType<String>()
          .toSet()
          .toList()
        ..sort();

  late bool _showMaterials = widget.openMaterials;
  bool _loading = true;
  bool _busy = false;
  List<Map<String, dynamic>> _assignments = [];
  List<Map<String, dynamic>> _materials = [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    try {
      final results = await Future.wait([
        _storage.read(key: _assignmentKey),
        _storage.read(key: _materialKey),
      ]);
      if (!mounted) return;
      setState(() {
        _assignments = _decode(results[0]);
        _materials = _decode(results[1]);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    final value = jsonDecode(raw) as List<dynamic>;
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList()
        .reversed
        .toList();
  }

  Future<void> _createAssignment() async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    var course = _courseNames.first;
    var due = DateTime.now().add(const Duration(days: 7));
    final draft = await showDialog<_AssignmentDraft>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, refreshDialog) => AlertDialog(
          title: const Text('Create assignment'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: course,
                    decoration: const InputDecoration(labelText: 'Course'),
                    items: [
                      for (final name in _courseNames)
                        DropdownMenuItem(
                          value: name,
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) => course = value ?? course,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Assignment title',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Add a title'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descriptionController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Instructions (optional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final selected = await showDatePicker(
                          context: context,
                          initialDate: due,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (selected != null) {
                          refreshDialog(() => due = selected);
                        }
                      },
                      icon: const Icon(Icons.event_outlined, size: 17),
                      label: Text('Due ${due.day}/${due.month}/${due.year}'),
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
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(
                  dialogContext,
                  _AssignmentDraft(
                    course: course,
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    due: due,
                  ),
                );
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
    titleController.dispose();
    descriptionController.dispose();
    if (draft == null || !mounted) return;
    final record = {
      'course': draft.course,
      'title': draft.title,
      'description': draft.description,
      'due': draft.due.toIso8601String(),
      'createdAt': DateTime.now().toIso8601String(),
    };
    await _appendRecord(_assignmentKey, record, assignments: true);
  }

  Future<void> _pickMaterial() async {
    try {
      final selected = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'ppt', 'pptx'],
      );
      if (selected == null || selected.path == null || !mounted) return;
      setState(() => _busy = true);
      final appDirectory = await getApplicationDocumentsDirectory();
      final targetDirectory = Directory(
        '${appDirectory.path}/snapmark_teacher_materials',
      );
      await targetDirectory.create(recursive: true);
      final extension = selected.extension?.toLowerCase() ?? 'file';
      final safeName =
          '${DateTime.now().millisecondsSinceEpoch}_${selected.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')}';
      final storedFile = await File(
        selected.path!,
      ).copy('${targetDirectory.path}/$safeName');
      final record = {
        'name': selected.name,
        'extension': extension,
        'path': storedFile.path,
        'addedAt': DateTime.now().toIso8601String(),
      };
      if (mounted) await _appendRecord(_materialKey, record, materials: true);
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not add that file. Try a PDF or PPT/PPTX.'),
          ),
        );
      }
    }
  }

  Future<void> _appendRecord(
    String key,
    Map<String, dynamic> record, {
    bool assignments = false,
    bool materials = false,
  }) async {
    setState(() => _busy = true);
    try {
      final raw = await _storage.read(key: key);
      final previous = raw == null
          ? <dynamic>[]
          : jsonDecode(raw) as List<dynamic>;
      await _storage.write(key: key, value: jsonEncode([...previous, record]));
      if (!mounted) return;
      setState(() {
        if (assignments) _assignments = [record, ..._assignments];
        if (materials) _materials = [record, ..._materials];
        _busy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            assignments
                ? 'Assignment saved on this device'
                : 'Material added on this device',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save this item. Please try again.'),
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
      appBar: AppBar(title: const Text('Teaching hub')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
                        _HubTab(
                          label: 'Assignments',
                          selected: !_showMaterials,
                          onTap: () => setState(() => _showMaterials = false),
                        ),
                        _HubTab(
                          label: 'PPT & PDF materials',
                          selected: _showMaterials,
                          onTap: () => setState(() => _showMaterials = true),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _showMaterials
                      ? _materials.isEmpty
                            ? _EmptyHub(
                                icon: Icons.picture_as_pdf_outlined,
                                title: 'Share class materials',
                                subtitle:
                                    'Add lecture PDFs or PowerPoint files to your teaching library.',
                                action: _busy ? null : _pickMaterial,
                                actionLabel: 'Add a PDF or PPT',
                              )
                            : _buildMaterials(colors, muted)
                      : _assignments.isEmpty
                      ? _EmptyHub(
                          icon: Icons.assignment_outlined,
                          title: 'No assignments yet',
                          subtitle:
                              'Create an assignment with instructions and a due date.',
                          action: _createAssignment,
                          actionLabel: 'Create assignment',
                        )
                      : _buildAssignments(colors, muted),
                ),
              ],
            ),
      floatingActionButton: _loading
          ? null
          : FloatingActionButton.extended(
              onPressed: _busy
                  ? null
                  : (_showMaterials ? _pickMaterial : _createAssignment),
              icon: Icon(
                _showMaterials
                    ? Icons.upload_file_rounded
                    : Icons.add_task_rounded,
              ),
              label: Text(_showMaterials ? 'Add material' : 'New assignment'),
              backgroundColor: const Color(0xff637FFF),
            ),
    );
  }

  Widget _buildAssignments(ColorScheme colors, Color muted) =>
      ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
        itemCount: _assignments.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = _assignments[index];
          final due = DateTime.tryParse(item['due'] as String? ?? '');
          final overdue = due != null && due.isBefore(DateTime.now());
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.onSurface.withValues(alpha: .06),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xff9A7BFF).withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.assignment_rounded,
                    color: Color(0xffB59AFF),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] as String? ?? 'Assignment',
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
                        item['course'] as String? ?? 'Course',
                        style: TextStyle(color: muted, fontSize: 10),
                      ),
                      if (due != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Due ${due.day}/${due.month}/${due.year}',
                          style: TextStyle(
                            color: overdue
                                ? const Color(0xffF07683)
                                : const Color(0xff9DB4FF),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: muted, size: 19),
              ],
            ),
          );
        },
      );

  Widget _buildMaterials(ColorScheme colors, Color muted) => ListView.separated(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
    itemCount: _materials.length,
    separatorBuilder: (_, _) => const SizedBox(height: 10),
    itemBuilder: (context, index) {
      final item = _materials[index];
      final isPdf = (item['extension'] as String? ?? '').toLowerCase() == 'pdf';
      final addedAt = DateTime.tryParse(item['addedAt'] as String? ?? '');
      return Container(
        padding: const EdgeInsets.all(13),
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
                color:
                    (isPdf ? const Color(0xffF07683) : const Color(0xff6D9BFF))
                        .withValues(alpha: .13),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                isPdf ? Icons.picture_as_pdf_rounded : Icons.slideshow_rounded,
                color: isPdf
                    ? const Color(0xffF07683)
                    : const Color(0xff82A5FF),
                size: 20,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] as String? ?? 'Material',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(item['extension'] as String? ?? 'file').toUpperCase()}${addedAt == null ? '' : '  ·  Added ${addedAt.day}/${addedAt.month}'}',
                    style: TextStyle(color: muted, fontSize: 9),
                  ),
                ],
              ),
            ),
            Icon(Icons.verified_user_outlined, color: muted, size: 16),
          ],
        ),
      );
    },
  );
}

class _AssignmentDraft {
  const _AssignmentDraft({
    required this.course,
    required this.title,
    required this.description,
    required this.due,
  });
  final String course;
  final String title;
  final String description;
  final DateTime due;
}

class _HubTab extends StatelessWidget {
  const _HubTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? const Color(0xff637FFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
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
    ),
  );
}

class _EmptyHub extends StatelessWidget {
  const _EmptyHub({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.actionLabel,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? action;
  final String actionLabel;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: colors.onSurface.withValues(alpha: .45),
              size: 38,
            ),
            const SizedBox(height: 13),
            Text(
              title,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurface.withValues(alpha: .62),
                fontSize: 11,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: action,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
