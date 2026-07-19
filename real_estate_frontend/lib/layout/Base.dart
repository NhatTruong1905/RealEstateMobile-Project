import 'package:flutter/material.dart';
import 'header.dart';
import 'footer.dart';

class Base extends StatefulWidget {
  final Widget body;

  const Base({super.key, required this.body});

  @override
  State<Base> createState() => _BaseLayoutState();
}

class _BaseLayoutState extends State<Base> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const Header(),
      body: SafeArea(child: widget.body), // Nội dung động thay đổi theo từng trang
      bottomNavigationBar: Footer( // Gắn cố định Footer và đồng bộ index
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