import 'package:flutter/material.dart';

class Header extends StatelessWidget  {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              const Icon(Icons.home_work, color: Color(0xFFE03C3C), size: 32),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Batdongsan',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFE03C3C).withOpacity(0.9)
                    ),
                  ),
                  const Text('by PropertyGuru', style: TextStyle(fontSize: 9, color: Colors.grey)),
                ],
              )
            ],
          ),
          const Icon(Icons.domain, color: Colors.grey, size: 36),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}