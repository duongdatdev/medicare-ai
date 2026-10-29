import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api.dart';

class NewsFeedScreen extends StatefulWidget {
  const NewsFeedScreen({super.key});
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

  @override
  Widget build(BuildContext context) => FutureBuilder<List<dynamic>>(
    future: _news,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(
          child: TextButton(
            onPressed: () => setState(_load),
            child: const Text('Không tải được tin. Thử lại'),
          ),
        );
      }
      final items = snapshot.data ?? [];
      if (items.isEmpty) {
        return const Center(child: Text('Chưa có tin tức mới'));
      }
      return RefreshIndicator(
        onRefresh: () async => setState(_load),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Tin tức phòng khám',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            for (final item in items)
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.article_outlined),
                  ),
                  title: Text('${item['title'] ?? 'Tin tức'}'),
                  subtitle: Text('${item['createdAt'] ?? ''}'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () async {
                    final url = Uri.tryParse('${item['url'] ?? ''}');
                    if (url != null && await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  },
                ),
              ),
          ],
        ),
      );
    },
  );
}
