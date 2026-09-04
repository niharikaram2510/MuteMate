import 'package:flutter/material.dart';
import 'app_session.dart';
import 'theme/app_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    return Scaffold(
      backgroundColor: AppTheme.background,

      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Settings'),
      ),

      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1200,
            ),

            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 32 : 16,
                vertical: 20,
              ),

              child: Column(
                children: [
                  // =====================================================
                  // MAIN SETTINGS
                  // =====================================================

                  _buildSectionCard(
                    children: [
                      _buildSettingsTile(
                        icon: Icons.person_outline,
                        title: 'Account / Profile',
                        subtitle:
                            'View your profile details',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const ProfilePage(),
                            ),
                          );
                        },
                      ),
                      _buildSettingsTile(
                        icon: Icons.info_outline,
                        title: 'About',
                        subtitle:
                            'About MuteMate',
                        onTap: () {
                          _showAboutDialog(context);
                        },
                        isLast: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // =====================================================
                  // LOGOUT
                  // =====================================================

                  _buildSectionCard(
                    children: [
                      _buildSettingsTile(
                        icon: Icons.logout_rounded,
                        title: 'Logout',
                        subtitle:
                            'Sign out from your account',
                        iconColor: AppTheme.danger,
                        textColor: AppTheme.danger,
                        onTap: () =>
                            _showLogoutDialog(context),
                        isLast: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // SECTION CARD
  // ===============================================================

  Widget _buildSectionCard({
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,

      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          AppTheme.softShadow(),
        ],
      ),

      child: Column(
        children: children,
      ),
    );
  }

  // ===============================================================
  // SETTINGS TILE
  // ===============================================================

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = AppTheme.primary,
    Color textColor = AppTheme.textPrimary,
    bool isLast = false,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 6,
          ),

          leading: Container(
            width: 46,
            height: 46,

            decoration: BoxDecoration(
              color: iconColor.withOpacity(.1),
              borderRadius:
                  BorderRadius.circular(13),
            ),

            child: Icon(
              icon,
              color: iconColor,
              size: 23,
            ),
          ),

          title: Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          subtitle: Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 13,
            ),
          ),

          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: AppTheme.textMuted,
          ),

          onTap: onTap,
        ),

        if (!isLast)
          const Divider(
            height: 1,
            indent: 86,
          ),
      ],
    );
  }

  // ===============================================================
  // ABOUT
  // ===============================================================

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,

      builder: (_) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,

          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(22),
          ),

          title: const Row(
            children: [
              Icon(
                Icons.sign_language_rounded,
                color: AppTheme.secondary,
              ),

              SizedBox(width: 10),

              Text('About MuteMate'),
            ],
          ),

          content: const Text(
            'MuteMate is an Indian Sign Language '
            'translation application that helps bridge '
            'communication between sign language users '
            'and non-signers.\n\n'
            'Built as an academic mini project using '
            'Flutter, Flask and TensorFlow.\n\n'
            'Version 1.0',
            style: TextStyle(
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),

          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context),

              child: const Text(
                'Close',
              ),
            ),
          ],
        );
      },
    );
  }

  // ===============================================================
  // LOGOUT
  // ===============================================================

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,

      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,

          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),

          title: const Text(
            'Log Out',
          ),

          content: const Text(
            'Are you sure you want to log out?',
          ),

          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(ctx),

              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppTheme.textMuted,
                ),
              ),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(ctx);

                AppSession.email = null;

                // Go back to login.
                Navigator.popUntil(
                  context,
                  (route) => route.isFirst,
                );
              },

              child: const Text(
                'Log Out',
                style: TextStyle(
                  color: AppTheme.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ===============================================================
// PROFILE PAGE
// ===============================================================

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,

      appBar: AppBar(
        title: const Text('Profile'),
      ),

      body: Center(
        child: Container(
          width: 500,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(28),

          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              AppTheme.softShadow(),
            ],
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,

                decoration: BoxDecoration(
                  color: const Color(0xFFF0EBFF),
                  borderRadius: BorderRadius.circular(22),
                ),

                child: const Icon(
                  Icons.person_outline_rounded,
                  color: AppTheme.secondary,
                  size: 38,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Account',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(14),
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Email',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      AppSession.email ?? 'Guest account',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Your account is ready to use.',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
