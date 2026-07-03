import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:photo_view/photo_view.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/employee_notice.dart';
import '../cubit/employee_notice_cubit.dart';

class EmployeeNoticeCard extends StatefulWidget {
  final EmployeeNotice notice;

  const EmployeeNoticeCard({super.key, required this.notice});

  @override
  State<EmployeeNoticeCard> createState() => _EmployeeNoticeCardState();
}

class _EmployeeNoticeCardState extends State<EmployeeNoticeCard> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    if (!widget.notice.isRead) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<EmployeeNoticeCubit>().markRead(widget.notice.id);
        }
      });
    }
  }

  void _markRead() {
    context.read<EmployeeNoticeCubit>().markRead(widget.notice.id);
  }

  @override
  Widget build(BuildContext context) {
    final notice = widget.notice;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space3),
      decoration: BoxDecoration(
        color: notice.isRead ? AppTheme.white : AppTheme.blue100.withOpacity(0.22),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.blue100),
        boxShadow: AppTheme.shadowXs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppTheme.space4, AppTheme.space4, AppTheme.space4, AppTheme.space3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InitialsAvatar(name: notice.postedByName),
                const SizedBox(width: AppTheme.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notice.postedByName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppTheme.navy,
                              ),
                            ),
                          ),
                          if (notice.isPinned)
                            const Icon(Icons.push_pin_rounded, size: 14, color: AppTheme.navy),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatTime(notice.postedAt),
                        style: const TextStyle(fontSize: 11, color: AppTheme.blue300),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (notice.title != null) ...[
                  Text(
                    notice.title!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                _ExpandableBody(
                  body: notice.body,
                  expanded: _expanded,
                  onToggle: () => setState(() => _expanded = !_expanded),
                ),
              ],
            ),
          ),
          if (notice.mediaUrls.isNotEmpty) ...[
            const SizedBox(height: AppTheme.space3),
            _MediaStrip(mediaUrls: notice.mediaUrls, mediaTypes: notice.mediaTypes),
          ],
          if (!notice.isRead) ...[
            const SizedBox(height: AppTheme.space2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space4),
              child: Align(
                alignment: Alignment.bottomRight,
                child: TextButton.icon(
                  onPressed: _markRead,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    minimumSize: const Size(0, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.done_rounded, size: 15, color: AppTheme.navy),
                  label: const Text(
                    'Mark as read',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.navy),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppTheme.space4),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String name;

  const _InitialsAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ').take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppTheme.navy.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.navy),
        ),
      ),
    );
  }
}

class _ExpandableBody extends StatelessWidget {
  final String body;
  final bool expanded;
  final VoidCallback onToggle;

  const _ExpandableBody({required this.body, required this.expanded, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    const maxLines = 3;
    final style = TextStyle(fontSize: 13, color: AppTheme.navy.withOpacity(0.85), height: 1.5);

    return LayoutBuilder(
      builder: (context, constraints) {
        final tp = TextPainter(
          text: TextSpan(text: body, style: style),
          maxLines: maxLines,
          textDirection: ui.TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);
        final isOverflow = tp.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              body,
              style: style,
              maxLines: expanded ? null : maxLines,
              overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            if (isOverflow) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: onToggle,
                child: Text(
                  expanded ? 'Show less' : 'Read more',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.navy,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _MediaStrip extends StatelessWidget {
  final List<String> mediaUrls;
  final List<String> mediaTypes;

  const _MediaStrip({required this.mediaUrls, required this.mediaTypes});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space4),
        itemCount: mediaUrls.length,
        itemBuilder: (context, i) {
          final url = mediaUrls[i];
          final type = i < mediaTypes.length ? mediaTypes[i] : 'image';
          return Padding(
            padding: const EdgeInsets.only(right: AppTheme.space2),
            child: _MediaThumb(url: url, type: type),
          );
        },
      ),
    );
  }
}

class _MediaThumb extends StatelessWidget {
  final String url;
  final String type;

  const _MediaThumb({required this.url, required this.type});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppTheme.blue100,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: _buildThumbContent(),
        ),
      ),
    );
  }

  Widget _buildThumbContent() {
    if (type == 'image') {
      return Image.network(url, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: AppTheme.blue300));
    }
    if (type == 'pdf') {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.picture_as_pdf_rounded, color: AppTheme.navy, size: 28),
          SizedBox(height: 4),
          Text('PDF', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.navy)),
        ],
      );
    }
    if (type == 'video') {
      return const Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.videocam_rounded, color: AppTheme.blue300, size: 32),
          Icon(Icons.play_circle_fill_rounded, color: AppTheme.navy, size: 20),
        ],
      );
    }
    return const Icon(Icons.attach_file_rounded, color: AppTheme.blue300);
  }

  void _open(BuildContext context) {
    if (type == 'image') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => _FullScreenImage(url: url)));
      return;
    }
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}

class _FullScreenImage extends StatelessWidget {
  final String url;

  const _FullScreenImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PhotoView(imageProvider: NetworkImage(url)),
    );
  }
}
