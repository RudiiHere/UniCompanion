import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/app_providers.dart';
import '../../models/app_models.dart';
import '../../config/app_theme.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {

  static const _roomId = 'global';

  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  final List<ChatMessage> _messages = [];
  bool _loading = true;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final db = ref.read(dbServiceProvider);

    // 1. Load the recent history once.
    final initial = await db.getMessages(_roomId);
    if (!mounted) return;
    setState(() {
      _messages
        ..clear()
        ..addAll(initial);
      _loading = false;
    });
    _scrollToBottom();


    _channel = db.subscribeToMessages(_roomId, _onIncoming);
  }

  void _onIncoming(ChatMessage msg) {
    if (!mounted) return;

    if (_messages.any((m) => m.id == msg.id)) return;
    setState(() => _messages.add(msg));
    _scrollToBottom();
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;
    final profile = ref.read(currentProfileProvider).value;

    final msg = ChatMessage(
      id: const Uuid().v4(),
      roomId: _roomId,
      content: text,
      userId: user.id,
      userName: profile?.fullName ?? 'You',
      createdAt: DateTime.now(),
    );

    _msgCtrl.clear();


    setState(() => _messages.add(msg));
    _scrollToBottom();

    try {
      await ref.read(dbServiceProvider).sendMessage(msg);
    } on PostgrestException catch (e) {

      if (!mounted) return;
      setState(() => _messages.removeWhere((m) => m.id == msg.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send: ${e.message}')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _messages.removeWhere((m) => m.id == msg.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message failed to send. Check your connection.')),
      );
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).value;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Community Chat'),
            Text(
              'Everyone on UniCompanion',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
      body: Column(
        children: [

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.forum_outlined, size: 48, color: cs.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text('No messages yet', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('Be the first to say something!',
                      style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 12)),
                ],
              ),
            )
                : ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final msg = _messages[i];
                final isMine = msg.userId == profile?.id;
                return _MessageBubble(msg: msg, isMine: isMine);
              },
            ),
          ),


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
                    decoration: const InputDecoration(
                      hintText: 'Message everyone…',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(color: AppTheme.indigo, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
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

class _MessageBubble extends StatelessWidget {
  final ChatMessage msg;
  final bool isMine;
  const _MessageBubble({required this.msg, required this.isMine});

  Color _avatarColor(String name) {
    final colors = [AppTheme.indigo, AppTheme.emerald, AppTheme.amber, AppTheme.sky, AppTheme.violet, AppTheme.rose];
    return colors[name.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _avatarColor(msg.userName);
    final initials = msg.userName.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
    final time = DateFormat('h:mm a').format(msg.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMine) ...[
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Center(child: Text(initials, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color))),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMine)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 2),
                    child: Text(msg.userName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cs.onSurface)),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                  decoration: BoxDecoration(
                    color: isMine ? AppTheme.indigo : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMine ? 16 : 4),
                      bottomRight: Radius.circular(isMine ? 4 : 16),
                    ),
                  ),
                  child: Text(
                    msg.content,
                    style: TextStyle(fontSize: 13, height: 1.4, color: isMine ? Colors.white : cs.onSurface),
                  ),
                ),
                const SizedBox(height: 3),
                Text(time, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          if (isMine) const SizedBox(width: 8),
        ],
      ),
    );
  }
}