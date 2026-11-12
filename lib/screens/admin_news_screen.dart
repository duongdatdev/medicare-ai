import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/clinic_widgets.dart';

class AdminNewsScreen extends StatefulWidget {
  const AdminNewsScreen({super.key});

  @override
  State<AdminNewsScreen> createState() => _AdminNewsScreenState();
}

class _AdminNewsScreenState extends State<AdminNewsScreen> {
  final _picker = ImagePicker();
  late Future<List<dynamic>> _items;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _items = Api.instance.list('/news?limit=50');
  }

  Future<void> _refresh() async {
    setState(_load);
    await _items;
  }

  Future<void> _create() async {
    final data = await showDialog<(String, String, XFile, Uint8List)?>(
      context: context,
      builder: (_) => _CreateNewsDialog(picker: _picker),
    );
    if (data == null) return;
    try {
      final form = FormData.fromMap({
        'title': data.$1,
        'url': data.$2,
        'image': MultipartFile.fromBytes(data.$4, filename: data.$3.name),
      });
      await Api.instance.client.post('/news', data: form);
      if (mounted) setState(_load);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(formatApiError(error))));
      }
    }
  }

  Future<void> _delete(int id, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tin tức?'),
        content: Text('Bạn có chắc muốn xóa bài viết "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.dangerFg),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await Api.instance.client.delete('/news/$id');
      if (mounted) setState(_load);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(formatApiError(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Quản lý tin tức')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _create,
      icon: const Icon(Icons.add),
      label: const Text('Thêm tin'),
    ),
    body: ResponsiveCenter(
      maxWidth: 780,
      child: FutureBuilder<List<dynamic>>(
        future: _items,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorStateView(
              message: formatApiError(snapshot.error!),
              onRetry: () => setState(_load),
              retryLabel: 'Tải lại tin tức',
            );
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const EmptyStateView(
              icon: Icons.newspaper_outlined,
              title: 'Chưa có tin tức',
              subtitle: 'Nhấn "Thêm tin" để đăng bài viết đầu tiên.',
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index] as Map<String, dynamic>;
                final imageUrl = Api.instance.resolveUrl(
                  item['imagePath'] as String?,
                );
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 76,
                            height: 60,
                            color: AppColors.primarySoft,
                            child: imageUrl != null
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Icon(
                                      Icons.article_outlined,
                                      color: AppColors.primaryDark,
                                    ),
                                  )
                                : const Icon(
                                    Icons.article_outlined,
                                    color: AppColors.primaryDark,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item['title']}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item['url']}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Xóa tin',
                          color: AppColors.dangerFg,
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _delete(
                            (item['id'] as num).toInt(),
                            '${item['title']}',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    ),
  );
}

class _CreateNewsDialog extends StatefulWidget {
  const _CreateNewsDialog({required this.picker});

  final ImagePicker picker;

  @override
  State<_CreateNewsDialog> createState() => _CreateNewsDialogState();
}

class _CreateNewsDialogState extends State<_CreateNewsDialog> {
  final _title = TextEditingController();
  final _url = TextEditingController();
  XFile? _image;
  Uint8List? _previewBytes;

  @override
  void dispose() {
    _title.dispose();
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Thêm tin tức'),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _title,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Tiêu đề'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _url,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Liên kết HTTPS'),
            ),
            const SizedBox(height: 12),
            if (_previewBytes != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _previewBytes!,
                  height: 130,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final selected = await widget.picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (selected != null) {
                    final bytes = await selected.readAsBytes();
                    if (mounted) {
                      setState(() {
                        _image = selected;
                        _previewBytes = bytes;
                      });
                    }
                  }
                },
                icon: const Icon(Icons.image_outlined),
                label: Text(_image?.name ?? 'Chọn ảnh'),
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton(
        onPressed:
            _image == null ||
                _previewBytes == null ||
                _title.text.trim().isEmpty ||
                _url.text.trim().isEmpty
            ? null
            : () => Navigator.pop(context, (
                _title.text.trim(),
                _url.text.trim(),
                _image!,
                _previewBytes!,
              )),
        child: const Text('Đăng tin'),
      ),
    ],
  );
}
