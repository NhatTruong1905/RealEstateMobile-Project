import 'package:flutter/material.dart';
import 'package:real_estate_frontend/layout/Footer.dart';
import 'package:real_estate_frontend/screens/FAQ.dart';
import 'package:real_estate_frontend/screens/PrivacyPolicy.dart';
import 'package:real_estate_frontend/screens/Terms.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFBFA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 24,
                  bottom: 32,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFF4EEE6),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hồ sơ',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1918),
                        fontFamily: 'Georgia',
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            image: const DecorationImage(
                              image: NetworkImage(
                                "https://res.cloudinary.com/dokjzty69/image/upload/v1783935864/dt10t2grghfqiesfxirn.png",
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Nguyễn Đinh Nhật Trường',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1918),
                              ),
                            ),
                            const Text(
                              'tn696199@gmail.com',
                              style: TextStyle(
                                color: Color(0xFF78736D),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Hướng dẫn'),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE8E3DC)),
                      ),
                      child: Column(
                        children: [
                          _buildProfileOption(
                            Icons.help_outline,
                            'Câu hỏi thường gặp',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const FaqScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),

                    _buildSectionTitle('Quy định'),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE8E3DC)),
                      ),
                      child: Column(
                        children: [
                          _buildProfileOption(
                            Icons.description_outlined,
                            'Điều khoản thỏa thuận',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TermsScreen(),
                                ),
                              );
                            },
                          ),
                          const Divider(
                            height: 1,
                            indent: 56,
                            color: Color(0xFFE8E3DC),
                          ),
                          _buildProfileOption(
                            Icons.verified_user_outlined,
                            'Chính sách bảo mật',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PrivacyPolicyScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),

                    _buildSectionTitle('Tài khoản & thông báo'),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE8E3DC)),
                      ),
                      child: Column(
                        children: [
                          _buildProfileOption(
                            Icons.settings_outlined,
                            'Cài đặt tài khoản',
                            onTap: () {},
                          ),
                          const Divider(
                            height: 1,
                            indent: 56,
                            color: Color(0xFFE8E3DC),
                          ),
                          _buildProfileOption(
                            Icons.lock_person_outlined,
                            'Đổi mật khẩu',
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.logout,
                          color: Color(0xFF945331),
                          size: 20,
                        ),
                        label: const Text(
                          'Đăng xuất',
                          style: TextStyle(
                            color: Color(0xFF1A1918),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF4EEE6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const Footer(currentIndex: 2),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color(0xFF78736D),
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildProfileOption(
    IconData icon,
    String label, {
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFF4EEE6),
        child: Icon(icon, color: const Color(0xFF945331), size: 22),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1A1918),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Color(0xFF78736D),
        size: 20,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
    );
  }
}
