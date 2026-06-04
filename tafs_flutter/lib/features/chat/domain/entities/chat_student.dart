import 'package:equatable/equatable.dart';

class ChatStudent extends Equatable {
  final int cc;
  final String fullName;
  final String? photographUrl;

  const ChatStudent({
    required this.cc,
    required this.fullName,
    this.photographUrl,
  });

  @override
  List<Object?> get props => [cc, fullName, photographUrl];
}
