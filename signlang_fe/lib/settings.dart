import 'package:flutter/material.dart';
import 'theme/app_theme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _buildSectionCard(context, [
            _buildSettingsTile(
              context,
              icon: Icons.person_outline,
              title: 'Account / Profile',
              subtitle: 'View and edit your profile details',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
            ),
            _buildSettingsTile(
              context,
              icon: Icons.notifications_none,
              title: 'Notifications',
              subtitle: 'Manage your notification preferences',
              onTap: () {},
            ),
            _buildSettingsTile(
              context,
              icon: Icons.lock_outline,
              title: 'Privacy',
              subtitle: 'Control your privacy settings',
              onTap: () {},
            ),
            _buildSettingsTile(
              context,
              icon: Icons.info_outline,
              title: 'About',
              subtitle: 'Learn more about the app',
              onTap: () {},
              isLast: true,
            ),
          ]),
          const SizedBox(height: 16),
          _buildSectionCard(context, [
            _buildSettingsTile(
              context,
              icon: Icons.logout,
              title: 'Logout',
              subtitle: 'Sign out from your account',
              iconColor: AppTheme.danger,
              textColor: AppTheme.danger,
              onTap: () => _showLogoutDialog(context),
              isLast: true,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [AppTheme.softShadow()],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Color iconColor = AppTheme.primary,
    Color textColor = AppTheme.textPrimary,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          title: Text(
            title,
            style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          subtitle: subtitle != null
              ? Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13))
              : null,
          trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
          onTap: onTap,
        ),
        if (!isLast) const Divider(height: 1, indent: 70),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context); // go back to previous screen
              },
              child: const Text('Log Out', style: TextStyle(color: AppTheme.danger)),
            ),
          ],
        );
      },
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(
        child: Text(
          'User Profile Information Coming Soon...',
          style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}