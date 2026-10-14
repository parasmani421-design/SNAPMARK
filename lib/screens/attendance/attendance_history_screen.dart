import 'package:flutter/material.dart';

import '../../core/services/attendance_record_store.dart';
import '../../core/services/student_directory_store.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({this.embedded = false, super.key});
  final bool embedded;

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  List<AttendanceEntry> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final present = _records.where((record) => record.present).length;
    final total = _records.length;
    final rate = total == 0 ? 0.0 : present / total;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: widget.embedded
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                'Attendance History',
                style: TextStyle(
                  color: colors.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
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
                      const Text(
                        'Overall Attendance',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(rate * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: rate,
                          minHeight: 9,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _summary('Present', present),
                          _summary('Absent', total - present),
                          _summary('Total', total),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                Text(
                  'Recent Attendance',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                if (_records.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      'Teacher-submitted attendance will appear here.',
                      style: TextStyle(
                        color: colors.onSurface.withValues(alpha: .65),
                        fontSize: 12,
                      ),
                    ),
                  )
                else
                  for (final record in _records)
                    _attendanceCard(context, record),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.blueAccent.withValues(alpha: .20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blueAccent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'These records sync from teacher-submitted manual registers on this device.',
                          style: TextStyle(
                            color: colors.onSurface.withValues(alpha: .68),
                            fontSize: 12,
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

  Widget _summary(String label, int value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '$value',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 21,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 3),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    ],
  );

  Widget _attendanceCard(BuildContext context, AttendanceEntry record) {
    final colors = Theme.of(context).colorScheme;
    final present = record.present;
    final date = DateTime.tryParse(record.date);
    final dateLabel = date == null
        ? record.date
        : '${date.day} ${_month(date.month)} ${date.year}';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: (present ? Colors.green : Colors.red).withValues(
              alpha: .12,
            ),
            child: Icon(
              present ? Icons.check_circle : Icons.cancel,
              color: present ? Colors.greenAccent : Colors.redAccent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.subject,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  dateLabel,
                  style: TextStyle(
                    color: colors.onSurface.withValues(alpha: .62),
                    fontSize: 11,
                  ),
                ),
                if (record.roll.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Roll ${record.roll}',
                    style: TextStyle(
                      color: colors.onSurface.withValues(alpha: .48),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            present ? 'Present' : 'Absent',
            style: TextStyle(
              color: present ? Colors.greenAccent : Colors.redAccent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _month(int month) => const [
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
  ][month - 1];
}
