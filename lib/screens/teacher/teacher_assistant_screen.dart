import 'package:flutter/material.dart';

import '../timetable/timetable_screen.dart';
import '../../core/services/campus_help_service.dart';

class TeacherAssistantScreen extends StatefulWidget {
  const TeacherAssistantScreen({super.key});

  @override
  State<TeacherAssistantScreen> createState() => _TeacherAssistantScreenState();
}

class _TeacherAssistantScreenState extends State<TeacherAssistantScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_TeacherChatMessage> _messages = [
    const _TeacherChatMessage(
      text:
          'Namaste! Aap student progress, class-time phone activity, ya next class aur room ke baare mein pooch sakte hain.',
      fromUser: false,
    ),
  ];

  static const _suggestions = [
    'Kaun sa student weak hai?',
    'Sabse zyada phone kisne use kiya?',
    'Meri next class kab aur kahan hai?',
    'Kis subject mein students weak hain?',
    'Where is the stationery shop?',
    'Medical room kahan hai?',
    'ERP office kahan hai?',
    'How do I pay fees by NEFT?',
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send([String? suggestedQuestion]) {
    final question = (suggestedQuestion ?? _inputController.text).trim();
    if (question.isEmpty) return;
    setState(() {
      _messages
        ..add(_TeacherChatMessage(text: question, fromUser: true))
        ..add(_TeacherChatMessage(text: _answer(question), fromUser: false));
    });
    _inputController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _answer(String question) {
    final campusReply = CampusHelpService.replyTo(question);
    if (campusReply != null) return campusReply;
    final query = question.toLowerCase();
    if (_hasAny(query, [
      'next class',
      'next lecture',
      'schedule',
      'timetable',
      'room',
      'kab hai',
      'kahan hai',
    ])) {
      return _nextClassAnswer();
    }
    if (_hasAny(query, [
      'phone',
      'mobile',
      'screen time',
      'use kiya',
      'phone use',
    ])) {
      const samplePhoneUse = [
        _StudentSample('Aarav Sharma', 27),
        _StudentSample('Kabir Singh', 18),
        _StudentSample('Riya Verma', 10),
        _StudentSample('Dev Patel', 6),
      ];
      final top = samplePhoneUse.reduce(
        (a, b) => a.minutes >= b.minutes ? a : b,
      );
      return 'Sample Class Focus data ke hisaab se ${top.name} ne sabse zyada phone use kiya: ${top.minutes} min in a 50-minute class. Live phone-activity tracking connected nahi hai.';
    }
    if (_hasAny(query, [
      'weak',
      'kamzor',
      'struggling',
      'low progress',
      'padhai',
    ])) {
      const samples = [
        _StudentProgressSample('Riya Verma', 'Data Structures', 46),
        _StudentProgressSample('Aarav Sharma', 'Java Programming', 58),
        _StudentProgressSample(
          'Kabir Singh',
          'Data Base Management System',
          74,
        ),
        _StudentProgressSample(
          'Dev Patel',
          'Multivariable Calculus and Differential Equations',
          81,
        ),
        _StudentProgressSample('Meera Jain', 'Computer Organization', 62),
        _StudentProgressSample('Ishaan Roy', 'Design Thinking', 69),
        _StudentProgressSample('Sana Kapoor', 'Advanced Aptitude Skill', 71),
      ];
      final lowest = samples.reduce((a, b) => a.progress <= b.progress ? a : b);
      if (_hasAny(query, ['subject', 'kis subject', 'topic'])) {
        return 'Sample progress data mein ${lowest.subject} sabse zyada support maang raha hai (${lowest.progress}% average). Student-wise live assessment records connected nahi hain.';
      }
      return 'Sample progress data mein ${lowest.name} ka progress sabse kam hai (${lowest.progress}%), khaaskar ${lowest.subject} mein. Isse support ke liye check-in signal samjhein, final judgement nahi. Live student records connected nahi hain.';
    }
    if (_hasAny(query, ['hello', 'hi', 'namaste', 'help'])) {
      return 'Aap pooch sakte hain: kaun weak hai, phone sabse zyada kisne use kiya, kis subject mein support chahiye, ya next class kab aur kis room mein hai.';
    }
    return 'Main demo student progress, class-time phone use, aur timetable ke baare mein jawab de sakta hoon. Upar suggestions tap karke try karein. Live AI aur student records abhi connected nahi hain.';
  }

  String _nextClassAnswer() {
    final now = DateTime.now();
    for (var offset = 0; offset < 7; offset++) {
      final date = now.add(Duration(days: offset));
      final dayClasses = timetableSchedule[date.weekday - 1] ?? const [];
      final upcoming = <({Map<String, String> item, DateTime start})>[];
      for (final item in dayClasses) {
        final start = _parseStartTime(item['time'] ?? '', date);
        if (start != null && start.isAfter(now)) {
          upcoming.add((item: item, start: start));
        }
      }
      if (upcoming.isNotEmpty) {
        upcoming.sort((a, b) => a.start.compareTo(b.start));
        final next = upcoming.first;
        final dayLabel = offset == 0
            ? 'today'
            : offset == 1
            ? 'tomorrow'
            : _weekday(date.weekday);
        final time = _formatTime(next.start);
        return 'Aapki next scheduled class $dayLabel ${next.item['subject'] ?? 'class'} hai, $time par, room ${next.item['room'] ?? 'not listed'} mein. Timetable demo data hai; faculty schedule sync connected nahi hai.';
      }
    }
    return 'Timetable mein agle 7 din ke liye koi valid upcoming class nahi mili. Timetable screen mein schedule check karein.';
  }

  DateTime? _parseStartTime(String range, DateTime date) {
    final startText = range.split(' - ').first.trim();
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(startText);
    if (match == null) return null;
    var hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    final period = match.group(3)!.toUpperCase();
    if (hour == null ||
        minute == null ||
        hour < 1 ||
        hour > 12 ||
        minute > 59) {
      return null;
    }
    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  String _weekday(int day) => const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ][day - 1];

  String _formatTime(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${value.hour >= 12 ? 'PM' : 'AM'}';
  }

  bool _hasAny(String value, List<String> terms) => terms.any(value.contains);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 31,
              height: 31,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xff16C7D9),
                    Color(0xff3977FF),
                    Color(0xffA45BFF),
                  ],
                ),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 17,
              ),
            ),
            const SizedBox(width: 9),
            Text(
              'SnapMark AI',
              style: TextStyle(
                color: colors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: colors.onSurface),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Ask about classes, fees or campus locations. Student metrics and timetable still use demo data.',
                style: TextStyle(
                  color: colors.onSurface.withValues(alpha: .68),
                  fontSize: 10,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) =>
                    _messageBubble(context, _messages[index]),
              ),
            ),
            SizedBox(
              height: 42,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                scrollDirection: Axis.horizontal,
                itemCount: _suggestions.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) => ActionChip(
                  label: Text(_suggestions[index]),
                  onPressed: () => _send(_suggestions[index]),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Teacher se related kuch poochho…',
                        filled: true,
                        fillColor: colors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _send,
                    tooltip: 'Send message',
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _messageBubble(BuildContext context, _TeacherChatMessage message) {
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: message.fromUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * .82,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: message.fromUser ? Colors.blueAccent : colors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(message.fromUser ? 18 : 5),
            bottomRight: Radius.circular(message.fromUser ? 5 : 18),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.fromUser ? Colors.white : colors.onSurface,
            height: 1.4,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _TeacherChatMessage {
  const _TeacherChatMessage({required this.text, required this.fromUser});
  final String text;
  final bool fromUser;
}

class _StudentSample {
  const _StudentSample(this.name, this.minutes);
  final String name;
  final int minutes;
}

class _StudentProgressSample {
  const _StudentProgressSample(this.name, this.subject, this.progress);
  final String name;
  final String subject;
  final int progress;
}
