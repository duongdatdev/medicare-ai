import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

import '../services/api.dart';

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

  Future<void> _create() async {
    final title = TextEditingController();
    final url = TextEditingController();
    XFile? image;
    final data = await showDialog<(String, String, XFile)?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: const Text('Thêm tin tức'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Tiêu đề'),
              ),
              TextField(
                controller: url,
                decoration: const InputDecoration(labelText: 'Liên kết HTTPS'),
              ),
              TextButton.icon(
                onPressed: () async {
                  final selected = await _picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (selected != null) setDialog(() => image = selected);
                },
                icon: const Icon(Icons.image),
                label: Text(image?.name ?? 'Chọn ảnh'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed:
                  image == null ||
                      title.text.trim().isEmpty ||
                      url.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(context, (
                      title.text.trim(),
                      url.text.trim(),
                      image!,
                    )),
              child: const Text('Đăng tin'),
            ),
          ],
        ),
      ),
    );
    title.dispose();
    url.dispose();
    if (data == null) return;
    try {
      final bytes = await data.$3.readAsBytes();
      final form = FormData.fromMap({
        'title': data.$1,
        'url': data.$2,
        'image': MultipartFile.fromBytes(bytes, filename: data.$3.name),
      });
      await Api.instance.client.post('/news', data: form);
      if (mounted) setState(_load);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  Future<void> _delete(int id) async {
    try {
      await Api.instance.client.delete('/news/$id');
      if (mounted) setState(_load);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
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
    body: FutureBuilder<List<dynamic>>(
      future: _items,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return Center(
            child: TextButton(
              onPressed: () => setState(_load),
              child: const Text('Tải lại tin tức'),
            ),
          );
        final items = snapshot.data ?? [];
        if (items.isEmpty) return const Center(child: Text('Chưa có tin tức'));
        return RefreshIndicator(
          onRefresh: () async => setState(_load),
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              for (final item in items)
                Card(
                  child: ListTile(
                    title: Text('${item['title']}'),
                    subtitle: Text('${item['url']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _delete((item['id'] as num).toInt()),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}
