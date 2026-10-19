part of '../Account.dart';

extension AccountView on _AccountScreenState {
  Widget _buildPage(BuildContext context) {
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
                        Material(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: const BorderSide(color: Color(0xFFE8E3DC)),
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
                        Material(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: const BorderSide(color: Color(0xFFE8E3DC)),
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
                          Material(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                              side: const BorderSide(color: Color(0xFFE8E3DC)),
                            ),
                            child: Column(
                              children: [
                                _buildProfileOption(
                                  Icons.settings_outlined,
                                  'Cài đặt tài khoản',
                                  onTap: () async {
                                    if (currentUserProfile != null) {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EditProfileScreen(
                                            currentUser: currentUserProfile!,
                                          ),
                                        ),
                                      );
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
                      if (widget.onSwitchMode != null) {
                        widget.onSwitchMode!(!widget.isSellerMode);
                      }
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.isSellerMode
                              ? Icons.home_outlined
                              : Icons.swap_horiz,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.isSellerMode
                              ? 'Chuyển sang tìm kiếm'
                              : 'Chuyển sang đăng tin',
                          style: const TextStyle(
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
    );
  }
}
