import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../notice_board/domain/entities/attendance_alert.dart';
import '../../notice_board/domain/entities/notice_feed_item.dart';
import '../../notice_board/presentation/bloc/notice_board_bloc.dart';
import '../../notice_board/presentation/bloc/notice_board_event.dart';
import '../../notice_board/presentation/bloc/notice_board_state.dart';
import '../../notice_board/presentation/widgets/attendance_alert_card.dart';
import '../../notice_board/presentation/widgets/notice_post_card.dart';
import '../../notice_board/presentation/widgets/calendar_alert_card.dart';
import '../../auth/presentation/bloc/selected_student_cubit.dart';
import '../../attendance_history/presentation/pages/attendance_calendar_page.dart';

enum _FeedFilter { all, notices, attendance }

class HomeTabBody extends StatefulWidget {
  const HomeTabBody({super.key});

  @override
  State<HomeTabBody> createState() => _HomeTabBodyState();
}

class _HomeTabBodyState extends State<HomeTabBody> {
  _FeedFilter _activeFilter = _FeedFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bloc = context.read<NoticeBoardBloc>();
      if (bloc.state is NoticeBoardInitial) {
        bloc.add(const NoticeBoardLoadRequested());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<NoticeBoardBloc>().add(const NoticeBoardLoadRequested());
        await Future.delayed(const Duration(milliseconds: 500));
      },
      color: AppTheme.navy,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BlocBuilder<NoticeBoardBloc, NoticeBoardState>(
              builder: (context, state) {
                bool hasUnreadNotices = false;
                bool hasUnreadAttendance = false;
                if (state is NoticeBoardLoaded) {
                  hasUnreadNotices = state.items.whereType<NoticeFeedPost>().any((i) => !i.isRead);
                  hasUnreadAttendance = state.items.whereType<NoticeFeedAlert>().any((i) => !i.isRead);
                }
                return _FilterBar(
                  activeFilter: _activeFilter,
                  onFilterChanged: (f) => setState(() => _activeFilter = f),
                  hasUnreadNotices: hasUnreadNotices,
                  hasUnreadAttendance: hasUnreadAttendance,
                );
              },
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.space5,
                  AppTheme.space3,
                  AppTheme.space5,
                  AppTheme.space5,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _NoticeBoardSection(filter: _activeFilter),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final _FeedFilter activeFilter;
  final ValueChanged<_FeedFilter> onFilterChanged;
  final bool hasUnreadNotices;
  final bool hasUnreadAttendance;

  const _FilterBar({
    required this.activeFilter,
    required this.onFilterChanged,
    required this.hasUnreadNotices,
    required this.hasUnreadAttendance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space5,
        AppTheme.space3,
        AppTheme.space5,
        AppTheme.space2,
      ),
      child: Row(
        children: [
          _Chip(
            label: 'All',
            icon: Icons.dynamic_feed_rounded,
            active: activeFilter == _FeedFilter.all,
            hasUnread: hasUnreadNotices || hasUnreadAttendance,
            onTap: () => onFilterChanged(_FeedFilter.all),
          ),
          const SizedBox(width: AppTheme.space2),
          _Chip(
            label: 'Notices',
            icon: Icons.campaign_rounded,
            active: activeFilter == _FeedFilter.notices,
            hasUnread: hasUnreadNotices,
            onTap: () => onFilterChanged(_FeedFilter.notices),
          ),
          const SizedBox(width: AppTheme.space2),
          _Chip(
            label: 'Attendance',
            icon: Icons.login_rounded,
            active: activeFilter == _FeedFilter.attendance,
            hasUnread: hasUnreadAttendance,
            onTap: () => onFilterChanged(_FeedFilter.attendance),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final bool hasUnread;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.icon,
    required this.active,
    required this.hasUnread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: active ? AppTheme.navy : AppTheme.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              border: Border.all(
                color: active ? AppTheme.navy : AppTheme.blue100,
                width: 1.5,
              ),
              boxShadow: active ? AppTheme.shadowSm : AppTheme.shadowXs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 13,
                  color: active ? AppTheme.white : AppTheme.blue300,
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    color: active ? AppTheme.white : AppTheme.blue300,
                  ),
                ),
              ],
            ),
          ),
          if (hasUnread)
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.unpaid,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NoticeBoardSection extends StatelessWidget {
  final _FeedFilter filter;

  const _NoticeBoardSection({required this.filter});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NoticeBoardBloc, NoticeBoardState>(
      builder: (context, state) {
        if (state is NoticeBoardLoading || state is NoticeBoardInitial) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppTheme.space8),
              child: CircularProgressIndicator(color: AppTheme.navy, strokeWidth: 2),
            ),
          );
        }

        if (state is NoticeBoardError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.space5),
            child: Text(
              'Could not load notices.',
              style: TextStyle(color: AppTheme.blue300, fontSize: 13),
            ),
          );
        }

        if (state is NoticeBoardLoaded) {
          final filtered = _applyFilter(state.items);

          if (filtered.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.space8),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      _emptyIcon(),
                      size: 40,
                      color: AppTheme.blue100,
                    ),
                    const SizedBox(height: AppTheme.space3),
                    Text(
                      _emptyMessage(),
                      style: const TextStyle(color: AppTheme.blue300, fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          }

          if (filter == _FeedFilter.attendance) {
            return _GroupedAttendanceList(items: filtered);
          }

          return Column(
            children: filtered.map((item) {
              if (item is NoticeFeedPost) {
                return NoticePostCard(key: ValueKey('post-${item.post.id}'), post: item.post);
              }
              if (item is NoticeFeedCalendarAlert) {
                return CalendarAlertCard(key: ValueKey('cal-alert-${item.alert.id}'), alert: item.alert);
              }
              final alert = (item as NoticeFeedAlert).alert;
              return AttendanceAlertCard(key: ValueKey('alert-${alert.id}'), alert: alert);
            }).toList(),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  List<NoticeFeedItem> _applyFilter(List<NoticeFeedItem> items) {
    switch (filter) {
      case _FeedFilter.notices:
        return items.whereType<NoticeFeedPost>().toList();
      case _FeedFilter.attendance:
        return items.where((item) => item is NoticeFeedAlert || item is NoticeFeedCalendarAlert).toList();
      case _FeedFilter.all:
        return items;
    }
  }

  IconData _emptyIcon() {
    switch (filter) {
      case _FeedFilter.notices:
        return Icons.campaign_rounded;
      case _FeedFilter.attendance:
        return Icons.login_rounded;
      case _FeedFilter.all:
        return Icons.dynamic_feed_rounded;
    }
  }

  String _emptyMessage() {
    switch (filter) {
      case _FeedFilter.notices:
        return 'No notices at the moment.';
      case _FeedFilter.attendance:
        return 'No attendance alerts yet.';
      case _FeedFilter.all:
        return 'Nothing to show yet.';
    }
  }
}

class _GroupedAttendanceList extends StatelessWidget {
  final List<NoticeFeedItem> items;

  const _GroupedAttendanceList({required this.items});

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<NoticeFeedItem>>{};
    for (final item in items) {
      if (item is NoticeFeedAlert) {
        final local = item.alert.scanTimeLocal;
        final key = _dayLabel(local);
        grouped.putIfAbsent(key, () => []).add(item);
      } else if (item is NoticeFeedCalendarAlert) {
        final local = item.alert.date.toLocal();
        final key = _dayLabel(local);
        grouped.putIfAbsent(key, () => []).add(item);
      }
    }

    return Column(
      children: grouped.entries.map((entry) {
        return _AttendanceDayGroup(dayLabel: entry.key, items: entry.value);
      }).toList(),
    );
  }

  String _dayLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return _weekday(dt.weekday);
    return '${_month(dt.month)} ${dt.day}';
  }

  String _weekday(int w) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[w - 1];
  }

  String _month(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[m - 1];
  }
}

