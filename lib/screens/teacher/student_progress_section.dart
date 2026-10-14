import 'package:flutter/material.dart';
import '../../core/services/campus_configuration_store.dart';

enum _ProgressSort {
  highestProgress('Highest progress'),
  lowestProgress('Lowest progress'),
  highestCgpa('Highest CGPA'),
  lowestCgpa('Lowest CGPA'),
  mostImproved('Most improved'),
  needsAttention('Needs attention'),
  subjectWeakness('Subject weakness');

  const _ProgressSort(this.label);
  final String label;
}

class _StudentSample {
  const _StudentSample({
    required this.name,
    required this.cgpa,
    required this.midterm,
    required this.viva,
    required this.quiz,
    required this.assignments,
    required this.practical,
    required this.tests,
    required this.trend,
    required this.weaknesses,
  });

  final String name;
  final double cgpa;
  final double midterm, viva, quiz, assignments, practical, tests, trend;
  final List<String> weaknesses;

  double get score =>
      midterm * .25 +
      viva * .15 +
      quiz * .15 +
      assignments * .15 +
      practical * .10 +
      tests * .10 +
      trend * .10;

  String get status => score >= 80
      ? 'Strong'
      : score >= 60
      ? 'Average'
      : 'Needs attention';
}

const _students47 = <_StudentSample>[
  _StudentSample(
    name: 'Paras',
    cgpa: 8.7,
    midterm: 88,
    viva: 92,
    quiz: 90,
    assignments: 94,
    practical: 89,
    tests: 86,
    trend: 91,
    weaknesses: ['No major gaps'],
  ),
  _StudentSample(
    name: 'Adarsh',
    cgpa: 7.4,
    midterm: 72,
    viva: 68,
    quiz: 75,
    assignments: 70,
    practical: 76,
    tests: 71,
    trend: 66,
    weaknesses: ['DSA · Trees', 'Data Base Management System · Normalization'],
  ),
  _StudentSample(
    name: 'Prem',
    cgpa: 6.1,
    midterm: 55,
    viva: 48,
    quiz: 52,
    assignments: 60,
    practical: 58,
    tests: 50,
    trend: 45,
    weaknesses: ['Algorithms · Sorting', 'OOP · Inheritance'],
  ),
  _StudentSample(
    name: 'Ashish',
    cgpa: 8.1,
    midterm: 79,
    viva: 83,
    quiz: 78,
    assignments: 88,
    practical: 85,
    tests: 80,
    trend: 87,
    weaknesses: ['Operating systems · Scheduling'],
  ),
  _StudentSample(
    name: 'Om Prakash',
    cgpa: 7.8,
    midterm: 68,
    viva: 74,
    quiz: 71,
    assignments: 73,
    practical: 69,
    tests: 72,
    trend: 78,
    weaknesses: ['Computer networks · Subnetting'],
  ),
];

const _students48 = <_StudentSample>[
  _StudentSample(
    name: 'Riya Sharma',
    cgpa: 8.2,
    midterm: 82,
    viva: 86,
    quiz: 84,
    assignments: 88,
    practical: 81,
    tests: 85,
    trend: 89,
    weaknesses: ['DBMS · Joins'],
  ),
  _StudentSample(
    name: 'Karan Patel',
    cgpa: 7.6,
    midterm: 75,
    viva: 72,
    quiz: 78,
    assignments: 74,
    practical: 80,
    tests: 76,
    trend: 82,
    weaknesses: ['DSA · Graph traversal'],
  ),
  _StudentSample(
    name: 'Neha Verma',
    cgpa: 9.0,
    midterm: 92,
    viva: 89,
    quiz: 94,
    assignments: 91,
    practical: 93,
    tests: 90,
    trend: 95,
    weaknesses: ['No major gaps'],
  ),
  _StudentSample(
    name: 'Rahul Singh',
    cgpa: 6.8,
    midterm: 61,
    viva: 58,
    quiz: 64,
    assignments: 67,
    practical: 62,
    tests: 60,
    trend: 55,
    weaknesses: ['OOP · Polymorphism', 'DSA · Trees'],
  ),
  _StudentSample(
    name: 'Sneha Gupta',
    cgpa: 7.9,
    midterm: 81,
    viva: 76,
    quiz: 73,
    assignments: 85,
    practical: 82,
    tests: 78,
    trend: 80,
    weaknesses: ['Operating systems · Processes'],
  ),
  _StudentSample(
    name: 'Arjun Mehta',
    cgpa: 7.1,
    midterm: 68,
    viva: 70,
    quiz: 66,
    assignments: 72,
    practical: 75,
    tests: 69,
    trend: 73,
    weaknesses: ['DBMS · Normalization'],
  ),
];

