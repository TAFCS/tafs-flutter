import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../domain/entities/staff_notice_post.dart';
import '../bloc/staff_notice_board_cubit.dart';
import 'staff_notice_board_compose_page.dart';
import 'staff_notice_board_detail_page.dart';

class StaffNoticeBoardPage extends StatefulWidget {
  final bool loadOnMount;

  const StaffNoticeBoardPage({super.key, this.loadOnMount = false});

  @override
  State<StaffNoticeBoardPage> createState() => _StaffNoticeBoardPageState();
}

class _StaffNoticeBoardPageState extends State<StaffNoticeBoardPage> {
  @override
  void initState() {
    super.initState();
    if (widget.loadOnMount) {
      context.read<StaffNoticeBoardCubit>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StaffNoticeBoardCubit, StaffNoticeBoardState>(
      builder: (context, state) {
        return Column(
          children: [
            if (state.error != null)
              _banner(state.error!, Colors.red.shade50, Colors.red.shade800),

            Expanded(
              child: Stack(
                children: [
                  state.loading && state.posts.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(color: AppTheme.navy),
                        )
                      : state.posts.isEmpty
                          ? const Center(
                              child: Text(
                                'No posts yet.\nTap + to create one.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppTheme.blue300),
                              ),
                            )
                          : RefreshIndicator(
                              color: AppTheme.navy,
                              onRefresh: () =>
                                  context.read<StaffNoticeBoardCubit>().refresh(),
                              child: _TimelineList(
                                posts: state.posts,
                                campuses: state.campuses,
                                onTap: (post) => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BlocProvider.value(
                                      value: context.read<StaffNoticeBoardCubit>(),
                                      child: StaffNoticeBoardDetailPage(post: post),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                  // FAB — bottom padding on list ensures last card is never hidden
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton.extended(
                      onPressed: state.loading
                          ? null
                          : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BlocProvider.value(
                                    value: context.read<StaffNoticeBoardCubit>(),
                                    child: const StaffNoticeBoardComposePage(),
                                  ),
                                ),
                              ),
                      backgroundColor: AppTheme.navy,
                      foregroundColor: Colors.white,
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('New Post',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _banner(String text, Color bg, Color fg) {
    return Material(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(text, style: TextStyle(color: fg, fontSize: 12)),
      ),
    );
  }
}

// Groups posts by calendar date and renders date separators
class _TimelineList extends StatelessWidget {
  final List<StaffNoticePost> posts;
  final List<CampusScope> campuses;
  final void Function(StaffNoticePost) onTap;

  const _TimelineList({
    required this.posts,
    required this.campuses,
    required this.onTap,
  });

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEEE').format(date); // e.g. "Monday"
    return DateFormat('MMMM d, y').format(date);
  }

  @override
  Widget build(BuildContext context) {
    // Build flat list of items: date headers + posts
    final items = <_ListItem>[];
    String? lastLabel;

    for (final post in posts) {
      final label = _dateLabel(post.postedAt);
      if (label != lastLabel) {
        items.add(_ListItem.header(label));
        lastLabel = label;
      }
      items.add(_ListItem.post(post));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item.isHeader) {
          return _DateSeparator(label: item.label!);
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _PostListTile(
            post: item.post!,
            campuses: campuses,
            onTap: () => onTap(item.post!),
          ),
        );
      },
    );
  }
}

class _ListItem {
  final bool isHeader;
  final String? label;
  final StaffNoticePost? post;

  const _ListItem.header(this.label)
      : isHeader = true,
        post = null;

  const _ListItem.post(this.post)
      : isHeader = false,
        label = null;
}

class _DateSeparator extends StatelessWidget {
  final String label;
  const _DateSeparator({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: Divider(color: AppTheme.blue100, thickness: 1)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.navy.withOpacity(0.07),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.navy,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Divider(color: AppTheme.blue100, thickness: 1)),
        ],
      ),
    );
  }
}

class _PostListTile extends StatelessWidget {
  final StaffNoticePost post;
  final List<CampusScope> campuses;
  final VoidCallback onTap;

  const _PostListTile({
    required this.post,
    required this.campuses,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scope = scopeLabelForPost(post, campuses);
    final time = DateFormat('h:mm a').format(post.postedAt);

    return Material(
      color: AppTheme.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.blue100),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (post.isPinned) ...[
                          const Icon(Icons.push_pin,
                              size: 14, color: AppTheme.navy),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            scope,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.blue300,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (post.title != null && post.title!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        post.title!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppTheme.navy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      post.body,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.blue300,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    time,
                    style: const TextStyle(fontSize: 11, color: AppTheme.blue300),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${post.readCount} read',
                    style: const TextStyle(fontSize: 11, color: AppTheme.blue300),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
