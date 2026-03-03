import 'package:equatable/equatable.dart';

class Student extends Equatable {
  final int id;
  final String fullName;
  final String section;
  final String? profilePictureUrl;

  const Student({
    required this.id,
    required this.fullName,
    required this.section,
    this.profilePictureUrl,
  });

  @override
  List<Object?> get props => [id, fullName, section, profilePictureUrl];
}
