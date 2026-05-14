import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../auth/domain/entities/student.dart';
import '../../auth/presentation/bloc/selected_student_cubit.dart';
import '../../fee_ledger/presentation/bloc/fee_ledger_bloc.dart';
import '../../fee_ledger/presentation/bloc/fee_ledger_event.dart';
import '../../fee_ledger/presentation/bloc/fee_summary_bloc.dart';
import '../../fee_ledger/presentation/bloc/fee_summary_event.dart';
import 'widgets/communication_feed.dart';
import 'widgets/live_ledger_card.dart';

class HomeTabBody extends StatelessWidget {
  final VoidCallback onSwitchToFees;

  const HomeTabBody({super.key, required this.onSwitchToFees});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SelectedStudentCubit, Student?>(
      builder: (context, student) {
        if (student == null) return const SizedBox.shrink();
        return RefreshIndicator(
          onRefresh: () async {
            context.read<FeeSummaryBloc>().add(FeeSummaryLoadRequested(student.cc));
            context.read<FeeLedgerBloc>().add(FeeLedgerLoadRequested(student.cc));
            await Future.delayed(const Duration(milliseconds: 500));
          },
          color: AppTheme.navy,
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppTheme.space5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LiveLedgerCard(
                    studentCc: student.cc,
                    studentName: student.fullName,
                    onTap: onSwitchToFees,
                  ),
                  const SizedBox(height: 32),
                  const CommunicationFeed(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
