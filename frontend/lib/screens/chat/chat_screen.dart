import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/api_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Uint8List? _pendingImageBytes;
  String? _uploadedImageUrl;
  bool _uploading = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 1200);
    if (xfile == null) return;
    final bytes = await xfile.readAsBytes();
    setState(() { _pendingImageBytes = bytes; _uploading = true; });
    try {
      final url = await ApiService.instance.uploadImage(xfile);
      setState(() { _uploadedImageUrl = url; _uploading = false; });
    } catch (e) {
      setState(() { _pendingImageBytes = null; _uploading = false; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed: ${apiError(e)}')),
      );
    }
  }

  void _showImageSource() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined, color: AppTheme.primary),
            title: const Text('Take a photo'),
            onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: AppTheme.primary),
            title: const Text('Choose from gallery'),
            onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
          ),
        ]),
      ),
    );
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty && _uploadedImageUrl == null) return;
    _msgCtrl.clear();
    final imgUrl = _uploadedImageUrl;
    setState(() { _pendingImageBytes = null; _uploadedImageUrl = null; });
    await ref.read(chatProvider.notifier).send(text.isEmpty ? 'Please analyze this image.' : text, imageUrl: imgUrl);
    _scrollToBottom();
  }

  Widget _buildMessage(ChatMessage msg) {
    final isUser = msg.role == MessageRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        child: Column(crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
          if (!isUser) Row(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.restaurant_menu_rounded, color: AppTheme.primary, size: 16),
            ),
            const SizedBox(width: 8),
            Text('NutriScan AI', style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.primary,
            )),
          ]),
          if (!isUser) const SizedBox(height: 8),
          if (msg.imageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: msg.imageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
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
                        listBullet: const TextStyle(color: AppTheme.onSurfaceMuted),
                      ),
                    ),
            ),
        ]),
      ),
    );
  }

  Widget _buildEmptyState() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.document_scanner_outlined, color: AppTheme.primary, size: 40),
          ),
          const SizedBox(height: 24),
          Text('Analyze any food', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Take a photo of a nutrition label or food\nand ask any question about it.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
            for (final q in [
              'Is this safe for me?',
              'How much protein?',
              'Is this healthy?',
              'Check for allergens',
            ])
              GestureDetector(
                onTap: () { _msgCtrl.text = q; },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(q, style: const TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 13)),
                ),
              ),
          ]),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(chat.messages.isEmpty ? 'NutriScan AI' : 'AI Analysis'),
        actions: [
          if (chat.messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.add_comment_outlined),
              onPressed: () => ref.read(chatProvider.notifier).newSession(),
              tooltip: 'New chat',
            ),
        ],
      ),
      body: Column(children: [
        Expanded(child: chat.messages.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(16),
                itemCount: chat.messages.length + (chat.isSending ? 1 : 0),
                itemBuilder: (ctx, i) {
                  if (i == chat.messages.length) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border, width: 0.5),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          for (int j = 0; j < 3; j++) ...[
                            TweenAnimationBuilder(
                              tween: Tween(begin: 0.3, end: 1.0),
                              duration: Duration(milliseconds: 400 + j * 150),
                              builder: (_, val, __) => Opacity(
                                opacity: val,
                                child: Container(width: 6, height: 6, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(3))),
                              ),
                            ),
                            if (j < 2) const SizedBox(width: 5),
                          ],
                        ]),
                      ),
                    );
                  }
                  return _buildMessage(chat.messages[i]);
                },
              )),
        if (chat.error != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Text(chat.error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13)),
          ),
        if (_pendingImageBytes != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 80,
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(_pendingImageBytes!, width: 80, height: 80, fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              if (_uploading)
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
              else
                const Icon(Icons.check_circle, color: AppTheme.primary),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppTheme.onSurfaceMuted),
                onPressed: () => setState(() { _pendingImageBytes = null; _uploadedImageUrl = null; }),
              ),
            ]),
          ),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          decoration: const BoxDecoration(
            color: AppTheme.surfaceCard,
            border: Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
          ),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.camera_alt_outlined, color: AppTheme.primary),
              onPressed: _showImageSource,
            ),
            Expanded(child: TextField(
              controller: _msgCtrl,
              maxLines: null,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'Ask about any food or nutrition label...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                filled: true,
                fillColor: AppTheme.surfaceElevated,
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
            )),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: chat.isSending || _uploading ? null : _send,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: chat.isSending || _uploading ? AppTheme.border : AppTheme.primary,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: chat.isSending || _uploading ? AppTheme.onSurfaceMuted : const Color(0xFF001A12),
                  size: 20,
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
