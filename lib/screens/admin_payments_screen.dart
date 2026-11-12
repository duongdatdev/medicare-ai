import 'package:flutter/material.dart';

import '../services/api.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/clinic_widgets.dart';

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

  Future<void> _refresh() async {
    setState(_load);
    await _items;
  }

  Future<void> _confirm(int id) async {
    try {
      await Api.instance.client.post('/admin/payments/$id/confirm');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xác nhận thanh toán lịch #$id')),
        );
        setState(_load);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(formatApiError(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
              return ErrorStateView(
                message: formatApiError(snapshot.error!),
                onRetry: () => setState(_load),
                retryLabel: 'Tải lại',
              );
            }
            final rows = snapshot.data ?? [];
            if (rows.isEmpty) {
              return EmptyStateView(
                icon: Icons.payments_outlined,
                title: 'Không có giao dịch',
                subtitle: _paid
                    ? 'Chưa có giao dịch nào đã hoàn tất.'
                    : 'Không có giao dịch đang chờ xác nhận.',
              );
            }
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: rows.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final row = rows[index] as Map<String, dynamic>;
                  final patient = row['patient'] as Map<String, dynamic>?;
                  final method =
                      (row['paymentMethod'] ?? row['method']) as String?;
                  final status =
                      (row['paymentStatus'] ?? row['status']) as String?;
                  final amount = row['payable'] ?? row['amount'] ?? 0;

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _paid
                                  ? AppColors.successBg
                                  : AppColors.warningBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              method == 'qr'
                                  ? Icons.qr_code_2
                                  : Icons.payments_outlined,
                              color: _paid
                                  ? AppColors.successFg
                                  : AppColors.warningFg,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${patient?['name'] ?? 'Bệnh nhân'} · lịch #${row['id']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      paymentMethodLabel(method),
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                    StatusBadge(
                                      label: paymentStatusLabel(status),
                                      tone: _paid
                                          ? BadgeTone.success
                                          : BadgeTone.warning,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatVnd(amount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDark,
                                  fontSize: 15,
                                ),
                              ),
                              if (!_paid) ...[
                                const SizedBox(height: 6),
                                FilledButton.tonalIcon(
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(0, 36),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                  ),
                                  onPressed: () =>
                                      _confirm((row['id'] as num).toInt()),
                                  icon: const Icon(
                                    Icons.check_circle_outline,
                                    size: 16,
                                  ),
                                  label: const Text('Duyệt'),
                                ),
                              ],
                            ],
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
    ],
  );
}
