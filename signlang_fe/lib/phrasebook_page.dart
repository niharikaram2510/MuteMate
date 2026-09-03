import 'package:flutter/material.dart';

import 'live_translation_page.dart';
import 'learn_page.dart';
import 'settings.dart';
import 'theme/app_theme.dart';

class PhrasebookPage extends StatelessWidget {
  const PhrasebookPage({super.key});

  void _openTranslate(BuildContext context) {
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

  void _openSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SettingsPage(),
      ),
    );
  }

  void _openCategory(
    BuildContext context,
    String category,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhraseCategoryPage(
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
              false,
              () => _openLearn(context),
            ),

            _navItem(
              'Phrasebook',
              true,
              () {},
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
      // BODY
      // ==========================================================

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
                  const Text(
                    'Phrasebook',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Useful signs for everyday communication.',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // =================================================
                  // CATEGORY CARDS
                  // =================================================

                  if (isDesktop)
                    Row(
                      children: [
                        Expanded(
                          child: _categoryCard(
                            icon: Icons.waving_hand_rounded,
                            title: 'Greetings',
                            subtitle:
                                'HELLO, HOW ARE YOU, WELCOME, BYE',
                            onTap: () {
                              _openCategory(
                                context,
                                'Greetings',
                              );
                            },
                          ),
                        ),

                        const SizedBox(width: 18),

                        Expanded(
                          child: _categoryCard(
                            icon: Icons.chat_bubble_outline_rounded,
                            title: 'Polite Expressions',
                            subtitle:
                                'THANK YOU, SORRY, PLEASE',
                            onTap: () {
                              _openCategory(
                                context,
                                'Polite Expressions',
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
                          icon: Icons.waving_hand_rounded,
                          title: 'Greetings',
                          subtitle:
                              'HELLO, HOW ARE YOU, WELCOME, BYE',
                          onTap: () {
                            _openCategory(
                              context,
                              'Greetings',
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        _categoryCard(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: 'Polite Expressions',
                          subtitle:
                              'THANK YOU, SORRY, PLEASE',
                          onTap: () {
                            _openCategory(
                              context,
                              'Polite Expressions',
                            );
                          },
                        ),
                      ],
                    ),

                  const SizedBox(height: 18),

                  _categoryCard(
                    icon: Icons.favorite_outline_rounded,
                    title: 'Common Expressions',
                    subtitle:
                        'I LOVE YOU, YES, NO, HELP',
                    onTap: () {
                      _openCategory(
                        context,
                        'Common Expressions',
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
      padding:
          const EdgeInsets.symmetric(horizontal: 3),

      child: TextButton(
        onPressed: onTap,

        style: TextButton.styleFrom(
          foregroundColor: active
              ? AppTheme.secondary
              : AppTheme.textMuted,

          padding:
              const EdgeInsets.symmetric(
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

  Widget _categoryCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppTheme.surface,

      borderRadius:
          BorderRadius.circular(20),

      child: InkWell(
        onTap: onTap,

        borderRadius:
            BorderRadius.circular(20),

        child: Container(
          width: double.infinity,

          padding:
              const EdgeInsets.all(24),

          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(20),

            border: Border.all(
              color:
                  const Color(0xFFE5E7EB),
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

                decoration:
                    BoxDecoration(
                  color:
                      const Color(0xFFF0EBFF),

                  borderRadius:
                      BorderRadius.circular(17),
                ),

                child: Icon(
                  icon,
                  color:
                      AppTheme.secondary,
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

                      style:
                          const TextStyle(
                        color:
                            AppTheme.textPrimary,
                        fontSize: 19,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      subtitle,

                      style:
                          const TextStyle(
                        color:
                            AppTheme.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              const Icon(
                Icons.arrow_forward_ios_rounded,
                color:
                    AppTheme.textMuted,
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
// PHRASE CATEGORY PAGE
// ==================================================================

class PhraseCategoryPage extends StatelessWidget {
  final String category;

  const PhraseCategoryPage({
    super.key,
    required this.category,
  });

  List<String> get _phrases {
    if (category == 'Greetings') {
      return const [
        'HELLO',
        'HOW ARE YOU',
        'WELCOME',
        'BYE',
      ];
    }

    if (category == 'Polite Expressions') {
      return const [
        'THANK YOU',
        'SORRY',
        'PLEASE',
      ];
    }

    return const [
      'I LOVE YOU',
      'YES',
      'NO',
      'HELP',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final width =
        MediaQuery.of(context).size.width;

    final isDesktop = width >= 900;

    final phrases = _phrases;

    return Scaffold(
      backgroundColor:
          AppTheme.background,

      appBar: AppBar(
        backgroundColor:
            AppTheme.surface,

        elevation: 0,

        surfaceTintColor:
            Colors.transparent,

        leading: IconButton(
          tooltip: 'Back',

          icon: const Icon(
            Icons.arrow_back_rounded,
            color:
                AppTheme.textPrimary,
          ),

          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: Text(
          category,

          style: const TextStyle(
            color:
                AppTheme.textPrimary,
            fontSize: 20,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),

      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 1100,
            ),

            child: SingleChildScrollView(
              padding:
                  EdgeInsets.symmetric(
                horizontal:
                    isDesktop ? 48 : 20,
                vertical: 30,
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    category,

                    style: const TextStyle(
                      color:
                          AppTheme.textPrimary,
                      fontSize: 30,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Choose a phrase to view its sign reference.',
                    style: TextStyle(
                      color:
                          AppTheme.textMuted,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 28),

                  GridView.builder(
                    shrinkWrap: true,

                    physics:
                        const NeverScrollableScrollPhysics(),

                    itemCount:
                        phrases.length,

                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          isDesktop ? 3 : 1,

                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,

                      childAspectRatio:
                          isDesktop ? 2.8 : 3.2,
                    ),

                    itemBuilder:
                        (context, index) {
                      return _phraseCard(
                        context,
                        phrases[index],
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

  Widget _phraseCard(
    BuildContext context,
    String phrase,
  ) {
    return Material(
      color:
          AppTheme.surface,

      borderRadius:
          BorderRadius.circular(18),

      child: InkWell(
        onTap: () {
          _showPhrase(
            context,
            phrase,
          );
        },

        borderRadius:
            BorderRadius.circular(18),

        child: Container(
          padding:
              const EdgeInsets.all(18),

          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(18),

            border: Border.all(
              color:
                  const Color(0xFFE5E7EB),
            ),

            boxShadow: [
              AppTheme.softShadow(),
            ],
          ),

          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,

                decoration:
                    BoxDecoration(
                  color:
                      const Color(0xFFF0EBFF),

                  borderRadius:
                      BorderRadius.circular(14),
                ),

                child: const Icon(
                  Icons.sign_language_rounded,
                  color:
                      AppTheme.secondary,
                  size: 24,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Text(
                  phrase,

                  style:
                      const TextStyle(
                    color:
                        AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios_rounded,
                color:
                    AppTheme.textMuted,
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPhrase(
    BuildContext context,
    String phrase,
  ) {
    showDialog(
      context: context,

      builder: (_) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(22),
          ),

          title: Text(
            phrase,

            style:
                const TextStyle(
              fontSize: 25,
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

                decoration:
                    BoxDecoration(
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
                'ISL sign reference for $phrase',

                textAlign:
                    TextAlign.center,

                style:
                    const TextStyle(
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

                style:
                    TextStyle(
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