import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'widgets/app_drawer.dart';
import 'widgets/student_switcher_sheet.dart';
import 'widgets/live_ledger_card.dart';
import 'widgets/communication_feed.dart';

class MainDashboardPage extends StatelessWidget {
  final Map<String, String> student;

  const MainDashboardPage({super.key, required this.student});

  void _showStudentSwitcher(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const StudentSwitcherSheet(),
    ).then((selectedStudent) {
      if (!context.mounted) return;
      if (selectedStudent != null && selectedStudent != student) {
        // Typically handled by BLoC instead of Navigator
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainDashboardPage(student: selectedStudent as Map<String, String>),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: AppTheme.surface1,
        foregroundColor: AppTheme.textMain,
        elevation: 0,
        centerTitle: false,
        title: GestureDetector(
          onTap: () => _showStudentSwitcher(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        student['name'] ?? 'Student',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, color: AppTheme.primary),
                    ],
                  ),
                  Text(
                    '${student['gr'] ?? 'GR-XXXX'} • ${student['campus'] ?? 'Main Campus'}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, Color(0xFF1B436D)], // Darker Denim
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${student['grade']} - ${student['section']}',
                      style: const TextStyle(
                        color: AppTheme.textOnPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Welcome to TAFS!',
                      style: TextStyle(
                        color: AppTheme.textOnPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Live Ledger
              const LiveLedgerCard(),
              const SizedBox(height: 32),
              // Communication Feed
              const CommunicationFeed(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
