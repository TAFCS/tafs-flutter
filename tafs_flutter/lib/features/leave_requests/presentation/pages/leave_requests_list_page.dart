import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/repositories/leave_requests_repository_impl.dart';
import '../../domain/entities/leave_request.dart';
import '../cubit/leave_requests_cubit.dart';
import 'submit_leave_page.dart';

class LeaveRequestsListPage extends StatefulWidget {
  final LeaveRequestsRepositoryImpl repository;

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
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.orange;
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openSubmit,
          icon: const Icon(Icons.add),
          label: const Text('Apply'),
          backgroundColor: AppTheme.primary,
        ),
        body: BlocBuilder<LeaveRequestsCubit, LeaveRequestsState>(
          builder: (context, state) {
            if (state is LeaveRequestsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is LeaveRequestsError) {
              return Center(child: Text(state.message));
            }
            if (state is! LeaveRequestsLoaded) {
              return const SizedBox.shrink();
            }

            if (state.items.isEmpty) {
              return RefreshIndicator(
                onRefresh: () async => refresh(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 120),
                    Center(child: Text('No leave requests yet.')),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => refresh(),
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                itemCount: state.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = state.items[index];
                  return _LeaveCard(
                    item: item,
                    statusColor: _statusColor(item.status),
                    dateLabel: '${_fmtDate(item.startDate)} – ${_fmtDate(item.endDate)}',
                    onCancel: item.status == 'PENDING'
                        ? () => _cubit.cancel(item.id)
                        : null,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LeaveCard extends StatelessWidget {
  final LeaveRequest item;
  final Color statusColor;
  final String dateLabel;
  final VoidCallback? onCancel;

  const _LeaveCard({
    required this.item,
    required this.statusColor,
    required this.dateLabel,
    this.onCancel,
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
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.status,
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(dateLabel, style: TextStyle(color: Colors.grey.shade600)),
            if (item.reason != null && item.reason!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(item.reason!),
            ],
            if (item.reviewReason != null && item.reviewReason!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Review: ${item.reviewReason}',
                style: TextStyle(color: Colors.grey.shade700, fontStyle: FontStyle.italic),
              ),
            ],
            if (onCancel != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onCancel,
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
