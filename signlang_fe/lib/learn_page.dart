import 'package:flutter/material.dart';

import 'settings.dart';
import 'live_translation_page.dart';
import 'theme/app_theme.dart';


class LearnPage extends StatefulWidget {
  const LearnPage({super.key});

  @override
  State<LearnPage> createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage> {
  String? _selectedCategory;
  

  void _openTranslate() {
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

 

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedCategory = null;
    });
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
              _openTranslate,
            ),

            _navItem(
              'Learn',
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
            onPressed: _openSettings,
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
              maxWidth: 1200,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 40 : 20,
                vertical: 30,
              ),
              child: _selectedCategory == null
                  ? _buildLanding(isDesktop)
                  : isDesktop
                      ? _buildSplitView()
                      : _buildMobileSelectedView(),
            ),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // ORIGINAL LANDING PAGE
  // ================================================================

  Widget _buildLanding(bool isDesktop) {
    return SingleChildScrollView(
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

          if (isDesktop)
            Row(
              children: [
                Expanded(
                  child: _categoryCard(
                    icon: Icons.back_hand_outlined,
                    title: 'Alphabets',
                    subtitle: 'A – Z',
                    description:
                        'Learn the ISL signs for each letter.',
                    onTap: () {
                      _selectCategory('Alphabets');
                    },
                  ),
                ),

                const SizedBox(width: 18),

                Expanded(
                  child: _categoryCard(
                    icon: Icons.pin_outlined,
                    title: 'Numbers',
                    subtitle: '0 – 9',
                    description:
                        'Learn common number signs in ISL.',
                    onTap: () {
                      _selectCategory('Numbers');
                    },
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                _categoryCard(
                  icon: Icons.back_hand_outlined,
                  title: 'Alphabets',
                  subtitle: 'A – Z',
                  description:
                      'Learn the ISL signs for each letter.',
                  onTap: () {
                    _selectCategory('Alphabets');
                  },
                ),

                const SizedBox(height: 16),

                _categoryCard(
                  icon: Icons.pin_outlined,
                  title: 'Numbers',
                  subtitle: '0 – 9',
                  description:
                      'Learn common number signs in ISL.',
                  onTap: () {
                    _selectCategory('Numbers');
                  },
                ),
              ],
            ),

        ],
      ),
    );
  }

  // ================================================================
  // DESKTOP SPLIT VIEW
  // ================================================================

  Widget _buildSplitView() {
    return SizedBox(
      height: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ==========================================================
          // LEFT PANEL
          // ==========================================================

          SizedBox(
            width: 330,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Learn Signs',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Choose a category.',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 24),

                _compactCategoryCard(
                  icon: Icons.back_hand_outlined,
                  title: 'Alphabets',
                  subtitle: 'A – Z',
                  selected:
                      _selectedCategory == 'Alphabets',
                  onTap: () {
                    _selectCategory('Alphabets');
                  },
                ),

                const SizedBox(height: 12),

                _compactCategoryCard(
                  icon: Icons.pin_outlined,
                  title: 'Numbers',
                  subtitle: '0 – 9',
                  selected:
                      _selectedCategory == 'Numbers',
                  onTap: () {
                    _selectCategory('Numbers');
                  },
                ),

              ],
            ),
          ),

          const SizedBox(width: 28),

          // ==========================================================
          // RIGHT PANEL
          // ==========================================================

          Expanded(
            child: _buildSelectedContent(),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // MOBILE SELECTED VIEW
  // ================================================================

  Widget _buildMobileSelectedView() {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Back',
              onPressed: _clearSelection,
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppTheme.textPrimary,
              ),
            ),

            const SizedBox(width: 4),

            Text(
              _selectedCategory!,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        Expanded(
          child: SingleChildScrollView(
            child: _buildSelectedContent(),
          ),
        ),
      ],
    );
  }

  // ================================================================
  // SELECTED CONTENT
  // ================================================================

  Widget _buildSelectedContent() {
    final category = _selectedCategory;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          AppTheme.softShadow(),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          24,
          24,
          24,
          16,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ======================================================
            // HEADER
            // ======================================================

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        category!,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        category == 'Alphabets'
                            ? 'Indian Sign Language alphabet'
                            : 'Indian Sign Language numbers',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  tooltip: 'Close',
                  onPressed: _clearSelection,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ======================================================
            // CONTENT AREA
            // ======================================================

            Expanded(
              child: _buildReferenceImage(
                category == 'Alphabets'
                    ? 'assets/isl/alphabets/alphabet.png'
                    : 'assets/isl/numbers/numbers.png',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // REFERENCE IMAGE
  // ================================================================

  Widget _buildReferenceImage(String assetPath) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F7FC),
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Center(
              child: Image.asset(
                assetPath,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.contain,
                alignment: Alignment.center,
                errorBuilder:
                    (context, error, stackTrace) {
                  return const Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported_outlined,
                        color: AppTheme.textMuted,
                        size: 40,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Reference image could not be loaded.',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Source: Indian Sign Language Research and Training Centre (ISLRTC), Government of India.',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // ================================================================
  // LARGE CATEGORY CARD
  // ================================================================

  Widget _categoryCard({
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
                  borderRadius:
                      BorderRadius.circular(17),
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

  // ================================================================
  // COMPACT CATEGORY CARD
  // ================================================================

  Widget _compactCategoryCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected
          ? const Color(0xFFF3EEFF)
          : AppTheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AppTheme.secondary
                  : const Color(0xFFE5E7EB),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EBFF),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.secondary,
                  size: 23,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.arrow_forward_ios_rounded,
                color: selected
                    ? AppTheme.secondary
                    : AppTheme.textMuted,
                size: selected ? 20 : 14,
              ),
            ],
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
}