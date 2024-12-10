import 'package:flutter/material.dart';
import 'package:safe_road/tabs/maintab_view.dart';

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
        primarySwatch: Colors.blue,
      ),
      home: const MainTab(),
    );
  }
}
