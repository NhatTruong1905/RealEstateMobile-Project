import 'dart:async';
import 'package:flutter/material.dart';
import 'package:real_estate_frontend/dto/ChatMessageDTO.dart';
import 'package:real_estate_frontend/dto/PropertyDTO.dart';
import 'package:real_estate_frontend/mixin/api/APIInteractionMixin.dart';
import 'package:real_estate_frontend/screens/ChatScreen.dart';
import 'package:real_estate_frontend/services/ChatService.dart';

class SellerChatCustomersScreen extends StatefulWidget {
  const SellerChatCustomersScreen({super.key});

  @override
  State<SellerChatCustomersScreen> createState() => _SellerChatCustomersScreenState();
}

class _SellerChatCustomersScreenState extends State<SellerChatCustomersScreen>
    with ApiInteractionMixin {
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _chatCustomers = [];
  bool _isLoading = true;
  String _searchQuery = '';

  StreamSubscription<ChatMessageDTO>? _msgSub;

  @override
  void initState() {
    super.initState();
    ChatService.hasUnreadNotification.value = false;
    _loadChatCustomers();

    _msgSub = _chatService.messageStream.listen((msg) {
      if (!mounted) return;
      _loadChatCustomers(isSilent: true);
    });
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadChatCustomers({bool isSilent = false}) async {
    if (!isSilent) setState(() => _isLoading = true);

    try {
      final myId = _chatService.currentUserId;

      // 1. Nạp danh sách khách hàng từ phiên chat local
      final localCustomers = await _chatService.getAllChatCustomers();

      // 2. Nạp tương tác từ API Backend
      final apiInteractions = await fetchUserInteractions();

      final Map<String, Map<String, dynamic>> mergedMap = {};

      // Đưa tương tác API vào danh sách
      for (var item in apiInteractions) {
        final code = (item['interactionTypeCode'] ?? item['code'] ?? item['type'] ?? '')
            .toString()
            .toUpperCase();
        if (code != 'CHAT' && code != 'MESSAGE') continue;

        final status = (item['status'] as num?)?.toInt() ?? 0;
        final isActiveViewing = (status == 1) &&
            (code == 'MESSAGE' || code == 'CHAT' || code == 'VIEWING');
        final senderObj = item['sender'] is Map ? item['sender'] as Map : null;
        final receiverObj = item['receiver'] is Map ? item['receiver'] as Map : null;
        final propObj = item['property'] is Map ? item['property'] as Map : null;

        int? customerId = item['senderId'] ?? senderObj?['id'];
        String name = item['senderName'] ??
            item['senderFullname'] ??
            item['senderUsername'] ??
            senderObj?['fullname'] ??
            senderObj?['username'] ??
            'Khách hàng nhắn tin';

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
        final propertyTitle = item['propertyTitle'] ?? propObj?['title'] ?? 'Bất động sản quan tâm';
        final message = item['message'] ?? item['content'] ?? 'Đã gửi tin nhắn tư vấn';
        final time = item['createdAt'] ?? item['createdDate'] ?? item['timestamp'] ?? 'Mới đây';

        final key = 'id_$senderId';

        if (!mergedMap.containsKey(key)) {
          mergedMap[key] = {
            'senderId': senderId,
            'propertyId': propertyId,
            'name': name,
            'phone': phone,
            'latestPropertyId': propertyId,
            'latestPropertyTitle': propertyTitle,
            'latestMessage': message,
            'latestTime': time,
            'hasActiveViewing': isActiveViewing,
            'count': 1,
          };
        } else {
          mergedMap[key]!['latestMessage'] = message;
          mergedMap[key]!['latestTime'] = time;
          if (isActiveViewing) {
            mergedMap[key]!['hasActiveViewing'] = true;
          }
        }
      }

      // Đưa các phiên chat local vào (nếu có khách mới chưa lưu DB)
      for (var c in localCustomers) {
        final senderId = c['senderId'];
        if (myId != null && senderId == myId) continue;
        final phone = c['phone'];
        final key = senderId != null ? 'id_$senderId' : 'phone_$phone';

        if (!mergedMap.containsKey(key)) {
          mergedMap[key] = c;
        } else {
          // Cập nhật thông tin tin nhắn mới nhất
          mergedMap[key]!['latestMessage'] = c['latestMessage'] ?? mergedMap[key]!['latestMessage'];
          mergedMap[key]!['latestTime'] = c['latestTime'] ?? mergedMap[key]!['latestTime'];
        }
      }

      final list = mergedMap.values.toList();
      // Sắp xếp theo thứ tự mới nhất đến cũ nhất
      list.sort((a, b) {
        final timeA = a['latestTime']?.toString() ?? '';
        final timeB = b['latestTime']?.toString() ?? '';
        return timeB.compareTo(timeA);
      });

      if (mounted) {
        setState(() {
          _chatCustomers = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi nạp danh sách khách hàng nhắn tin: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFBFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A1918), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Khách hàng nhắn tin',
          style: TextStyle(
            color: Color(0xFF1A1918),
            fontWeight: FontWeight.bold,
            fontFamily: 'Georgia',
            fontSize: 20,
          ),
        ),
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

          // DANH SÁCH KHÁCH HÀNG NHẮN TIN
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF945331)),
                  )
                : RefreshIndicator(
                    onRefresh: _loadChatCustomers,
                    color: const Color(0xFF945331),
                    child: () {
                      final filtered = _chatCustomers.where((c) {
                        if (_searchQuery.trim().isNotEmpty) {
                          final q = _searchQuery.trim().toLowerCase();
                          final name = (c['name'] ?? '').toString().toLowerCase();
                          return name.contains(q);
                        }
                        return true;
                      }).toList();

                      if (filtered.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 100),
                            Center(
                              child: Text(
                                'Chưa có tin nhắn từ khách hàng nào',
                                style: TextStyle(color: Color(0xFF78736D)),
                              ),
                            ),
                          ],
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return _buildCustomerChatItem(item);
                        },
                      );
                    }(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerChatItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E3DC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
                  item['name'].toString().substring(0, 1).toUpperCase(),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item['name'] ?? 'Khách hàng',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1A1918),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '💬 Mới nhất',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF1565C0),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item['phone']} • ${item['latestTime'] ?? 'Mới đây'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF78736D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: Color(0xFFE8E3DC), height: 1),
          const SizedBox(height: 10),

          Text(
            'BĐS quan tâm: ${item['latestPropertyTitle'] ?? 'Bất động sản'}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1918),
            ),
          ),
          const SizedBox(height: 6),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF4EEE6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline, size: 16, color: Color(0xFF945331)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item['latestMessage'] ?? 'Nội dung tin nhắn',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF1A1918)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final dummyProperty = PropertyDTO(
                      id: item['latestPropertyId'] ?? 1,
                      title: item['latestPropertyTitle'] ?? 'Bất động sản quan tâm',
                      price: 2500000000,
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          property: dummyProperty,
                          receiverId: item['senderId'],
                          receiverName: item['name'],
                          isSeller: true,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat, color: Color(0xFF945331), size: 16),
                  label: const Text(
                    'Trò chuyện',
                    style: TextStyle(color: Color(0xFF945331), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: const BorderSide(color: Color(0xFF945331)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (item['hasActiveViewing'] == true) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final propId = (item['latestPropertyId'] ?? item['propertyId'] ?? 1) as int;
                      final customerId = (item['senderId'] ?? item['userId'] ?? 0) as int;
                      try {
                        await markInteractionCompleted(
                          propertyId: propId,
                          senderId: customerId,
                          receiverId: _chatService.currentUserId ?? 0,
                          interactionTypeId: 2,
                          interactionTypeCode: 'MESSAGE',
                          completeBoth: true,
                        );
                        _loadChatCustomers();
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
                    icon: const Icon(Icons.task_alt_rounded, color: Colors.white, size: 16),
                    label: const Text(
                      'Đã xem nhà xong',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      padding: const EdgeInsets.symmetric(vertical: 10),
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
}
