import 'package:flutter/material.dart';

import '../services/api.dart';

Future<List<int>?> showCompleteAppointmentDialog(BuildContext context) async {
  final response = await Api.instance.client.get<Map<String, dynamic>>(
    '/diseases',
  );
  final choices = (response.data?['items'] as List<dynamic>? ?? [])
      .whereType<Map<String, dynamic>>()
      .where((item) => item['active'] != false)
      .toList();
  final selected = <int>{};
  if (!context.mounted) return null;
  return showDialog<List<int>>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Chẩn đoán và hoàn tất khám'),
        content: SizedBox(
          width: 420,
          child: choices.isEmpty
              ? const Text(
                  'Cần thêm dịch vụ khám trong bảng giá trước khi hoàn tất.',
                )
              : ListView(
                  shrinkWrap: true,
                  children: [
                    for (final item in choices)
                      CheckboxListTile(
                        value: selected.contains((item['id'] as num).toInt()),
                        title: Text('${item['name']}'),
                        subtitle: Text(
                          '${item['price'] ?? 0} ₫ · ${item['bhytCovered'] == true ? 'BHYT' : 'Tự chi trả'}',
                        ),
                        onChanged: (checked) => setState(() {
                          final id = (item['id'] as num).toInt();
                          if (checked == true) {
                            selected.add(id);
                          } else {
                            selected.remove(id);
                          }
                        }),
                      ),
                  ],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: selected.isEmpty
                ? null
                : () => Navigator.pop(context, selected.toList()),
            child: const Text('Hoàn tất'),
          ),
        ],
      ),
    ),
  );
}
