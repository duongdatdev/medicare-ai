import 'package:flutter/material.dart';

import '../services/api.dart';

class AdminDiseasesScreen extends StatefulWidget {
  const AdminDiseasesScreen({super.key});
  @override
  State<AdminDiseasesScreen> createState() => _AdminDiseasesScreenState();
}

class _AdminDiseasesScreenState extends State<AdminDiseasesScreen> {
  late Future<Map<String, dynamic>> _data;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _data = Api.instance.client
        .get<Map<String, dynamic>>('/diseases')
        .then((response) => response.data ?? {});
  }

  Future<void> _edit([Map<String, dynamic>? item]) async {
    final name = TextEditingController(text: '${item?['name'] ?? ''}');
    final price = TextEditingController(text: '${item?['price'] ?? ''}');
    bool covered = item?['bhytCovered'] as bool? ?? true;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(item == null ? 'Thêm dịch vụ khám' : 'Sửa bảng giá'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(
                  labelText: 'Tên bệnh / dịch vụ',
                ),
              ),
              TextField(
                controller: price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Giá (₫)'),
              ),
              SwitchListTile(
                title: const Text('BHYT chi trả'),
                value: covered,
                onChanged: (value) => setDialog(() => covered = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                final amount = int.tryParse(price.text);
                if (name.text.trim().isNotEmpty &&
                    amount != null &&
                    amount >= 0)
                  Navigator.pop(context, {
                    'name': name.text.trim(),
                    'price': amount,
                    'bhytCovered': covered,
                  });
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    price.dispose();
    if (result == null) return;
    try {
      if (item == null)
        await Api.instance.client.post('/diseases', data: result);
      else
        await Api.instance.client.patch(
          '/diseases/${item['id']}',
          data: result,
        );
      if (mounted) setState(_load);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Bảng giá dịch vụ')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _edit(),
      icon: const Icon(Icons.add),
      label: const Text('Thêm dịch vụ'),
    ),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return Center(
            child: TextButton(
              onPressed: () => setState(_load),
              child: const Text('Tải lại'),
            ),
          );
        final items = snapshot.data?['items'] as List<dynamic>? ?? [];
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            ListTile(
              title: const Text('Phí khám'),
              trailing: Text('${snapshot.data?['examFee'] ?? 0} ₫'),
            ),
            for (final item in items)
              Card(
                child: ListTile(
                  title: Text('${item['name']}'),
                  subtitle: Text(
                    '${item['price']} ₫ · ${item['bhytCovered'] == true ? 'Có BHYT' : 'Không BHYT'}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _edit(item as Map<String, dynamic>),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}
