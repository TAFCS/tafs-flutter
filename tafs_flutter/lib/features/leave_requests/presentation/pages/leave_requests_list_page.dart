import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_cached_network_image.dart';
import '../../../../core/widgets/app_dialog_actions.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/leave_request.dart';
import '../../domain/repositories/leave_requests_repository.dart';
import '../cubit/leave_requests_cubit.dart';
import 'submit_leave_page.dart';

class LeaveRequestsListPage extends StatefulWidget {
  final LeaveRequestsRepository repository;

  const LeaveRequestsListPage({super.key, required this.repository});

  @override
  State<LeaveRequestsListPage> createState() => LeaveRequestsListPageState();
}

class LeaveRequestsListPageState extends State<LeaveRequestsListPage> {
  late final LeaveRequestsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = LeaveRequestsCubit(repository: widget.repository)..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void refresh() => _cubit.load();

  Color _statusColor(String status) {
    switch (status) {
      case 'APPROVED':
        return AppTheme.paid;
      case 'REJECTED':
        return AppTheme.danger;
      default:
        return AppTheme.warning;
    }
  }

  String _fmtDate(String iso) {
    final d = DateTime.parse('${iso}T00:00:00Z');
    return DateFormat('d MMM yyyy').format(d);
  }

  Future<void> _openSubmit() async {
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SubmitLeavePage(repository: widget.repository),
      ),
    );
    if (submitted == true) refresh();
  }

  Future<void> _confirmCancel(LeaveRequest item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel leave request?'),
        content: const Text('This will remove your pending leave request.'),
        actions: [
          AppDialogActions.cancel(
            ctx,
            label: 'Keep',
            onPressed: () => Navigator.pop(ctx, false),
          ),
          AppDialogActions.destructive(
            ctx,
            label: 'Cancel request',
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final error = await _cubit.cancel(item.id);
    if (!mounted) return;
    if (error != null) {
      showAppSnackBar(context, error, type: AppSnackBarType.error);
    }
  }

  Future<void> _openAttachment(LeaveRequest item) async {
    final url = item.attachmentUrl;
    if (url == null) return;
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open attachment')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<LeaveRequestsCubit, LeaveRequestsState>(
        builder: (context, state) {
          Widget body;
          if (state is LeaveRequestsLoading) {
            body = const Center(child: CircularProgressIndicator());
          } else if (state is LeaveRequestsError) {
            body = Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMuted),
                ),
              ),
            );
          } else if (state is! LeaveRequestsLoaded) {
            body = const SizedBox.shrink();
          } else if (state.items.isEmpty) {
            body = RefreshIndicator(
              onRefresh: () async => refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 96),
                children: [
                  Icon(Icons.event_busy_outlined, size: 48, color: AppTheme.textMuted.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  const Text(
                    'No leave requests yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 15),
                  ),
                ],
              ),
            );
          } else {
            body = RefreshIndicator(
              onRefresh: () async => refresh(),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: state.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = state.items[index];
                  return _LeaveCard(
                    item: item,
                    statusColor: _statusColor(item.status),
                    dateLabel: '${_fmtDate(item.startDate)} – ${_fmtDate(item.endDate)}',
                    onCancel: item.status == 'PENDING'
                        ? () => _confirmCancel(item)
                        : null,
                    onAttachmentTap: item.attachmentUrl != null
                        ? () => _openAttachment(item)
                        : null,
                  );
                },
              ),
            );
          }

          return Stack(
            children: [
              Positioned.fill(child: body),
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton.extended(
                  onPressed: _openSubmit,
                  backgroundColor: AppTheme.navy,
                  foregroundColor: AppTheme.white,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text(
                    'Apply for Leave',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LeaveCard extends StatelessWidget {
  final LeaveRequest item;
  final Color statusColor;
  final String dateLabel;
  final VoidCallback? onCancel;
  final VoidCallback? onAttachmentTap;

  const _LeaveCard({
    required this.item,
    required this.statusColor,
    required this.dateLabel,
    this.onCancel,
    this.onAttachmentTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.leaveTypeName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppTheme.textMain,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Text(
                    item.status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(dateLabel, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
            if (item.reason != null && item.reason!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(item.reason!, style: const TextStyle(color: AppTheme.textMain, fontSize: 14)),
            ],
            if (item.reviewReason != null && item.reviewReason!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Review: ${item.reviewReason}',
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (item.attachmentUrl != null) ...[
              const SizedBox(height: 8),
              if (item.attachmentType == 'image')
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  child: AppCachedNetworkImage(
                    url: item.attachmentUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: const SizedBox.shrink(),
                  ),
                ),
              TextButton.icon(
                onPressed: onAttachmentTap,
                icon: const Icon(Icons.attach_file, size: 18),
                label: Text(
                  item.attachmentType == 'image' ? 'View attachment' : 'Open PDF',
                ),
              ),
            ],
            if (onCancel != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onCancel,
                  child: const Text('Cancel request'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
