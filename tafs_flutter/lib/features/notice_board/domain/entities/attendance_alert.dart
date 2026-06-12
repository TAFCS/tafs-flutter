import 'package:equatable/equatable.dart';

class AttendanceAlert extends Equatable {
  final int id;
  final int studentCc;
  final String studentName;
  final String direction; // 'IN' | 'OUT'
  final DateTime scanTime;
  final String title;
  final String body;
  final bool isRead;

  const AttendanceAlert({
    required this.id,
    required this.studentCc,
    required this.studentName,
    required this.direction,
    required this.scanTime,
    required this.title,
    required this.body,
    required this.isRead,
  });

  // `scanTime` is stored as a naive timestamp representing the device's
  // local wall-clock time (not a true UTC instant). `scanTimeLocal` reads
  // back those wall-clock components as a local DateTime, and `scanTimeUtc`
  // converts that to a real UTC instant for cross-feed sorting.
  DateTime get scanTimeLocal => DateTime(
        scanTime.year,
        scanTime.month,
        scanTime.day,
        scanTime.hour,
        scanTime.minute,
        scanTime.second,
      );

  DateTime get scanTimeUtc => scanTimeLocal.toUtc();

  AttendanceAlert copyWith({bool? isRead}) {
    return AttendanceAlert(
      id: id,
      studentCc: studentCc,
      studentName: studentName,
      direction: direction,
      scanTime: scanTime,
      title: title,
      body: body,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  List<Object?> get props => [id, studentCc, direction, scanTime, isRead];
}
