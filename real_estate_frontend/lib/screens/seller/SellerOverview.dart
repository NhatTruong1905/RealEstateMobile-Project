import 'package:flutter/material.dart';
import 'package:real_estate_frontend/dto/UserDTO.dart';
import 'package:real_estate_frontend/services/ChatService.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SellerOverviewScreen extends StatefulWidget {
  final VoidCallback onPostNewProperty;
  final VoidCallback onManageProperties;
  final VoidCallback onManageCustomers;

  const SellerOverviewScreen({
    super.key,
    required this.onPostNewProperty,
    required this.onManageProperties,
    required this.onManageCustomers,
  });

  @override
  State<SellerOverviewScreen> createState() => _SellerOverviewScreenState();
}

class _SellerOverviewScreenState extends State<SellerOverviewScreen> {
  UserDTO? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    String? userJsonString = prefs.getString('user_profile');
    if (userJsonString != null) {
      setState(() {
        _userProfile = UserDTO.fromJson(jsonDecode(userJsonString));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = _userProfile?.fullname ?? _userProfile?.username ?? 'Chủ tin đăng';

    return Scaffold(
      backgroundColor: const Color(0xFFFCFBFA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER GREETING
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xin chào, $userName!',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1918),
                            fontFamily: 'Georgia',
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tổng quan hoạt động kinh doanh bất động sản',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF78736D),
                            fontFamily: 'Plus Jakarta Sans',
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      ValueListenableBuilder<bool>(
                        valueListenable: ChatService.hasUnreadNotification,
                        builder: (context, hasUnread, child) {
                          return InkWell(
                            onTap: () {
                              ChatService.hasUnreadNotification.value = false;
                              widget.onManageCustomers();
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (hasUnread) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDC2626),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x29DC2626),
                                          blurRadius: 6,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 12),
                                        SizedBox(width: 4),
                                        Text(
                                          'Bạn có 1 tin nhắn mới',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.notifications_none_outlined,
                                        color: Color(0xFF1A1918),
                                        size: 26,
                                      ),
                                      onPressed: () {
                                        ChatService.hasUnreadNotification.value = false;
                                        widget.onManageCustomers();
                                      },
                                    ),
                                    if (hasUnread)
                                      Positioned(
                                        top: 10,
                                        right: 10,
                                        child: Container(
                                          width: 9,
                                          height: 9,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFDC2626),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 1.5),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 6),
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFFF4EEE6),
                        backgroundImage: (_userProfile?.avatar != null &&
                                _userProfile!.avatar!.isNotEmpty)
                            ? NetworkImage(_userProfile!.avatar!)
                            : null,
                        child: (_userProfile?.avatar == null ||
                                _userProfile!.avatar!.isEmpty)
                            ? const Icon(Icons.person, color: Color(0xFF945331))
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // BÀN CỜ THỐNG KÊ (METRICS GRID)
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.article_outlined,
                      title: 'Tổng bài đăng',
                      value: '12',
                      subtitle: '8 đang hiển thị',
                      color: const Color(0xFF945331),
                      onTap: widget.onManageProperties,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.people_alt_outlined,
                      title: 'Khách liên hệ',
                      value: '28',
                      subtitle: '+5 lượt mới hôm nay',
                      color: const Color(0xFF2E7D32),
                      onTap: widget.onManageCustomers,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.remove_red_eye_outlined,
                      title: 'Lượt xem bài',
                      value: '1.4k',
                      subtitle: 'Tăng 18% tuần này',
                      color: const Color(0xFF1565C0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.star_border_rounded,
                      title: 'Đánh giá tốt',
                      value: '4.9★',
                      subtitle: 'Từ 16 khách hàng',
                      color: const Color(0xFFE65100),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // PHÍM TẮT THAO TÁC NHANH
              const Text(
                'Thao tác nhanh',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1918),
                  fontFamily: 'Georgia',
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: widget.onPostNewProperty,
                      icon: const Icon(Icons.add_circle_outline,
                          color: Colors.white, size: 20),
                      label: const Text(
                        'Đăng tin mới',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFF945331),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onManageProperties,
                      icon: const Icon(Icons.list_alt,
                          color: Color(0xFF1A1918), size: 20),
                      label: const Text(
                        'Quản lý bài',
                        style: TextStyle(
                          color: Color(0xFF1A1918),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFE8E3DC)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // KHÁCH HÀNG MỚI LIÊN HỆ
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Khách hàng mới liên hệ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1918),
                      fontFamily: 'Georgia',
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onManageCustomers,
                    child: const Text(
                      'Xem tất cả',
                      style: TextStyle(
                        color: Color(0xFF945331),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              _buildRecentCustomerCard(
                name: 'Nguyễn Văn Minh',
                phone: '0912 345 678',
                propertyTitle: 'Căn hộ chung cư cao cấp Vinhomes 2PN',
                time: '10 phút trước',
                status: 'Chưa tư vấn',
                statusColor: const Color(0xFFE65100),
              ),
              const SizedBox(height: 12),
              _buildRecentCustomerCard(
                name: 'Trần Thị Thu Thảo',
                phone: '0988 765 432',
                propertyTitle: 'Nhà phố mặt tiền đường Lê Văn Sỹ 3 tầng',
                time: '2 giờ trước',
                status: 'Hẹn xem nhà',
                statusColor: const Color(0xFF2E7D32),
              ),
              const SizedBox(height: 12),
              _buildRecentCustomerCard(
                name: 'Lê Hoàng Nam',
                phone: '0903 112 233',
                propertyTitle: 'Biệt thự sân vườn Thảo Điền Quận 2',
                time: 'Hôm qua',
                status: 'Đã gọi tư vấn',
                statusColor: const Color(0xFF1565C0),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8E3DC)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
                fontFamily: 'Georgia',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1918),
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF78736D),
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentCustomerCard({
    required String name,
    required String phone,
    required String propertyTitle,
    required String time,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8E3DC)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFF4EEE6),
            child: Text(
              name.substring(0, 1),
              style: const TextStyle(
                color: Color(0xFF945331),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1A1918),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  propertyTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF78736D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$phone • $time',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF945331),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
