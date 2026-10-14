import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../timetable/timetable_screen.dart';

class TeacherProgressQuestionsScreen extends StatefulWidget {
  const TeacherProgressQuestionsScreen({super.key});

  @override
  State<TeacherProgressQuestionsScreen> createState() =>
      _TeacherProgressQuestionsScreenState();
}

class _TeacherProgressQuestionsScreenState
    extends State<TeacherProgressQuestionsScreen> {
  static const _storage = FlutterSecureStorage();
  static const _storageKey = 'snapmark_teacher_progress_question_sets';
  static const _draftBank = <String, List<_ProgressQuestion>>{
    'Data Structures': [
      _ProgressQuestion(
        question: 'Which data structure follows LIFO order?',
        options: ['Queue', 'Stack', 'Tree', 'Graph'],
        answer: 1,
      ),
      _ProgressQuestion(
        question: 'Which structure is typically used for breadth-first search?',
        options: ['Stack', 'Queue', 'Heap', 'Hash map'],
        answer: 1,
      ),
      _ProgressQuestion(
        question: 'What is the average lookup time in a hash table?',
        options: ['O(1)', 'O(n)', 'O(log n)', 'O(n²)'],
        answer: 0,
      ),
    ],
    'Computer Organization': [
      _ProgressQuestion(
        question: 'Which component performs arithmetic and logical operations?',
        options: ['ALU', 'Control Unit', 'Register', 'Cache'],
        answer: 0,
      ),
      _ProgressQuestion(
        question: 'Which memory is closest to the CPU core?',
        options: ['Hard disk', 'RAM', 'Register', 'Optical disk'],
        answer: 2,
      ),
      _ProgressQuestion(
        question: 'What does the control unit primarily do?',
        options: [
          'Stores files',
          'Directs instruction execution',
          'Displays output',
          'Cools the CPU',
        ],
        answer: 1,
      ),
    ],
    'Java Programming': [
      _ProgressQuestion(
        question: 'Which keyword lets a Java class inherit another class?',
        options: ['implements', 'extends', 'inherits', 'super'],
        answer: 1,
      ),
      _ProgressQuestion(
        question: 'Method overloading is based on different…',
        options: [
          'Return values only',
          'Parameter lists',
          'Class names',
          'Access levels only',
        ],
        answer: 1,
      ),
      _ProgressQuestion(
        question: 'Which type stores true or false?',
        options: ['int', 'String', 'boolean', 'char'],
        answer: 2,
      ),
    ],
    'Data Base Management System': [
      _ProgressQuestion(
        question: 'Which SQL command retrieves rows from a table?',
        options: ['INSERT', 'SELECT', 'UPDATE', 'DELETE'],
        answer: 1,
      ),
      _ProgressQuestion(
        question: 'Which key uniquely identifies a row?',
        options: ['Foreign key', 'Primary key', 'Index only', 'View'],
        answer: 1,
      ),
      _ProgressQuestion(
        question: 'What does normalization primarily reduce?',
        options: [
          'Data redundancy',
          'Query language',
          'Table names',
          'User roles',
        ],
        answer: 0,
      ),
    ],
    'Multivariable Calculus and Differential Equations': [
      _ProgressQuestion(
        question: 'What is the derivative of x²?',
        options: ['x', '2x', 'x²', '2'],
        answer: 1,
      ),
      _ProgressQuestion(
        question: 'A matrix with equal rows and columns is called…',
        options: ['Diagonal only', 'Square', 'Scalar only', 'Null'],
        answer: 1,
      ),
      _ProgressQuestion(
        question: 'What is the determinant of [[1, 0], [0, 1]]?',
        options: ['0', '1', '2', '-1'],
        answer: 1,
      ),
    ],
    'Advanced Aptitude Skill': [
      _ProgressQuestion(
        question:
            'If a value increases by 20% and then decreases by 20%, what is the net change?',
        options: ['No change', '4% decrease', '4% increase', '2% decrease'],
        answer: 1,
      ),
      _ProgressQuestion(
        question:
            'A train travels 120 km in 2 hours. What is its average speed?',
        options: ['40 km/h', '50 km/h', '60 km/h', '80 km/h'],
        answer: 2,
      ),
      _ProgressQuestion(
        question: 'What comes next in the sequence 2, 6, 12, 20, …?',
        options: ['24', '28', '30', '32'],
        answer: 2,
      ),
    ],
    'Design Thinking': [
      _ProgressQuestion(
        question: 'Which is usually the first step in design thinking?',
        options: ['Prototype', 'Empathize', 'Test', 'Launch'],
        answer: 1,
      ),
      _ProgressQuestion(
        question: 'What is the main goal of a prototype?',
        options: [
          'Explore and test an idea',
          'Finalize pricing',
          'Replace user research',
          'Measure attendance',
        ],
        answer: 0,
      ),
      _ProgressQuestion(
        question: 'Who should be at the center of a design-thinking process?',
        options: [
          'The end user',
          'The compiler',
          'The budget sheet',
          'The project schedule',
        ],
        answer: 0,
      ),
    ],
  };

  late final List<String> _courses =
      timetableSchedule.values
          .expand((day) => day)
          .map((item) => item['subject'])
          .whereType<String>()
          .toSet()
          .toList()
        ..sort();
  final _titleController = TextEditingController();
  final _questionController = TextEditingController();
  final _optionControllers = List.generate(4, (_) => TextEditingController());
  final List<_ProgressQuestion> _questions = [];
  List<Map<String, dynamic>> _savedSets = [];
  String? _selectedCourse;
  bool _showSaved = false;
  bool _loading = true;
  bool _saving = false;
  int? _editingQuestionIndex;
  bool _questionEditorOpen = false;
  int _correctAnswer = 0;

  @override
  void initState() {
    super.initState();
    _selectedCourse = _courses.isEmpty ? null : _courses.first;
    _loadSets();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _questionController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSets() async {
    try {
      final raw = await _storage.read(key: _storageKey);
      final decoded = raw == null
          ? <dynamic>[]
          : jsonDecode(raw) as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _savedSets = decoded
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
            .reversed
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _addManualQuestion() {
    _questionController.clear();
    for (final controller in _optionControllers) {
      controller.clear();
    }
    setState(() {
      _editingQuestionIndex = null;
      _correctAnswer = 0;
      _questionEditorOpen = true;
    });
  }

  void _editQuestion(int index) {
    final question = _questions[index];
    _questionController.text = question.question;
    for (var option = 0; option < _optionControllers.length; option++) {
      _optionControllers[option].text = question.options[option];
    }
    setState(() {
      _editingQuestionIndex = index;
      _correctAnswer = question.answer;
      _questionEditorOpen = true;
    });
  }

  void _saveQuestionDraft() {
    final question = _questionController.text.trim();
    final options = _optionControllers.map((item) => item.text.trim()).toList();
    if (question.isEmpty || options.any((option) => option.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a question and all four options.')),
      );
      return;
    }
    final updated = _ProgressQuestion(
      question: question,
      options: options,
      answer: _correctAnswer,
    );
    setState(() {
      final index = _editingQuestionIndex;
      if (index == null) {
        _questions.add(updated);
      } else {
        _questions[index] = updated;
      }
      _questionEditorOpen = false;
      _editingQuestionIndex = null;
    });
  }

  void _cancelQuestionDraft() => setState(() {
    _questionEditorOpen = false;
    _editingQuestionIndex = null;
  });

  void _addAiDraft() {
    final course = _selectedCourse;
    if (course == null) return;
    final normalizedCourse = course.replaceAll('Skills', 'Skill');
    final suggestions =
        _draftBank[course] ??
        _draftBank[normalizedCourse] ??
        _draftBank.values.first;
    setState(() => _questions.addAll(suggestions));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Sample draft added. Review and edit each question before saving.',
        ),
      ),
    );
  }

  Future<void> _saveQuestionSet() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _selectedCourse == null || _questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add a title, choose a course and include at least one question',
          ),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final record = <String, dynamic>{
      'title': title,
      'course': _selectedCourse,
      'createdAt': DateTime.now().toIso8601String(),
      'questions': _questions.map((item) => item.toJson()).toList(),
    };
    try {
      final raw = await _storage.read(key: _storageKey);
      final previous = raw == null
          ? <dynamic>[]
          : jsonDecode(raw) as List<dynamic>;
      await _storage.write(
        key: _storageKey,
        value: jsonEncode([...previous, record]),
      );
      if (!mounted) return;
      setState(() {
        _savedSets = [record, ..._savedSets];
        _questions.clear();
        _titleController.clear();
        _showSaved = true;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Question set saved on this device. Student assignment is not connected yet.',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not save this question set. Please try again.',
            ),
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
      appBar: AppBar(title: const Text('Progress questions')),
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
                        _QuestionTab(
                          label: 'Build a question set',
                          selected: !_showSaved,
                          onTap: () => setState(() => _showSaved = false),
                        ),
                        _QuestionTab(
                          label: 'Saved sets',
                          count: _savedSets.length,
                          selected: _showSaved,
                          onTap: () => setState(() => _showSaved = true),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _showSaved
                      ? _savedSetList(colors, muted)
                      : _questionBuilder(colors, muted),
                ),
              ],
            ),
    );
  }

  Widget _questionBuilder(ColorScheme colors, Color muted) => Column(
    children: [
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 15),
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Progress check title',
                hintText: 'e.g. Week 4 understanding check',
                filled: true,
                fillColor: colors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 11),
            DropdownButtonFormField<String>(
              initialValue: _selectedCourse,
              decoration: InputDecoration(
                labelText: 'Course',
                filled: true,
                fillColor: colors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              items: [
                for (final course in _courses)
                  DropdownMenuItem(
                    value: course,
                    child: Text(
                      course,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) => setState(() => _selectedCourse = value),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xff6558D8).withValues(alpha: .10),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: const Color(0xff8B7BFF).withValues(alpha: .20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xffB3A1FF),
                        size: 17,
                      ),
                      const SizedBox(width: 7),
                      const Expanded(
                        child: Text(
                          'AI question ideas',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _addAiDraft,
                        icon: const Icon(Icons.bolt_rounded, size: 15),
                        label: const Text(
                          'Draft 3',
                          style: TextStyle(fontSize: 10),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Sample subject-based suggestions only. Live AI is not connected; review and edit before saving.',
                    style: TextStyle(color: muted, fontSize: 9, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 17),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Questions (${_questions.length})',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _addManualQuestion,
                  icon: const Icon(Icons.add_rounded, size: 17),
                  label: const Text(
                    'Write manually',
                    style: TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),
            if (_questionEditorOpen)
              _questionEditor(colors)
            else if (_questions.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  'Add your own question or draft subject-based ideas, then tap a question to review it.',
                  style: TextStyle(color: muted, fontSize: 10, height: 1.4),
                ),
              )
            else
              for (var index = 0; index < _questions.length; index++)
                _QuestionCard(
                  index: index,
                  question: _questions[index],
                  onTap: () => _editQuestion(index),
                  onRemove: () => setState(() => _questions.removeAt(index)),
                ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 7, 20, 14),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: _saving ? null : _saveQuestionSet,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.lock_outline_rounded, size: 18),
            label: Text(_saving ? 'Saving…' : 'Save question set'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xff637FFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _questionEditor(ColorScheme colors) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: colors.surface,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: colors.onSurface.withValues(alpha: .08)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _editingQuestionIndex == null ? 'Write a question' : 'Edit question',
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _questionController,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Question'),
        ),
        for (var index = 0; index < _optionControllers.length; index++)
          TextField(
            controller: _optionControllers[index],
            decoration: InputDecoration(
              labelText: 'Option ${String.fromCharCode(65 + index)}',
            ),
          ),
        const SizedBox(height: 10),
        Text(
          'Choose the correct answer',
          style: TextStyle(
            color: colors.onSurface.withValues(alpha: .65),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 7,
          children: [
            for (var index = 0; index < 4; index++)
              ChoiceChip(
                label: Text(String.fromCharCode(65 + index)),
                selected: _correctAnswer == index,
                onSelected: (_) => setState(() => _correctAnswer = index),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _cancelQuestionDraft,
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _saveQuestionDraft,
              icon: const Icon(Icons.check_rounded, size: 17),
              label: const Text('Done'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _savedSetList(ColorScheme colors, Color muted) {
    if (_savedSets.isEmpty) {
      return Center(
        child: Text(
          'No saved progress checks yet',
          style: TextStyle(color: muted, fontSize: 12),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      itemCount: _savedSets.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final set = _savedSets[index];
        final items = set['questions'] as List<dynamic>? ?? const [];
        final created = DateTime.tryParse(set['createdAt'] as String? ?? '');
        return Container(
          padding: const EdgeInsets.all(14),
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
                  color: const Color(0xff728BFF).withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.quiz_rounded,
                  color: Color(0xff93A9FF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      set['title'] as String? ?? 'Progress check',
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
                      '${set['course'] ?? 'Course'}  ·  ${items.length} questions',
                      style: TextStyle(color: muted, fontSize: 9),
                    ),
                  ],
                ),
              ),
              if (created != null)
                Text(
                  '${created.day}/${created.month}',
                  style: TextStyle(color: muted, fontSize: 9),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ProgressQuestion {
  const _ProgressQuestion({
    required this.question,
    required this.options,
    required this.answer,
  });
  final String question;
  final List<String> options;
  final int answer;
  Map<String, dynamic> toJson() => {
    'question': question,
    'options': options,
    'answer': answer,
  };
}

class _QuestionTab extends StatelessWidget {
  const _QuestionTab({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });
  final String label;
  final bool selected;
  final int? count;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? const Color(0xff637FFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
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
            if (count != null) ...[
              const SizedBox(width: 5),
              Text(
                '$count',
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: .65),
                  fontSize: 9,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.index,
    required this.question,
    required this.onTap,
    required this.onRemove,
  });
  final int index;
  final _ProgressQuestion question;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.fromLTRB(12, 10, 5, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.onSurface.withValues(alpha: .06)),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xff718AFF).withValues(alpha: .13),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Color(0xffAFC0FF),
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
                      question.question,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '4 choices · tap to edit',
                      style: TextStyle(
                        color: colors.onSurface.withValues(alpha: .55),
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onRemove,
                icon: Icon(
                  Icons.close_rounded,
                  color: colors.onSurface.withValues(alpha: .45),
                  size: 17,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