class _AttendanceDayGroup extends StatefulWidget {
  final String dayLabel;
  final List<NoticeFeedItem> items;

  const _AttendanceDayGroup({required this.dayLabel, required this.items});

  @override
  State<_AttendanceDayGroup> createState() => _AttendanceDayGroupState();
}

class _AttendanceDayGroupState extends State<_AttendanceDayGroup> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space3),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.blue100),
        boxShadow: AppTheme.shadowXs,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space4,
                vertical: AppTheme.space3,
              ),
              child: Row(
                children: [
                  Text(
                    widget.dayLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.navy,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.blue100.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: Text(
                      '${widget.items.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.navy,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    size: 18,
                    color: AppTheme.blue300,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: AppTheme.blue100),
            ...widget.items.asMap().entries.map((entry) {
              final item = entry.value;
              final isLast = entry.key == widget.items.length - 1;

              if (item is NoticeFeedCalendarAlert) {
                final alert = item.alert;
                IconData icon;
                Color iconColor;
                Color iconBg;

                if (alert.alertType == 'SCHOOL_OPEN') {
                  icon = Icons.event_available_rounded;
                  iconColor = AppTheme.paid;
                  iconBg = AppTheme.paidBg;
                } else if (alert.alertType == 'DAY_OFF') {
                  icon = Icons.calendar_today_rounded;
                  iconColor = AppTheme.warning;
                  iconBg = AppTheme.warningBg;
                } else {
                  icon = Icons.event_busy_rounded;
                  iconColor = AppTheme.unpaid;
                  iconBg = AppTheme.unpaidBg;
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space4,
                        vertical: AppTheme.space3,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                            child: Icon(icon, size: 15, color: iconColor),
                          ),
                          const SizedBox(width: AppTheme.space3),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                final activeStudent = context.read<SelectedStudentCubit>().state;
                                if (activeStudent != null && activeStudent.cc == alert.studentCc) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AttendanceCalendarPage(
                                        student: activeStudent,
                                        initialSelectedDate: alert.date.toLocal(),
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                alert.body,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.navy,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16, color: AppTheme.blue100),
                  ],
                );
              }

              final alert = (item as NoticeFeedAlert).alert;
              final isClockIn = alert.direction == 'IN';
              final iconColor = isClockIn ? AppTheme.paid : AppTheme.navy;
              final iconBg = isClockIn ? AppTheme.paidBg : AppTheme.blue100;
              final icon = isClockIn ? Icons.login_rounded : Icons.logout_rounded;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space4,
                      vertical: AppTheme.space3,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                          child: Icon(icon, size: 15, color: iconColor),
                        ),
                        const SizedBox(width: AppTheme.space3),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              final activeStudent = context.read<SelectedStudentCubit>().state;
                              if (activeStudent != null && activeStudent.cc == alert.studentCc) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AttendanceCalendarPage(
                                      student: activeStudent,
                                      initialSelectedDate: alert.scanTimeUtc.toLocal(),
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Text(
                              alert.body,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.navy,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16, color: AppTheme.blue100),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }
}
