import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/app_dialog_actions.dart';
import '../../domain/entities/staff_notice_post.dart';
import '../bloc/staff_notice_board_cubit.dart';

class StaffNoticeBoardDetailPage extends StatefulWidget {
  final StaffNoticePost post;

  const StaffNoticeBoardDetailPage({super.key, required this.post});

  @override
  State<StaffNoticeBoardDetailPage> createState() =>
      _StaffNoticeBoardDetailPageState();
}

class _StaffNoticeBoardDetailPageState extends State<StaffNoticeBoardDetailPage> {
  NoticeReadStats? _stats;
  bool _loadingStats = true;
  late bool _isPinned;

  @override
  void initState() {
    super.initState();
    _isPinned = widget.post.isPinned;
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);
    final stats =
        await context.read<StaffNoticeBoardCubit>().loadReadStats(widget.post.id);
    if (mounted) {
      setState(() {
        _stats = stats;
        _loadingStats = false;
      });
    }
  }

  Future<void> _togglePin() async {
    final cubit = context.read<StaffNoticeBoardCubit>();
    if (cubit.state.actionLoading) return;
    final pinned = await cubit.togglePin(widget.post);
    if (mounted) setState(() => _isPinned = pinned);
  }

  Future<void> _delete() async {
    if (context.read<StaffNoticeBoardCubit>().state.actionLoading) return;
    final title = widget.post.title ?? 'this post';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete post?'),
        content: Text('Delete "$title"?'),
        actions: [
          AppDialogActions.cancel(
            ctx,
            onPressed: () => Navigator.pop(ctx, false),
          ),
          AppDialogActions.destructive(
            ctx,
            label: 'Delete',
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final deleted =
        await context.read<StaffNoticeBoardCubit>().deletePost(widget.post.id);
    if (deleted && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StaffNoticeBoardCubit, StaffNoticeBoardState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppTheme.surface2,
          appBar: AppBar(
            title: const Text('Post Analytics'),
            backgroundColor: AppTheme.white,
            foregroundColor: AppTheme.navy,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(
                  _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: _isPinned ? AppTheme.navy : AppTheme.blue300,
                ),
                onPressed: state.actionLoading ? null : _togglePin,
                tooltip: _isPinned ? 'Unpin' : 'Pin',
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: state.actionLoading ? Colors.grey : Colors.red,
                ),
                onPressed: state.actionLoading ? null : _delete,
              ),
            ],
          ),
          body: _buildBody(state),
        );
      },
    );
  }

  Widget _buildBody(StaffNoticeBoardState state) {
    final scope = scopeLabelForPost(widget.post, state.campuses);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (state.actionError != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(8),
            color: Colors.red.shade50,
            child: Text(
              state.actionError!,
              style: TextStyle(color: Colors.red.shade800, fontSize: 12),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.blue100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _badge(scope),
                  if (_isPinned) _badge('Pinned', pinned: true),
                ],
              ),
              if (widget.post.title != null &&
                  widget.post.title!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  widget.post.title!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.navy,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                widget.post.body,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.blue300,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Posted by ${widget.post.postedByName} · ${_formatTimeAgo(widget.post.postedAt)}'
                '${widget.post.expiresAt != null ? ' · Expires ${_formatTimeAgo(widget.post.expiresAt!)}' : ''}',
                style: const TextStyle(fontSize: 11, color: AppTheme.blue300),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'READ ANALYTICS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppTheme.blue300,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        if (_loadingStats)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: AppTheme.navy),
            ),
          )
        else if (_stats == null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Could not load analytics.',
                style: TextStyle(color: AppTheme.blue300),
              ),
              TextButton(
                onPressed: _loadStats,
                child: const Text('Retry'),
              ),
            ],
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: _statCard(
                  '${_stats!.totalReached}',
                  'Families Reached',
                  AppTheme.white,
                  AppTheme.navy,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  '${_stats!.totalRead}',
                  'Families Read',
                  AppTheme.navy.withValues(alpha: 0.08),
                  AppTheme.navy,
                ),
              ),
            ],
          ),
          if (_stats!.totalReached > 0) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Read rate',
                  style: TextStyle(fontSize: 12, color: AppTheme.blue300),
                ),
                Text(
                  '${(_stats!.readRate * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.navy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _stats!.readRate,
                minHeight: 8,
                backgroundColor: AppTheme.blue100,
                color: AppTheme.navy,
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _badge(String text, {bool pinned = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: pinned
            ? AppTheme.navy.withValues(alpha: 0.1)
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: pinned ? AppTheme.navy : AppTheme.blue300,
        ),
      ),
    );
  }

  Widget _statCard(String value, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.blue100),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: fg,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: AppTheme.blue300),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, yyyy').format(date);
  }
}
