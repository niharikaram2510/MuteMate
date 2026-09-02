import 'package:flutter/material.dart';

import 'splash_screen.dart';
import 'settings.dart';
import 'live_translation_page.dart';
import 'home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MuteMate',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3AED),
        ),

        scaffoldBackgroundColor:
            const Color(0xFFF7F8FC),
      ),

      home: const SplashScreen(),

      routes: {
        '/home': (context) => const HomePage(),

        '/live-translation': (context) =>
            const LiveTranslationPage(),

        '/settings': (context) =>
            const SettingsPage(),
      },
    );
  }
}