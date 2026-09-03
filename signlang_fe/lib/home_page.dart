import 'package:flutter/material.dart';

import 'live_translation_page.dart';
import 'learn_page.dart';
import 'phrasebook_page.dart';
import 'settings.dart';
import 'theme/app_theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // ==============================================================
  // NAVIGATION
  // ==============================================================

  void _openLiveTranslation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LiveTranslationPage(),
      ),
    );
  }

  void _openLearn(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LearnPage(),
      ),
    );
  }

  void _openPhrasebook(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PhrasebookPage(),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SettingsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    return Scaffold(
      backgroundColor: AppTheme.background,

      // ==========================================================
      // NAVBAR
      // ==========================================================

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
          if (isDesktop) ...[
            _buildNavItem(
              label: 'Home',
              active: true,
              onTap: () {},
            ),

            _buildNavItem(
              label: 'Translate',
              active: false,
              onTap: () {
                _openLiveTranslation(context);
              },
            ),

            _buildNavItem(
              label: 'Learn',
              active: false,
              onTap: () {
                _openLearn(context);
              },
            ),

            _buildNavItem(
              label: 'Phrasebook',
              active: false,
              onTap: () {
                _openPhrasebook(context);
              },
            ),

            const SizedBox(width: 10),

            Container(
              width: 1,
              height: 28,
              color: const Color(0xFFE5E7EB),
            ),

            const SizedBox(width: 8),
          ],

          IconButton(
            tooltip: 'Settings',
            icon: const Icon(
              Icons.settings_outlined,
              color: AppTheme.textPrimary,
            ),
            onPressed: () {
              _openSettings(context);
            },
          ),

          const SizedBox(width: 16),
        ],
      ),

      // ==========================================================
      // HOME CONTENT
      // ==========================================================

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 48 : 20,
              vertical: isDesktop ? 32 : 24,
            ),

            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1100,
              ),

              child: Column(
                children: [
                  // =================================================
                  // TOP TWO CARDS
                  // =================================================

                  if (isDesktop)
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildFeatureCard(
                            icon: Icons.videocam_rounded,
                            title: 'Live Translation',
                            description:
                                'Translate signs using your camera.',
                            action: 'Start Translating',
                            highlighted: true,
                            onTap: () {
                              _openLiveTranslation(
                                context,
                              );
                            },
                          ),
                        ),

                        const SizedBox(width: 20),

                        Expanded(
                          child: _buildFeatureCard(
                            icon:
                                Icons.sign_language_rounded,
                            title: 'Learn Signs',
                            description:
                                'Explore supported signs and their meanings.',
                            action: 'Explore',
                            onTap: () {
                              _openLearn(context);
                            },
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildFeatureCard(
                          icon: Icons.videocam_rounded,
                          title: 'Live Translation',
                          description:
                              'Translate signs using your camera.',
                          action: 'Start Translating',
                          highlighted: true,
                          onTap: () {
                            _openLiveTranslation(
                              context,
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        _buildFeatureCard(
                          icon:
                              Icons.sign_language_rounded,
                          title: 'Learn Signs',
                          description:
                              'Explore supported signs and their meanings.',
                          action: 'Explore',
                          onTap: () {
                            _openLearn(context);
                          },
                        ),
                      ],
                    ),

                  const SizedBox(height: 20),

                  // =================================================
                  // PHRASEBOOK
                  // =================================================

                  _buildPhrasebookCard(
                    onTap: () {
                      _openPhrasebook(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // NAV ITEM
  // ==============================================================

  Widget _buildNavItem({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 3,
      ),

      child: TextButton(
        onPressed: onTap,

        style: TextButton.styleFrom(
          foregroundColor: active
              ? AppTheme.secondary
              : AppTheme.textMuted,

          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),

        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: active
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // FEATURE CARD
  // ==============================================================

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required String action,
    required VoidCallback onTap,
    bool highlighted = false,
  }) {
    return Material(
      color: AppTheme.surface,

      borderRadius: BorderRadius.circular(22),

      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(22),

        child: Container(
          width: double.infinity,

          padding: const EdgeInsets.all(28),

          decoration: BoxDecoration(
            color: AppTheme.surface,

            borderRadius: BorderRadius.circular(22),

            border: Border.all(
              color: highlighted
                  ? AppTheme.secondary.withValues(
                      alpha: 0.18,
                    )
                  : const Color(0xFFE5E7EB),
            ),

            boxShadow: [
              AppTheme.softShadow(),
            ],
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              // Icon

              Container(
                width: 58,
                height: 58,

                decoration: BoxDecoration(
                  color:
                      const Color(0xFFF0EBFF),

                  borderRadius:
                      BorderRadius.circular(17),
                ),

                child: Icon(
                  icon,
                  color: AppTheme.secondary,
                  size: 29,
                ),
              ),

              const SizedBox(height: 22),

              // Title

              Text(
                title,

                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              // Description

              Text(
                description,

                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 22),

              // Action

              Row(
                children: [
                  Text(
                    action,

                    style: const TextStyle(
                      color: AppTheme.secondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(width: 8),

                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppTheme.secondary,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // PHRASEBOOK CARD
  // ==============================================================

  Widget _buildPhrasebookCard({
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppTheme.surface,

      borderRadius: BorderRadius.circular(22),

      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(22),

        child: Container(
          width: double.infinity,

          padding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 22,
          ),

          decoration: BoxDecoration(
            color: AppTheme.surface,

            borderRadius: BorderRadius.circular(22),

            border: Border.all(
              color: const Color(0xFFE5E7EB),
            ),

            boxShadow: [
              AppTheme.softShadow(),
            ],
          ),

          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,

                decoration: BoxDecoration(
                  color: const Color(0xFFF0EBFF),

                  borderRadius:
                      BorderRadius.circular(17),
                ),

                child: const Icon(
                  Icons.menu_book_rounded,
                  color: AppTheme.secondary,
                  size: 29,
                ),
              ),

              const SizedBox(width: 18),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      'Phrasebook',

                      style: TextStyle(
                        color:
                            AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    SizedBox(height: 5),

                    Text(
                      'Useful signs for everyday communication.',

                      style: TextStyle(
                        color:
                            AppTheme.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.arrow_forward_rounded,
                color: AppTheme.secondary,
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }
}