const _students49 = <_StudentSample>[
  _StudentSample(
    name: 'Aanya Das',
    cgpa: 8.8,
    midterm: 89,
    viva: 92,
    quiz: 87,
    assignments: 90,
    practical: 91,
    tests: 88,
    trend: 93,
    weaknesses: ['No major gaps'],
  ),
  _StudentSample(
    name: 'Dev Malhotra',
    cgpa: 7.3,
    midterm: 70,
    viva: 74,
    quiz: 69,
    assignments: 77,
    practical: 72,
    tests: 71,
    trend: 79,
    weaknesses: ['Algorithms · Recursion'],
  ),
  _StudentSample(
    name: 'Ishita Roy',
    cgpa: 8.0,
    midterm: 78,
    viva: 82,
    quiz: 80,
    assignments: 84,
    practical: 79,
    tests: 81,
    trend: 86,
    weaknesses: ['Computer networks · Routing'],
  ),
  _StudentSample(
    name: 'Manav Joshi',
    cgpa: 6.4,
    midterm: 52,
    viva: 57,
    quiz: 55,
    assignments: 61,
    practical: 58,
    tests: 54,
    trend: 49,
    weaknesses: ['DSA · Complexity', 'DBMS · Keys'],
  ),
  _StudentSample(
    name: 'Pooja Nair',
    cgpa: 8.4,
    midterm: 85,
    viva: 88,
    quiz: 86,
    assignments: 83,
    practical: 90,
    tests: 84,
    trend: 87,
    weaknesses: ['No major gaps'],
  ),
  _StudentSample(
    name: 'Kabir Khan',
    cgpa: 7.7,
    midterm: 76,
    viva: 79,
    quiz: 74,
    assignments: 80,
    practical: 77,
    tests: 75,
    trend: 81,
    weaknesses: ['Java · Collections'],
  ),
];

const _studentsBySection = <String, List<_StudentSample>>{
  '47': _students47,
  '48': _students48,
  '49': _students49,
};

class StudentProgressOverviewCard extends StatelessWidget {
  const StudentProgressOverviewCard({
    super.key,
    required this.muted,
    required this.onOpen,
  });

  final Color muted;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final average =
        _students47.map((student) => student.score).reduce((a, b) => a + b) /
        _students47.length;
    final strong = _students47
        .where((student) => student.status == 'Strong')
        .length;
    final attention = _students47
        .where((student) => student.status == 'Needs attention')
        .length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: colors.onSurface.withValues(alpha: .07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xff728BFF).withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: Color(0xff93A9FF),
                  size: 18,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Student progress',
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Section 47 · ${_students47.length} students',
                      style: TextStyle(color: muted, fontSize: 9),
                    ),
                  ],
                ),
              ),
              _badge('SAMPLE DATA', const Color(0xffB8A5FF)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _overviewMetric(
                '${average.round()}%',
                'Avg. progress',
                const Color(0xff83A0FF),
                muted,
              ),
              _overviewMetric(
                '$strong',
                'Strong',
                const Color(0xff5ED6B3),
                muted,
              ),
              _overviewMetric(
                '$attention',
                'Need attention',
                const Color(0xffFFBA68),
                muted,
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.groups_rounded, size: 16),
              label: const Text('View section progress'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xffA994FF),
                side: BorderSide(
                  color: const Color(0xffA994FF).withValues(alpha: .4),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
                padding: const EdgeInsets.symmetric(vertical: 9),
                textStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _overviewMetric(String value, String label, Color tint, Color muted) =>
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: tint,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: muted, fontSize: 8)),
          ],
        ),
      );

  Widget _badge(String label, Color tint) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: tint.withValues(alpha: .13),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: tint,
        fontSize: 7,
        letterSpacing: .7,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class StudentProgressSection extends StatefulWidget {
  const StudentProgressSection({super.key, required this.muted});
  final Color muted;

  @override
  State<StudentProgressSection> createState() => _StudentProgressSectionState();
}

class _StudentProgressSectionState extends State<StudentProgressSection> {
  _ProgressSort _sort = _ProgressSort.highestProgress;
  String? _expanded;
  String _selectedSection = '47';

  String get _activeSection =>
      CampusConfigurationStore.sections.contains(_selectedSection)
      ? _selectedSection
      : CampusConfigurationStore.sections.first;
  List<_StudentSample> get _students =>
      _studentsBySection[_activeSection] ?? const [];

