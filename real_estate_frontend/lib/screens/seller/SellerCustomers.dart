import 'dart:async';
import 'package:flutter/material.dart';
import 'package:real_estate_frontend/dto/ChatMessageDTO.dart';
import 'package:real_estate_frontend/dto/PropertyDTO.dart';
import 'package:real_estate_frontend/mixin/api/APIInteractionMixin.dart';
import 'package:real_estate_frontend/screens/ChatScreen.dart';
import 'package:real_estate_frontend/screens/seller/SellerChatCustomersScreen.dart';
import 'package:real_estate_frontend/services/ChatService.dart';
import 'package:url_launcher/url_launcher.dart';

class SellerCustomersScreen extends StatefulWidget {
  const SellerCustomersScreen({super.key});

  @override
  State<SellerCustomersScreen> createState() => _SellerCustomersScreenState();
}

class _SellerCustomersScreenState extends State<SellerCustomersScreen>
    with ApiInteractionMixin {
  String _activeTab = 'Tất cả';
  bool _isLoading = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ChatService _chatService = ChatService();
  StreamSubscription<ChatMessageDTO>? _globalMsgSub;

  @override
  void initState() {
    super.initState();
    _loadInteractions();

    _globalMsgSub = _chatService.messageStream.listen((msg) {
      if (!mounted) return;

      // Cập nhật lại danh sách khách hàng và trạng thái nút xem nhà realtime KHÔNG hiện loading spinner
      _loadInteractions(isSilent: true);
      ChatService.hasUnreadNotification.value = true;
    });
  }

  @override
  void dispose() {
    _globalMsgSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInteractions({bool isSilent = false}) async {
    if (!isSilent) setState(() => _isLoading = true);
    final apiItems = await fetchUserInteractions();

    if (mounted) {
      final Map<String, Map<String, dynamic>> groupedMap = {};

      for (var item in apiItems) {
        final code = (item['interactionTypeCode'] ?? item['code'] ?? item['type'] ?? '')
            .toString()
            .toUpperCase();

        final myId = _chatService.currentUserId;
        final senderObj = item['sender'] is Map ? item['sender'] as Map : null;
        final receiverObj = item['receiver'] is Map ? item['receiver'] as Map : null;
        final propObj = item['property'] is Map ? item['property'] as Map : null;

        int? customerId = item['senderId'] ?? senderObj?['id'];
        String name = item['senderName'] ??
            item['senderFullname'] ??
            item['senderUsername'] ??
            senderObj?['fullname'] ??
            senderObj?['username'] ??
            'Khách hàng quan tâm';

        if (myId != null && customerId == myId) {
          customerId = item['receiverId'] ?? receiverObj?['id'];
          final recName = item['receiverName'] ??
              item['receiverFullname'] ??
              item['receiverUsername'] ??
              receiverObj?['fullname'] ??
              receiverObj?['username'];
          if (recName != null && recName.toString().isNotEmpty) {
            name = recName.toString();
          }
        }

        if (myId != null && customerId == myId) continue;
        if (customerId == null) continue;

        final senderId = customerId;
        final propertyId = item['propertyId'] ?? propObj?['id'];
        final phone = item['senderPhone'] ??
            senderObj?['phone'] ??
            item['phone'] ??
            'Chưa cập nhật SĐT';
        final email = item['senderEmail'] ?? senderObj?['email'] ?? item['email'] ?? '';
        final propertyTitle = item['propertyTitle'] ?? propObj?['title'] ?? 'Bất động sản quan tâm';
        final message = item['message'] ?? item['content'] ?? 'Khách hàng đã tương tác';
        final time = item['createdAt'] ?? item['createdDate'] ?? item['timestamp'] ?? 'Mới đây';

        final status = (item['status'] as num?)?.toInt() ?? 0;
        final isActiveViewing = (status == 1) &&
            (code == 'MESSAGE' || code == 'CHAT' || code == 'VIEWING');

        // Gom nhóm duy nhất theo Khách hàng (senderId hoặc SĐT)
        final groupKey = 'id_$senderId';

        final interactionItem = {
          'code': code,
          'status': status,
          'propertyId': propertyId,
          'propertyTitle': propertyTitle,
          'message': message,
          'time': time,
          'raw': item,
        };

        if (!groupedMap.containsKey(groupKey)) {
          groupedMap[groupKey] = {
            'senderId': senderId,
            'name': name,
            'phone': phone,
            'email': email,
            'latestPropertyId': propertyId,
            'latestPropertyTitle': propertyTitle,
            'latestMessage': message,
            'latestTime': time,
            'callCount': code == 'CALL' ? 1 : 0,
            'messageCount': (code == 'MESSAGE' || code == 'CHAT') ? 1 : 0,
            'viewingCount': code == 'VIEWING' ? 1 : 0,
            'hasActiveViewing': isActiveViewing,
            'history': [interactionItem],
          };
        } else {
          final group = groupedMap[groupKey]!;
          (group['history'] as List<Map<String, dynamic>>).add(interactionItem);
          if (code == 'CALL') {
            group['callCount'] = (group['callCount'] as int) + 1;
          } else if (code == 'MESSAGE' || code == 'CHAT') {
            group['messageCount'] = (group['messageCount'] as int) + 1;
          } else if (code == 'VIEWING') {
            group['viewingCount'] = (group['viewingCount'] as int) + 1;
          }
          if (isActiveViewing) {
            group['hasActiveViewing'] = true;
          }
          // Cập nhật thông tin tương tác mới nhất
          group['latestMessage'] = message;
          group['latestTime'] = time;
          group['latestPropertyTitle'] = propertyTitle;
          if (propertyId != null) {
            group['latestPropertyId'] = propertyId;
          }
          if (group['senderId'] == null) {
            group['senderId'] = senderId;
          }
        }
      }

      // Nạp các phiên chat local từ máy (để hiển thị khách chỉ nhắn tin chưa lưu DB)
      final localChatCustomers = await _chatService.getAllChatCustomers();

      for (var c in localChatCustomers) {
        final senderId = c['senderId'];
        final phone = c['phone'];
        final groupKey = senderId != null ? 'id_$senderId' : 'phone_$phone';

        if (!groupedMap.containsKey(groupKey)) {
          groupedMap[groupKey] = {
            'senderId': senderId,
            'name': c['name'],
            'phone': phone,
            'email': '',
            'latestPropertyId': c['latestPropertyId'],
            'latestPropertyTitle': c['latestPropertyTitle'],
            'latestMessage': c['latestMessage'],
            'latestTime': c['latestTime'],
            'callCount': 0,
            'messageCount': c['messageCount'] ?? 1,
            'viewingCount': 0,
            'history': [
              {
                'code': 'CHAT',
                'propertyId': c['latestPropertyId'],
                'propertyTitle': c['latestPropertyTitle'],
                'message': c['latestMessage'],
                'time': c['latestTime'],
              }
            ],
          };
        } else {
          final group = groupedMap[groupKey]!;
          final currentMsgCount = (group['messageCount'] as int? ?? 0);
          if (currentMsgCount == 0) {
            group['messageCount'] = c['messageCount'] ?? 1;
            group['latestMessage'] = c['latestMessage'] ?? group['latestMessage'];
            group['latestTime'] = c['latestTime'] ?? group['latestTime'];
          }
        }
      }

      setState(() {
        _customers = groupedMap.values.toList();
        _isLoading = false;
      });
    }
  }

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

  List<Map<String, dynamic>> _customers = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFBFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black12,
        automaticallyImplyLeading: false,
        title: const Text(
          'Quản lý Khách hàng',
          style: TextStyle(
            color: Color(0xFF1A1918),
            fontWeight: FontWeight.bold,
            fontFamily: 'Georgia',
            fontSize: 20,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ValueListenableBuilder<bool>(
              valueListenable: ChatService.hasUnreadNotification,
              builder: (context, hasUnread, child) {
                return InkWell(
                  onTap: () {
                    ChatService.hasUnreadNotification.value = false;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SellerChatCustomersScreen(),
                      ),
                    );
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
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SellerChatCustomersScreen(),
                                ),
                              );
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
          ),
        ],
      ),
      body: Column(
        children: [
          // Ô TÌM KIẾM
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Nhập tên khách hàng...',
                      hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
                      prefixIcon: const Icon(Icons.person_search, color: Color(0xFF945331)),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18, color: Color(0xFF78736D)),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE8E3DC)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE8E3DC)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF945331), width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _searchQuery = _searchController.text;
                    });
                  },
                  icon: const Icon(Icons.search, color: Colors.white, size: 18),
                  label: const Text(
                    'Tìm',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF945331),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),

          // NÚT MỞ TRANG "KHÁCH HÀNG NHẮN TIN" (SẮP XẾP MỚI NHẤT ĐẾN CỦ NHẤT)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SellerChatCustomersScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF945331), Color(0xFFB45309)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF945331).withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mark_chat_unread, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Khách hàng nhắn tin',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 2),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
          ),

          // BỘ LỌC TRẠNG THÁI KHÁCH HÀNG
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                _buildStatusChip('Tất cả'),
                _buildStatusChip('Hẹn xem nhà'),
                _buildStatusChip('Đã tư vấn'),
                _buildStatusChip('Cuộc gọi'),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // DANH SÁCH KHÁCH HÀNG
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF945331)),
                  )
                : RefreshIndicator(
                    onRefresh: _loadInteractions,
                    color: const Color(0xFF945331),
                    child: () {
                      final filtered = _customers.where((c) {
                        // Lọc theo tên khách hàng
                        if (_searchQuery.trim().isNotEmpty) {
                          final query = _searchQuery.trim().toLowerCase();
                          final customerName = (c['name'] ?? '').toString().toLowerCase();
                          if (!customerName.contains(query)) {
                            return false;
                          }
                        }

                        // Lọc theo tab tương tác
                        if (_activeTab == 'Hẹn xem nhà') {
                          return (c['viewingCount'] as int? ?? 0) > 0;
                        } else if (_activeTab == 'Đã tư vấn') {
                          return (c['messageCount'] as int? ?? 0) > 0;
                        } else if (_activeTab == 'Cuộc gọi') {
                          return (c['callCount'] as int? ?? 0) > 0;
                        }
                        return true;
                      }).toList();

                      if (filtered.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 80),
                            Center(
                              child: Text(
                                'Không tìm thấy dữ liệu khách hàng',
                                style: TextStyle(color: Color(0xFF78736D)),
                              ),
                            ),
                          ],
                        );
                      }

                      return ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final customer = filtered[index];
                          return _buildCustomerItem(customer);
                        },
                      );
                    }(),
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

  void _showInteractionHistoryBottomSheet(
      BuildContext context, Map<String, dynamic> customer) {
    final historyList =
        (customer['history'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 520,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFFF4EEE6),
                    child: Text(
                      customer['name'].toString().substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF945331),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1A1918),
                          ),
                        ),
                        Text(
                          '${customer['phone']} • Lịch sử ${historyList.length} lần tương tác',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF78736D),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: Color(0xFFE8E3DC)),
              const SizedBox(height: 8),
              const Text(
                'Lịch sử chi tiết (Cuộc gọi, Tin nhắn & Hẹn xem nhà):',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1918),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: historyList.length,
                  itemBuilder: (context, index) {
                    final h = historyList[index];
                    final code = h['code'] ?? '';
                    final IconData iconData = code == 'CALL'
                        ? Icons.phone_callback
                        : (code == 'VIEWING'
                            ? Icons.calendar_today
                            : Icons.chat_bubble_outline);
                    final Color iconColor = code == 'CALL'
                        ? const Color(0xFFD32F2F)
                        : (code == 'VIEWING'
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFF1565C0));
                    final String typeLabel = code == 'CALL'
                        ? 'Cuộc gọi'
                        : (code == 'VIEWING'
                            ? 'Lịch hẹn xem nhà'
                            : 'Tin nhắn / Tư vấn');

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F6F0),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE8E3DC)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: iconColor.withValues(alpha: 0.15),
                            child: Icon(iconData, size: 18, color: iconColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      typeLabel,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: iconColor,
                                      ),
                                    ),
                                    Text(
                                      h['time'] ?? 'Mới đây',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF78736D),
                                      ),
                                    ),
                                  ],
                                ),
                                if (h['propertyTitle'] != null &&
                                    h['propertyTitle'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'BĐS: ${h['propertyTitle']}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A1918),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  h['message'] ?? 'Tương tác',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF4A4A4A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCustomerItem(Map<String, dynamic> customer) {
    final historyList = (customer['history'] as List?) ?? [];
    final int callCount = customer['callCount'] ?? 0;
    final int messageCount = customer['messageCount'] ?? 0;
    final int viewingCount = customer['viewingCount'] ?? 0;
    final int totalCount = historyList.length;

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
          // HEADER: THÔNG TIN KHÁCH HÀNG
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFF4EEE6),
                child: Text(
                  customer['name'].toString().substring(0, 1).toUpperCase(),
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
                    Text(
                      customer['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1A1918),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${customer['phone']} • ${customer['latestTime'] ?? 'Mới đây'}',
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

          // KHU VỰC THỐNG KÊ: SỐ CUỘC GỌI, TIN NHẮN, HẸN XEM NHÀ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F6F0),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8E3DC)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatBadge(
                  icon: Icons.phone_callback,
                  color: const Color(0xFFD32F2F),
                  label: 'Cuộc gọi',
                  count: callCount,
                ),
                Container(width: 1, height: 22, color: const Color(0xFFE8E3DC)),
                _buildStatBadge(
                  icon: Icons.chat_bubble_outline,
                  color: const Color(0xFF1565C0),
                  label: 'Tin nhắn',
                  count: messageCount,
                ),
                Container(width: 1, height: 22, color: const Color(0xFFE8E3DC)),
                _buildStatBadge(
                  icon: Icons.calendar_today,
                  color: const Color(0xFF2E7D32),
                  label: 'Hẹn xem',
                  count: viewingCount,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // BĐS QUAN TÂM & NỘI DUNG MỚI NHẤT
          if (customer['latestPropertyTitle'] != null) ...[
            const Text(
              'BĐS quan tâm:',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF78736D),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              customer['latestPropertyTitle'],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1918),
              ),
            ),
            const SizedBox(height: 8),
          ],

          if (customer['latestMessage'] != null)
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
                      customer['latestMessage'],
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

          const SizedBox(height: 10),

          // NÚT XEM LỊCH SỬ TƯƠNG TÁC
          InkWell(
            onTap: () =>
                _showInteractionHistoryBottomSheet(context, customer),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF945331).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.history, size: 16, color: Color(0xFF945331)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Xem toàn bộ lịch sử tương tác ($totalCount lần)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF945331),
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      size: 16, color: Color(0xFF945331)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // NÚT HÀNH ĐỘNG GỌI / NHẮN TIN / ĐÃ XEM NHÀ XONG KHÁCH HÀNG
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _makePhoneCall(customer['phone']);
                  },
                  icon: const Icon(Icons.phone, color: Colors.white, size: 15),
                  label: const Text(
                    'Gọi điện',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final dummyProperty = PropertyDTO(
                      id: customer['latestPropertyId'] ?? 1,
                      title: customer['latestPropertyTitle'] ?? 'Bất động sản quan tâm',
                      price: 2500000000,
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          property: dummyProperty,
                          receiverId: customer['senderId'] ?? customer['userId'],
                          receiverName: customer['name'],
                          isSeller: true,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF945331), size: 15),
                  label: const Text(
                    'Nhắn tin',
                    style: TextStyle(color: Color(0xFF945331), fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    side: const BorderSide(color: Color(0xFF945331)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (customer['hasActiveViewing'] == true) ...[
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final propId = (customer['latestPropertyId'] ?? 1) as int;
                      final customerId = (customer['senderId'] ?? customer['userId'] ?? 0) as int;
                      try {
                        await markInteractionCompleted(
                          propertyId: propId,
                          senderId: customerId,
                          receiverId: _chatService.currentUserId ?? 0,
                          interactionTypeId: 2,
                          interactionTypeCode: 'MESSAGE',
                          completeBoth: true,
                        );
                        _loadInteractions();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã cập nhật hoàn tất lượt xem nhà cho khách hàng này!'),
                              backgroundColor: Color(0xFF2E7D32),
                            ),
                          );
                        }
                      } catch (e) {
                        debugPrint('Lỗi hoàn tất xem nhà: $e');
                      }
                    },
                    icon: const Icon(Icons.task_alt_rounded, color: Colors.white, size: 15),
                    label: const Text(
                      'Đã xem xong',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required Color color,
    required String label,
    required int count,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          '$count $label',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: count > 0 ? const Color(0xFF1A1918) : const Color(0xFF9E9E9E),
          ),
        ),
      ],
    );
  }
}

