import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/clinic_widgets.dart';

class NewsFeedScreen extends StatefulWidget {
  const NewsFeedScreen({
    this.onBookAppointment,
    this.onOpenAppointments,
    this.onOpenProfile,
    super.key,
  });

  final VoidCallback? onBookAppointment;
  final VoidCallback? onOpenAppointments;
  final VoidCallback? onOpenProfile;

  @override
  State<NewsFeedScreen> createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends State<NewsFeedScreen> {
  late Future<List<dynamic>> _news;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _news = Api.instance.list('/news?limit=20');
  }

  Future<void> _refresh() async {
    setState(_load);
    await _news;
  }

  @override
  Widget build(BuildContext context) {
    final session = maybeSession(context);
    final greetingName = session?.name?.isNotEmpty == true
        ? session!.name!
        : 'Bạn';

    return FutureBuilder<List<dynamic>>(
      future: _news,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return ErrorStateView(
            message: formatApiError(snapshot.error!),
            onRetry: () => setState(_load),
            retryLabel: 'Không tải được tin. Thử lại',
          );
        }
        final items = snapshot.data ?? [];
        return RefreshIndicator(
          onRefresh: _refresh,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 640 ? 2 : 1;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _WelcomeHero(
                    name: greetingName,
                    onBookAppointment: widget.onBookAppointment,
                    onOpenAppointments: widget.onOpenAppointments,
                    onOpenProfile: widget.onOpenProfile,
                  ),
                  const SizedBox(height: 20),
                  SectionHeader(
                    title: 'Tin tức phòng khám',
                    subtitle: items.isEmpty
                        ? null
                        : '${items.length} bài viết sức khỏe mới nhất',
                  ),
                  const SizedBox(height: 12),
                  if (items.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 28),
                        child: EmptyStateView(
                          icon: Icons.newspaper_outlined,
                          title: 'Chưa có tin tức mới',
                          subtitle:
                              'Các thông báo và bài viết y khoa từ phòng khám sẽ hiển thị tại đây.',
                        ),
                      ),
                    )
                  else if (columns == 1)
                    for (final item in items) ...[
                      _NewsCard(item: item as Map<String, dynamic>),
                      const SizedBox(height: 12),
                    ]
                  else
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final item in items)
                          SizedBox(
                            width: (constraints.maxWidth - 32 - 12) / 2,
                            child: _NewsCard(
                              item: item as Map<String, dynamic>,
                            ),
                          ),
                      ],
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero({
    required this.name,
    this.onBookAppointment,
    this.onOpenAppointments,
    this.onOpenProfile,
  });

  final String name;
  final VoidCallback? onBookAppointment;
  final VoidCallback? onOpenAppointments;
  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.primary, AppColors.primaryDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.health_and_safety_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Xin chào, $name',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Chủ động theo dõi lịch hẹn, hồ sơ BHYT và tin y khoa.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (onBookAppointment != null ||
            onOpenAppointments != null ||
            onOpenProfile != null) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (onBookAppointment != null)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryDark,
                    minimumSize: const Size(0, 40),
                  ),
                  onPressed: onBookAppointment,
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Đặt lịch khám'),
                ),
              if (onOpenAppointments != null)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                    minimumSize: const Size(0, 40),
                  ),
                  onPressed: onOpenAppointments,
                  icon: const Icon(Icons.calendar_today_outlined, size: 16),
                  label: const Text('Lịch của tôi'),
                ),
              if (onOpenProfile != null)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                    minimumSize: const Size(0, 40),
                  ),
                  onPressed: onOpenProfile,
                  icon: const Icon(Icons.badge_outlined, size: 16),
                  label: const Text('Thẻ BHYT'),
                ),
            ],
          ),
        ],
      ],
    ),
  );
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.item});

  final Map<String, dynamic> item;

  Future<void> _openUrl() async {
    final url = Uri.tryParse('${item['url'] ?? ''}');
    if (url != null && await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = Api.instance.resolveUrl(item['imagePath'] as String?);
    final createdAt = formatIsoDateTime(item['createdAt'], fallback: '');

    return Card(
      child: InkWell(
        onTap: _openUrl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _imagePlaceholder(),
                    )
                  : _imagePlaceholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item['title'] ?? 'Tin tức'}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_outlined,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          createdAt.isEmpty ? 'Tin phòng khám' : createdAt,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.open_in_new,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [AppColors.primarySoft, AppColors.secondarySoft],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: const Center(
      child: Icon(
        Icons.article_outlined,
        size: 40,
        color: AppColors.primaryDark,
      ),
    ),
  );
}
