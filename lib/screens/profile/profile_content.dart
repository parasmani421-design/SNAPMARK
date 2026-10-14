import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/services/student_directory_store.dart';

class ProfileContent extends StatefulWidget {
  const ProfileContent({super.key});

  @override
  State<ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<ProfileContent> {
  static const _storage = FlutterSecureStorage();
  static const _fields = <_ProfileField>[
    _ProfileField(
      'full_name',
      'Full name',
      Icons.person_outline,
      initialValue: 'Paras',
    ),
    _ProfileField(
      'phone',
      'Mobile number',
      Icons.phone_outlined,
      keyboardType: TextInputType.phone,
    ),
    _ProfileField(
      'email',
      'Email address',
      Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
    ),
    _ProfileField(
      'date_of_birth',
      'Date of birth',
      Icons.cake_outlined,
      hint: 'DD/MM/YYYY',
    ),
    _ProfileField('gender', 'Gender', Icons.wc_outlined),
    _ProfileField(
      'admission_number',
      'Admission number',
      Icons.assignment_ind_outlined,
    ),
    _ProfileField(
      'enrollment_number',
      'Enrollment number',
      Icons.numbers_outlined,
    ),
    _ProfileField(
      'roll_number',
      'Roll number',
      Icons.confirmation_number_outlined,
    ),
    _ProfileField(
      'program',
      'Course / program',
      Icons.school_outlined,
      initialValue: 'CSE (AI)',
    ),
    _ProfileField(
      'academic_year',
      'Academic year',
      Icons.calendar_month_outlined,
    ),
    _ProfileField('semester', 'Current semester', Icons.book_outlined),
    _ProfileField('abc_id', 'ABC ID', Icons.account_balance_outlined),
    _ProfileField(
      'address',
      'House / street address',
      Icons.home_outlined,
      maxLines: 2,
    ),
    _ProfileField('city', 'City', Icons.location_city_outlined),
    _ProfileField('state', 'State', Icons.map_outlined),
    _ProfileField(
      'pin_code',
      'PIN code',
      Icons.local_post_office_outlined,
      keyboardType: TextInputType.number,
    ),
    _ProfileField('father_name', 'Father’s name', Icons.person_outline),
    _ProfileField(
      'father_phone',
      'Father’s phone',
      Icons.phone_outlined,
      keyboardType: TextInputType.phone,
    ),
    _ProfileField('mother_name', 'Mother’s name', Icons.person_outline),
    _ProfileField(
      'mother_phone',
      'Mother’s phone',
      Icons.phone_outlined,
      keyboardType: TextInputType.phone,
    ),
    _ProfileField(
      'guardian_name',
      'Guardian name (optional)',
      Icons.supervisor_account_outlined,
    ),
    _ProfileField(
      'guardian_phone',
      'Guardian phone (optional)',
      Icons.phone_outlined,
      keyboardType: TextInputType.phone,
    ),
  ];

  static const _documents = <_ProfileDocument>[
    _ProfileDocument('government_id', 'Government ID'),
    _ProfileDocument('tenth_marksheet', 'Class 10 marksheet'),
    _ProfileDocument('twelfth_marksheet', 'Class 12 marksheet'),
    _ProfileDocument('admission_proof', 'Admission proof'),
    _ProfileDocument('abc_id_document', 'ABC ID document'),
  ];

  final Map<String, TextEditingController> _controllers = {
    for (final field in _fields)
      field.keyName: TextEditingController(text: field.initialValue),
  };
  final Map<String, String> _documentNames = {};
  bool _loading = true;
  bool _saving = false;
  String _displayName = 'Paras';

  @override
  void initState() {
    super.initState();
    _loadSavedProfile();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSavedProfile() async {
    try {
      for (final field in _fields) {
        final value = await _storage.read(
          key: 'snapmark.profile.${field.keyName}',
        );
        if (value != null && value.isNotEmpty) {
          _controllers[field.keyName]!.text = value;
        }
      }
      final activeEmail = await StudentDirectoryStore.activeEmail();
      if (activeEmail != null) {
        final student = await StudentDirectoryStore.findByEmail(activeEmail);
        if (student != null) {
          for (final field in _fields) {
            final value = student.value(field.keyName);
            if (value.isNotEmpty) _controllers[field.keyName]!.text = value;
          }
        }
      }
      for (final document in _documents) {
        final value = await _storage.read(
          key: 'snapmark.document.${document.keyName}',
        );
        if (value == null) continue;
        final saved = jsonDecode(value) as Map<String, dynamic>;
        final path = saved['path'] as String?;
        final name = saved['name'] as String?;
        if (path != null && name != null && await File(path).exists()) {
          _documentNames[document.keyName] = name;
        }
      }
    } catch (_) {
      if (mounted) _showMessage('Could not load saved profile information.');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _displayName = _controllers['full_name']!.text.trim().isEmpty
              ? 'Student'
              : _controllers['full_name']!.text.trim();
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      for (final field in _fields) {
        final value = _controllers[field.keyName]!.text.trim();
        final key = 'snapmark.profile.${field.keyName}';
        if (value.isEmpty) {
          await _storage.delete(key: key);
        } else {
          await _storage.write(key: key, value: value);
        }
      }
      final profileValues = <String, String>{
        for (final field in _fields)
          field.keyName: _controllers[field.keyName]!.text.trim(),
      };
      await StudentDirectoryStore.syncActiveProfile(profileValues);
      if (!mounted) return;
      setState(() {
        _displayName = _controllers['full_name']!.text.trim().isEmpty
            ? 'Student'
            : _controllers['full_name']!.text.trim();
      });
      _showMessage(
        'Profile saved securely and updated in the local admin directory.',
      );
    } catch (_) {
      _showMessage('Could not save profile. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDocument(_ProfileDocument document) async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (files.isEmpty) return;

      final pickedFile = files.single;
      final sourcePath = pickedFile.path;
      if (sourcePath == null) {
        _showMessage(
          'This file could not be opened. Choose a file stored on your phone.',
        );
        return;
      }
      if ((await pickedFile.length() ?? 0) > 15 * 1024 * 1024) {
        _showMessage('Choose a document smaller than 15 MB.');
        return;
      }

      final appDirectory = await getApplicationDocumentsDirectory();
      final documentDirectory = Directory(
        '${appDirectory.path}${Platform.pathSeparator}snapmark_documents',
      );
      await documentDirectory.create(recursive: true);
      final safeName = pickedFile.name.replaceAll(
        RegExp(r'[^A-Za-z0-9._-]'),
        '_',
      );
      final fileName =
          '${document.keyName}_${DateTime.now().millisecondsSinceEpoch}_$safeName';
      final destinationPath =
          '${documentDirectory.path}${Platform.pathSeparator}$fileName';
      await File(sourcePath).copy(destinationPath);

      final storageKey = 'snapmark.document.${document.keyName}';
      final previous = await _storage.read(key: storageKey);
      if (previous != null) {
        final previousPath =
            (jsonDecode(previous) as Map<String, dynamic>)['path'] as String?;
        if (previousPath != null && await File(previousPath).exists()) {
          await File(previousPath).delete();
        }
      }
      await _storage.write(
        key: storageKey,
        value: jsonEncode({'path': destinationPath, 'name': pickedFile.name}),
      );
      if (!mounted) return;
      setState(() => _documentNames[document.keyName] = pickedFile.name);
      _showMessage(
        'Document saved on this device. It has not been submitted to your college.',
      );
    } catch (_) {
      _showMessage('Could not save the selected document. Please try again.');
    }
  }

  Future<void> _removeDocument(_ProfileDocument document) async {
    try {
      final key = 'snapmark.document.${document.keyName}';
      final value = await _storage.read(key: key);
      if (value != null) {
        final path =
            (jsonDecode(value) as Map<String, dynamic>)['path'] as String?;
        if (path != null && await File(path).exists()) {
          await File(path).delete();
        }
      }
      await _storage.delete(key: key);
      if (mounted) setState(() => _documentNames.remove(document.keyName));
    } catch (_) {
      _showMessage('Could not remove this document.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (_loading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 38,
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.person, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 12),
              Text(
                _displayName,
                style: TextStyle(
                  color: colors.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _controllers['program']!.text.trim().isEmpty
                    ? 'Student'
                    : 'Student · ${_controllers['program']!.text.trim()}',
                style: TextStyle(
                  color: colors.onSurface.withValues(alpha: .65),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _noticeCard(
          context,
          icon: Icons.lock_outline,
          text:
              'Profile information is saved securely on this device. College account sync is not connected.',
        ),
        const SizedBox(height: 18),
        _section(context, 'Personal information', Icons.person_outline, [
          'full_name',
          'phone',
          'email',
          'date_of_birth',
          'gender',
        ]),
        _section(context, 'Enrollment & admission', Icons.school_outlined, [
          'admission_number',
          'enrollment_number',
          'roll_number',
          'program',
          'academic_year',
          'semester',
          'abc_id',
        ]),
        _section(context, 'Address', Icons.home_outlined, [
          'address',
          'city',
          'state',
          'pin_code',
        ]),
        _section(context, 'Parents & guardian', Icons.family_restroom, [
          'father_name',
          'father_phone',
          'mother_name',
          'mother_phone',
          'guardian_name',
          'guardian_phone',
        ]),
        _documentsSection(context),
        const SizedBox(height: 14),
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: _saving ? null : _saveProfile,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Saving…' : 'Save profile'),
          ),
        ),
      ],
    );
  }

  Widget _section(
    BuildContext context,
    String title,
    IconData icon,
    List<String> fieldKeys,
  ) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 9),
              Text(
                title,
                style: TextStyle(
                  color: colors.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final key in fieldKeys) _field(context, _fieldByKey(key)),
        ],
      ),
    );
  }

  Widget _field(BuildContext context, _ProfileField field) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: _controllers[field.keyName],
        keyboardType: field.keyboardType,
        maxLines: field.maxLines,
        style: TextStyle(color: colors.onSurface, fontSize: 14),
        decoration: InputDecoration(
          labelText: field.label,
          hintText: field.hint,
          prefixIcon: Icon(field.icon, size: 19),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: .04)
              : const Color(0xffF5F7FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 13,
          ),
        ),
      ),
    );
  }

  Widget _documentsSection(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.folder_outlined,
                color: Colors.blueAccent,
                size: 20,
              ),
              const SizedBox(width: 9),
              Text(
                'Documents',
                style: TextStyle(
                  color: colors.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'PDF, JPG or PNG · up to 15 MB each · stored privately on this device',
            style: TextStyle(
              color: colors.onSurface.withValues(alpha: .58),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          for (final document in _documents)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                _documentNames.containsKey(document.keyName)
                    ? Icons.task_outlined
                    : Icons.upload_file_outlined,
                color: _documentNames.containsKey(document.keyName)
                    ? Colors.green
                    : Colors.blueAccent,
              ),
              title: Text(
                document.label,
                style: TextStyle(color: colors.onSurface, fontSize: 13),
              ),
              subtitle: Text(
                _documentNames[document.keyName] ?? 'Not added',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.onSurface.withValues(alpha: .58),
                  fontSize: 11,
                ),
              ),
              trailing: _documentNames.containsKey(document.keyName)
                  ? IconButton(
                      tooltip: 'Remove document',
                      onPressed: () => _removeDocument(document),
                      icon: const Icon(Icons.delete_outline),
                    )
                  : IconButton(
                      tooltip: 'Choose document',
                      onPressed: () => _pickDocument(document),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
              onTap: () => _pickDocument(document),
            ),
        ],
      ),
    );
  }

  Widget _noticeCard(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.primary, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: colors.onSurface.withValues(alpha: .72),
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _ProfileField _fieldByKey(String key) =>
      _fields.firstWhere((field) => field.keyName == key);
}

class _ProfileField {
  const _ProfileField(
    this.keyName,
    this.label,
    this.icon, {
    this.keyboardType = TextInputType.text,
    this.initialValue = '',
    this.hint,
    this.maxLines = 1,
  });

  final String keyName;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final String initialValue;
  final String? hint;
  final int maxLines;
}

class _ProfileDocument {
  const _ProfileDocument(this.keyName, this.label);

  final String keyName;
  final String label;
}
