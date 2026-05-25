import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(historyProvider),
          ),
        ],
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (e, _) => Center(child: Text('Failed to load history.\n${apiError(e)}', textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.onSurfaceMuted))),
        data: (conversations) => conversations.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.history_outlined, color: AppTheme.onSurfaceMuted, size: 48),
                const SizedBox(height: 16),
                Text('No conversations yet', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Start analyzing food with the AI chat', style: Theme.of(context).textTheme.bodyMedium),
              ]))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: conversations.length,
                itemBuilder: (ctx, i) {
                  final c = conversations[i];
                  return Dismissible(
                    key: Key(c.sessionId),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.delete_outline, color: AppTheme.danger),
                    ),
                    onDismissed: (_) async {
                      await ApiService.instance.deleteConversation(c.sessionId);
                      ref.invalidate(historyProvider);
                    },
                    child: GestureDetector(
                      onTap: () => context.push('/conversation/${c.sessionId}'),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: c.title.startsWith('Compare:') ? AppTheme.info.withOpacity(0.1) : AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              c.title.startsWith('Compare:') ? Icons.compare_arrows_rounded : Icons.chat_bubble_outline_rounded,
                              color: c.title.startsWith('Compare:') ? AppTheme.info : AppTheme.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(c.title, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(
                              '${c.messageCount} messages · ${_formatDate(c.lastMessageAt)}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ])),
                          const Icon(Icons.chevron_right_rounded, color: AppTheme.onSurfaceMuted),
                        ]),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
