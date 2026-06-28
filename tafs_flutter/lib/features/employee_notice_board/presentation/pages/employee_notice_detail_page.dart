import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/employee_notice.dart';
import '../cubit/employee_notice_cubit.dart';

class EmployeeNoticeDetailPage extends StatefulWidget {
  final EmployeeNotice notice;

  const EmployeeNoticeDetailPage({super.key, required this.notice});

  @override
  State<EmployeeNoticeDetailPage> createState() => _EmployeeNoticeDetailPageState();
}

class _EmployeeNoticeDetailPageState extends State<EmployeeNoticeDetailPage> {
  @override
  void initState() {
    super.initState();
    // Mark as read when detail page opens
    if (!widget.notice.isRead) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<EmployeeNoticeCubit>().markRead(widget.notice.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final notice = widget.notice;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(notice.title ?? 'Notice'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header metadata
            Row(
              children: [
                if (notice.isPinned) ...[
                  Icon(Icons.push_pin, size: 14, color: colorScheme.primary),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    'From ${notice.postedByName}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),
                Text(
                  _formatDate(notice.postedAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (notice.title != null) ...[
              Text(
                notice.title!,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
            ],

            Text(
              notice.body,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.6,
                color: colorScheme.onSurface.withOpacity(0.85),
              ),
            ),

            // Expiry note
            if (notice.expiresAt != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: colorScheme.error),
                    const SizedBox(width: 8),
                    Text(
                      'Expires ${_formatDate(notice.expiresAt!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Media attachments
            if (notice.mediaUrls.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Attachments',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ...notice.mediaUrls.asMap().entries.map((entry) {
                final i = entry.key;
                final url = entry.value;
                final type = i < notice.mediaTypes.length ? notice.mediaTypes[i] : 'misc';
                return _MediaTile(url: url, type: type);
              }),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _MediaTile extends StatelessWidget {
  final String url;
  final String type;

  const _MediaTile({required this.url, required this.type});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    IconData icon;
    switch (type) {
      case 'image':
        icon = Icons.image_outlined;
        break;
      case 'video':
        icon = Icons.play_circle_outline;
        break;
      case 'pdf':
        icon = Icons.picture_as_pdf_outlined;
        break;
      default:
        icon = Icons.attach_file;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              url.split('/').last,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
