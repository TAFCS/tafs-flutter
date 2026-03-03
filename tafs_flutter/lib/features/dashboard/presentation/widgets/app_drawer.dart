import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.background,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 64, bottom: 24, left: 16, right: 16),
            width: double.infinity,
            color: AppTheme.primary,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.surface1,
                  child: Icon(Icons.person, color: AppTheme.primary, size: 36),
                ),
                SizedBox(height: 16),
                Text(
                  'FamID: 98765-XYZ',
                  style: TextStyle(
                    color: AppTheme.surface2,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Muhammad Ali',
                  style: TextStyle(
                    color: AppTheme.textOnPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Parent / Guardian',
                  style: TextStyle(
                    color: Color(0xB3FFFFFF), // 70% white
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.dashboard,
                  text: 'Dashboard',
                  onTap: () => Navigator.pop(context),
                  isActive: true,
                ),
                _buildDrawerItem(
                  icon: Icons.account_balance_wallet,
                  text: 'Fee Ledger',
                  onTap: () {
                    // Navigate to Fee Ledger
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.download,
                  text: 'Downloads',
                  onTap: () {
                    // Navigate to Downloads
                  },
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'FUTURE MODULES',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                  ),
                ),
                _buildDrawerItem(
                  icon: Icons.calendar_today,
                  text: 'Attendance',
                  isPlaceholder: true,
                ),
                _buildDrawerItem(
                  icon: Icons.assessment,
                  text: 'Report Cards',
                  isPlaceholder: true,
                ),
                _buildDrawerItem(
                  icon: Icons.people,
                  text: 'Staff Directory',
                  isPlaceholder: true,
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'TAFS App Version 1.0.0',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    VoidCallback? onTap,
    bool isActive = false,
    bool isPlaceholder = false,
  }) {
    final color = isPlaceholder ? AppTheme.textMuted.withValues(alpha: 0.5) : (isActive ? AppTheme.primary : AppTheme.textMain);
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      onTap: isPlaceholder ? null : onTap,
      trailing: isPlaceholder
          ? Icon(Icons.lock_outline, size: 16, color: AppTheme.textMuted.withValues(alpha: 0.5))
          : null,
    );
  }
}
