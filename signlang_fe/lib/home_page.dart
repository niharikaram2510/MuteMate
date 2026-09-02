import 'package:flutter/material.dart';

import 'live_translation_page.dart';
import 'settings.dart';
import 'theme/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String get _greeting {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  void _openLiveTranslation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LiveTranslationPage(),
      ),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SettingsPage(),
      ),
    );
  }

  void _showHistoryMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Translation history will be available soon.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    return Scaffold(
      backgroundColor: AppTheme.background,

      // ----------------------------------------------------------
      // APP BAR
      // ----------------------------------------------------------

      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,

        titleSpacing: isDesktop ? 32 : 20,

        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: AppTheme.brandGradient,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.sign_language_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),

            const SizedBox(width: 12),

            const Text(
              'MuteMate',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(
              Icons.settings_outlined,
              color: AppTheme.textPrimary,
            ),
            onPressed: _openSettings,
          ),

          const SizedBox(width: 16),
        ],
      ),

      // ----------------------------------------------------------
      // BODY
      // ----------------------------------------------------------

      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 48 : 20,
            vertical: 32,
          ),

          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1180,
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ------------------------------------------------
                  // GREETING
                  // ------------------------------------------------

                  Text(
                    '$_greeting 👋',
                    style: TextStyle(
                      fontSize: isDesktop ? 34 : 28,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Ready to communicate?',
                    style: TextStyle(
                      fontSize: 17,
                      color: AppTheme.textMuted,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ------------------------------------------------
                  // MAIN LIVE TRANSLATION CARD
                  // ------------------------------------------------

                  _buildLiveCard(isDesktop),

                  const SizedBox(height: 28),

                  // ------------------------------------------------
                  // QUICK ACCESS TITLE
                  // ------------------------------------------------

                  const Text(
                    'Quick Access',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ------------------------------------------------
                  // QUICK ACCESS
                  // ------------------------------------------------

                  if (isDesktop)
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickCard(
                            icon: Icons.history_rounded,
                            title: 'Translation History',
                            subtitle: 'View previous translations',
                            onTap: _showHistoryMessage,
                          ),
                        ),

                        const SizedBox(width: 18),

                        Expanded(
                          child: _buildQuickCard(
                            icon: Icons.settings_outlined,
                            title: 'Settings',
                            subtitle: 'Manage your preferences',
                            onTap: _openSettings,
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildQuickCard(
                          icon: Icons.history_rounded,
                          title: 'Translation History',
                          subtitle: 'View previous translations',
                          onTap: _showHistoryMessage,
                        ),

                        const SizedBox(height: 14),

                        _buildQuickCard(
                          icon: Icons.settings_outlined,
                          title: 'Settings',
                          subtitle: 'Manage your preferences',
                          onTap: _openSettings,
                        ),
                      ],
                    ),

                  const SizedBox(height: 32),

                  // ------------------------------------------------
                  // RECENT TRANSLATIONS
                  // ------------------------------------------------

                  const Text(
                    'Recent Translations',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 14),

                  _buildEmptyHistory(),

                  const SizedBox(height: 32),

                  // ------------------------------------------------
                  // FOOTER
                  // ------------------------------------------------

                  Center(
                    child: Text(
                      'MuteMate • Bridging the Silence',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // LIVE TRANSLATION CARD
  // ==============================================================

  Widget _buildLiveCard(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        isDesktop ? 32 : 24,
      ),

      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.circular(28),

        boxShadow: [
          AppTheme.softShadow(),
        ],
      ),

      child: isDesktop
          ? Row(
              children: [
                Expanded(
                  child: _buildLiveCardContent(),
                ),

                const SizedBox(width: 30),

                _buildCameraIcon(),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCameraIcon(),

                const SizedBox(height: 24),

                _buildLiveCardContent(),
              ],
            ),
    );
  }

  Widget _buildLiveCardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // Small label

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),

          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(20),
          ),

          child: const Text(
            'LIVE TRANSLATION',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
            ),
          ),
        ),

        const SizedBox(height: 18),

        const Text(
          'Translate Sign Language',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 10),

        const Text(
          'Use your camera to translate sign language '
          'in real time.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 15,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 24),

        SizedBox(
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _openLiveTranslation,

            icon: const Icon(
              Icons.videocam_outlined,
              size: 21,
            ),

            label: const Text(
              'Open Camera',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),

            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.secondary,
              elevation: 0,

              padding: const EdgeInsets.symmetric(
                horizontal: 22,
              ),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCameraIcon() {
    return Container(
      width: 110,
      height: 110,

      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
      ),

      child: const Icon(
        Icons.videocam_rounded,
        color: Colors.white,
        size: 54,
      ),
    );
  }

  // ==============================================================
  // QUICK ACCESS CARD
  // ==============================================================

  Widget _buildQuickCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(20),

      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,

        child: Container(
          padding: const EdgeInsets.all(20),

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),

            boxShadow: [
              AppTheme.softShadow(),
            ],
          ),

          child: Row(
            children: [

              Container(
                width: 52,
                height: 52,

                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),

                child: Icon(
                  icon,
                  color: AppTheme.secondary,
                  size: 25,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppTheme.textMuted,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // EMPTY HISTORY
  // ==============================================================

  Widget _buildEmptyHistory() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 30,
        horizontal: 24,
      ),

      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          AppTheme.softShadow(),
        ],
      ),

      child: Column(
        children: [

          Container(
            width: 58,
            height: 58,

            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(
                alpha: 0.08,
              ),
              borderRadius: BorderRadius.circular(18),
            ),

            child: const Icon(
              Icons.translate_rounded,
              color: AppTheme.secondary,
              size: 27,
            ),
          ),

          const SizedBox(height: 14),

          const Text(
            'No translations yet',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Your recent translations will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}