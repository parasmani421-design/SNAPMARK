import 'package:flutter/material.dart';

class SkillAssessmentScreen extends StatefulWidget {
  const SkillAssessmentScreen({super.key});

  @override
  State<SkillAssessmentScreen> createState() => _SkillAssessmentScreenState();
}

class _SkillAssessmentScreenState extends State<SkillAssessmentScreen> {
  int currentQuestion = 0;
  int score = 0;

  final List<Map<String, dynamic>> questions = [
    {
      'question': 'Which data structure follows LIFO principle?',
      'options': ['Queue', 'Stack', 'Array', 'Linked List'],
      'answer': 1,
    },
    {
      'question': 'Which command is used to upload code to GitHub?',
      'options': ['git push', 'git pull', 'git clone', 'git init'],
      'answer': 0,
    },
    {
      'question': 'What does API stand for?',
      'options': [
        'Application Programming Interface',
        'Advanced Programming Input',
        'Application Process Integration',
        'Applied Program Interface',
      ],
      'answer': 0,
    },
    {
      'question': 'Which HTTP method is commonly used to retrieve data?',
      'options': ['POST', 'DELETE', 'GET', 'PUT'],
      'answer': 2,
    },
    {
      'question':
          'Which language is mainly used for Android development with Flutter?',
      'options': ['Dart', 'JavaScript', 'Python', 'C'],
      'answer': 0,
    },
    {
      'question': 'Which SQL command is used to retrieve data?',
      'options': ['INSERT', 'SELECT', 'UPDATE', 'DELETE'],
      'answer': 1,
    },
    {
      'question': 'What is Git mainly used for?',
      'options': [
        'Video Editing',
        'Data Base Management System',
        'Version Control',
        'Web Hosting',
      ],
      'answer': 2,
    },
    {
      'question': 'Which one is a cloud computing platform?',
      'options': ['AWS', 'HTML', 'CSS', 'Git'],
      'answer': 0,
    },
    {
      'question': 'Which concept allows a class to have multiple forms?',
      'options': [
        'Inheritance',
        'Polymorphism',
        'Encapsulation',
        'Abstraction',
      ],
      'answer': 1,
    },
    {
      'question': 'What is the main purpose of debugging?',
      'options': [
        'Design UI',
        'Find and fix errors',
        'Create database',
        'Deploy application',
      ],
      'answer': 1,
    },
  ];

  int? selectedAnswer;

  void selectAnswer(int index) {
    if (selectedAnswer != null) return;

    setState(() {
      selectedAnswer = index;

      if (index == questions[currentQuestion]['answer']) {
        score++;
      }
    });
  }

  void nextQuestion() {
    if (selectedAnswer == null) return;

    if (currentQuestion < questions.length - 1) {
      setState(() {
        currentQuestion++;
        selectedAnswer = null;
      });
    } else {
      _showResult();
    }
  }

  void _showResult() {
    final percentage = ((score / questions.length) * 100).round();

    String level;

    if (percentage >= 80) {
      level = 'Excellent';
    } else if (percentage >= 60) {
      level = 'Good';
    } else if (percentage >= 40) {
      level = 'Average';
    } else {
      level = 'Needs Improvement';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color(0xff101827),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Assessment Complete 🎉',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 70),

              const SizedBox(height: 15),

              Text(
                '$percentage%',
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                '$score / ${questions.length} correct',
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),

              const SizedBox(height: 10),

              Text(
                level,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text(
                'DONE',
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = questions[currentQuestion];

    final progress = (currentQuestion + 1) / questions.length;

    return Scaffold(
      backgroundColor: const Color(0xff070B14),

      appBar: AppBar(
        backgroundColor: const Color(0xff070B14),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Skill Assessment',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Test Your Skills 🧠',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Answer the questions and discover your current skill level.',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),

              const SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${currentQuestion + 1}',
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${questions.length} Questions',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.blueAccent,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xff101827),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(
                  question['question'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    height: 1.4,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              ...List.generate(question['options'].length, (index) {
                final bool selected = selectedAnswer == index;

                final bool correct = question['answer'] == index;

                Color borderColor = Colors.white10;

                Color backgroundColor = const Color(0xff101827);

                IconData? icon;

                if (selectedAnswer != null) {
                  if (correct) {
                    borderColor = Colors.greenAccent;
                    backgroundColor = Colors.green.withOpacity(.12);
                    icon = Icons.check_circle;
                  } else if (selected) {
                    borderColor = Colors.redAccent;
                    backgroundColor = Colors.red.withOpacity(.12);
                    icon = Icons.cancel;
                  }
                }

                return GestureDetector(
                  onTap: () => selectAnswer(index),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 17,
                    ),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: borderColor,
                        width: selectedAnswer != null && (correct || selected)
                            ? 1.5
                            : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white10,
                          ),
                          child: Text(
                            String.fromCharCode(65 + index),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(width: 13),

                        Expanded(
                          child: Text(
                            question['options'][index],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),

                        if (icon != null)
                          Icon(
                            icon,
                            color: correct
                                ? Colors.greenAccent
                                : Colors.redAccent,
                          ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: selectedAnswer == null ? null : nextQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    disabledBackgroundColor: Colors.white12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    currentQuestion == questions.length - 1
                        ? 'FINISH ASSESSMENT'
                        : 'NEXT QUESTION',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Center(
                child: Text(
                  'Score: $score / ${questions.length}',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
