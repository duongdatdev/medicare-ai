import 'package:flutter/material.dart';

import '../services/api.dart';

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});
  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {
  bool _paid = false;
  late Future<List<dynamic>> _items;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _items = Api.instance.list(
      '/admin/payments?status=${_paid ? 'paid' : 'pending'}',
    );
  }

  Future<void> _confirm(int id) async {
    try {
      await Api.instance.client.post('/admin/payments/$id/confirm');
      if (mounted) setState(_load);
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
      Padding(
        padding: const EdgeInsets.all(12),
        child: SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Chờ xác nhận')),
            ButtonSegment(value: true, label: Text('Đã thanh toán')),
          ],
          selected: {_paid},
          onSelectionChanged: (value) => setState(() {
            _paid = value.first;
            _load();
          }),
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
                  child: const Text('Tải lại'),
                ),
              );
            }
            final rows = snapshot.data ?? [];
            if (rows.isEmpty) {
              return const Center(child: Text('Không có giao dịch'));
            }
            return RefreshIndicator(
              onRefresh: () async => setState(_load),
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  for (final row in rows)
                    Card(
                      child: ListTile(
                        title: Text(
                          '${(row['patient'] as Map<String, dynamic>?)?['name'] ?? 'Bệnh nhân'} · lịch #${row['id']}',
                        ),
                        subtitle: Text(
                          '${row['paymentMethod'] ?? row['method'] ?? ''} · ${row['paymentStatus'] ?? row['status'] ?? ''}',
                        ),
                        trailing: _paid
                            ? Text('${row['payable'] ?? row['amount'] ?? 0} ₫')
                            : IconButton(
                                tooltip: 'Xác nhận thanh toán',
                                icon: const Icon(Icons.check_circle_outline),
                                onPressed: () =>
                                    _confirm((row['id'] as num).toInt()),
                              ),
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
