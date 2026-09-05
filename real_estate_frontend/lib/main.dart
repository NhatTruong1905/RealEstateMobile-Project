import 'package:flutter/material.dart';
import 'package:real_estate_frontend/screens/MainScreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Real Estate App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE03C3C)),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}
