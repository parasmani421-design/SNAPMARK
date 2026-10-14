import 'package:flutter/material.dart';
import 'skill_assessment_screen.dart';

  class SkillCareerScreen extends StatefulWidget {
    const SkillCareerScreen({super.key});

    @override
    State<SkillCareerScreen> createState() =>
        _SkillCareerScreenState();
  }

  class _SkillCareerScreenState
      extends State<SkillCareerScreen> {
    String selectedCareer = 'Software Developer';

    final List<String> careers = [
      'Software Developer',
      'Data Analyst',
      'AI / ML Engineer',
      'Cybersecurity Analyst',
      'Cloud Engineer',
      'Web Developer',
    ];

    final List<Map<String, dynamic>> roadmap = [
      {
        'week': 'Week 1',
        'title': 'DSA Fundamentals',
        'description':
            'Arrays, Strings, Searching, Sorting and basic problem solving.',
        'icon': Icons.account_tree,
        'tasks': [
          'Learn Arrays & Strings',
          'Practice Searching',
          'Practice Sorting',
          'Solve 10 coding problems',
        ],
      },
      {
        'week': 'Week 2',
        'title': 'Git & GitHub',
        'description':
            'Learn version control and build a professional GitHub profile.',
        'icon': Icons.code,
        'tasks': [
          'Learn Git basics',
          'Create GitHub repository',
          'Learn branches & merge',
          'Upload one project',
        ],
      },
      {
        'week': 'Week 3',
        'title': 'REST API & Backend',
        'description':
            'Understand APIs, HTTP methods and backend communication.',
        'icon': Icons.api,
        'tasks': [
          'Understand HTTP methods',
          'Learn REST API basics',
          'Test APIs with Postman',
          'Build a simple API project',
        ],
      },
      {
        'week': 'Week 4',
        'title': 'Industry Project',
        'description':
            'Build a practical project using the skills learned.',
        'icon': Icons.rocket_launch,
        'tasks': [
          'Select project idea',
          'Create project structure',
          'Connect API / database',
          'Publish project on GitHub',
        ],
      },
    ];

    final Map<String, List<bool>> completedTasks = {};

    @override
    void initState() {
      super.initState();

      for (final item in roadmap) {
        completedTasks[item['week']] =
            List<bool>.filled(
          (item['tasks'] as List).length,
          false,
        );
      }
    }

    int get totalTasks {
      int total = 0;

      for (final item in roadmap) {
        total += (item['tasks'] as List).length;
      }

    return total;
  }

  int get completedCount {
    int count = 0;

    for (final values in completedTasks.values) {
      count += values.where((value) => value).length;
    }

    return count;
  }

  double get roadmapProgress {
    if (totalTasks == 0) {
      return 0;
    }

    return completedCount / totalTasks;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff070B14),

      appBar: AppBar(
        backgroundColor: const Color(0xff070B14),
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        title: const Text(
          'Skill & Career',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            // ==================================================
            // HEADER
            // ==================================================

            const Text(
              'Build Your Career 🎯',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Discover your skill gaps and prepare for industry demands.',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 25),

            // ==================================================
            // CAREER GOAL
            // ==================================================

            _sectionTitle('Career Goal'),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: const Color(0xff101827),
                borderRadius:
                    BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white10,
                ),
              ),
              child:
                  DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedCareer,
                  dropdownColor:
                      const Color(0xff101827),
                  isExpanded: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white70,
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                  items:
                      careers.map((career) {
                    return DropdownMenuItem<String>(
                      value: career,
                      child: Text(career),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      selectedCareer = value;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ==================================================
            // CAREER READINESS
            // ==================================================

            _sectionTitle('Career Readiness'),

            const SizedBox(height: 12),

            _readinessCard(),

            const SizedBox(height: 18),

            // ==================================================
            // SKILL ASSESSMENT BUTTON
            // ==================================================

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const SkillAssessmentScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.assessment,
                  color: Colors.white,
                ),
                label: const Text(
                  'TAKE SKILL ASSESSMENT',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: .5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.blueAccent,
                  elevation: 0,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ==================================================
            // SKILL GAP ANALYSIS
            // ==================================================

            _sectionTitle('Skill Gap Analysis'),

            const SizedBox(height: 12),

            _skillCard(
              'Java',
              0.82,
              'Strong',
              Icons.check_circle,
              true,
            ),

            _skillCard(
              'SQL',
              0.64,
              'Good',
              Icons.trending_up,
              true,
            ),

            _skillCard(
              'DSA',
              0.40,
              'Needs Improvement',
              Icons.warning_amber,
              false,
            ),

            _skillCard(
              'Git & GitHub',
              0.30,
              'Priority Skill',
              Icons.warning_amber,
              false,
            ),

            _skillCard(
              'REST API',
              0.25,
              'Priority Skill',
              Icons.warning_amber,
              false,
            ),

            const SizedBox(height: 28),

            // ==================================================
            // INDUSTRY REQUIREMENTS
            // ==================================================

            _sectionTitle(
              'Industry Requirements',
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xff101827),
                borderRadius:
                    BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.blueAccent
                      .withOpacity(.2),
                ),
              ),
              child: Column(
                children: [

                  _requirement(
                    'DSA',
                    'High Demand',
                  ),

                  _requirement(
                    'Git / GitHub',
                    'High Demand',
                  ),

                  _requirement(
                    'REST API',
                    'Medium Demand',
                  ),

                  _requirement(
                    'Cloud Basics',
                    'Growing Demand',
                  ),

                  _requirement(
                    'System Design',
                    'Growing Demand',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ==================================================
            // LEARNING ROADMAP
            // ==================================================

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [

                _sectionTitle(
                  'Learning Roadmap',
                ),

                Text(
                  '${(roadmapProgress * 100).round()}%',
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            ClipRRect(
              borderRadius:
                  BorderRadius.circular(10),
              child:
                  LinearProgressIndicator(
                value: roadmapProgress,
                minHeight: 8,
                backgroundColor:
                    Colors.white12,
                valueColor:
                    const AlwaysStoppedAnimation<
                        Color>(
                  Colors.blueAccent,
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ROADMAP CARDS

            ...roadmap.map(
              (item) => _roadmapCard(item),
            ),

            const SizedBox(height: 28),

            // ==================================================
            // AI RECOMMENDATION
            // ==================================================

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xff101827),
                borderRadius:
                    BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.blueAccent
                      .withOpacity(.3),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  const Row(
                    children: [

                      CircleAvatar(
                        radius: 24,
                        backgroundColor:
                            Color(0xff172554),
                        child: Icon(
                          Icons.auto_awesome,
                          color:
                              Colors.blueAccent,
                        ),
                      ),

                      SizedBox(width: 12),

                      Text(
                        'AI Recommendation',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'For your $selectedCareer goal, focus on DSA, Git/GitHub and REST APIs. Complete the roadmap step-by-step and build practical projects to become industry ready.',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    'Recommended Path → DSA → Git → REST API → Backend Project',
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // CAREER READINESS CARD
  // ==========================================================

  Widget _readinessCard() {
    final readiness =
        0.68 + (roadmapProgress * 0.20);

    final finalReadiness =
        readiness > 1 ? 1.0 : readiness;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xff155EEF),
            Color(0xff4527A0),
          ],
        ),
        borderRadius:
            BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [

              const Text(
                'Overall Readiness',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),

              Text(
                '${(finalReadiness * 100).round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          ClipRRect(
            borderRadius:
                BorderRadius.circular(10),
            child:
                LinearProgressIndicator(
              value: finalReadiness,
              minHeight: 9,
              backgroundColor:
                  Colors.white24,
              valueColor:
                  const AlwaysStoppedAnimation<
                      Color>(
                Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            completedCount == 0
                ? 'Start your roadmap to improve your industry readiness.'
                : '$completedCount of $totalTasks learning tasks completed.',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ROADMAP CARD
  // ==========================================================

  Widget _roadmapCard(
    Map<String, dynamic> item,
  ) {
    final String week =
        item['week'] as String;

    final List<String> tasks =
        List<String>.from(
      item['tasks'],
    );

    final List<bool> progress =
        completedTasks[week]!;

    final int completed =
        progress
            .where(
              (value) => value,
            )
            .length;

    final bool isComplete =
        completed == tasks.length;

    return Container(
      margin:
          const EdgeInsets.only(bottom: 14),
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xff101827),
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: isComplete
              ? Colors.greenAccent
                  .withOpacity(.3)
              : Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [

          Row(
            children: [

              CircleAvatar(
                radius: 23,
                backgroundColor:
                    isComplete
                        ? Colors.green
                            .withOpacity(.15)
                        : const Color(
                            0xff172554,
                          ),
                child: Icon(
                  isComplete
                      ? Icons.check
                      : item['icon']
                          as IconData,
                  color: isComplete
                      ? Colors.greenAccent
                      : Colors.blueAccent,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    Text(
                      week,
                      style:
                          const TextStyle(
                        color:
                            Colors.blueAccent,
                        fontSize: 12,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      item['title']
                          as String,
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                '$completed/${tasks.length}',
                style:
                    const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            item['description']
                as String,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 12),

          ...List.generate(
            tasks.length,
            (index) {
              return CheckboxListTile(
                contentPadding:
                    EdgeInsets.zero,
                dense: true,
                controlAffinity:
                    ListTileControlAffinity
                        .leading,
                activeColor:
                    Colors.blueAccent,
                checkColor: Colors.white,
                value: progress[index],
                title: Text(
                  tasks[index],
                  style: TextStyle(
                    color: progress[index]
                        ? Colors.white38
                        : Colors.white70,
                    fontSize: 13,
                    decoration:
                        progress[index]
                            ? TextDecoration
                                .lineThrough
                            : null,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    progress[index] =
                        value ?? false;
                  });
                },
              );
            },
          ),
        ],
      ),
    );
  }
  // ==========================================================
  // SECTION TITLE
  // ==========================================================

  Widget _sectionTitle(
    String title,
  ) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 21,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // ==========================================================
  // SKILL CARD
  // ==========================================================

  Widget _skillCard(
    String name,
    double progress,
    String status,
    IconData icon,
    bool good,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(bottom: 10),
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff101827),
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Column(
        children: [

          Row(
            children: [

              Icon(
                icon,
                color: good
                    ? Colors.greenAccent
                    : Colors.orangeAccent,
                size: 22,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  name,
                  style:
                      const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),

              Text(
                '${(progress * 100).round()}%',
                style:
                    const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ClipRRect(
            borderRadius:
                BorderRadius.circular(10),
            child:
                LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor:
                  Colors.white12,
              valueColor:
                  AlwaysStoppedAnimation<
                      Color>(
                good
                    ? Colors.blueAccent
                    : Colors.orangeAccent,
              ),
            ),
          ),

          const SizedBox(height: 6),

          Align(
            alignment:
                Alignment.centerLeft,
            child: Text(
              status,
              style: TextStyle(
                color: good
                    ? Colors.greenAccent
                    : Colors.orangeAccent,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // INDUSTRY REQUIREMENT
  // ==========================================================

  Widget _requirement(
    String skill,
    String demand,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 9,
      ),
      child: Row(
        children: [

          const Icon(
            Icons.work_outline,
            color: Colors.blueAccent,
            size: 20,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              skill,
              style:
                  const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),

          Text(
            demand,
            style:
                const TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}