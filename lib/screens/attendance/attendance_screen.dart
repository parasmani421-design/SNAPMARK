import 'package:flutter/material.dart';

import '../../core/services/attendance_demo_data.dart';
import '../../core/services/attendance_record_store.dart';
import '../../core/services/student_directory_store.dart';

enum _AttendanceView { dayWise, overall, subjectWise }

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  _AttendanceView _selectedView = _AttendanceView.overall;
  List<AttendanceEntry> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    final email = await StudentDirectoryStore.activeEmail();
    final records = email == null
        ? <AttendanceEntry>[]
        : await AttendanceRecordStore.forStudent(email);
    if (!mounted) return;
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  List<_SubjectAttendance> get _subjects {
    if (_showingDemo) {
      return AttendanceDemoData.subjects
          .map(
            (subject) => _SubjectAttendance(
              subject.name,
              subject.present,
              subject.total,
            ),
          )
          .toList();
    }
    final grouped = <String, List<AttendanceEntry>>{};
    for (final record in _records) {
      grouped.putIfAbsent(record.subject, () => []).add(record);
    }
    return grouped.entries
        .map(
          (entry) => _SubjectAttendance(
            entry.key,
            entry.value.where((record) => record.present).length,
            entry.value.length,
          ),
        )
        .toList();
  }

  int get _attendedClasses =>
      _subjects.fold(0, (total, subject) => total + subject.present);
  int get _deliveredClasses =>
      _subjects.fold(0, (total, subject) => total + subject.total);
  double get _overallRate =>
      _deliveredClasses == 0 ? 0 : _attendedClasses / _deliveredClasses;
  List<_AttendanceRecord> get _recentClasses => _records
      .map(
        (record) =>
            _AttendanceRecord(record.subject, record.date, record.present),
      )
      .toList();

  bool get _showingDemo => !AttendanceDemoData.hasCompleteSubjectCoverage(
    _records.map((record) => record.subject),
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Attendance',
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: colors.onSurface),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                _sessionCard(),
                const SizedBox(height: 18),
                _viewSelector(),
                const SizedBox(height: 22),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _buildSelectedView(),
                ),
                const SizedBox(height: 14),
                Text(
                  _showingDemo
                      ? 'Sample attendance for CSE (AI) · complete teacher data will replace demo figures'
                      : 'Attendance synced from teacher-submitted registers',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onSurface.withValues(alpha: .45),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _sessionCard() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.onSurface.withValues(alpha: .08)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Color(0xff172554),
            child: Icon(Icons.school_outlined, color: Colors.blueAccent),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Academic Year',
                  style: TextStyle(
                    color: colors.onSurface.withValues(alpha: .62),
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '2026–2027  ·  CSE (AI)',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _viewSelector() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _viewButton('Day Wise', _AttendanceView.dayWise),
          _viewButton('Overall', _AttendanceView.overall),
          _viewButton('Subject Wise', _AttendanceView.subjectWise),
        ],
      ),
    );
  }

  Widget _viewButton(String label, _AttendanceView view) {
    final colors = Theme.of(context).colorScheme;
    final selected = _selectedView == view;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedView = view),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? Colors.blueAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : colors.onSurface.withValues(alpha: .68),
              fontSize: 12,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedView() {
    switch (_selectedView) {
      case _AttendanceView.dayWise:
        return _dayWiseView(key: const ValueKey('day-wise'));
      case _AttendanceView.overall:
        return _overallView(key: const ValueKey('overall'));
      case _AttendanceView.subjectWise:
        return _subjectWiseView(key: const ValueKey('subject-wise'));
    }
  }

  Widget _overallView({required Key key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xff155EEF), Color(0xff4527A0)],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overall Attendance',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(_overallRate * 100).round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 46,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      _overallRate >= .70 ? 'On track' : 'At risk',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _overallRate,
                  minHeight: 8,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SummaryStat(value: '$_attendedClasses', label: 'Present'),
                  _SummaryStat(
                    value: '${_deliveredClasses - _attendedClasses}',
                    label: 'Absent',
                  ),
                  _SummaryStat(value: '$_deliveredClasses', label: 'Total'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (_showingDemo)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '${_subjects.length} CSE (AI) subjects included in this sample',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: .60),
                fontSize: 12,
              ),
            ),
          ),
        if (_deliveredClasses == 0)
          _emptyAttendanceCard()
        else if (_overallRate < .70)
          _debarmentWarningCard()
        else
          _statusCard(),
      ],
    );
  }

  Widget _subjectWiseView({required Key key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subject Wise Attendance',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        if (_subjects.isEmpty)
          _emptyAttendanceCard()
        else
          for (final subject in _subjects) _subjectCard(subject),
      ],
    );
  }

  Widget _dayWiseView({required Key key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Attendance',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        if (_records.isEmpty)
          for (final subject in AttendanceDemoData.subjects.take(6))
            _historyCard(
              _AttendanceRecord(
                subject.name,
                'Sample recent class',
                subject.present >= subject.total - 1,
              ),
            )
        else if (_recentClasses.isEmpty)
          _emptyAttendanceCard()
        else
          for (final record in _recentClasses) _historyCard(record),
      ],
    );
  }

  Widget _statusCard() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.greenAccent.withOpacity(.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Color(0xff123524),
            child: Icon(Icons.check, color: Colors.greenAccent),
          ),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attendance Status',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Above the required 75% threshold.',
                  style: TextStyle(
                    color: colors.onSurface.withValues(alpha: .62),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _debarmentWarningCard() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.redAccent.withValues(alpha: .45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.redAccent,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Debarment risk',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Overall attendance is below 70%. You may be debarred from exams under college rules. Attend upcoming classes and contact your faculty.',
                  style: TextStyle(
                    color: colors.onSurface.withValues(alpha: .78),
                    fontSize: 12,
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

  Widget _subjectCard(_SubjectAttendance subject) {
    final colors = Theme.of(context).colorScheme;
    final percentage = subject.total == 0
        ? 0.0
        : subject.present / subject.total;
    final color = percentage >= .75 ? Colors.green : Colors.redAccent;
    final classesNeeded = (3 * subject.total - 4 * subject.present).clamp(
      0,
      1 << 31,
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book, color: Colors.blueAccent),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  subject.name,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${(percentage * 100).toStringAsFixed(0)}%',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 7,
              backgroundColor: colors.onSurface.withValues(alpha: .12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 9),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${subject.present} attended / ${subject.total} classes · ${(percentage * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                color: colors.onSurface.withValues(alpha: .62),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: (classesNeeded > 0 ? Colors.orange : Colors.green)
                  .withValues(alpha: .10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  classesNeeded > 0
                      ? Icons.tips_and_updates_outlined
                      : Icons.check_circle_outline,
                  size: 18,
                  color: classesNeeded > 0
                      ? Colors.orange.shade800
                      : Colors.green.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    classesNeeded > 0
                        ? 'Suggestion: Attend the next $classesNeeded classes to reach 75% in this subject.'
                        : '75% target met. Keep attending to maintain your attendance.',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyCard(_AttendanceRecord record) {
    final colors = Theme.of(context).colorScheme;
    final color = record.present ? Colors.greenAccent : Colors.redAccent;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: record.present
              ? const Color(0xff123524)
              : const Color(0xff3b1515),
          child: Icon(record.present ? Icons.check : Icons.close, color: color),
        ),
        title: Text(
          record.subject,
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          record.date,
          style: TextStyle(color: colors.onSurface.withValues(alpha: .62)),
        ),
        trailing: Text(
          record.present ? 'Present' : 'Absent',
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _emptyAttendanceCard() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Your teacher-submitted attendance will appear here.',
        style: TextStyle(
          color: colors.onSurface.withValues(alpha: .65),
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SubjectAttendance {
  final String name;
  final int present;
  final int total;

  const _SubjectAttendance(this.name, this.present, this.total);
}

class _AttendanceRecord {
  final String subject;
  final String date;
  final bool present;

  const _AttendanceRecord(this.subject, this.date, this.present);
}

class _SummaryStat extends StatelessWidget {
  final String value;
  final String label;

  const _SummaryStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
