import 'package:flutter/material.dart';

import '../services/api.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/clinic_widgets.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({this.onUnreadChanged, super.key});

  final ValueChanged<int>? onUnreadChanged;

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
          final count = (response.data?['count'] as num?)?.toInt() ?? 0;
          if (mounted) {
            setState(() => _unread = count);
            widget.onUnreadChanged?.call(count);
          }
        })
        .catchError((Object error) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(formatApiError(error))));
          }
        });
  }

  Future<void> _refresh() async {
    setState(_load);
    await _items;
  }

  Future<void> _readAll() async {
    try {
      await Api.instance.client.post('/admin/notifications/read-all');
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
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusBadge(
                    label: 'Chưa đọc: $_unread',
                    tone: _unread > 0 ? BadgeTone.warning : BadgeTone.neutral,
                    icon: Icons.notifications_outlined,
                  ),
                  TextButton.icon(
                    onPressed: _unread == 0 ? null : _readAll,
                    icon: const Icon(Icons.done_all, size: 18),
                    label: const Text('Đánh dấu đã đọc'),
                  ),
                ],
              ),
            ),
          ),
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
                retryLabel: 'Tải lại thông báo',
              );
            }
            final rows = snapshot.data ?? [];
            if (rows.isEmpty) {
              return const EmptyStateView(
                icon: Icons.mark_email_read_outlined,
                title: 'Hộp thư đang trống',
                subtitle: 'Thông báo từ cổng thanh toán SePay sẽ xuất hiện tại đây.',
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
                  final unread = row['readAt'] == null;
                  final bodyText = '${row['body'] ?? ''}'.trim();
                  final timeText = formatIsoDateTime(
                    row['createdAt'],
                    fallback: '',
                  );

                  return Card(
                    color: unread ? AppColors.primarySoft : AppColors.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: unread
                                  ? Colors.white
                                  : AppColors.surfaceSubtle,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              unread
                                  ? Icons.notifications_active
                                  : Icons.notifications_none,
                              color: unread
                                  ? AppColors.primaryDark
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${row['title'] ?? 'Thông báo'}',
                                        style: TextStyle(
                                          fontWeight: unread
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    if (unread)
                                      const StatusBadge(
                                        label: 'Mới',
                                        tone: BadgeTone.primary,
                                      ),
                                  ],
                                ),
                                if (bodyText.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    bodyText,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                                if (timeText.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    timeText,
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
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
