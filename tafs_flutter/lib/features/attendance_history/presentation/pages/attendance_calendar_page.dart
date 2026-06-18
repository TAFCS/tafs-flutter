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

    for (final day in days) {
      if (day.status == 'PRESENT') {
        present++;
      } else if (day.status == 'LATE') {
        lateDays++;
      } else if (day.status == 'ABSENT') {
        absent++;
      }
    }

    // Filter day list for display logic or highlighting
    final filteredDays = days.where((day) {
      if (_filterType == null) return true;
      if (_filterType == 'PRESENT') return day.status == 'PRESENT';
      if (_filterType == 'LATE') return day.status == 'LATE';
      if (_filterType == 'ABSENT') return day.status == 'ABSENT';
      return true;
    }).toList();

    return Column(
      children: [
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
            children: ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'].map((day) {
              return SizedBox(
                width: 40,
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.blue300,
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatChip('Present', present, 'PRESENT', AppTheme.paid),
              _buildStatChip('Late', lateDays, 'LATE', AppTheme.warning),
              _buildStatChip('Absent', absent, 'ABSENT', AppTheme.danger),
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
    final totalEmptyCells = firstDayOfWeek - 1;

    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final totalCells = totalEmptyCells + daysInMonth;

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 0.95,
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

  Widget _buildDayCell(AttendanceDay day, int dayNumber, bool isSelected, bool isToday) {
    Color? cellColor = AppTheme.white;
    Color borderCol = isSelected
        ? AppTheme.navy
        : isToday
            ? AppTheme.blue300
            : AppTheme.blue100;
    double borderWidth = isSelected ? 2.0 : (isToday ? 1.5 : 1.0);

    Color dotColor = Colors.transparent;
    if (day.status == 'PRESENT') {
      dotColor = AppTheme.paid;
    } else if (day.status == 'LATE') {
      dotColor = AppTheme.warning;
    } else if (day.status == 'ABSENT') {
      cellColor = AppTheme.danger.withOpacity(0.08);
      dotColor = AppTheme.danger;
    }

    final date = DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
    final isFuture = date.isAfter(DateTime.now());

    return Opacity(
      opacity: isFuture ? 0.4 : 1.0,
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
            color: cellColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: borderCol, width: borderWidth),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$dayNumber',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppTheme.navy : AppTheme.navy.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 4),
              if (dotColor != Colors.transparent)
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                )
              else
                const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
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
            Text(
              formattedDate,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.navy),
            ),
            const SizedBox(height: AppTheme.space3),
            if (dayData.status == 'ABSENT')
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
          Text(
            'Absent — No attendance registered',
            style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold, fontSize: 13),
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
          Text(
            'No scan records found for this date',
            style: TextStyle(color: AppTheme.blue300, fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
