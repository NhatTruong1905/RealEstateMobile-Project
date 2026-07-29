import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SellerCustomersScreen extends StatefulWidget {
  const SellerCustomersScreen({super.key});

  @override
  State<SellerCustomersScreen> createState() => _SellerCustomersScreenState();
}

class _SellerCustomersScreenState extends State<SellerCustomersScreen> {
  String _activeTab = 'Tất cả';

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.isEmpty) return;
    final Uri launchUri = Uri.parse('tel:$cleanPhone');
    try {
      final launched = await launchUrl(
        launchUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(launchUri);
      }
    } catch (e) {
      debugPrint('Lỗi gọi điện: $e');
    }
  }

  final List<Map<String, dynamic>> _customers = [
    {
      'name': 'Nguyễn Văn Minh',
      'phone': '0912 345 678',
      'email': 'minh.nguyen@gmail.com',
      'propertyTitle': 'Căn hộ chung cư cao cấp Vinhomes 2PN Landmark 81',
      'message': 'Tôi cần xem nhà trực tiếp vào sáng Thứ 7 tuần này lúc 9h.',
      'time': '10 phút trước',
      'status': 'Chưa liên hệ',
      'statusColor': const Color(0xFFE65100),
    },
    {
      'name': 'Trần Thị Thu Thảo',
      'phone': '0988 765 432',
      'email': 'thuthao.tran@yahoo.com',
      'propertyTitle': 'Nhà phố mặt tiền đường Lê Văn Sỹ 3 tầng kinh doanh',
      'message': 'Giá bán này còn thương lượng thêm được không ạ?',
      'time': '2 giờ trước',
      'status': 'Hẹn xem nhà',
      'statusColor': const Color(0xFF2E7D32),
    },
    {
      'name': 'Lê Hoàng Nam',
      'phone': '0903 112 233',
      'email': 'nam.lehoang@outlook.com',
      'propertyTitle': 'Biệt thự sân vườn Thảo Điền Quận 2 view sông',
      'message': 'Nhờ anh gửi giúp sổ hồng và giấy tờ pháp lý qua Zalo.',
      'time': 'Hôm qua',
      'status': 'Đã tư vấn',
      'statusColor': const Color(0xFF1565C0),
    },
    {
      'name': 'Phạm Đức Anh',
      'phone': '0977 888 999',
      'email': 'ducanh.pham@gmail.com',
      'propertyTitle': 'Đất nền thổ cư Hóc Môn 100m2 chính chủ',
      'message': 'Đất có dính quy hoạch gì không chủ nhà ơi?',
      'time': '3 ngày trước',
      'status': 'Chưa liên hệ',
      'statusColor': const Color(0xFFE65100),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFBFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCFBFA),
        elevation: 0,
        title: const Text(
          'Khách hàng liên hệ',
          style: TextStyle(
            color: Color(0xFF1A1918),
            fontWeight: FontWeight.bold,
            fontFamily: 'Georgia',
            fontSize: 22,
          ),
        ),
      ),
      body: Column(
        children: [
          // BỘ LỌC TRẠNG THÁI KHÁCH HÀNG
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                _buildStatusChip('Tất cả'),
                _buildStatusChip('Chưa liên hệ'),
                _buildStatusChip('Hẹn xem nhà'),
                _buildStatusChip('Đã tư vấn'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // DANH SÁCH KHÁCH HÀNG
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: _customers.length,
              itemBuilder: (context, index) {
                final customer = _customers[index];
                return _buildCustomerItem(customer);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label) {
    final isSelected = _activeTab == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: const Color(0xFF945331),
        backgroundColor: const Color(0xFFF4EEE6),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF78736D),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide.none,
        ),
        onSelected: (selected) {
          if (selected) {
            setState(() => _activeTab = label);
          }
        },
      ),
    );
  }

  Widget _buildCustomerItem(Map<String, dynamic> customer) {
    Color statusColor = customer['statusColor'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFF4EEE6),
                child: Text(
                  customer['name'].substring(0, 1),
                  style: const TextStyle(
                    color: Color(0xFF945331),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
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
                        Text(
                          customer['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1A1918),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            customer['status'],
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${customer['phone']} • ${customer['time']}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF78736D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFE8E3DC), height: 1),
          const SizedBox(height: 12),

          Text(
            'BĐS quan tâm:',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF78736D),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            customer['propertyTitle'],
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1918),
            ),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4EEE6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.format_quote,
                    color: Color(0xFF945331), size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    customer['message'],
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1A1918),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // NÚT HÀNH ĐỘNG GỌI / NHẮN TIN KHÁCH HÀNG
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _makePhoneCall(customer['phone']);
                  },
                  icon: const Icon(Icons.phone, color: Colors.white, size: 18),
                  label: const Text('Gọi điện',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã mở khung nhắn Zalo với ${customer['name']}'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline,
                      color: Color(0xFF945331), size: 18),
                  label: const Text('Nhắn tin',
                      style: TextStyle(
                          color: Color(0xFF945331), fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFF945331)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
