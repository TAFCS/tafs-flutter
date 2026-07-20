import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class GuardianChangeSubmitted extends ProfileEvent {
  final int guardianId;
  final int familyId;
  final Map<String, String> changes;
  final String? localPhotoPath;
  final String? localCnicPhotoPath;

  const GuardianChangeSubmitted({
    required this.guardianId,
    required this.familyId,
    required this.changes,
    this.localPhotoPath,
    this.localCnicPhotoPath,
  });

  @override
  List<Object?> get props => [
        guardianId,
        familyId,
        changes,
        localPhotoPath,
        localCnicPhotoPath,
      ];
}

class StudentChangeSubmitted extends ProfileEvent {
  final int guardianId;
  final int familyId;
  final int studentCc;
  final Map<String, dynamic> changes;
  final String? localPhotoPath;

  const StudentChangeSubmitted({
    required this.guardianId,
    required this.familyId,
    required this.studentCc,
    required this.changes,
    this.localPhotoPath,
  });

  @override
  List<Object?> get props => [guardianId, familyId, studentCc, changes, localPhotoPath];
}

class ProfileResetRequested extends ProfileEvent {
  const ProfileResetRequested();
}
