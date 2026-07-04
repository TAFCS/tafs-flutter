import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubit/employee_notice_cubit.dart';
import '../widgets/employee_notice_card.dart';
import '../../../notice_board/presentation/widgets/notice_board_skeleton.dart';
import '../../domain/repositories/employee_notice_repository.dart';

class EmployeeNoticeBoardPage extends StatefulWidget {
  final EmployeeNoticeRepository repository;

  const EmployeeNoticeBoardPage({super.key, required this.repository});

  @override
  State<EmployeeNoticeBoardPage> createState() => _EmployeeNoticeBoardPageState();
}

class _EmployeeNoticeBoardPageState extends State<EmployeeNoticeBoardPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<EmployeeNoticeCubit>(),
      child: const _EmployeeNoticeFeed(),
    );
  }
}

class _EmployeeNoticeFeed extends StatelessWidget {
  const _EmployeeNoticeFeed();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EmployeeNoticeCubit, EmployeeNoticeState>(
      builder: (context, state) {
        if (state.loading && state.notices.isEmpty) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(
              AppTheme.space5,
              AppTheme.space3,
              AppTheme.space5,
              AppTheme.space5,
            ),
            child: NoticeBoardSkeletonList(),
          );
        }

        if (state.error != null && state.notices.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off_outlined, size: 48,
                      color: AppTheme.textMuted.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  Text(
                    state.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: () => context.read<EmployeeNoticeCubit>().refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state.notices.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => context.read<EmployeeNoticeCubit>().refresh(),
            color: AppTheme.navy,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 80),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.campaign_outlined, size: 48, color: AppTheme.blue100),
                      const SizedBox(height: AppTheme.space3),
                      const Text(
                        'No notices yet',
                        style: TextStyle(color: AppTheme.blue300, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'You\'ll see announcements here.',
                        style: TextStyle(color: AppTheme.blue300, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => context.read<EmployeeNoticeCubit>().refresh(),
          color: AppTheme.navy,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space5,
              AppTheme.space3,
              AppTheme.space5,
              AppTheme.space5,
            ),
            itemCount: state.notices.length,
            itemBuilder: (context, index) {
              return EmployeeNoticeCard(notice: state.notices[index]);
            },
          ),
        );
      },
    );
  }
}
