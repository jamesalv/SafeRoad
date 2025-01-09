import 'package:flutter/material.dart';
import 'package:safe_road/screens/splash_screen.dart';
import 'package:safe_road/utils/theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safe Road',
      theme: ThemeData(
        primaryColor: SafeRoadTheme.primary,
        scaffoldBackgroundColor: SafeRoadTheme.background,
        navigationBarTheme: SafeRoadTheme.navigationBarTheme,
        useMaterial3: true, // Using Material 3 design
      ),
      home: const SplashScreen(),
    );
  }
}
