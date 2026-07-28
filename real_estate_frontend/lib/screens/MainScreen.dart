import 'package:flutter/material.dart';
import 'package:real_estate_frontend/layout/Footer.dart';
import 'package:real_estate_frontend/screens/Account.dart';
import 'package:real_estate_frontend/screens/Home.dart';
import 'package:real_estate_frontend/screens/SaveNews.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(key: ValueKey('home_$_currentIndex')),
          SavedNewsScreen(key: ValueKey('saved_$_currentIndex')),
          AccountScreen(key: ValueKey('account_$_currentIndex')),
        ],
      ),
      bottomNavigationBar: Footer(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
