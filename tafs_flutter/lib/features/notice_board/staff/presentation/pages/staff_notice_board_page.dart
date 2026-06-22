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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  const Text(
                    'Notice Board',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.navy,
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
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
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New Post'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.navy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: state.loading && state.posts.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.navy),
                    )
                  : state.posts.isEmpty
                      ? const Center(
                          child: Text(
                            'No posts yet.\nTap New Post to create one.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.blue300),
                          ),
                        )
                      : RefreshIndicator(
                          color: AppTheme.navy,
                          onRefresh: () =>
                              context.read<StaffNoticeBoardCubit>().refresh(),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            itemCount: state.posts.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final post = state.posts[index];
                              return _PostListTile(
                                post: post,
                                campuses: state.campuses,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BlocProvider.value(
                                      value:
                                          context.read<StaffNoticeBoardCubit>(),
                                      child: StaffNoticeBoardDetailPage(
                                        post: post,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
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
    final timeAgo = _formatTimeAgo(post.postedAt);

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
                    timeAgo,
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

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(date);
  }
}
