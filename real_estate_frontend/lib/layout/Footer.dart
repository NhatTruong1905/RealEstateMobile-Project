import 'package:flutter/material.dart';

class Footer extends StatelessWidget {
  final int currentIndex;
  final bool isSellerMode;
  final ValueChanged<int>? onTap;
  final VoidCallback? onPostTap;

  const Footer({
    super.key,
    required this.currentIndex,
    this.isSellerMode = false,
    this.onTap,
    this.onPostTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!isSellerMode) {
      // MÀN HÌNH NGƯỜI TÌM NHÀ (TRANG CHỦ - ĐÃ LƯU - TÀI KHOẢN)
      return BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: const Color(0xFF945331),
        unselectedItemColor: const Color(0xFF78736d),
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        onTap: (index) {
          if (index == currentIndex) return;
          if (onTap != null) {
            onTap!(index);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: 'Đã lưu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Tài khoản',
          ),
        ],
      );
    }

    // MÀN HÌNH CHỦ ĐĂNG TIN (TỔNG QUAN - TIN ĐĂNG - (+) ĐĂNG TIN - KHÁCH HÀNG - TÀI KHOẢN)
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF945331),
        unselectedItemColor: const Color(0xFF78736d),
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        onTap: (index) {
          if (index == 2) {
            if (onPostTap != null) onPostTap!();
            return;
          }
          if (onTap != null) {
            onTap!(index);
          }
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Tổng quan',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.article_outlined),
            activeIcon: Icon(Icons.article),
            label: 'Tin đăng',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF945331),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x40945331),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            ),
            label: 'Đăng tin',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined),
            activeIcon: Icon(Icons.people_alt),
            label: 'Khách hàng',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}
