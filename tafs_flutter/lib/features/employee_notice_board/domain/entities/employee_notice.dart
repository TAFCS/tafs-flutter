import 'package:equatable/equatable.dart';

class EmployeeNotice extends Equatable {
  final int id;
  final String? title;
  final String body;
  final String postedByName;
  final List<String> mediaUrls;
  final List<String> mediaTypes;
  final bool isPinned;
  final DateTime postedAt;
  final DateTime? expiresAt;
  final bool isRead;
  final DateTime? readAt;

  const EmployeeNotice({
    required this.id,
    this.title,
    required this.body,
    required this.postedByName,
    required this.mediaUrls,
    required this.mediaTypes,
    required this.isPinned,
    required this.postedAt,
    this.expiresAt,
    required this.isRead,
    this.readAt,
  });

  EmployeeNotice copyWith({bool? isRead, DateTime? readAt}) {
    return EmployeeNotice(
      id: id,
      title: title,
      body: body,
      postedByName: postedByName,
      mediaUrls: mediaUrls,
      mediaTypes: mediaTypes,
      isPinned: isPinned,
      postedAt: postedAt,
      expiresAt: expiresAt,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
    );
  }

  @override
  List<Object?> get props => [id, title, body, postedByName, isPinned, postedAt, isRead];
}
