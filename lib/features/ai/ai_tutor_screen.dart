import 'package:flutter/material.dart';

class AiTutorScreen extends StatefulWidget {
  const AiTutorScreen({super.key});

  @override
  State<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends State<AiTutorScreen> {
  final _promptController = TextEditingController();
  final _promptFocus = FocusNode();
  bool _isListening = false;

  @override
  void dispose() {
    _promptController.dispose();
    _promptFocus.dispose();
    super.dispose();
  }

  void _usePrompt(String prompt) {
    _promptController.text = prompt;
    _promptFocus.requestFocus();
  }

  void _send() {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your tutor is ready for an LLM connection.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF11121B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF11121B),
        title: const Text(
          'AI Tutor',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF163D6D),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFF2E74B7)),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome, color: Color(0xFF28A4FF), size: 16),
                SizedBox(width: 7),
                Text(
                  'Auto',
                  style: TextStyle(
                    color: Color(0xFF62B9FF),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF62B9FF),
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 14),
                child: Column(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: const Color(0xFF11121B),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1597F5)
                                .withValues(alpha: 0.3),
                            blurRadius: 28,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.smart_toy_rounded,
                          color: Color(0xFF1597F5),
                          size: 72,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: "Hey, let's learn ",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 27,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(
                            text: 'Python',
                            style: TextStyle(
                              color: Color(0xFF1F9EFF),
                              fontSize: 27,
                              fontWeight: FontWeight.w800,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ask anything — loops, errors, ideas, quizzes.',
                      style: TextStyle(color: Color(0xFFD3D4DD), fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 26),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 1.05,
                      children: [
                        _PromptCard(
                          icon: Icons.sync_rounded,
                          iconColor: const Color(0xFF1697F5),
                          title: 'Explain loops',
                          subtitle: 'for & while, simply',
                          onTap: () =>
                              _usePrompt('Explain for and while loops simply'),
                        ),
                        _PromptCard(
                          icon: Icons.help_outline_rounded,
                          iconColor: const Color(0xFFD0B5FF),
                          title: 'Quiz me',
                          subtitle: 'strings checkpoint',
                          onTap: () => _usePrompt('Quiz me on Python strings'),
                        ),
                        _PromptCard(
                          icon: Icons.build_rounded,
                          iconColor: const Color(0xFFFFB81C),
                          title: 'Fix my code',
                          subtitle: 'paste the error',
                          onTap: () =>
                              _usePrompt('Help me fix this Python error: '),
                        ),
                        _PromptCard(
                          icon: Icons.emoji_events_rounded,
                          iconColor: const Color(0xFF7CF000),
                          title: 'Challenge',
                          subtitle: "today's pickup",
                          onTap: () => _usePrompt(
                            'Give me a fun Python challenge for today',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            _Composer(
              controller: _promptController,
              focusNode: _promptFocus,
              isListening: _isListening,
              onMic: () => setState(() => _isListening = !_isListening),
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF191A24),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFF343541)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: iconColor.withValues(alpha: 0.5)),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFFD3D4DD), fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.isListening,
    required this.onMic,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isListening;
  final VoidCallback onMic;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 18),
      decoration: const BoxDecoration(
        color: Color(0xFF11121B),
        border: Border(top: BorderSide(color: Color(0xFF2A2B35))),
      ),
      child: Container(
        padding: const EdgeInsets.only(left: 16, right: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF20212D),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFF3C3D4A)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                style: const TextStyle(color: Colors.white),
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Why is my function crashing?',
                  hintStyle: TextStyle(color: Color(0xFF9294A2)),
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              onPressed: onMic,
              tooltip: 'Voice input',
              icon: Icon(
                isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: const Color(0xFF1597F5),
              ),
            ),
            IconButton(
              onPressed: onSend,
              tooltip: 'Send to tutor',
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF373846),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.arrow_upward_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
