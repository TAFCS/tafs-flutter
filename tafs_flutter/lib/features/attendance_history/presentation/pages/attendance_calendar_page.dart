import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../injection_container.dart';
import '../../../auth/domain/entities/student.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/selected_student_cubit.dart';
import '../../../dashboard/presentation/widgets/student_switcher_sheet.dart';
import '../../domain/entities/attendance_day.dart';
import '../bloc/attendance_history_bloc.dart';
import '../bloc/attendance_history_event.dart';
import '../bloc/attendance_history_state.dart';

class AttendanceCalendarPage extends StatefulWidget {
  final Student student;
  final DateTime? initialSelectedDate;

  const AttendanceCalendarPage({
    super.key,
    required this.student,
    this.initialSelectedDate,
  });

  @override
  State<AttendanceCalendarPage> createState() => _AttendanceCalendarPageState();
}

class _AttendanceCalendarPageState extends State<AttendanceCalendarPage> {
  late DateTime _currentMonth;
  DateTime? _selectedDate;
  String? _filterType; // null, "PRESENT", "ABSENT", "LATE"

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(
      widget.initialSelectedDate?.year ?? now.year,
      widget.initialSelectedDate?.month ?? now.month,
      1,
    );
    _selectedDate = widget.initialSelectedDate ?? now;
    _loadHistory();
  }

  void _loadHistory() {
    final monthStr = DateFormat('yyyy-MM').format(_currentMonth);
    context.read<AttendanceHistoryBloc>().add(
          AttendanceHistoryLoadRequested(
            studentCc: widget.student.cc,
            month: monthStr,
          ),
        );
  }

  void _changeMonth(int offset) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + offset, 1);
      _filterType = null;
      // Clear selected date if it doesn't belong to the newly navigated month
      if (_selectedDate != null &&
          (_selectedDate!.year != _currentMonth.year ||
              _selectedDate!.month != _currentMonth.month)) {
        _selectedDate = null;
      }
    });
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.navy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (sheetCtx) => BlocProvider.value(
                value: BlocProvider.of<SelectedStudentCubit>(context),
                child: BlocProvider.value(
                  value: BlocProvider.of<AuthBloc>(context),
                  child: const StudentSwitcherSheet(),
                ),
              ),
            ).then((_) {
              if (mounted) {
                final newActiveStudent = context.read<SelectedStudentCubit>().state;
                if (newActiveStudent != null && newActiveStudent.cc != widget.student.cc) {
                  // Push a replacement page to load the sibling's calendar history
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AttendanceCalendarPage(
                        student: newActiveStudent,
                      ),
                    ),
                  );
                }
              }
            });
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Attendance History',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Text(
                        widget.student.fullName,
                        style: const TextStyle(fontSize: 12, color: AppTheme.blue300, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_drop_down, color: AppTheme.blue300, size: 16),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: BlocBuilder<AttendanceHistoryBloc, AttendanceHistoryState>(
        builder: (context, state) {
          if (state is AttendanceHistoryLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.navy),
            );
          }

          if (state is AttendanceHistoryError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.space6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off_rounded, size: 48, color: AppTheme.blue100),
                    const SizedBox(height: AppTheme.space3),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.navy, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: AppTheme.space4),
                    ElevatedButton(
                      onPressed: _loadHistory,
                      child: const Text('Try Again'),
                    )
                  ],
                ),
              ),
            );
          }

          if (state is AttendanceHistoryLoaded) {
            return _buildContent(state.days);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(List<AttendanceDay> days) {
    // Calculate Stats
    int present = 0;
    int lateDays = 0;
    int absent = 0;
    int holidays = 0;
    int weekends = 0;

    for (final day in days) {
      if (day.isWeekend) {
        weekends++;
      } else if (day.isHoliday) {
        holidays++;
      } else if (day.status == 'PRESENT') {
        present++;
      } else if (day.status == 'LATE') {
        lateDays++;
      } else if (day.status == 'ABSENT') {
        absent++;
      }
    }

    return Column(
      children: [
        // Notice: attendance isn't live yet
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.space5,
            AppTheme.space3,
            AppTheme.space5,
            0,
          ),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.space3),
            decoration: BoxDecoration(
              color: AppTheme.warningBg,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: AppTheme.warning, size: 18),
                const SizedBox(width: AppTheme.space2),
                Expanded(
                  child: Text(
                    'Attendance will start being tracked here once biometric devices are '
                    'installed and all students are enrolled with their biometric records.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.navy.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Month Selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space5, vertical: AppTheme.space2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMMM yyyy').format(_currentMonth),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.navy,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, color: AppTheme.navy, size: 28),
                    onPressed: () => _changeMonth(-1),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, color: AppTheme.navy, size: 28),
                    onPressed: () {
                      final now = DateTime.now();
                      if (_currentMonth.year == now.year && _currentMonth.month == now.month) {
                        return; // Prevent navigating to future months
                      }
                      _changeMonth(1);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        // Calendar Grid Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'].map((day) {
              final isWeekend = day == 'Su' || day == 'Sa';
              return SizedBox(
                width: 40,
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isWeekend
                        ? const Color(0xFFF43F5E)
                        : const Color(0xFF71717A),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppTheme.space2),

        // Grid view
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space5),
            child: _buildCalendarGrid(days),
          ),
        ),

        // Summary Statistics row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space5, vertical: AppTheme.space3),
          child: Wrap(
            spacing: AppTheme.space2,
            runSpacing: AppTheme.space2,
            alignment: WrapAlignment.center,
            children: [
              _buildStatChip('Present', present, 'PRESENT', AppTheme.paid),
              _buildStatChip('Late', lateDays, 'LATE', AppTheme.warning),
              _buildStatChip('Absent', absent, 'ABSENT', AppTheme.danger),
              if (weekends > 0)
                _buildStatChip('Weekend', weekends, 'WEEKEND', const Color(0xFF6B7280)),
              if (holidays > 0)
                _buildStatChip('Holiday', holidays, 'HOLIDAY', const Color(0xFF9333EA)),
            ],
          ),
        ),
        const Divider(color: AppTheme.blue100),

        // Selected Day Details panel
        Expanded(
          flex: 3,
          child: _buildDetailsPanel(days),
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, int count, String type, Color color) {
    final isSelected = _filterType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filterType = isSelected ? null : type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space3, vertical: AppTheme.space2),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.white : color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$count $label',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTheme.white : AppTheme.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(List<AttendanceDay> days) {
    final firstDayOfWeek = _currentMonth.weekday; // 1 = Monday, 7 = Sunday
    final totalEmptyCells = firstDayOfWeek == 7 ? 0 : firstDayOfWeek;

    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final totalCells = totalEmptyCells + daysInMonth;

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1.0,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        if (index < totalEmptyCells) {
          return const SizedBox.shrink();
        }

        final dayNumber = index - totalEmptyCells + 1;
        final dateStr = '${_currentMonth.year}-${_currentMonth.month.toString().padLeft(2, '0')}-${dayNumber.toString().padLeft(2, '0')}';
        final dayData = days.cast<AttendanceDay>().firstWhere(
          (d) => d.date == dateStr,
          orElse: () => AttendanceDay(date: dateStr, sessions: const []),
        );

        final parsedDate = DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
        final isSelected = _selectedDate != null &&
            _selectedDate!.year == parsedDate.year &&
            _selectedDate!.month == parsedDate.month &&
            _selectedDate!.day == parsedDate.day;

        final now = DateTime.now();
        final isToday = now.year == parsedDate.year && now.month == parsedDate.month && now.day == parsedDate.day;

        return _buildDayCell(dayData, dayNumber, isSelected, isToday);
      },
    );
  }

  bool _matchesFilter(AttendanceDay day) {
    switch (_filterType) {
      case 'PRESENT':
        return day.status == 'PRESENT';
      case 'LATE':
        return day.status == 'LATE';
      case 'ABSENT':
        return day.status == 'ABSENT';
      case 'WEEKEND':
        return day.isWeekend;
      case 'HOLIDAY':
        return day.isHoliday || day.isExcused;
      default:
        return true;
    }
  }

  Widget _buildDayCell(AttendanceDay day, int dayNumber, bool isSelected, bool isToday) {
    final isHoliday = day.isHoliday;
    final isWeekendOverride = day.isWeekend;
    final isExcused = day.isExcused;

    final date = DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
    final now = DateTime.now();
    final todayKey = DateTime(now.year, now.month, now.day);
    final dayKey = DateTime(date.year, date.month, date.day);
    final isFuture = dayKey.isAfter(todayKey);

    String classification = 'PRESENT';
    if (isWeekendOverride) {
      classification = 'DAY_OFF';
    } else if (isHoliday || isExcused) {
      classification = 'EXCUSED';
    } else if (day.status == 'LATE') {
      classification = 'LATE';
    } else if (day.status == 'ABSENT') {
      classification = 'ABSENT';
    } else if (day.status == 'PRESENT') {
      classification = 'PRESENT';
    } else {
      classification = 'NONE';
    }

    final hasFilter = _filterType != null;
    final matchesFilter = !hasFilter || _matchesFilter(day);
    final isApprovedLeave = classification == 'EXCUSED';
    final useMutedStyle = (isFuture && !isApprovedLeave) || (hasFilter && !matchesFilter);

    final style = _getCellStyle(useMutedStyle ? 'NONE' : classification, isSelected, isToday, isFuture);

    final background = style.background;
    final textColor = style.text;
    final showDot = !useMutedStyle && classification != 'DAY_OFF' && classification != 'NONE';
    final label = _shortLabel(classification);
    final showLabel = !useMutedStyle &&
        classification != 'DAY_OFF' &&
        classification != 'NONE' &&
        label.isNotEmpty;

    return Opacity(
      opacity: isFuture ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: isFuture
            ? null
            : () {
                setState(() {
                  _selectedDate = DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
                });
              },
        child: Container(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: style.border,
              width: isSelected ? 2.0 : (isToday ? 1.5 : 1.0),
            ),
          ),
          padding: const EdgeInsets.all(4),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (showDot)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: style.dot,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              Center(
                child: Text(
                  '$dayNumber',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    fontSize: 14,
                  ),
                ),
              ),
              if (showLabel)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 1,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: TextStyle(
                      fontSize: 7.5,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      height: 1,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _shortLabel(String classification) {
    switch (classification) {
      case 'PRESENT':
        return 'Present';
      case 'LATE':
        return 'Late';
      case 'ABSENT':
        return 'Absent';
      case 'EXCUSED':
        return 'Leave';
      default:
        return '';
    }
  }

  _CellStyle _getCellStyle(String classification, bool isSelected, bool isToday, bool isFuture) {
    Color borderCol = isSelected
        ? AppTheme.navy
        : isToday
            ? AppTheme.blue300
            : const Color(0xFFE4E4E7);

    switch (classification) {
      case 'LATE':
        return _CellStyle(
          background: const Color(0xFFFFFBEB),
          dot: const Color(0xFFF59E0B),
          text: const Color(0xFFB45309),
          border: isSelected ? AppTheme.navy : (isToday ? AppTheme.blue300 : const Color(0xFFFDE68A)),
        );
      case 'ABSENT':
        return _CellStyle(
          background: const Color(0xFFFFF1F2),
          dot: const Color(0xFFF43F5E),
          text: const Color(0xFFE11D48),
          border: isSelected ? AppTheme.navy : (isToday ? AppTheme.blue300 : const Color(0xFFFECDD3)),
        );
      case 'EXCUSED':
        return _CellStyle(
          background: const Color(0xFFF0F9FF),
          dot: const Color(0xFF38BDF8),
          text: const Color(0xFF0369A1),
          border: isSelected ? AppTheme.navy : (isToday ? AppTheme.blue300 : const Color(0xFFBAE6FD)),
        );
      case 'DAY_OFF':
        return _CellStyle(
          background: const Color(0xFFF4F4F5),
          dot: Colors.transparent,
          text: const Color(0xFF71717A),
          border: isSelected ? AppTheme.navy : (isToday ? AppTheme.blue300 : const Color(0xFFD1D5DB)),
        );
      case 'PRESENT':
        return _CellStyle(
          background: const Color(0xFFECFDF5),
          dot: const Color(0xFF10B981),
          text: const Color(0xFF065F46),
          border: isSelected ? AppTheme.navy : (isToday ? AppTheme.blue300 : const Color(0xFFA7F3D0)),
        );
      case 'NONE':
      default:
        return _CellStyle(
          background: isFuture ? const Color(0xFFFAFAFA) : Colors.white,
          dot: Colors.transparent,
          text: isFuture ? const Color(0xFFA1A1AA) : const Color(0xFF71717A),
          border: borderCol,
        );
    }
  }

  Widget _buildDetailsPanel(List<AttendanceDay> days) {
    if (_selectedDate == null) {
      return const Center(
        child: Text(
          'Select a day to view timings',
          style: TextStyle(color: AppTheme.blue300),
        ),
      );
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final dayData = days.cast<AttendanceDay>().firstWhere(
      (d) => d.date == dateStr,
      orElse: () => AttendanceDay(date: dateStr, sessions: const []),
    );

    final formattedDate = DateFormat('EEEE, d MMMM yyyy').format(_selectedDate!);

    return Container(
      width: double.infinity,
      color: AppTheme.white,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space5, vertical: AppTheme.space4),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.navy),
                ),
                if (dayData.status != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: dayData.status == 'PRESENT'
                          ? AppTheme.paid.withOpacity(0.1)
                          : dayData.status == 'LATE'
                              ? AppTheme.warning.withOpacity(0.15)
                              : dayData.status == 'ABSENT'
                                  ? AppTheme.danger.withOpacity(0.1)
                                  : AppTheme.blue300.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      border: Border.all(
                        color: dayData.status == 'PRESENT'
                            ? AppTheme.paid.withOpacity(0.3)
                            : dayData.status == 'LATE'
                                ? AppTheme.warning.withOpacity(0.3)
                                : dayData.status == 'ABSENT'
                                    ? AppTheme.danger.withOpacity(0.3)
                                    : AppTheme.blue300.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      dayData.status!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: dayData.status == 'PRESENT'
                            ? AppTheme.paid
                            : dayData.status == 'LATE'
                                ? AppTheme.warning
                                : dayData.status == 'ABSENT'
                                    ? AppTheme.danger
                                    : AppTheme.blue300,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.space3),
            if (dayData.isHoliday || dayData.isExcused)
              _buildHolidayCard(dayData.holidayDescription ?? (dayData.isExcused ? 'Excused — day off' : null))
            else if (dayData.isWeekend)
              _buildWeekendCard(dayData.holidayDescription)
            else if (dayData.status == 'ABSENT')
              _buildAbsentDetailCard()
            else if (dayData.sessions.isEmpty)
              _buildNoRecordCard()
            else
              ...dayData.sessions.map((session) => _buildSessionCard(session)),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(AttendanceSession session) {
    final inTimeStr = DateFormat('hh:mm a').format(session.clockIn);
    final outTimeStr = session.clockOut != null ? DateFormat('hh:mm a').format(session.clockOut!) : 'Active';

    String durationStr = '';
    if (session.clockOut != null) {
      final diff = session.clockOut!.difference(session.clockIn);
      final hrs = diff.inHours;
      final mins = diff.inMinutes % 60;
      durationStr = '${hrs}h ${mins}m';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space2),
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.blue100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.space2),
                decoration: const BoxDecoration(
                  color: AppTheme.paidBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.login_rounded, color: AppTheme.paid, size: 18),
              ),
              const SizedBox(width: AppTheme.space3),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Clock In', style: TextStyle(fontSize: 11, color: AppTheme.blue300, fontWeight: FontWeight.bold)),
                  Text(inTimeStr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.navy)),
                ],
              ),
            ],
          ),
          if (durationStr.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.blue100.withOpacity(0.3),
                borderRadius: BorderRadius.circular(AppTheme.radiusXs),
              ),
              child: Text(
                durationStr,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.navy),
              ),
            ),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Clock Out', style: TextStyle(fontSize: 11, color: AppTheme.blue300, fontWeight: FontWeight.bold)),
                  Text(outTimeStr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.navy)),
                ],
              ),
              const SizedBox(width: AppTheme.space3),
              Container(
                padding: const EdgeInsets.all(AppTheme.space2),
                decoration: BoxDecoration(
                  color: session.clockOut != null ? AppTheme.blue100.withOpacity(0.3) : AppTheme.warningBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: session.clockOut != null ? AppTheme.navy : AppTheme.warning,
                  size: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHolidayCard(String? description) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: const Color(0xFFD8B4FE)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.space2),
            decoration: const BoxDecoration(
              color: Color(0xFFEDE9FE),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.celebration_rounded, color: Color(0xFF7C3AED), size: 20),
          ),
          const SizedBox(width: AppTheme.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Holiday',
                  style: TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold, fontSize: 13),
                ),
                if (description != null && description.isNotEmpty)
                  Text(
                    description,
                    style: const TextStyle(color: Color(0xFF6D28D9), fontSize: 12, fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekendCard(String? description) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Row(
        children: [
          const Icon(Icons.weekend_rounded, color: Color(0xFFF59E0B), size: 24),
          const SizedBox(width: AppTheme.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weekend / Day Off',
                  style: TextStyle(color: Color(0xFFB45309), fontWeight: FontWeight.bold, fontSize: 13),
                ),
                if (description != null && description.isNotEmpty)
                  Text(
                    description,
                    style: const TextStyle(color: Color(0xFFB45309), fontSize: 12, fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbsentDetailCard() {

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: AppTheme.danger.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.danger.withOpacity(0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.cancel_rounded, color: AppTheme.danger, size: 24),
          SizedBox(width: AppTheme.space3),
          Expanded(
            child: Text(
              'Absent — No attendance registered',
              style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoRecordCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space4),
      decoration: BoxDecoration(
        color: AppTheme.blue100.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.blue100),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppTheme.blue300, size: 24),
          SizedBox(width: AppTheme.space3),
          Expanded(
            child: Text(
              'No scan records found for this date',
              style: TextStyle(color: AppTheme.blue300, fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _CellStyle {
  final Color background;
  final Color dot;
  final Color text;
  final Color border;

  const _CellStyle({
    required this.background,
    required this.dot,
    required this.text,
    required this.border,
  });
}
