import 'package:equatable/equatable.dart';

class Student extends Equatable {
  final int cc;
  final String fullName;
  final String? section;
  final String? profilePictureUrl;

  const Student({
    required this.cc,
    required this.fullName,
    this.section,
    this.profilePictureUrl,
  });

  @override
  List<Object?> get props => [cc, fullName, section, profilePictureUrl];
}
