import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/employee_notice_cubit.dart';
import '../widgets/employee_notice_card.dart';
import 'employee_notice_detail_page.dart';
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
      child: const _EmployeeNoticeBoardView(),
    );
  }
}

class _EmployeeNoticeBoardView extends StatelessWidget {
  const _EmployeeNoticeBoardView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EmployeeNoticeCubit, EmployeeNoticeState>(
      builder: (context, state) {
        final colorScheme = Theme.of(context).colorScheme;

        if (state.loading && state.notices.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.error != null && state.notices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off_outlined, size: 48, color: colorScheme.onSurface.withOpacity(0.3)),
                const SizedBox(height: 12),
                Text(
                  state.error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () => context.read<EmployeeNoticeCubit>().refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state.notices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.campaign_outlined, size: 56, color: colorScheme.onSurface.withOpacity(0.2)),
                const SizedBox(height: 12),
                Text(
                  'No notices yet',
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.45),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You\'ll see school announcements here.',
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.3),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => context.read<EmployeeNoticeCubit>().refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            itemCount: state.notices.length,
            itemBuilder: (context, index) {
              final notice = state.notices[index];
              return EmployeeNoticeCard(
                notice: notice,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<EmployeeNoticeCubit>(),
                        child: EmployeeNoticeDetailPage(notice: notice),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
