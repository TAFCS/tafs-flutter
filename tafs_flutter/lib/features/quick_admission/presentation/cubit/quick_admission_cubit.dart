import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/quick_admission_repository.dart';
import 'quick_admission_state.dart';

class QuickAdmissionCubit extends Cubit<QuickAdmissionState> {
  final QuickAdmissionRepository repository;

  QuickAdmissionCubit({required this.repository}) : super(QuickAdmissionInitial());

  Future<void> submitAdmissionForm(Map<String, dynamic> data, String? localImagePath) async {
    emit(QuickAdmissionSubmitInProgress());

    final result = await repository.createQuickAdmission(data);
    await result.fold(
      (failure) async {
        emit(QuickAdmissionSubmitFailure(failure.message));
      },
      (admission) async {
        if (localImagePath != null && localImagePath.isNotEmpty) {
          final uploadResult = await repository.uploadPhoto(admission.id, localImagePath);
          await uploadResult.fold(
            (failure) async {
              // Even if upload fails, we created the record. We can emit failure,
              // but it's cleaner to show warning or complete with a note. Let's fail for consistency.
              emit(QuickAdmissionSubmitFailure('Admission created but photo upload failed: ${failure.message}'));
            },
            (photoUrl) async {
              emit(QuickAdmissionSubmitSuccess(admission));
            },
          );
        } else {
          emit(QuickAdmissionSubmitSuccess(admission));
        }
      },
    );
  }

  Future<void> fetchDepositSlip(int cc) async {
    emit(QuickAdmissionPdfLoading());

    final result = await repository.getDepositSlipPdf(cc);
    result.fold(
      (failure) => emit(QuickAdmissionPdfFailure(failure.message)),
      (pdfBytes) => emit(QuickAdmissionPdfSuccess(pdfBytes)),
    );
  }

  void reset() {
    emit(QuickAdmissionInitial());
  }
}