  List<_StudentSample> get _sorted {
    final result = [..._students];
    switch (_sort) {
      case _ProgressSort.highestProgress:
        result.sort((a, b) => b.score.compareTo(a.score));
        break;
      case _ProgressSort.lowestProgress:
        result.sort((a, b) => a.score.compareTo(b.score));
        break;
      case _ProgressSort.highestCgpa:
        result.sort((a, b) => b.cgpa.compareTo(a.cgpa));
        break;
      case _ProgressSort.lowestCgpa:
        result.sort((a, b) => a.cgpa.compareTo(b.cgpa));
        break;
      case _ProgressSort.mostImproved:
        result.sort((a, b) => b.trend.compareTo(a.trend));
        break;
      case _ProgressSort.needsAttention:
        result.sort((a, b) => a.score.compareTo(b.score));
        break;
      case _ProgressSort.subjectWeakness:
        result.sort(
          (a, b) => b.weaknesses.length.compareTo(a.weaknesses.length),
        );
        break;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final average =
        _students.map((s) => s.score).reduce((a, b) => a + b) /
        _students.length;
    final attention = _students
        .where((s) => s.status == 'Needs attention')
        .length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: colors.onSurface.withValues(alpha: .07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights_rounded,
                size: 17,
                color: const Color(0xff9DAEFF),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Student progress',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _badge('SAMPLE DATA', const Color(0xffB8A5FF)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Section',
                style: TextStyle(
                  color: widget.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              for (final section in CampusConfigurationStore.sections) ...[
                ChoiceChip(
                  label: Text(section),
                  selected: _activeSection == section,
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  labelStyle: TextStyle(
                    color: _activeSection == section
                        ? Colors.white
                        : widget.muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                  backgroundColor: colors.onSurface.withValues(alpha: .045),
                  selectedColor: const Color(0xff637FFF),
                  side: BorderSide.none,
                  onSelected: (_) => setState(() {
                    _selectedSection = section;
                    _expanded = null;
                  }),
                ),
                if (section != '49') const SizedBox(width: 3),
              ],
              const Spacer(),
              Text(
                '${_students.length} students',
                style: TextStyle(color: widget.muted, fontSize: 9),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              _metric(
                '${average.round()}%',
                'Avg. progress',
                const Color(0xff83A0FF),
              ),
              _metric(
                '${_students.where((s) => s.status == 'Strong').length}/${_students.length}',
                'Strong',
                const Color(0xff5ED6B3),
              ),
              _metric('$attention', 'Need follow-up', const Color(0xffFFBA68)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'CGPA stays separate from this term score',
                  style: TextStyle(color: widget.muted, fontSize: 9),
                ),
              ),
              PopupMenuButton<_ProgressSort>(
                tooltip: 'Sort students',
                onSelected: (value) => setState(() {
                  _sort = value;
                  _expanded = null;
                }),
                itemBuilder: (_) => _ProgressSort.values
                    .map((s) => PopupMenuItem(value: s, child: Text(s.label)))
                    .toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: colors.onSurface.withValues(alpha: .055),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _sort.label,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.expand_more_rounded, size: 15),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          for (final student in _sorted) _studentRow(student, colors),
          const SizedBox(height: 5),
          Text(
            'Score weights: Mid-term 25% · Viva 15% · Quiz 15% · Assignments 15% · Practical 10% · Tests 10% · Trend 10%',
            style: TextStyle(color: widget.muted, fontSize: 8, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _studentRow(_StudentSample s, ColorScheme colors) {
    final open = _expanded == s.name;
    final tint = s.status == 'Strong'
        ? const Color(0xff5ED6B3)
        : s.status == 'Average'
        ? const Color(0xffFFBA68)
        : const Color(0xffff777e);
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: () => setState(() => _expanded = open ? null : s.name),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: tint.withValues(alpha: .13),
                  child: Text(
                    s.name.split(' ').map((p) => p[0]).take(2).join(),
                    style: TextStyle(
                      color: tint,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: s.score / 100,
                                minHeight: 4,
                                backgroundColor: colors.onSurface.withValues(
                                  alpha: .08,
                                ),
                                color: tint,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            '${s.score.round()}%',
                            style: TextStyle(
                              color: tint,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'CGPA ${s.cgpa.toStringAsFixed(1)}',
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      s.status,
                      style: TextStyle(
                        color: tint,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 3),
                Icon(
                  open
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: widget.muted,
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: open
              ? _details(s, colors, tint)
              : const SizedBox(width: double.infinity, height: 0),
        ),
        Divider(height: 1, color: colors.onSurface.withValues(alpha: .055)),
      ],
    );
  }

  Widget _details(_StudentSample s, ColorScheme colors, Color tint) => Padding(
    padding: const EdgeInsets.fromLTRB(39, 0, 4, 11),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 7,
          children: [
            _tiny('Mid-term', s.midterm),
            _tiny('Viva', s.viva),
            _tiny('Quiz', s.quiz),
            _tiny('Assignments', s.assignments),
            _tiny('Practical', s.practical),
            _tiny('Tests', s.tests),
            _tiny('Trend', s.trend),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lightbulb_outline_rounded, size: 13, color: tint),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                s.weaknesses.join('  ·  '),
                style: TextStyle(
                  color: colors.onSurface.withValues(alpha: .72),
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _tiny(String label, double value) => Text(
    '$label ${value.round()}%',
    style: TextStyle(color: widget.muted, fontSize: 8),
  );
  Widget _metric(String value, String label, Color tint) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: tint,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: widget.muted, fontSize: 8)),
      ],
    ),
  );
  Widget _badge(String label, Color tint) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: tint.withValues(alpha: .13),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: tint,
        fontSize: 7,
        letterSpacing: .7,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}
