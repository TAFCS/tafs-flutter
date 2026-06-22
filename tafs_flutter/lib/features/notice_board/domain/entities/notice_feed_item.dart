import 'package:equatable/equatable.dart';
import 'attendance_alert.dart';
import 'calendar_alert.dart';
import 'notice_post.dart';

abstract class NoticeFeedItem extends Equatable {
  const NoticeFeedItem();

  DateTime get timestamp;
  bool get isRead;
}

class NoticeFeedPost extends NoticeFeedItem {
  final NoticePost post;
  const NoticeFeedPost(this.post);

  @override
  DateTime get timestamp => post.postedAt;

  @override
  bool get isRead => post.isRead;

  NoticeFeedPost copyWith({bool? isRead}) => NoticeFeedPost(post.copyWith(isRead: isRead));

  @override
  List<Object?> get props => [post];
}

class NoticeFeedAlert extends NoticeFeedItem {
  final AttendanceAlert alert;
  const NoticeFeedAlert(this.alert);

  @override
  DateTime get timestamp => alert.scanTimeUtc;

  @override
  bool get isRead => alert.isRead;

  NoticeFeedAlert copyWith({bool? isRead}) => NoticeFeedAlert(alert.copyWith(isRead: isRead));

  @override
  List<Object?> get props => [alert];
}

class NoticeFeedCalendarAlert extends NoticeFeedItem {
  final CalendarAlert alert;
  const NoticeFeedCalendarAlert(this.alert);

  @override
  DateTime get timestamp => alert.createdAt;

  @override
  bool get isRead => alert.isRead;

  NoticeFeedCalendarAlert copyWith({bool? isRead}) => NoticeFeedCalendarAlert(alert.copyWith(isRead: isRead));

  @override
  List<Object?> get props => [alert];
}
