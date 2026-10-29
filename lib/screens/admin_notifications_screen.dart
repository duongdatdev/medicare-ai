import 'package:flutter/material.dart';

import '../services/api.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});
  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  late Future<List<dynamic>> _items;
  int _unread = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _items = Api.instance.list('/admin/notifications');
    Api.instance.client
        .get<Map<String, dynamic>>('/admin/notifications/unread-count')
        .then((response) {
          if (mounted) {
            setState(
              () => _unread = (response.data?['count'] as num?)?.toInt() ?? 0,
            );
          }
        });
  }

  Future<void> _readAll() async {
    try {
      await Api.instance.client.post('/admin/notifications/read-all');
      if (mounted) setState(() => _load());
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ListTile(
        title: Text('Chưa đọc: $_unread'),
        trailing: TextButton(
          onPressed: _unread == 0 ? null : _readAll,
          child: const Text('Đánh dấu đã đọc'),
        ),
      ),
      Expanded(
        child: FutureBuilder<List<dynamic>>(
          future: _items,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: TextButton(
                  onPressed: () => setState(_load),
                  child: const Text('Tải lại thông báo'),
                ),
              );
            }
            final rows = snapshot.data ?? [];
            if (rows.isEmpty) {
              return const Center(child: Text('Hộp thư đang trống'));
            }
            return RefreshIndicator(
              onRefresh: () async => setState(_load),
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  for (final row in rows)
                    Card(
                      child: ListTile(
                        leading: Icon(
                          row['readAt'] == null
                              ? Icons.notifications_active
                              : Icons.notifications_none,
                        ),
                        title: Text(
                          '${row['title'] ?? row['message'] ?? 'Thông báo'}',
                        ),
                        subtitle: Text('${row['createdAt'] ?? ''}'),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    ],
  );
}
