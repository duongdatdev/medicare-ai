import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/api.dart';

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
      _error = '$error';
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
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Thanh toán hóa đơn')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lịch khám #${widget.appointmentId}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      _line('Tổng hóa đơn', _data['total']),
                      _line('BHYT chi trả', _data['insuranceCovered']),
                      _line('Cần thanh toán', _data['payable']),
                      _line('Trạng thái', _paymentStatus ?? 'unpaid'),
                    ],
                  ),
                ),
              ),
              if ((_paymentStatus ?? 'unpaid') != 'paid') ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _saving ? null : () => _pay('cash'),
                  icon: const Icon(Icons.payments),
                  label: const Text('Thanh toán tiền mặt'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _saving ? null : () => _pay('qr'),
                  icon: const Icon(Icons.qr_code),
                  label: const Text('Chuyển khoản VietQR'),
                ),
              ],
              if (_qr != null) ...[
                const SizedBox(height: 16),
                Center(
                  child: QrImageView(data: '${_qr!['payload']}', size: 240),
                ),
                Center(
                  child: Text('Nội dung chuyển khoản: ${_qr!['content']}'),
                ),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              TextButton.icon(
                onPressed: _reload,
                icon: const Icon(Icons.refresh),
                label: const Text('Cập nhật trạng thái'),
              ),
            ],
          ),
  );

  Widget _line(String label, dynamic value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(value == null ? '—' : '$value'),
      ],
    ),
  );
}
