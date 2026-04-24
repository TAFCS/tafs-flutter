import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../fee_ledger/presentation/bloc/fee_ledger_bloc.dart';
import '../../../fee_ledger/presentation/bloc/fee_ledger_event.dart';
import '../../../fee_ledger/presentation/bloc/fee_ledger_state.dart';
import '../../../fee_ledger/presentation/pages/student_profile_page.dart';

class StudentProfileLoader extends StatelessWidget {
  final int studentCc;

  const StudentProfileLoader({super.key, required this.studentCc});

  @override
  Widget build(BuildContext context) {
    // Trigger loading if not already in progress or loaded for this student
    context.read<FeeLedgerBloc>().add(LedgerLoadRequested(studentCc));

    return BlocBuilder<FeeLedgerBloc, FeeLedgerState>(
      builder: (context, state) {
        if (state is LedgerLoaded && state.ledger.student.cc == studentCc) {
          return StudentProfilePage(student: state.ledger.student);
        }
        if (state is FeeLedgerError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Student Profile')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        context.read<FeeLedgerBloc>().add(LedgerLoadRequested(studentCc));
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
