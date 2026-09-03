import 'package:flutter/material.dart';

import 'settings.dart';
import 'live_translation_page.dart';
import 'theme/app_theme.dart';
import 'phrasebook_page.dart';

class LearnPage extends StatelessWidget {
  const LearnPage({super.key});

  void _openTranslate(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LiveTranslationPage(),
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

  void _openCategory(BuildContext context, String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SignCategoryPage(
          category: category,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    return Scaffold(
      backgroundColor: AppTheme.background,

      // ============================================================
      // NAVBAR
      // ============================================================
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
            _navItem(
              'Home',
              false,
              () {
                Navigator.popUntil(
                  context,
                  (route) => route.isFirst,
                );
              },
            ),

            _navItem(
              'Translate',
              false,
              () => _openTranslate(context),
            ),

            _navItem(
              'Learn',
              true,
              () {},
            ),

            _navItem(
              'Phrasebook',
              false,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PhrasebookPage(),
                  ),
                );
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
            onPressed: () => _openSettings(context),
          ),

          const SizedBox(width: 16),
        ],
      ),

      // ============================================================
      // BODY
      // ============================================================
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1100,
            ),

            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 48 : 20,
                vertical: 30,
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  const Text(
                    'Learn Signs',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Explore Indian Sign Language references.',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // =================================================
                  // ALPHABETS + NUMBERS
                  // =================================================

                  if (isDesktop)
                    Row(
                      children: [
                        Expanded(
                          child: _categoryCard(
                            context,

                            icon: Icons.back_hand_outlined,

                            title: 'Alphabets',

                            subtitle: 'A – Z',

                            description:
                                'Learn the ISL signs for each letter.',

                            onTap: () {
                              _openCategory(
                                context,
                                'Alphabets',
                              );
                            },
                          ),
                        ),

                        const SizedBox(width: 18),

                        Expanded(
                          child: _categoryCard(
                            context,

                            icon: Icons.pin_outlined,

                            title: 'Numbers',

                            subtitle: '0 – 9',

                            description:
                                'Learn common number signs in ISL.',

                            onTap: () {
                              _openCategory(
                                context,
                                'Numbers',
                              );
                            },
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _categoryCard(
                          context,

                          icon: Icons.back_hand_outlined,

                          title: 'Alphabets',

                          subtitle: 'A – Z',

                          description:
                              'Learn the ISL signs for each letter.',

                          onTap: () {
                            _openCategory(
                              context,
                              'Alphabets',
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        _categoryCard(
                          context,

                          icon: Icons.pin_outlined,

                          title: 'Numbers',

                          subtitle: '0 – 9',

                          description:
                              'Learn common number signs in ISL.',

                          onTap: () {
                            _openCategory(
                              context,
                              'Numbers',
                            );
                          },
                        ),
                      ],
                    ),

                  const SizedBox(height: 18),

                  // =================================================
                  // EVERYDAY PHRASES
                  // =================================================

                  _categoryCard(
                    context,

                    icon: Icons.chat_bubble_outline_rounded,

                    title: 'Common Everyday Phrases',

                    subtitle:
                        'Useful everyday communication',

                    description:
                        'HELLO, THANK YOU, SORRY, WELCOME and more.',

                    onTap: () {
                      _openCategory(
                        context,
                        'Common Everyday Phrases',
                      );
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

  // ================================================================
  // NAV ITEM
  // ================================================================

  Widget _navItem(
    String label,
    bool active,
    VoidCallback onTap,
  ) {
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

  // ================================================================
  // CATEGORY CARD
  // ================================================================

  Widget _categoryCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppTheme.surface,

      borderRadius: BorderRadius.circular(20),

      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(20),

        child: Container(
          padding: const EdgeInsets.all(24),

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),

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
                width: 62,
                height: 62,

                decoration: BoxDecoration(
                  color: const Color(0xFFF0EBFF),
                  borderRadius: BorderRadius.circular(17),
                ),

                child: Icon(
                  icon,
                  color: AppTheme.secondary,
                  size: 30,
                ),
              ),

              const SizedBox(width: 18),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      title,

                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,

                      style: const TextStyle(
                        color: AppTheme.secondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      description,

                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppTheme.textMuted,
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================================================================
// CATEGORY PAGE
// ==================================================================

class SignCategoryPage extends StatelessWidget {
  final String category;

  const SignCategoryPage({
    super.key,
    required this.category,
  });

  // ================================================================
  // CONTENT
  // ================================================================

  List<String> get _signs {
    if (category == 'Alphabets') {
      return 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');
    }

    if (category == 'Numbers') {
      return List.generate(
        10,
        (index) => '$index',
      );
    }

    return const [
      'HELLO',
      'HOW ARE YOU',
      'THANK YOU',
      'SORRY',
      'WELCOME',
      'BYE',
      'I LOVE YOU',
    ];
  }

  String get _subtitle {
    if (category == 'Alphabets') {
      return 'Indian Sign Language alphabet';
    }

    if (category == 'Numbers') {
      return 'Indian Sign Language numbers';
    }

    return 'Useful signs for everyday communication';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    final signs = _signs;

    final isPhraseCategory =
        category == 'Common Everyday Phrases';

    return Scaffold(
      backgroundColor: AppTheme.background,

      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,

        leading: IconButton(
          tooltip: 'Back',

          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppTheme.textPrimary,
          ),

          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: Text(
          category,

          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1100,
            ),

            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 48 : 20,
                vertical: 30,
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    category,

                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    _subtitle,

                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 28),

                  GridView.builder(
                    shrinkWrap: true,

                    physics:
                        const NeverScrollableScrollPhysics(),

                    itemCount: signs.length,

                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isPhraseCategory
                          ? (isDesktop ? 3 : 1)
                          : (isDesktop ? 7 : 4),

                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,

                      childAspectRatio: isPhraseCategory
                          ? (isDesktop ? 2.8 : 3.2)
                          : 1.0,
                    ),

                    itemBuilder: (context, index) {
                      return _signCard(
                        context,
                        signs[index],
                      );
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

  // ================================================================
  // SIGN CARD
  // ================================================================

  Widget _signCard(
    BuildContext context,
    String sign,
  ) {
    return Material(
      color: AppTheme.surface,

      borderRadius: BorderRadius.circular(18),

      child: InkWell(
        onTap: () {
          _showSign(
            context,
            sign,
          );
        },

        borderRadius: BorderRadius.circular(18),

        child: Container(
          padding: const EdgeInsets.all(16),

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),

            border: Border.all(
              color: const Color(0xFFE5E7EB),
            ),

            boxShadow: [
              AppTheme.softShadow(),
            ],
          ),

          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [
              Container(
                width: 52,
                height: 52,

                decoration: BoxDecoration(
                  color: const Color(0xFFF0EBFF),

                  borderRadius:
                      BorderRadius.circular(15),
                ),

                child: const Icon(
                  Icons.sign_language_rounded,

                  color: AppTheme.secondary,

                  size: 26,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                sign,

                textAlign: TextAlign.center,

                maxLines: 2,

                overflow:
                    TextOverflow.ellipsis,

                style: const TextStyle(
                  color: AppTheme.textPrimary,

                  fontSize: 16,

                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // SIGN DETAIL
  // ================================================================

  void _showSign(
    BuildContext context,
    String sign,
  ) {
    showDialog(
      context: context,

      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(22),
          ),

          title: Text(
            sign,

            style: const TextStyle(
              fontSize: 26,

              fontWeight:
                  FontWeight.w700,

              color:
                  AppTheme.textPrimary,
            ),
          ),

          content: Column(
            mainAxisSize:
                MainAxisSize.min,

            children: [
              Container(
                width: 170,
                height: 170,

                decoration: BoxDecoration(
                  color:
                      const Color(0xFFF0EBFF),

                  borderRadius:
                      BorderRadius.circular(24),
                ),

                child: const Icon(
                  Icons.sign_language_rounded,

                  color:
                      AppTheme.secondary,

                  size: 76,
                ),
              ),

              const SizedBox(height: 18),

              Text(
                'ISL sign reference for $sign',

                textAlign:
                    TextAlign.center,

                style: const TextStyle(
                  color:
                      AppTheme.textMuted,

                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Sign illustration can be added here.',

                textAlign:
                    TextAlign.center,

                style: TextStyle(
                  color:
                      AppTheme.textMuted,

                  fontSize: 12,
                ),
              ),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child:
                  const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}