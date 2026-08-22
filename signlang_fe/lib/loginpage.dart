import 'package:flutter/material.dart';
import 'main.dart';
import 'theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _goToTranslator() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const TranslatorPage(),
      ),
    );
  }

  Future<void> _handleContinue() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // TODO: Replace with Flask authentication
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    _goToTranslator();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    double cardWidth = width;

    if (width > 1200) {
      cardWidth = 500;
    } else if (width > 700) {
      cardWidth = 460;
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 30,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: cardWidth,
                ),
                child: Column(
                  children: [

                    //---------------------------------------
                    // LOGO
                    //---------------------------------------

                    Hero(
                      tag: "logo",
                      child: Container(
                        width: 95,
                        height: 95,
                        decoration: BoxDecoration(
                          gradient: AppTheme.brandGradient,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppTheme.secondary.withOpacity(.25),
                              blurRadius: 22,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        child: const Icon(
                          Icons.sign_language_rounded,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    Text(
                      "MuteMate",
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                          ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      "Bridging the Silence",
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 42),

                    //---------------------------------------
                    // LOGIN CARD
                    //---------------------------------------

                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.all(26),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          AppTheme.softShadow(),
                        ],
                      ),

                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [

                            //-----------------------------------
                            // USERNAME
                            //-----------------------------------

                            TextFormField(
                              controller: usernameController,
                              textInputAction: TextInputAction.next,

                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty) {
                                  return "Enter your username";
                                }

                                if (value.trim().length < 3) {
                                  return "Username is too short";
                                }

                                return null;
                              },

                              decoration: const InputDecoration(
                                prefixIcon:
                                    Icon(Icons.person_outline),
                                hintText: "Username",
                              ),
                            ),

                            const SizedBox(height: 20),

                            //-----------------------------------
                            // PASSWORD
                            //-----------------------------------

                            TextFormField(
                              controller: passwordController,
                              obscureText: _obscurePassword,
                              textInputAction:
                                  TextInputAction.done,

                              onFieldSubmitted: (_) {
                                if (!_isLoading) {
                                  _handleContinue();
                                }
                              },

                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty) {
                                  return "Enter your password";
                                }

                                if (value.length < 4) {
                                  return "Password too short";
                                }

                                return null;
                              },

                              decoration: InputDecoration(
                                prefixIcon:
                                    const Icon(Icons.lock_outline),

                                hintText: "Password",

                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
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

                            const SizedBox(height: 30),
                                                        //-----------------------------------
                            // LOGIN BUTTON
                            //-----------------------------------

                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed:
                                    _isLoading ? null : _handleContinue,

                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(18),
                                  ),
                                ),

                                child: AnimatedSwitcher(
                                  duration:
                                      const Duration(milliseconds: 250),

                                  child: _isLoading
                                      ? Row(
                                          key: const ValueKey("loading"),
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: const [

                                            SizedBox(
                                              height: 22,
                                              width: 22,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Colors.white,
                                              ),
                                            ),

                                            SizedBox(width: 14),

                                            Text(
                                              "Authenticating...",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight:
                                                    FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        )
                                      : const Text(
                                          "Continue",
                                          key: ValueKey("continue"),
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 18),

                            //-----------------------------------
                            // GUEST LOGIN
                            //-----------------------------------

                            TextButton.icon(
                              onPressed:
                                  _isLoading ? null : _goToTranslator,

                              icon: const Icon(Icons.person_outline),

                              label: const Text(
                                "Continue as Guest",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      "MuteMate v1.0",
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      "Powered by Flutter • Flask • TensorFlow",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}