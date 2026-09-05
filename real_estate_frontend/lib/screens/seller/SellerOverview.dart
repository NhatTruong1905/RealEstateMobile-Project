import 'package:flutter/material.dart';
import 'package:real_estate_frontend/dto/PropertyDTO.dart';
import 'package:real_estate_frontend/dto/UserDTO.dart';
import 'package:real_estate_frontend/mixin/api/APIPropertyMixin.dart';
import 'package:real_estate_frontend/mixin/api/APIInteractionMixin.dart';
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

class _SellerOverviewScreenState extends State<SellerOverviewScreen>
    with ApiPropertyMixin, ApiInteractionMixin {
  UserDTO? _userProfile;
  List<PropertyDTO> _myProperties = [];
  List<Map<String, dynamic>> _recentInteractions = [];
  bool _isLoadingProperties = true;
  bool _isLoadingInteractions = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await _loadProfile();
    await Future.wait([
      _loadMyProperties(),
      _loadInteractions(),
    ]);
  }

  Future<void> _loadMyProperties() async {
    final list = await fetchMyProperties();
    if (mounted) {
      setState(() {
        _myProperties = list;
        _isLoadingProperties = false;
      });
    }
  }

  Future<void> _loadInteractions() async {
    final items = await fetchUserInteractions();
    if (mounted) {
      setState(() {
        _recentInteractions = items;
        _isLoadingInteractions = false;
      });
    }
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    String? userJsonString = prefs.getString('user_profile');
    if (userJsonString != null) {
      try {
        setState(() {
          _userProfile = UserDTO.fromJson(jsonDecode(userJsonString));
        });
      } catch (e) {
        debugPrint('Lỗi parse profile: $e');
      }
    }
  }

  List<Map<String, dynamic>> get _filteredCustomerInteractions {
    final myId = _userProfile?.id;
    final myUsername = _userProfile?.username?.trim().toLowerCase();
    final myFullname = _userProfile?.fullname?.trim().toLowerCase();

    final List<Map<String, dynamic>> filtered = [];

    for (var item in _recentInteractions) {
      final senderObj = item['sender'] is Map ? item['sender'] as Map : null;
      final receiverObj = item['receiver'] is Map ? item['receiver'] as Map : null;

      final senderId = item['senderId'] ?? senderObj?['id'];
      final sUser = (item['senderUsername'] ?? senderObj?['username'] ?? '').toString().trim().toLowerCase();
      final sName = (item['senderName'] ?? item['senderFullname'] ?? senderObj?['fullname'] ?? '').toString().trim().toLowerCase();

      final receiverId = item['receiverId'] ?? receiverObj?['id'];
      final rUser = (item['receiverUsername'] ?? receiverObj?['username'] ?? '').toString().trim().toLowerCase();
      final rName = (item['receiverName'] ?? item['receiverFullname'] ?? receiverObj?['fullname'] ?? '').toString().trim().toLowerCase();

      final isSenderMe = (myId != null && senderId == myId) ||
          (myUsername != null && myUsername.isNotEmpty && sUser == myUsername) ||
          (myFullname != null && myFullname.isNotEmpty && sName == myFullname);

      final isReceiverMe = (myId != null && receiverId == myId) ||
          (myUsername != null && myUsername.isNotEmpty && rUser == myUsername) ||
          (myFullname != null && myFullname.isNotEmpty && rName == myFullname);

      if (isSenderMe && isReceiverMe) continue;

      if (isSenderMe) {
        if (myId != null && receiverId == myId) continue;
        if (myFullname != null && myFullname.isNotEmpty && rName == myFullname) continue;
        if (myUsername != null && myUsername.isNotEmpty && rUser == myUsername) continue;
      } else {
        if (myId != null && senderId == myId) continue;
        if (myFullname != null && myFullname.isNotEmpty && sName == myFullname) continue;
        if (myUsername != null && myUsername.isNotEmpty && sUser == myUsername) continue;
      }

      filtered.add(item);
    }
    return filtered;
  }

  int get _uniqueCustomerCount {
    final customerIds = <dynamic>{};
    final myId = _userProfile?.id;
    final myFullname = _userProfile?.fullname?.trim().toLowerCase();
    final myUsername = _userProfile?.username?.trim().toLowerCase();

    for (var item in _filteredCustomerInteractions) {
      final senderObj = item['sender'] is Map ? item['sender'] as Map : null;
      final receiverObj = item['receiver'] is Map ? item['receiver'] as Map : null;

      final senderId = item['senderId'] ?? senderObj?['id'];
      final sUser = (item['senderUsername'] ?? senderObj?['username'] ?? '').toString().trim().toLowerCase();
      final sName = (item['senderName'] ?? item['senderFullname'] ?? senderObj?['fullname'] ?? '').toString().trim().toLowerCase();

      final isSenderMe = (myId != null && senderId == myId) ||
          (myUsername != null && myUsername.isNotEmpty && sUser == myUsername) ||
          (myFullname != null && myFullname.isNotEmpty && sName == myFullname);

      dynamic custIdentifier;
      if (isSenderMe) {
        custIdentifier = item['receiverId'] ?? receiverObj?['id'] ?? item['receiverPhone'] ?? receiverObj?['phone'] ?? item['receiverName'] ?? receiverObj?['fullname'];
      } else {
        custIdentifier = senderId ?? item['senderPhone'] ?? senderObj?['phone'] ?? item['senderName'] ?? senderObj?['fullname'];
      }

      if (custIdentifier != null) {
        final strId = custIdentifier.toString().trim().toLowerCase();
        if (myFullname != null && myFullname.isNotEmpty && strId == myFullname) continue;
        if (myUsername != null && myUsername.isNotEmpty && strId == myUsername) continue;
        customerIds.add(custIdentifier);
      }
    }
    return customerIds.length;
  }

  @override
  Widget build(BuildContext context) {
    final userName = _userProfile?.fullname ?? _userProfile?.username ?? 'Chủ tin đăng';
    final publishedCount = _myProperties.where((p) {
      final s = (p.status ?? '').toLowerCase();
      return s == 'đang mở bán' || s == 'published' || s == 'đang hiển thị';
    }).length;
    final uniqueCustomers = _uniqueCustomerCount;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFBFA),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF945331),
          onRefresh: _loadAllData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                                            'Tin nhắn mới',
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

                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        icon: Icons.article_outlined,
                        title: 'Tổng bài đăng',
                        value: _isLoadingProperties ? '...' : '${_myProperties.length}',
                        subtitle: _isLoadingProperties
                            ? 'Đang tải...'
                            : '$publishedCount đang hiển thị',
                        color: const Color(0xFF945331),
                        onTap: widget.onManageProperties,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        icon: Icons.people_alt_outlined,
                        title: 'Khách liên hệ',
                        value: _isLoadingInteractions
                            ? '...'
                            : '$uniqueCustomers',
                        subtitle: _isLoadingInteractions
                            ? 'Đang tải...'
                            : (uniqueCustomers == 0
                                ? 'Chưa có khách mới'
                                : '$uniqueCustomers khách hàng'),
                        color: const Color(0xFF2E7D32),
                        onTap: widget.onManageCustomers,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

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

                _buildCustomerSection(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerSection() {
    if (_isLoadingInteractions) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF945331)),
        ),
      );
    }

    final filteredItems = _filteredCustomerInteractions;

    if (filteredItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8E3DC)),
        ),
        child: Column(
          children: [
            const Icon(Icons.people_outline_rounded, size: 40, color: Color(0xFF9CA3AF)),
            const SizedBox(height: 10),
            const Text(
              'Chưa có khách hàng liên hệ mới',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF1A1918),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Các lượt đăng ký tư vấn hoặc hẹn xem nhà từ khách hàng sẽ hiển thị tại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF78736D)),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: widget.onPostNewProperty,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF945331),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Đăng tin để tiếp cận khách hàng', style: TextStyle(color: Colors.white, fontSize: 13)),
            ),
          ],
        ),
      );
    }

    final displayItems = filteredItems.take(4).toList();

    return Column(
      children: displayItems.map((item) {
        final senderObj = item['sender'] is Map ? item['sender'] as Map : null;
        final receiverObj = item['receiver'] is Map ? item['receiver'] as Map : null;
        final propObj = item['property'] is Map ? item['property'] as Map : null;

        final senderId = item['senderId'] ?? senderObj?['id'];
        final sUser = (item['senderUsername'] ?? senderObj?['username'] ?? '').toString().trim().toLowerCase();
        final sName = (item['senderName'] ?? item['senderFullname'] ?? senderObj?['fullname'] ?? '').toString().trim().toLowerCase();

        final myId = _userProfile?.id;
        final myFullname = _userProfile?.fullname?.trim().toLowerCase();
        final myUsername = _userProfile?.username?.trim().toLowerCase();

        final isSenderMe = (myId != null && senderId == myId) ||
            (myFullname != null && myFullname.isNotEmpty && sName == myFullname) ||
            (myUsername != null && myUsername.isNotEmpty && sUser == myUsername);

        final String name;
        final String phone;

        if (isSenderMe) {
          name = (item['receiverName'] ??
              item['receiverFullname'] ??
              item['receiverUsername'] ??
              receiverObj?['fullname'] ??
              receiverObj?['username'] ??
              'Khách hàng quan tâm').toString();

          phone = (item['receiverPhone'] ??
              receiverObj?['phone'] ??
              receiverObj?['email'] ??
              'Chưa cập nhật SĐT').toString();
        } else {
          name = (item['senderName'] ??
              item['senderFullname'] ??
              item['senderUsername'] ??
              senderObj?['fullname'] ??
              senderObj?['username'] ??
              'Khách hàng quan tâm').toString();

          phone = (item['senderPhone'] ??
              senderObj?['phone'] ??
              senderObj?['email'] ??
              'Chưa cập nhật SĐT').toString();
        }

        final propertyTitle = item['propertyTitle'] ??
            propObj?['title'] ??
            'Bất động sản quan tâm';

        final code = (item['interactionTypeCode'] ?? item['code'] ?? item['type'] ?? '')
            .toString()
            .toUpperCase();

        String status = 'Yêu cầu tư vấn';
        Color statusColor = const Color(0xFFE65100);

        if (code == 'VIEWING') {
          status = 'Hẹn xem nhà';
          statusColor = const Color(0xFF2E7D32);
        } else if (code == 'MESSAGE') {
          status = 'Gửi tin nhắn';
          statusColor = const Color(0xFF1565C0);
        } else if (code == 'COMPLETED') {
          status = 'Đã hoàn thành';
          statusColor = const Color(0xFF64748B);
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildRecentCustomerCard(
            name: name,
            phone: phone,
            propertyTitle: propertyTitle,
            time: 'Vừa xong',
            status: status,
            statusColor: statusColor,
            onTap: widget.onManageCustomers,
          ),
        );
      }).toList(),
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
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFF4EEE6),
              child: Text(
                name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'K',
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
      ),
    );
  }
}

