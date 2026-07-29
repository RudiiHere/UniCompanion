import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../config/app_theme.dart';
import '../../widgets/common_widgets.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final _msgCtrl    = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_AiMsg> _messages = [];
  bool _loading = false;

  static const _suggestions = [
    'Explain deadlock in OS',
    'What is Big-O notation?',
    'Summarize my OS notes PDF',
    'Help me debug my code',
    'What is a binary search tree?',
    'Explain TCP vs UDP',
  ];

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String content) async {
    if (content.trim().isEmpty) return;
    _msgCtrl.clear();
    setState(() {
      _messages.add(_AiMsg(role: 'user', content: content.trim()));
      _loading = true;
    });
    _scrollDown();

    try {
      // AiService manages conversation history internally and takes a single
      // positional message argument.
      final response = await ref.read(aiServiceProvider).chat(content.trim());
      if (mounted) {
        setState(() {
          _messages.add(_AiMsg(role: 'assistant', content: response));
          _loading = false;
        });
        _scrollDown();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(_AiMsg(role: 'assistant', content: 'Sorry, I ran into an error. Please try again.'));
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome_rounded, size: 15, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Study Assistant'),
                Text('Powered by Gemini', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w400)),
              ],
            ),
          ],
        ),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              tooltip: 'Clear chat',
              onPressed: () {
                ref.read(aiServiceProvider).clearHistory();
                setState(() => _messages.clear());
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _EmptyAiState(suggestions: _suggestions, onTap: _send)
                : ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (_, i) {
                if (_loading && i == _messages.length) return const _TypingIndicator();
                return _AiBubble(msg: _messages[i]);
              },
            ),
          ),

          // ── Input bar ──────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(top: BorderSide(color: cs.outline, width: 0.5)),
            ),
            padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).viewInsets.bottom + 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: const InputDecoration(hintText: 'Ask anything about your studies…'),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (v) => _send(v),
                    maxLines: 3, minLines: 1,
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: GestureDetector(
                    onTap: _loading ? null : () => _send(_msgCtrl.text),
                    child: Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _loading
                          ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
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
}

class _AiMsg {
  final String role;
  final String content;
  const _AiMsg({required this.role, required this.content});
}

class _EmptyAiState extends StatelessWidget {
  final List<String> suggestions;
  final Function(String) onTap;
  const _EmptyAiState({required this.suggestions, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 16),
        Center(
          child: Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: AppTheme.indigo.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: const Icon(Icons.auto_awesome_rounded, size: 30, color: Colors.white),
          ),
        ),
        const SizedBox(height: 16),
        const Center(child: Text('Your AI Study Assistant', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.4))),
        const SizedBox(height: 6),
        Center(child: Text('Ask me anything about your courses', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant))),
        const SizedBox(height: 28),
        const SectionHeader(title: 'Suggested prompts'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: suggestions.map((s) => GestureDetector(
            onTap: () => onTap(s),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.indigoSoft,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: AppTheme.indigo.withValues(alpha: 0.2)),
              ),
              child: Text(s, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.indigo)),
            ),
          )).toList(),
        ),
      ],
    );
  }
}

class _AiBubble extends StatelessWidget {
  final _AiMsg msg;
  const _AiBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.role == 'user';
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome_rounded, size: 15, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: msg.content));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 1)),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
                decoration: BoxDecoration(
                  color: isUser ? AppTheme.indigo : cs.surfaceVariant,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 16),
                  ),
                ),
                child: Text(
                  msg.content,
                  style: TextStyle(
                    fontSize: 13, height: 1.55,
                    color: isUser ? Colors.white : cs.onSurface,
                  ),
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome_rounded, size: 15, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: cs.surfaceVariant, borderRadius: BorderRadius.circular(16)),
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final delay = i / 3.0;
                  final val = ((_ctrl.value - delay) % 1.0).clamp(0.0, 1.0);
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 7, height: 7,
                    decoration: BoxDecoration(
                      color: AppTheme.indigo.withValues(alpha: 0.3 + 0.7 * (val < 0.5 ? val * 2 : (1 - val) * 2)),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
