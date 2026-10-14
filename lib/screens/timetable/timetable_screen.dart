import 'package:flutter/material.dart';
import '../../core/services/student_directory_store.dart';
import '../../widgets/teacher_assignment_text.dart';

final Map<int, List<Map<String, String>>> timetableSchedule = {
  0: [
    {
      'subject': 'Multivariable Calculus and Differential Equations',
      'teacher': 'Dr. Pooja Singh',
      'time': '08:30 AM - 09:20 AM',
      'room': 'GU_AI_208',
      'type': 'Lecture',
    },
    {
      'subject': 'Data Structures',
      'teacher': 'Dr.Gaurav Agarwal',
      'time': '09:20 AM - 10:10 AM',
      'room': 'GU_AI_208',
      'type': 'Lab',
    },
    {
      'subject': 'Advanced Aptitude Skill',
      'teacher': 'Simran Singh',
      'time': '10:30 AM - 11:15 AM',
      'room': 'GU_Ai_603',
      'type': 'Lecture',
    },
    {
      'subject': 'Java Programming',
      'teacher': 'Rani Singh',
      'time': '11:20 AM - 12:10 PM',
      'room': 'GU_AI_603',
      'type': 'Practical',
    },
    {
      'subject': 'Multivariable Calculus and Differential Equations',
      'teacher': 'Dr. Pankaj Kumar',
      'time': '11:20 AM - 12:10 PM',
      'room': 'GU_AI_410',
      'type': 'Lecture',
    },
  ],

  1: [
    {
      'subject': 'Data Base Management System',
      'teacher': 'Dr. Shweta',
      'time': '08:30 AM - 09:20 AM',
      'room': 'GU_AI-208',
      'type': 'Lecture',
    },
    {
      'subject': 'Computer Organization',
      'teacher': 'Dr. Pragya Srivastava',
      'time': '09:20 AM - 10:10 AM',
      'room': 'GU_AI-208',
      'type': 'Lecture',
    },
    {
      'subject': 'Data Structures',
      'teacher': 'Dr. Gaurav Agrawal',
      'time': '10:15 AM - 11:05 AM',
      'room': 'GU_AI-208',
      'type': 'Lecture',
    },
    {
      'subject': 'Design Thinking',
      'teacher': 'Trapti Shrivastava',
      'time': '11:05 AM - 11:55 AM',
      'room': 'GU_AI-208',
      'type': 'Lecture',
    },
  ],

  2: [
    {
      'subject': 'Java Programming',
      'teacher': 'Rani Singh',
      'time': '08:30 AM - 09:20 AM',
      'room': 'GU_AI-208',
      'type': 'Lecture',
    },
    {
      'subject': 'Java Programming',
      'teacher': 'Rani Singh',
      'time': '09:20 AM - 10:10 AM',
      'room': 'GU_AI-208',
      'type': 'Lecture',
    },
    {
      'subject': 'Data Structures',
      'teacher': 'Dr. Gaurav Agrawal',
      'time': '11:05 AM - 11:55 AM',
      'room': 'GU_AI-208',
      'type': 'Lecture',
    },
    {
      'subject': 'Multivariable Calculus and Differential Equations',
      'teacher': 'Dr. Pankaj Kumar',
      'time': '12:50 PM - 01:40 PM',
      'room': 'GU_AI-321',
      'type': 'Lecture',
    },
  ],

  3: [
    {
      'subject': 'Data Base Management System',
      'teacher': 'Dr. Shweta',
      'time': '08:30 AM - 09:20 AM',
      'room': 'GU_AI-208',
      'type': 'Lecture',
    },
    {
      'subject': 'Data Base Management System',
      'teacher': 'Dr. Shweta',
      'time': '09:20 AM - 10:10 AM',
      'room': 'GU_AI-208',
      'type': 'Lecture',
    },
    {
      'subject': 'Java Programming',
      'teacher': 'Rani Singh',
      'time': '10:15 AM - 11:05 AM',
      'room': 'GU_AI-208',
      'type': 'Lecture',
    },
    {
      'subject': 'Multivariable Calculus and Differential Equations',
      'teacher': 'Dr. Pankaj Kumar',
      'time': '12:50 PM - 01:40 PM',
      'room': 'GU_AI-310',
      'type': 'Lecture',
    },
  ],

  4: [
    {
      'subject': 'Advanced Aptitude Skill',
      'teacher': 'Prashant Tiwari',
      'time': '08:30 AM - 09:20 AM',
      'room': 'GU_AI-208',
      'type': 'Lab',
    },
    {
      'subject': 'Advanced Aptitude Skill',
      'teacher': 'Prashant Tiwari',
      'time': '09:20 AM - 10:10 AM',
      'room': 'GU_AI-208',
      'type': 'Lab',
    },
    {
      'subject': 'Multivariable Calculus and Differential Equations',
      'teacher': 'Dr. Ravikant Singh',
      'time': '10:15 AM - 11:05 AM',
      'room': 'GU_AI-305',
      'type': 'Lab',
    },
    {
      'subject': 'Multivariable Calculus and Differential Equations',
      'teacher': 'Dr. Ravikant Singh',
      'time': '11:05 AM - 11:55 AM',
      'room': 'GU_AI-305',
      'type': 'Lab',
    },
    {
      'subject': 'Data Structures',
      'teacher': 'Dr. Gaurav Agrawal',
      'time': '12:00 PM - 12:50 PM',
      'room': 'GU_AI-208',
      'type': 'Lecture',
    },
    {
      'subject': 'Data Structures',
      'teacher': 'Kushal Gupta',
      'time': '01:45 PM - 02:35 PM',
      'room': 'GU_AI-310',
      'type': 'Lab',
    },
    {
      'subject': 'Data Structures',
      'teacher': 'Kushal Gupta',
      'time': '02:35 PM - 03:25 PM',
      'room': 'GU_AI-310',
      'type': 'Lab',
    },
    {
      'subject': 'Multivariable Calculus and Differential Equations',
      'teacher': 'Dr. Pooja Singh',
      'time': '03:30 PM - 04:20 PM',
      'room': 'GU_AI-012',
      'type': 'Lab',
    },
    {
      'subject': 'Multivariable Calculus and Differential Equations',
      'teacher': 'Dr. Pooja Singh',
      'time': '04:20 PM - 05:10 PM',
      'room': 'GU_AI-012',
      'type': 'Lab',
    },
    {
      'subject': 'Multivariable Calculus and Differential Equations',
      'teacher': 'Dr. Pankaj Kumar',
      'time': '05:10 PM - 06:00 PM',
      'room': 'GU_AI-114',
      'type': 'Lecture',
    },
  ],

  5: [
    {
      'subject': 'Computer Organization',
      'teacher': 'Dr. Pragya Srivastava',
      'time': '08:30 AM - 09:20 AM',
      'room': 'GU_AI-208',
      'type': 'Lecture',
    },
    {
      'subject': 'Computer Organization',
      'teacher': 'Dr. Pragya Srivastava',
      'time': '09:20 AM - 10:10 AM',
      'room': 'GU_AI-208',
      'type': 'Lecture',
    },
    {
      'subject': 'Advanced Aptitude Skill',
      'teacher': 'Simran Thakur',
      'time': '10:15 AM - 11:05 AM',
      'room': 'GU_AI-208',
      'type': 'Lab',
    },
    {
      'subject': 'Advanced Aptitude Skill',
      'teacher': 'Simran Thakur',
      'time': '11:05 AM - 11:55 AM',
      'room': 'GU_AI-208',
      'type': 'Lab',
    },
    {
      'subject': 'Data Base Management System',
      'teacher': 'Ankit Sharma',
      'time': '12:00 PM - 12:50 PM',
      'room': 'GU_AI-408',
      'type': 'Lab',
    },
    {
      'subject': 'Data Base Management System',
      'teacher': 'Ankit Sharma',
      'time': '12:50 PM - 01:40 PM',
      'room': 'GU_AI-408',
      'type': 'Lab',
    },
    {
      'subject': 'Java Programming',
      'teacher': 'Abhishek Kumar Agrahari',
      'time': '01:45 PM - 02:35 PM',
      'room': 'GU_AI-404',
      'type': 'Lab',
    },
    {
      'subject': 'Java Programming',
      'teacher': 'Abhishek Kumar Agrahari',
      'time': '02:35 PM - 03:25 PM',
      'room': 'GU_AI-404',
      'type': 'Lab',
    },
    {
      'subject': 'Multivariable Calculus and Differential Equations',
      'teacher': 'Dr. Pooja Singh',
      'time': '03:30 PM - 04:20 PM',
      'room': 'GU_AI-212',
      'type': 'Lab',
    },
    {
      'subject': 'Multivariable Calculus and Differential Equations',
      'teacher': 'Dr. Pooja Singh',
      'time': '04:20 PM - 05:10 PM',
      'room': 'GU_AI-212',
      'type': 'Lab',
    },
  ],
};

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  int selectedDay = 0;
  String _studentSection = '';

  final List<String> days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

  final List<String> fullDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  void initState() {
    super.initState();
    _loadStudentSection();
  }

  Future<void> _loadStudentSection() async {
    if (await StudentDirectoryStore.activeFacultyEmail() != null) return;
    final email = await StudentDirectoryStore.activeEmail();
    if (email == null) return;
    final profile = await StudentDirectoryStore.findByEmail(email);
    if (!mounted) return;
    setState(
      () =>
          _studentSection = _normalizeSection(profile?.value('section') ?? ''),
    );
  }

  String _normalizeSection(String value) =>
      RegExp(r'\d+').firstMatch(value)?.group(0) ?? value.trim();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = colors.onSurface;
    final muted = colors.onSurface.withValues(alpha: .62);
    final todayClasses = (timetableSchedule[selectedDay] ?? []).where((lesson) {
      final section = lesson['section']?.trim() ?? '';
      return section.isEmpty ||
          _studentSection.isEmpty ||
          _normalizeSection(section) == _studentSection;
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,

        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: foreground),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: Text(
          'Timetable',
          style: TextStyle(
            color: foreground,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Timetable refreshed')),
              );
            },
            icon: Icon(Icons.refresh, color: foreground),
          ),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 5),

            // WEEK HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: List.generate(days.length, (index) {
                    final selected = selectedDay == index;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedDay = index;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.blueAccent
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Column(
                            children: [
                              Text(
                                days[index],
                                style: TextStyle(
                                  color: selected ? Colors.white : muted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${index + 18}',
                                style: TextStyle(
                                  color: selected ? Colors.white : muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // SELECTED DAY
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullDays[selectedDay],
                        style: TextStyle(
                          color: foreground,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${todayClasses.length} classes scheduled',
                        style: TextStyle(color: muted, fontSize: 13),
                      ),
                    ],
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.calendar_month,
                          color: Colors.blueAccent,
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Text(
                          '2026',
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // CLASS LIST
            Expanded(
              child: todayClasses.isEmpty
                  ? Center(
                      child: Text(
                        'No classes scheduled',
                        style: TextStyle(color: muted, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 25),
                      itemCount: todayClasses.length,
                      itemBuilder: (context, index) {
                        final item = todayClasses[index];

                        return _classCard(
                          subject: item['subject']!,
                          teacher: item['teacher']!,
                          substituteTeacher: item['substituteTeacher'] ?? '',
                          time: item['time']!,
                          room: item['room']!,
                          type: item['type']!,
                          index: index,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _classCard({
    required String subject,
    required String teacher,
    required String substituteTeacher,
    required String time,
    required String room,
    required String type,
    required int index,
  }) {
    final colors = Theme.of(context).colorScheme;
    final foreground = colors.onSurface;
    final muted = colors.onSurface.withValues(alpha: .62);
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.onSurface.withValues(alpha: .08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TIME
            SizedBox(
              width: 72,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    time.split(' - ')[0],
                    style: TextStyle(
                      color: foreground,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    time.split(' - ')[1],
                    style: TextStyle(color: muted, fontSize: 11),
                  ),
                ],
              ),
            ),

            Container(
              width: 3,
              height: 82,
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(5),
              ),
            ),

            const SizedBox(width: 15),

            // SUBJECT DETAILS
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Icon(Icons.person_outline, color: muted, size: 16),
                      const SizedBox(width: 5),
                      Expanded(
                        child: TeacherAssignmentText(
                          teacher: teacher,
                          substituteTeacher: substituteTeacher,
                          maxLines: 1,
                          style: TextStyle(color: muted, fontSize: 12),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, color: muted, size: 16),
                      const SizedBox(width: 5),
                      Text(room, style: TextStyle(color: muted, fontSize: 12)),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      type,
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 5),

            // MORE BUTTON
            IconButton(
              onPressed: () {
                _showClassDetails(context, subject, teacher, time, room, type);
              },
              icon: Icon(Icons.more_vert, color: muted),
            ),
          ],
        ),
      ),
    );
  }

  void _showClassDetails(
    BuildContext context,
    String subject,
    String teacher,
    String time,
    String room,
    String type,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              Text(
                subject,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 18),

              _detailRow(Icons.access_time, time),

              _detailRow(Icons.person_outline, teacher),

              _detailRow(Icons.location_on_outlined, room),

              _detailRow(Icons.category_outlined, type),

              const SizedBox(height: 15),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: .7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
