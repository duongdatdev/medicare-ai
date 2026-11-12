import 'package:flutter/material.dart';

import '../services/api.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/clinic_widgets.dart';

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

  Future<void> _refresh() async {
    setState(_load);
    await _data;
  }

  Future<void> _edit([Map<String, dynamic>? item]) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _DiseaseEditDialog(item: item),
    );
    if (result == null) return;
    try {
      if (item == null) {
        await Api.instance.client.post('/diseases', data: result);
      } else {
        await Api.instance.client.patch(
          '/diseases/${item['id']}',
          data: result,
        );
      }
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
    appBar: AppBar(title: const Text('Bảng giá dịch vụ')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _edit(),
      icon: const Icon(Icons.add),
      label: const Text('Thêm dịch vụ'),
    ),
    body: ResponsiveCenter(
      maxWidth: 760,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _data,
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
          final items = snapshot.data?['items'] as List<dynamic>? ?? [];
          final examFee = snapshot.data?['examFee'] ?? 0;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              children: [
                Card(
                  color: AppColors.primarySoft,
                  child: ListTile(
                    leading: const Icon(
                      Icons.local_hospital_outlined,
                      color: AppColors.primaryDark,
                    ),
                    title: const Text(
                      'Phí khám cơ bản',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    trailing: Text(
                      formatVnd(examFee),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SectionHeader(
                  title: 'Danh mục dịch vụ & bệnh lý',
                  subtitle: '${items.length} mục trong bảng giá',
                ),
                const SizedBox(height: 10),
                if (items.isEmpty)
                  const EmptyStateView(
                    icon: Icons.medical_information_outlined,
                    title: 'Chưa có dịch vụ nào',
                    subtitle: 'Nhấn "Thêm dịch vụ" để tạo mục bảng giá mới.',
                  )
                else
                  for (final raw in items) ...[
                    _diseaseCard(raw as Map<String, dynamic>),
                    const SizedBox(height: 10),
                  ],
              ],
            ),
          );
        },
      ),
    ),
  );

  Widget _diseaseCard(Map<String, dynamic> item) {
    final covered = item['bhytCovered'] == true;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        title: Text(
          '${item['name']}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                formatVnd(item['price']),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
              StatusBadge(
                label: covered ? 'Có BHYT' : 'Không BHYT',
                tone: covered ? BadgeTone.success : BadgeTone.neutral,
              ),
            ],
          ),
        ),
        trailing: IconButton(
          tooltip: 'Chỉnh sửa',
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => _edit(item),
        ),
      ),
    );
  }
}

class _DiseaseEditDialog extends StatefulWidget {
  const _DiseaseEditDialog({this.item});

  final Map<String, dynamic>? item;

  @override
  State<_DiseaseEditDialog> createState() => _DiseaseEditDialogState();
}

class _DiseaseEditDialogState extends State<_DiseaseEditDialog> {
  late final TextEditingController _name;
  late final TextEditingController _price;
  late bool _covered;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: '${widget.item?['name'] ?? ''}');
    _price = TextEditingController(text: '${widget.item?['price'] ?? ''}');
    _covered = widget.item?['bhytCovered'] as bool? ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.item == null ? 'Thêm dịch vụ khám' : 'Sửa bảng giá'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Tên bệnh / dịch vụ'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _price,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Giá (₫)'),
        ),
        const SizedBox(height: 6),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('BHYT chi trả'),
          value: _covered,
          onChanged: (value) => setState(() => _covered = value),
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
          final amount = int.tryParse(_price.text.trim());
          if (_name.text.trim().isNotEmpty && amount != null && amount >= 0) {
            Navigator.pop(context, {
              'name': _name.text.trim(),
              'price': amount,
              'bhytCovered': _covered,
            });
          }
        },
        child: const Text('Lưu'),
      ),
    ],
  );
}
