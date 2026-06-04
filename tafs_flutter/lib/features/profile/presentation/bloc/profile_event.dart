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

  const GuardianChangeSubmitted({
    required this.guardianId,
    required this.familyId,
    required this.changes,
  });

  @override
  List<Object?> get props => [guardianId, familyId, changes];
}
