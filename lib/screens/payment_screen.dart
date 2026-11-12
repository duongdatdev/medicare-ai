import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/api.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/clinic_widgets.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({required this.appointmentId, super.key});
  final int appointmentId;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  Map<String, dynamic> _data = {};
  Map<String, dynamic>? _qr;
  String? _paymentStatus;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    try {
      final response = await Api.instance.client.get<Map<String, dynamic>>(
        '/patient/appointment/${widget.appointmentId}',
      );
      _data = response.data ?? {};
      _paymentStatus = _data['paymentStatus'] as String? ?? _paymentStatus;
      _error = null;
    } catch (error) {
      _error = formatApiError(error);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pay(String method) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final response = await Api.instance.client.post<Map<String, dynamic>>(
        '/patient/appointment/${widget.appointmentId}/pay',
        data: {'method': method},
      );
      final qr = response.data?['qr'] as Map<String, dynamic>?;
      if (mounted) {
        setState(() {
          _qr = qr;
          _paymentStatus = response.data?['paymentStatus'] as String?;
        });
      }
      await _reload();
    } catch (error) {
      if (mounted) setState(() => _error = formatApiError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _paymentStatus ?? 'unpaid';
    final statusTone = switch (status) {
      'paid' => BadgeTone.success,
      'pending' => BadgeTone.warning,
      _ => BadgeTone.danger,
    };
    final items =
        (_data['items'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        const <Map<String, dynamic>>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán hóa đơn')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ResponsiveCenter(
              maxWidth: 680,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Lịch khám #${widget.appointmentId}',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              StatusBadge(
                                label: paymentStatusLabel(status),
                                tone: statusTone,
                              ),
                            ],
                          ),
                          if (_data['insuranceCardNumber'] != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Thẻ BHYT: ${_data['insuranceCardNumber']}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          const Divider(),
                          const SizedBox(height: 8),
                          if (_data['examFee'] != null)
                            KeyValueRow(
                              label: 'Phí khám',
                              value: formatVnd(_data['examFee']),
                            ),
                          for (final item in items)
                            KeyValueRow(
                              label:
                                  '${item['name']} ${item['bhytCovered'] == true ? '(BHYT)' : '(Tự trả)'}',
                              value: formatVnd(item['price']),
                            ),
                          if (_data['examFee'] != null || items.isNotEmpty)
                            const Divider(),
                          KeyValueRow(
                            label: 'Tổng hóa đơn',
                            value: formatVnd(_data['total']),
                          ),
                          KeyValueRow(
                            label: _data['insuranceRate'] != null
                                ? 'BHYT chi trả (${((_data['insuranceRate'] as num) * 100).round()}%)'
                                : 'BHYT chi trả',
                            value: _data['insuranceCovered'] == null
                                ? '—'
                                : '-${formatVnd(_data['insuranceCovered'])}',
                            valueColor: AppColors.successFg,
                          ),
                          const Divider(),
                          KeyValueRow(
                            label: 'Cần thanh toán',
                            value: formatVnd(_data['payable']),
                            bold: true,
                            valueColor: AppColors.primaryDark,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (status == 'paid') ...[
                    const SizedBox(height: 14),
                    const ClinicBanner(
                      message: 'Hóa đơn đã được thanh toán hoàn tất.',
                      tone: BadgeTone.success,
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                    const SectionHeader(
                      title: 'Chọn phương thức thanh toán',
                      subtitle: 'Thanh toán tại quầy hoặc chuyển khoản VietQR',
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: _saving ? null : () => _pay('cash'),
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text('Thanh toán tiền mặt'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _saving ? null : () => _pay('qr'),
                      icon: const Icon(Icons.qr_code_2),
                      label: const Text('Chuyển khoản VietQR'),
                    ),
                  ],
                  if (_qr != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const SectionHeader(
                              title: 'Quét mã VietQR để thanh toán',
                              subtitle:
                                  'Giữ nguyên nội dung chuyển khoản để đối soát tự động',
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: QrImageView(
                                data: '${_qr!['payload']}',
                                size: 220,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_qr!['bankName'] != null)
                              KeyValueRow(
                                label: 'Ngân hàng',
                                value: '${_qr!['bankName']}',
                              ),
                            if (_qr!['accountNo'] != null)
                              KeyValueRow(
                                label: 'Số tài khoản',
                                value: '${_qr!['accountNo']}',
                              ),
                            if (_qr!['accountName'] != null &&
                                '${_qr!['accountName']}'.isNotEmpty)
                              KeyValueRow(
                                label: 'Chủ tài khoản',
                                value: '${_qr!['accountName']}',
                              ),
                            if (_qr!['amount'] != null)
                              KeyValueRow(
                                label: 'Số tiền',
                                value: formatVnd(_qr!['amount']),
                                bold: true,
                              ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Nội dung chuyển khoản: ${_qr!['content']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Sao chép nội dung',
                                    onPressed: () {
                                      Clipboard.setData(
                                        ClipboardData(
                                          text: '${_qr!['content']}',
                                        ),
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Đã sao chép nội dung chuyển khoản',
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.copy_outlined,
                                      size: 18,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    ClinicBanner(message: _error!, tone: BadgeTone.danger),
                  ],
                  const SizedBox(height: 14),
                  TextButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Cập nhật trạng thái'),
                  ),
                ],
              ),
            ),
    );
  }
}
