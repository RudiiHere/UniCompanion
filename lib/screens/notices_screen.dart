import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/app_providers.dart';
import '../../models/app_models.dart';
import '../../config/app_theme.dart';
import '../../widgets/common_widgets.dart';

class NoticesScreen extends ConsumerWidget {
  const NoticesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noticesAsync = ref.watch(noticesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notice Board')),
      body: noticesAsync.when(
        data: (notices) => notices.isEmpty
            ? const EmptyState(
          icon: Icons.campaign_outlined,
          title: 'No notices yet',
          subtitle: 'Check back later for announcements',
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notices.length,
          itemBuilder: (context, i) => _NoticeCard(notice: notices[i]),
        ),
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 5,
          itemBuilder: (context, index) => const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: ShimmerCard(height: 90),
          ),
        ),
        error: (_, __) => const Center(child: Text('Could not load notices')),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final Notice notice;
  const _NoticeCard({required this.notice});

  Color _categoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'academic': return AppTheme.indigo;
      case 'event':    return AppTheme.emerald;
      case 'update':   return AppTheme.sky;
      case 'urgent':   return AppTheme.rose;
      default:         return AppTheme.amber;
    }
  }

  Color _categoryBg(String cat) {
    switch (cat.toLowerCase()) {
      case 'academic': return AppTheme.indigoSoft;
      case 'event':    return AppTheme.emeraldSoft;
      case 'update':   return AppTheme.skySoft;
      case 'urgent':   return AppTheme.roseSoft;
      default:         return AppTheme.amberSoft;
    }
  }

  IconData _categoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'academic': return Icons.school_rounded;
      case 'event':    return Icons.event_rounded;
      case 'update':   return Icons.update_rounded;
      case 'urgent':   return Icons.priority_high_rounded;
      default:         return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final color = _categoryColor(notice.category);
    final bgColor = _categoryBg(notice.category);
    final timeAgo = _formatTime(notice.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
                child: Icon(_categoryIcon(notice.category), size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notice.title,
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: cs.onSurface),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(timeAgo, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              BadgePill(label: notice.category, color: color, bgColor: bgColor),
            ]),
            if (notice.content.isNotEmpty) ...[
              const SizedBox(height: 10),
              Divider(height: 0.5, color: cs.outline),
              const SizedBox(height: 10),
              Text(notice.content, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, height: 1.5)),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    return DateFormat('d MMM').format(dt);
  }
}
