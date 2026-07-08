import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/api_error_mapper.dart';
import '../../domain/repositories/profile_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository repository;

  ProfileBloc({required this.repository}) : super(ProfileInitial()) {
    on<GuardianChangeSubmitted>(_onGuardianChangeSubmitted);
    on<StudentChangeSubmitted>(_onStudentChangeSubmitted);
    on<ProfileResetRequested>(_onReset);
  }

  Future<void> _onGuardianChangeSubmitted(
    GuardianChangeSubmitted event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());

    final finalChanges = Map<String, String>.from(event.changes);

    if (event.localPhotoPath != null) {
      final uploadResult = await repository.uploadGuardianPhoto(
        guardianId: event.guardianId,
        filePath: event.localPhotoPath!,
      );

      bool hasError = false;
      uploadResult.fold(
        (failure) {
          emit(ProfileError(ApiErrorMapper.userMessage(failure)));
          hasError = true;
        },
        (url) {
          finalChanges['photo_url'] = url;
        },
      );

      if (hasError) return;
    }

    final result = await repository.submitGuardianChangeRequest(
      guardianId: event.guardianId,
      familyId: event.familyId,
      changes: finalChanges,
    );
    result.fold(
      (failure) => emit(ProfileError(ApiErrorMapper.userMessage(failure))),
      (_) => emit(ProfileSuccess()),
    );
  }

  Future<void> _onStudentChangeSubmitted(
    StudentChangeSubmitted event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());

    final finalChanges = Map<String, dynamic>.from(event.changes);

    if (event.localPhotoPath != null) {
      final uploadResult = await repository.uploadStudentPhoto(
        studentCc: event.studentCc,
        filePath: event.localPhotoPath!,
      );

      bool hasError = false;
      uploadResult.fold(
        (failure) {
          emit(ProfileError(ApiErrorMapper.userMessage(failure)));
          hasError = true;
        },
        (url) {
          finalChanges['photograph_url'] = url;
        },
      );

      if (hasError) return;
    }

    final result = await repository.submitStudentChangeRequest(
      guardianId: event.guardianId,
      familyId: event.familyId,
      studentCc: event.studentCc,
      changes: finalChanges,
    );

    result.fold(
      (failure) => emit(ProfileError(ApiErrorMapper.userMessage(failure))),
      (_) => emit(ProfileSuccess()),
    );
  }

  void _onReset(
    ProfileResetRequested event,
    Emitter<ProfileState> emit,
  ) {
    emit(ProfileInitial());
  }
}
