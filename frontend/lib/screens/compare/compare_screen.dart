import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';

class _ProductEntry {
  final String id;
  String name;
  Uint8List? localImageBytes;
  String? uploadedUrl;
  bool uploading = false;

  _ProductEntry({required this.id, this.name = ''});
}

class CompareScreen extends ConsumerStatefulWidget {
  const CompareScreen({super.key});
  @override
  ConsumerState<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends ConsumerState<CompareScreen> {
  final List<_ProductEntry> _products = [
    _ProductEntry(id: '1', name: 'Product 1'),
    _ProductEntry(id: '2', name: 'Product 2'),
  ];
  bool _comparing = false;
  CompareResult? _result;
  String? _error;

  Future<void> _pickImage(int index, ImageSource source) async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 1200);
    if (xfile == null) return;
    final bytes = await xfile.readAsBytes();
    setState(() { _products[index].localImageBytes = bytes; _products[index].uploading = true; });
    try {
      final url = await ApiService.instance.uploadImage(xfile);
      setState(() { _products[index].uploadedUrl = url; _products[index].uploading = false; });
    } catch (e) {
      setState(() { _products[index].localImageBytes = null; _products[index].uploading = false; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: ${apiError(e)}')));
    }
  }

  Future<void> _compare() async {
    final ready = _products.where((p) => p.uploadedUrl != null).toList();
    if (ready.length < 2) {
      setState(() => _error = 'Please upload images for at least 2 products.');
      return;
    }
    setState(() { _comparing = true; _result = null; _error = null; });
    try {
      final result = await ApiService.instance.compareProducts(
        ready.map((p) => {'name': p.name, 'image_url': p.uploadedUrl!}).toList(),
      );
      setState(() { _result = result; _comparing = false; });
    } catch (e) {
      setState(() { _error = apiError(e); _comparing = false; });
    }
  }

  Widget _buildProductCard(int index) {
    final p = _products[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.uploadedUrl != null ? AppTheme.primary.withOpacity(0.4) : AppTheme.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: TextFormField(
            initialValue: p.name,
            decoration: InputDecoration(
              labelText: 'Product ${index + 1} name',
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              isDense: true,
            ),
            onChanged: (v) => p.name = v,
          )),
          if (_products.length > 2) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: AppTheme.danger),
              onPressed: () => setState(() => _products.removeAt(index)),
            ),
          ],
        ]),
        const SizedBox(height: 12),
        if (p.localImageBytes != null)
          Stack(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(p.localImageBytes!, height: 140, width: double.infinity, fit: BoxFit.cover),
            ),
            if (p.uploading)
              Container(
                height: 140, decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                child: const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
              )
            else if (p.uploadedUrl != null)
              Positioned(top: 8, right: 8, child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              )),
            Positioned(bottom: 8, right: 8, child: GestureDetector(
              onTap: () => setState(() { p.localImageBytes = null; p.uploadedUrl = null; }),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            )),
          ])
        else
          GestureDetector(
            onTap: () => showModalBottomSheet(
              context: context,
              backgroundColor: AppTheme.surfaceCard,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
              builder: (_) => Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  ListTile(leading: const Icon(Icons.camera_alt_outlined, color: AppTheme.primary), title: const Text('Take photo'),
                    onTap: () { Navigator.pop(context); _pickImage(index, ImageSource.camera); }),
                  ListTile(leading: const Icon(Icons.photo_library_outlined, color: AppTheme.primary), title: const Text('Choose from gallery'),
                    onTap: () { Navigator.pop(context); _pickImage(index, ImageSource.gallery); }),
                ]),
              ),
            ),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border, style: BorderStyle.solid),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.add_photo_alternate_outlined, color: AppTheme.onSurfaceMuted, size: 32),
                const SizedBox(height: 8),
                Text('Add nutrition label photo', style: Theme.of(context).textTheme.bodyMedium),
              ]),
            ),
          ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Compare Products')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          for (int i = 0; i < _products.length; i++) _buildProductCard(i),
          if (_products.length < 5)
            TextButton.icon(
              onPressed: () => setState(() => _products.add(_ProductEntry(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: 'Product ${_products.length + 1}',
              ))),
              icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
              label: const Text('Add product', style: TextStyle(color: AppTheme.primary)),
            ),
          const SizedBox(height: 16),
          if (_error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13)),
            ),
          ElevatedButton(
            onPressed: _comparing ? null : _compare,
            child: _comparing
                ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                    SizedBox(width: 12),
                    Text('Analyzing...'),
                  ])
                : const Text('Compare Products'),
          ),
          if (_result != null) ...[
            const SizedBox(height: 24),
            if (_result!.winner != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
                ),
                child: Row(children: [
                  const Icon(Icons.emoji_events_rounded, color: AppTheme.primary),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Winner for you: ${_result!.winner}',
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 15))),
                ]),
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: MarkdownBody(
                data: _result!.comparisonText,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(color: AppTheme.onSurface, fontSize: 15, height: 1.6),
                  tableHead: const TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w600),
                  tableBody: const TextStyle(color: AppTheme.onSurface, fontSize: 14),
                  tableBorder: TableBorder.all(color: AppTheme.border, width: 0.5),
                  tableHeadAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
