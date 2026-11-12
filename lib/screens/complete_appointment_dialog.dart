import 'package:flutter/material.dart';

import '../services/api.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/clinic_widgets.dart';

Future<List<int>?> showCompleteAppointmentDialog(BuildContext context) async {
  final response = await Api.instance.client.get<Map<String, dynamic>>(
    '/diseases',
  );
  final choices = (response.data?['items'] as List<dynamic>? ?? [])
      .whereType<Map<String, dynamic>>()
      .where((item) => item['active'] != false)
      .toList();
  final examFee = response.data?['examFee'] as num?;
  final selected = <int>{};
  if (!context.mounted) return null;

  return showDialog<List<int>>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final subtotal = choices
            .where((item) => selected.contains((item['id'] as num).toInt()))
            .fold<int>(
              0,
              (sum, item) => sum + ((item['price'] as num?)?.toInt() ?? 0),
            );

        return AlertDialog(
          title: const Text('Chẩn đoán và hoàn tất khám'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (examFee != null) ...[
                  ClinicBanner(
                    message: 'Phí khám cơ bản: ${formatVnd(examFee)}',
                    tone: BadgeTone.primary,
                  ),
                  const SizedBox(height: 10),
                ],
                if (choices.isEmpty)
                  const Text(
                    'Cần thêm dịch vụ khám trong bảng giá trước khi hoàn tất.',
                  )
                else
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final item in choices)
                          CheckboxListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            value: selected.contains(
                              (item['id'] as num).toInt(),
                            ),
                            title: Text(
                              '${item['name']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${formatVnd(item['price'] ?? 0)} · ${item['bhytCovered'] == true ? 'BHYT' : 'Tự chi trả'}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
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
                if (choices.isNotEmpty) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Đã chọn ${selected.length} dịch vụ',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        formatVnd(subtotal),
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
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
        );
      },
    ),
  );
}
