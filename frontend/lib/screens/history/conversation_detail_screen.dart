import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../providers/providers.dart';

class ConversationDetailScreen extends ConsumerStatefulWidget {
  final String sessionId;
  const ConversationDetailScreen({super.key, required this.sessionId});

  @override
  ConsumerState<ConversationDetailScreen> createState() => _ConversationDetailScreenState();
}

class _ConversationDetailScreenState extends ConsumerState<ConversationDetailScreen> {
  List<ChatMessage>? _messages;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final msgs = await ApiService.instance.getConversation(widget.sessionId);
      if (mounted) setState(() { _messages = msgs; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = apiError(e); _loading = false; });
    }
  }

  void _continueInChat() {
    final messages = _messages ?? [];
    ref.read(chatProvider.notifier).setSession(widget.sessionId, messages);
    context.go('/home');
  }

  Widget _buildMessage(ChatMessage msg) {
    final isUser = msg.role == MessageRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        child: Column(crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
          if (!isUser) Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.restaurant_menu_rounded, color: AppTheme.primary, size: 14),
              ),
              const SizedBox(width: 6),
              Text('NutriScan AI', style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600, fontSize: 11, color: AppTheme.primary,
              )),
            ]),
          ),
          if (msg.imageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(imageUrl: msg.imageUrl!, height: 160, width: double.infinity, fit: BoxFit.cover),
            ),
            const SizedBox(height: 8),
          ],
          if (msg.content.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.primary : AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomRight: isUser ? const Radius.circular(4) : null,
                  bottomLeft: !isUser ? const Radius.circular(4) : null,
                ),
                border: isUser ? null : Border.all(color: AppTheme.border, width: 0.5),
              ),
              child: isUser
                  ? Text(msg.content, style: const TextStyle(color: Color(0xFF001A12), fontSize: 15))
                  : MarkdownBody(
                      data: msg.content,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(color: AppTheme.onSurface, fontSize: 15, height: 1.6),
                        strong: const TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w600),
                      ),
                    ),
            ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('Conversation'),
        actions: [
          TextButton.icon(
            onPressed: _continueInChat,
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
            label: const Text('Continue'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppTheme.onSurfaceMuted)))
              : _messages!.isEmpty
                  ? const Center(child: Text('No messages', style: TextStyle(color: AppTheme.onSurfaceMuted)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages!.length,
                      itemBuilder: (_, i) => _buildMessage(_messages![i]),
                    ),
    );
  }
}
