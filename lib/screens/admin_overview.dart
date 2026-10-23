import 'package:flutter/material.dart';

import '../services/api.dart';

class AdminOverview extends StatefulWidget {
  const AdminOverview({super.key});

  @override
  State<AdminOverview> createState() => _AdminOverviewState();
}

class _AdminOverviewState extends State<AdminOverview> {
  late Future<_OverviewData> _data;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _data = Future.wait([
      Api.instance.list('/admin/doctor-salaries'),
      Api.instance.list('/doctor/list'),
      Api.instance.list('/doctor/shift-overview'),
    ]).then((result) => _OverviewData(result[0], result[1], result[2]));
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<_OverviewData>(
    future: _data,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(
          child: TextButton.icon(
            onPressed: () => setState(_reload),
            icon: const Icon(Icons.refresh),
            label: const Text('Không tải được dữ liệu. Thử lại'),
          ),
        );
      }
      final data = snapshot.data!;
      return RefreshIndicator(
        onRefresh: () async => setState(_reload),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Tổng quan phòng khám',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Metric(
                  label: 'Bác sĩ',
                  value: '${data.doctors.length}',
                  icon: Icons.medical_services,
                ),
                _Metric(
                  label: 'Bảng lương',
                  value: '${data.salaries.length}',
                  icon: Icons.payments_outlined,
                ),
                _Metric(
                  label: 'Phân ca',
                  value: '${data.shifts.length}',
                  icon: Icons.schedule,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Bác sĩ và lương',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            for (final row in data.salaries)
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person_outline),
                  ),
                  title: Text(
                    '${row['name'] ?? row['doctorName'] ?? 'Bác sĩ'}',
                  ),
                  subtitle: Text('${row['totalHours'] ?? 0} giờ làm'),
                  trailing: Text(_money(row['salary'])),
                ),
              ),
          ],
        ),
      );
    },
  );

  String _money(dynamic value) {
    final amount = (value as num?)?.toInt() ?? 0;
    return '${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')} ₫';
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 150,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(label),
          ],
        ),
      ),
    ),
  );
}

class _OverviewData {
  const _OverviewData(this.salaries, this.doctors, this.shifts);
  final List<dynamic> salaries;
  final List<dynamic> doctors;
  final List<dynamic> shifts;
}
