import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:real_estate_frontend/dto/UserDTO.dart';
import 'package:real_estate_frontend/mixin/api/ApiLoginMixin.dart';
import 'package:real_estate_frontend/screens/Auth.dart';
import 'package:real_estate_frontend/screens/ChangePassword.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:real_estate_frontend/layout/Footer.dart';
import 'package:real_estate_frontend/screens/FAQ.dart';
import 'package:real_estate_frontend/screens/PrivacyPolicy.dart';
import 'package:real_estate_frontend/screens/Terms.dart';

import 'package:real_estate_frontend/screens/UserProfile.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

// Bỏ ApiUserMixin đi cho nhẹ vì chúng ta chỉ cần gọi logout() từ ApiLoginMixin
class _AccountScreenState extends State<AccountScreen> with ApiLoginMixin {
  bool isLoggedIn = false;
  String currentUsername = '';

  // Biến lưu trữ thông tin Profile lấy từ API/Cache
  UserDTO? currentUserProfile;
  bool isLoadingProfile = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    bool loggedIn = prefs.getBool('is_logged_in') ?? false;

    if (loggedIn) {
      // 1. LẤY CHUỖI JSON TỪ CACHE
      String? userJsonString = prefs.getString('user_profile');

      if (mounted) {
        setState(() {
          isLoggedIn = true;

          if (userJsonString != null) {
            // 2. GIẢI MÃ CHUỖI JSON THÀNH ĐỐI TƯỢNG UserDTO
            Map<String, dynamic> userMap = jsonDecode(userJsonString);
            currentUserProfile = UserDTO.fromJson(userMap);
            currentUsername = currentUserProfile?.username ?? '';
          }

          isLoadingProfile = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => isLoggedIn = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    await logout(); // Hàm từ ApiLoginMixin
    if (mounted) {
      setState(() {
        isLoggedIn = false;
        currentUsername = '';
        currentUserProfile = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFBFA),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 90),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  isLoggedIn ? _buildLoggedInHeader() : _buildLoggedOutHeader(),

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
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const FaqScreen(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

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
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const TermsScreen(),
                                  ),
                                ),
                              ),
                              const Divider(
                                height: 1,
                                indent: 56,
                                color: Color(0xFFE8E3DC),
                              ),
                              _buildProfileOption(
                                Icons.verified_user_outlined,
                                'Chính sách bảo mật',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PrivacyPolicyScreen(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (isLoggedIn) ...[
                          _buildSectionTitle('Tài khoản & thông báo'),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFFE8E3DC),
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildProfileOption(
                                  Icons.settings_outlined,
                                  'Cài đặt tài khoản',
                                  onTap: () async {
                                    // Truyền currentUserProfile vào màn hình EditProfile
                                    if (currentUserProfile != null) {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EditProfileScreen(
                                            currentUser: currentUserProfile!,
                                          ),
                                        ),
                                      );

                                      // Đợi màn hình EditProfile pop() về. Nếu có cập nhật (result == true) thì load lại data.
                                      if (result == true) {
                                        _checkLoginStatus();
                                      }
                                    }
                                  },
                                ),
                                const Divider(
                                  height: 1,
                                  indent: 56,
                                  color: Color(0xFFE8E3DC),
                                ),
                                _buildProfileOption(
                                  Icons.lock_person_outlined,
                                  'Đổi mật khẩu',
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ChangePasswordScreen(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: _handleLogout,
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

                        const SizedBox(height: 24),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Giấy ĐKKD số 0104630479 do Sở KHĐT TP Hồ Chí Minh cấp lần đầu ngày 02/06/2010\nChịu trách nhiệm sàn GDTMĐT: Ông Nhật Trường',
                                style: TextStyle(
                                  color: Color(0xFF78736D),
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'CÔNG TY CỔ PHẦN PROPERTYSUMDEV VIỆT NAM',
                                style: TextStyle(
                                  color: Color(0xFF1A1918),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Tầng 1, Thanh Doan Landmark, Đông Thạnh, Hóc Môn, Hồ Chí Minh\n(096) 7294 349 - (090) 9321 982',
                                style: TextStyle(
                                  color: Color(0xFF78736D),
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: Center(
                child: InkWell(
                  onTap: () {
                    if (!isLoggedIn) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AuthScreen(
                            onLoginSuccess: () {
                              _checkLoginStatus();
                            },
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Tính năng Đăng tin đang được phát triển!',
                          ),
                          backgroundColor: const Color(0xFF945331),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1918),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.swap_horiz, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Chuyển sang đăng tin',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const Footer(currentIndex: 2),
    );
  }

  Widget _buildLoggedOutHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFE8E3DC)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1877F2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sentiment_satisfied_alt,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Đăng nhập tài khoản để xem thông tin và liên hệ người bán/cho thuê',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1918),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AuthScreen(
                        onLoginSuccess: () {
                          _checkLoginStatus();
                        },
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF1A1918), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  'Đăng nhập',
                  style: TextStyle(
                    color: Color(0xFF1A1918),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoggedInHeader() {
    final displayName =
        currentUserProfile?.fullname ??
        currentUserProfile?.username ??
        (currentUsername.isNotEmpty ? currentUsername : 'Chưa cập nhật tên');

    final displayEmail = currentUserProfile?.email ?? 'Chưa cập nhật Email';
    final avatarUrl = currentUserProfile?.avatar;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 32),
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
                  color: const Color(0xFFE8E3DC),
                  image: hasAvatar
                      ? DecorationImage(
                          image: NetworkImage(avatarUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: !hasAvatar
                    ? const Icon(
                        Icons.person,
                        size: 40,
                        color: Color(0xFF945331),
                      )
                    : null,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: isLoadingProfile
                    ? const Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Color(0xFF945331),
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1918),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            displayEmail,
                            style: const TextStyle(
                              color: Color(0xFF78736D),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ],
      ),
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
          letterSpacing: 0.5,
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
        child: Icon(icon, color: const Color(0xFF945331), size: 20),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      onTap: onTap,
    );
  }
}
