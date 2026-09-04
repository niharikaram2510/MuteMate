import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'home_page.dart';
import 'register_page.dart';
import 'app_session.dart';
import 'theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;

  static const String backendUrl =
      'http://127.0.0.1:5000';

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ==============================================================
  // GO HOME
  // ==============================================================

  void _goToHome() {
    AppSession.email = null;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const HomePage(),
      ),
    );
  }

  // ==============================================================
  // LOGIN
  // ==============================================================

  Future<void> _handleContinue() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$backendUrl/login'),

        headers: {
          'Content-Type': 'application/json',
        },

        body: jsonEncode({
          'email': emailController.text.trim(),
          'password': passwordController.text,
        }),
      );

      if (!mounted) return;

      final data = jsonDecode(response.body);

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200 &&
          data['success'] == true) {
        AppSession.email =
            data['user']?['email'] ?? emailController.text.trim();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const HomePage(),
          ),
        );
      } else {
        _showMessage(
          data['message'] ??
              'Invalid email or password.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        'Unable to connect to the backend.',
      );
    }
  }

  // ==============================================================
  // CREATE ACCOUNT
  // ==============================================================

  void _openRegisterPage() {
    FocusScope.of(context).unfocus();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RegisterPage(),
      ),
    );
  }

  // MESSAGE
  // ==============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ==============================================================
  // SETTINGS
  // ==============================================================

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },

      child: Scaffold(
        backgroundColor: AppTheme.background,

        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;
              final isDesktop = width >= 700;
              final isCompact = height < 900;

              return Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal:
                        isDesktop ? 24 : 20,
                    vertical: isCompact ? 8 : 20,
                  ),

                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: isDesktop ? 520 : width - 40,
                      child: ConstrainedBox(
                        constraints:
                            const BoxConstraints(
                          maxWidth: 520,
                        ),

                        child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,

                      children: [
                        // ==================================================
                        // LOGO
                        // ==================================================

                        Hero(
                          tag: 'logo',

                          child: Container(
                            width:
                                isDesktop ? (isCompact ? 60 : 82) : (isCompact ? 60 : 72),

                            height:
                                isDesktop ? (isCompact ? 60 : 82) : (isCompact ? 60 : 72),

                            decoration:
                                BoxDecoration(
                              gradient:
                                  AppTheme
                                      .brandGradient,

                              borderRadius:
                                  BorderRadius
                                      .circular(
                                24,
                              ),

                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme
                                      .secondary
                                      .withOpacity(
                                    .22,
                                  ),

                                  blurRadius: 20,

                                  offset:
                                      const Offset(
                                    0,
                                    8,
                                  ),
                                ),
                              ],
                            ),

                            child: Icon(
                              Icons
                                  .sign_language_rounded,
                              color: Colors.white,
                              size: isDesktop
                                  ? (isCompact ? 38 : 44)
                                  : (isCompact ? 34 : 38),
                            ),
                          ),
                        ),

                        SizedBox(
                          height: isCompact ? 6 : 18,
                        ),

                        Text(
                          'MuteMate',

                          style: TextStyle(
                            color:
                                AppTheme.textPrimary,
                            fontSize: isCompact ? 28 : 32,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        const Text(
                          'Bridging the Silence',

                          style: TextStyle(
                            color:
                                AppTheme.textMuted,
                            fontSize: 15,
                          ),
                        ),

                        SizedBox(
                          height: isCompact ? 10 : 28,
                        ),

                        // ==================================================
                        // LOGIN CARD
                        // ==================================================

                        Container(
                          width: double.infinity,

                          padding:
                              EdgeInsets.fromLTRB(
                            isCompact ? 24 : 28,
                            isCompact ? 18 : 26,
                            isCompact ? 24 : 28,
                            isCompact ? 12 : 20,
                          ),

                          decoration:
                              BoxDecoration(
                            color:
                                AppTheme.surface,

                            borderRadius:
                                BorderRadius
                                    .circular(
                              26,
                            ),

                            boxShadow: [
                              AppTheme
                                  .softShadow(),
                            ],
                          ),

                          child: Form(
                            key: _formKey,

                            child: Column(
                              children: [
                                // =========================================
                                // EMAIL
                                // =========================================

                                TextFormField(
                                  controller:
                                      emailController,

                                  keyboardType:
                                      TextInputType
                                          .emailAddress,

                                  textInputAction:
                                      TextInputAction
                                          .next,

                                  validator: (value) {
                                    final email =
                                        value
                                            ?.trim() ??
                                            '';

                                    if (email
                                        .isEmpty) {
                                      return 'Enter your email';
                                    }

                                    if (!email
                                        .contains('@')) {
                                      return 'Enter a valid email';
                                    }

                                    return null;
                                  },

                                  decoration:
                                      const InputDecoration(
                                    prefixIcon:
                                        Icon(
                                      Icons
                                          .email_outlined,
                                    ),

                                    hintText:
                                        'Email',
                                  ),
                                ),

                                SizedBox(
                                  height: isCompact ? 8 : 16,
                                ),

                                // =========================================
                                // PASSWORD
                                // =========================================

                                TextFormField(
                                  controller:
                                      passwordController,

                                  obscureText:
                                      _obscurePassword,

                                  textInputAction:
                                      TextInputAction
                                          .done,

                                  onFieldSubmitted:
                                      (_) {
                                    if (!_isLoading) {
                                      _handleContinue();
                                    }
                                  },

                                  validator: (value) {
                                    if (value ==
                                            null ||
                                        value.isEmpty) {
                                      return 'Enter your password';
                                    }

                                    if (value.length <
                                        4) {
                                      return 'Password must be at least 4 characters';
                                    }

                                    return null;
                                  },

                                  decoration:
                                      InputDecoration(
                                    prefixIcon:
                                        const Icon(
                                      Icons
                                          .lock_outline,
                                    ),

                                    hintText:
                                        'Password',

                                    suffixIcon:
                                        IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons
                                                .visibility_off_outlined
                                            : Icons
                                                .visibility_outlined,
                                      ),

                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword =
                                              !_obscurePassword;
                                        });
                                      },
                                    ),
                                  ),
                                ),

                                SizedBox(
                                  height: isCompact ? 10 : 24,
                                ),

                                // =========================================
                                // LOGIN
                                // =========================================

                                SizedBox(
                                  width:
                                      double.infinity,

                                  height: isCompact ? 44 : 52,

                                  child:
                                      ElevatedButton(
                                    onPressed:
                                        _isLoading
                                            ? null
                                            : _handleContinue,

                                    style:
                                        ElevatedButton
                                            .styleFrom(
                                      elevation: 0,

                                      shape:
                                          RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          16,
                                        ),
                                      ),
                                    ),

                                    child:
                                        _isLoading
                                            ? const SizedBox(
                                                height:
                                                    21,
                                                width:
                                                    21,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth:
                                                      2.5,
                                                  color:
                                                      Colors.white,
                                                ),
                                              )
                                            : const Text(
                                                'Continue',

                                                style:
                                                    TextStyle(
                                                  fontSize:
                                                      16,
                                                  fontWeight:
                                                      FontWeight
                                                          .w600,
                                                ),
                                              ),
                                  ),
                                ),

                                SizedBox(
                                  height: isCompact ? 0 : 10,
                                ),

                                // =========================================
                                // CREATE ACCOUNT
                                // =========================================

                                TextButton(
                                  onPressed:
                                      _isLoading
                                          ? null
                                          : _openRegisterPage,

                                  child:
                                      const Text(
                                    'Create an account',

                                    style:
                                        TextStyle(
                                      color:
                                          AppTheme.secondary,
                                      fontWeight:
                                          FontWeight.w600,
                                    ),
                                  ),
                                ),

                                SizedBox(
                                  height: 0,
                                ),

                                // =========================================
                                // GUEST
                                // =========================================

                                TextButton.icon(
                                  onPressed:
                                      _isLoading
                                          ? null
                                          : _goToHome,

                                  icon:
                                      const Icon(
                                    Icons
                                        .person_outline,
                                    size: 19,
                                  ),

                                  label:
                                      const Text(
                                    'Continue as Guest',

                                    style:
                                        TextStyle(
                                      fontWeight:
                                          FontWeight
                                              .w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(
                          height: isCompact ? 5 : 20,
                        ),

                        Text(
                          'MuteMate v1.0',

                          style: TextStyle(
                            color:
                                AppTheme.textMuted,
                            fontSize: isCompact ? 10 : 12,
                          ),
                        ),

                        const SizedBox(
                          height: 5,
                        ),

                        Text(
                          'Powered by Flutter • Flask • TensorFlow',

                          textAlign:
                              TextAlign.center,

                          style: TextStyle(
                            color:
                                AppTheme.textMuted,
                            fontSize: isCompact ? 9 : 11,
                          ),
                        ),
                        ],
                      ),
                    ),
                  ),
                ),
              ));
            },
          ),
        ),
      ),
    );
  }
}