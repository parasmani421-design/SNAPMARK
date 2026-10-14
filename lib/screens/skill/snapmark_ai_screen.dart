import 'package:flutter/material.dart';

import '../../core/services/snapmark_assistant_service.dart';

class SnapMarkAiScreen extends StatefulWidget {
  const SnapMarkAiScreen({super.key});

  @override
  State<SnapMarkAiScreen> createState() => _SnapMarkAiScreenState();
}

class _SnapMarkAiScreenState extends State<SnapMarkAiScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _assistant = const SnapMarkAssistantService();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text:
          'Hi Paras! Ask me about attendance, subject targets, fees, timetable, or study planning.',
      fromUser: false,
    ),
  ];

  static const _suggestions = [
    'Check my attendance',
    'How many classes to reach 75%?',
    'Am I at risk of debarment?',
    'Give me study tips',
    'Where is the stationery shop?',
    'Medical room kahan hai?',
    'ERP office kaha hai?',
    'How do I pay fees by NEFT?',
    'Where is the stationery shop?',
    'Medical room kahan hai?',
    'ERP office kaha hai?',
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
        ..add(_ChatMessage(text: question, fromUser: true))
        ..add(
          _ChatMessage(text: _assistant.replyTo(question), fromUser: false),
        );
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'SnapMark AI',
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.bold,
          ),
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
                'Ask about classes, fees or campus locations. Campus locations use admin-editable demo information.',
                style: TextStyle(
                  color: colors.onSurface.withValues(alpha: .68),
                  fontSize: 11,
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
                separatorBuilder: (context, index) => const SizedBox(width: 8),
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
                        hintText: 'Ask SnapMark…',
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

  Widget _messageBubble(BuildContext context, _ChatMessage message) {
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

class _ChatMessage {
  final String text;
  final bool fromUser;

  const _ChatMessage({required this.text, required this.fromUser});
}
