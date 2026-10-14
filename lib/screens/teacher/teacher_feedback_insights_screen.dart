import 'package:flutter/material.dart';

import '../../core/services/student_directory_store.dart';
import '../../core/services/teacher_feedback_store.dart';

class TeacherFeedbackInsightsScreen extends StatefulWidget {
  const TeacherFeedbackInsightsScreen({super.key});

  @override
  State<TeacherFeedbackInsightsScreen> createState() =>
      _TeacherFeedbackInsightsScreenState();
}

class _TeacherFeedbackInsightsScreenState
    extends State<TeacherFeedbackInsightsScreen> {
  static const _sections = ['47', '48', '49'];
  List<TeacherFeedback> _feedback = [];
  bool _loading = true;
  String _teacherName = 'Teacher';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final email = await StudentDirectoryStore.activeFacultyEmail();
    final profile = email == null
        ? null
        : await StudentDirectoryStore.findFacultyByEmail(email);
    final feedback = email == null
        ? <TeacherFeedback>[]
        : await TeacherFeedbackStore.forFaculty(
            email,
            facultyName: profile?.value('full_name') ?? '',
          );
    if (!mounted) return;
    setState(() {
      _teacherName = profile?.value('full_name').isNotEmpty == true
          ? profile!.value('full_name')
          : 'Teacher';
      _feedback = feedback;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final sections = <String>{
      ..._sections,
      ..._feedback.map((feedback) => feedback.section),
    }.toList()..sort();
    final average = _feedback.isEmpty
        ? 0.0
        : _feedback.fold<int>(0, (sum, item) => sum + item.rating) /
              _feedback.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Class feedback'),
        actions: [
          IconButton(
            tooltip: 'Refresh feedback',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
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
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.white24,
                          child: Icon(
                            Icons.insights_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Feedback for $_teacherName',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_feedback.length} student responses · ${_feedback.isEmpty ? '—' : average.toStringAsFixed(1)} / 5 average',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Section-wise ratings',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final section in sections) _sectionCard(section),
                  const SizedBox(height: 12),
                  _tagSummaryCard(
                    title: 'What students value',
                    icon: Icons.thumb_up_alt_outlined,
                    tags: _countTags((item) => item.strengths),
                    color: const Color(0xff35C995),
                    emptyMessage: 'No positive checklist feedback yet.',
                  ),
                  const SizedBox(height: 10),
                  _tagSummaryCard(
                    title: 'Where to improve',
                    icon: Icons.lightbulb_outline_rounded,
                    tags: _countTags((item) => item.improvements),
                    color: const Color(0xffFFB454),
                    emptyMessage: 'No improvement areas selected yet.',
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Written comments',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 9),
                  ..._feedback
                      .where((item) => item.comment.trim().isNotEmpty)
                      .take(20)
                      .map(_commentCard),
                  if (_feedback.every((item) => item.comment.trim().isEmpty))
                    _emptyCard('Student comments will appear here.'),
                  const SizedBox(height: 12),
                  Text(
                    'Feedback is shown without student names or email addresses. Use section patterns and comments as constructive guidance; small response counts may not represent the whole class.',
                    style: TextStyle(
                      color: colors.onSurface.withValues(alpha: .5),
                      fontSize: 10,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Demo mode: feedback is stored on this app installation until a campus backend is connected.',
                    style: TextStyle(
                      color: colors.onSurface.withValues(alpha: .42),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionCard(String section) {
    final colors = Theme.of(context).colorScheme;
    final items = _feedback.where((item) => item.section == section).toList();
    final average = items.isEmpty
        ? 0.0
        : items.fold<int>(0, (sum, item) => sum + item.rating) / items.length;
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: colors.onSurface.withValues(alpha: .07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Section $section',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              if (items.isEmpty)
                Text(
                  'No ratings yet',
                  style: TextStyle(
                    color: colors.onSurface.withValues(alpha: .5),
                    fontSize: 10,
                  ),
                )
              else ...[
                const Icon(
                  Icons.star_rounded,
                  size: 18,
                  color: Color(0xffFFB454),
                ),
                const SizedBox(width: 3),
                Text(
                  average.toStringAsFixed(1),
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${items.length})',
                  style: TextStyle(
                    color: colors.onSurface.withValues(alpha: .5),
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 11),
            for (var stars = 5; stars >= 1; stars--)
              _ratingBar(
                stars,
                items.where((item) => item.rating == stars).length,
                items.length,
              ),
          ],
        ],
      ),
    );
  }

  Widget _ratingBar(int stars, int count, int total) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$stars★',
              style: TextStyle(
                color: colors.onSurface.withValues(alpha: .65),
                fontSize: 9,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : count / total,
                minHeight: 6,
                backgroundColor: colors.onSurface.withValues(alpha: .08),
                color: const Color(0xff7795FF),
              ),
            ),
          ),
          SizedBox(
            width: 27,
            child: Text(
              '$count',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: colors.onSurface.withValues(alpha: .58),
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, int> _countTags(List<String> Function(TeacherFeedback) select) {
    final counts = <String, int>{};
    for (final item in _feedback) {
      for (final tag in select(item)) {
        counts.update(tag, (count) => count + 1, ifAbsent: () => 1);
      }
    }
    return counts;
  }

  Widget _tagSummaryCard({
    required String title,
    required IconData icon,
    required Map<String, int> tags,
    required Color color,
    required String emptyMessage,
  }) {
    final colors = Theme.of(context).colorScheme;
    final sortedTags = tags.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: colors.onSurface.withValues(alpha: .07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (sortedTags.isEmpty)
            Text(
              emptyMessage,
              style: TextStyle(
                color: colors.onSurface.withValues(alpha: .54),
                fontSize: 11,
              ),
            )
          else
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final entry in sortedTags.take(6))
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${entry.key} · ${entry.value}',
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _commentCard(TeacherFeedback item) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Section ${item.section}',
                style: TextStyle(
                  color: colors.onSurface.withValues(alpha: .65),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.star_rounded,
                size: 15,
                color: Color(0xffFFB454),
              ),
              Text(
                '${item.rating}/5',
                style: TextStyle(color: colors.onSurface, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            item.comment,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(String message) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Text(message, style: const TextStyle(fontSize: 11)),
  );
}
