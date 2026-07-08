import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/student.dart';
import '../../../attendance_history/presentation/pages/attendance_calendar_page.dart';
import '../../domain/entities/ledger.dart';
import '../../../profile/presentation/edit_student_page.dart';

class StudentProfilePage extends StatelessWidget {
  final StudentProfile student;

  const StudentProfilePage({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        title: const Text('Student Profile'),
        backgroundColor: AppTheme.white,
        foregroundColor: AppTheme.navy,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppTheme.navy),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditStudentPage(student: student),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.space5),
        child: Column(
          children: [
            _buildProfileHeader(context),
            const SizedBox(height: AppTheme.space6),
            _buildInfoSection(
              context: context,
              title: 'Academic Details',
              items: [
                _InfoRow(label: 'Campus', value: student.campus ?? 'N/A'),
                _InfoRow(label: 'Class', value: student.className ?? 'N/A'),
                _InfoRow(label: 'Section', value: student.section ?? 'N/A'),
                _InfoRow(label: 'House', value: student.house ?? 'N/A'),
                _InfoRow(label: 'CC', value: student.cc.toString()),
                _InfoRow(label: 'GR Number', value: student.grNumber ?? 'N/A'),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AttendanceCalendarPage(
                          student: Student(
                            cc: student.cc,
                            fullName: student.fullName,
                            grNumber: student.grNumber,
                            photographUrl: student.photographUrl,
                            campus: student.campus,
                            className: student.className,
                            section: student.section,
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Attendance Record',
                          style: TextStyle(color: AppTheme.navy, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Row(
                          children: [
                            Text(
                              'View Calendar',
                              style: TextStyle(color: AppTheme.blue300, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.calendar_month_rounded, color: AppTheme.navy, size: 18),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space6),
            _buildInfoSection(
              context: context,
              title: 'Personal Details',
              items: [
                _InfoRow(
                  label: 'Date of Birth',
                  value: student.dob != null ? DateFormat('dd MMM yyyy').format(student.dob!) : 'N/A',
                ),
                _InfoRow(label: 'Gender', value: student.gender ?? 'N/A'),
              ],
            ),
            const SizedBox(height: AppTheme.space6),
            _buildInfoSection(
              context: context,
              title: 'Guardian Information',
              items: student.guardians.map((g) => _InfoRow(
                label: g.relationship,
                value: '${g.name}${g.phone != null ? '\n${g.phone}' : ''}',
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space6),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: AppTheme.shadowSm,
        border: Border.all(color: AppTheme.blue100.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Hero(
            tag: 'student_photo_${student.cc}',
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.blue100, width: 3),
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: AppTheme.blue100.withValues(alpha: 0.3),
                backgroundImage: student.photographUrl != null
                    ? NetworkImage(student.photographUrl!)
                    : null,
                child: student.photographUrl == null
                    ? const Icon(Icons.person, size: 50, color: AppTheme.navy)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            student.fullName,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppTheme.space1),
          Text(
            'CC: ${student.cc}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.blue300,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({required BuildContext context, required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppTheme.space2, bottom: AppTheme.space3),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(AppTheme.space4),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.blue100),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  item,
                  if (idx < items.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppTheme.space3),
                      child: Divider(height: 1, color: AppTheme.blue100),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.blue300,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        const SizedBox(width: AppTheme.space4),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.navy,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

