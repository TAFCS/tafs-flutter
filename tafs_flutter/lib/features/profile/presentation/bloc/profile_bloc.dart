import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/profile_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository repository;

  ProfileBloc({required this.repository}) : super(ProfileInitial()) {
    on<GuardianChangeSubmitted>(_onGuardianChangeSubmitted);
  }

  Future<void> _onGuardianChangeSubmitted(
    GuardianChangeSubmitted event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    final result = await repository.submitGuardianChangeRequest(
      guardianId: event.guardianId,
      familyId: event.familyId,
      changes: event.changes,
    );
    result.fold(
      (failure) => emit(ProfileError(failure.message)),
      (_) => emit(ProfileSuccess()),
    );
  }
}
