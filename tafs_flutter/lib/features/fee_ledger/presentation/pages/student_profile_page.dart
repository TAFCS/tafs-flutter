import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/ledger.dart';

class StudentProfilePage extends StatelessWidget {
  final StudentProfile student;

  const StudentProfilePage({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Student Profile'),
        backgroundColor: AppTheme.surface1,
        foregroundColor: AppTheme.textMain,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 24),
            _buildInfoSection(
              title: 'Academic Details',
              items: [
                _InfoRow(label: 'Campus', value: student.campus ?? 'N/A'),
                _InfoRow(label: 'Class', value: student.className ?? 'N/A'),
                _InfoRow(label: 'Section', value: student.section ?? 'N/A'),
                _InfoRow(label: 'House', value: student.house ?? 'N/A'),
                _InfoRow(label: 'CC', value: student.cc.toString()),
                _InfoRow(label: 'GR Number', value: student.grNumber ?? 'N/A'),
              ],
            ),
            const SizedBox(height: 24),
            _buildInfoSection(
              title: 'Personal Details',
              items: [
                _InfoRow(
                  label: 'Date of Birth',
                  value: student.dob != null ? DateFormat('dd MMM yyyy').format(student.dob!) : 'N/A',
                ),
                _InfoRow(label: 'Gender', value: student.gender ?? 'N/A'),
              ],
            ),
            const SizedBox(height: 24),
            _buildInfoSection(
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

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface1,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.shadowL1,
      ),
      child: Column(
        children: [
          Hero(
            tag: 'student_photo_${student.cc}',
            child: CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primary.withOpacity(0.1),
              backgroundImage: student.photographUrl != null
                  ? NetworkImage(student.photographUrl!)
                  : null,
              child: student.photographUrl == null
                  ? const Icon(Icons.person, size: 50, color: AppTheme.primary)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            student.fullName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textMain,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'CC: ${student.cc}',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({required String title, required List<_InfoRow> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.textMuted,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface1,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderSubtle),
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
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, color: AppTheme.borderSubtle),
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
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textMain,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
