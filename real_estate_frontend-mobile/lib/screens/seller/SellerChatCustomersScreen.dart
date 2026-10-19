import 'dart:async';
import 'package:flutter/material.dart';
import 'package:real_estate_frontend/dto/ChatMessageDTO.dart';
import 'package:real_estate_frontend/dto/PropertyDTO.dart';
import 'package:real_estate_frontend/mixin/api/APIInteractionMixin.dart';
import 'package:real_estate_frontend/screens/ChatScreen.dart';
import 'package:real_estate_frontend/services/ChatService.dart';

part 'seller_chat_customers/seller_chat_customers_view.dart';
part 'seller_chat_customers/seller_chat_customer_item.dart';

class SellerChatCustomersScreen extends StatefulWidget {
  const SellerChatCustomersScreen({super.key});

  @override
  State<SellerChatCustomersScreen> createState() =>
      _SellerChatCustomersScreenState();
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

      final localCustomers = await _chatService.getAllChatCustomers();

      final apiInteractions = await fetchUserInteractions();

      final Map<String, Map<String, dynamic>> mergedMap = {};

      for (var item in apiInteractions) {
        final code =
            (item['interactionTypeCode'] ?? item['code'] ?? item['type'] ?? '')
                .toString()
                .toUpperCase();
        if (code != 'CHAT' && code != 'MESSAGE') continue;

        final status = (item['status'] as num?)?.toInt() ?? 0;
        final isActiveViewing =
            (status == 1) &&
            (code == 'MESSAGE' || code == 'CHAT' || code == 'VIEWING');
        final senderObj = item['sender'] is Map ? item['sender'] as Map : null;
        final receiverObj = item['receiver'] is Map
            ? item['receiver'] as Map
            : null;
        final propObj = item['property'] is Map
            ? item['property'] as Map
            : null;

        int? customerId = item['senderId'] ?? senderObj?['id'];
        String name =
            item['senderName'] ??
            item['senderFullname'] ??
            item['senderUsername'] ??
            senderObj?['fullname'] ??
            senderObj?['username'] ??
            'Khách hàng nhắn tin';

        if (myId != null && customerId == myId) {
          customerId = item['receiverId'] ?? receiverObj?['id'];
          final recName =
              item['receiverName'] ??
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
        final phone =
            item['senderPhone'] ??
            senderObj?['phone'] ??
            item['phone'] ??
            'Chưa cập nhật SĐT';
        final propertyTitle =
            item['propertyTitle'] ??
            propObj?['title'] ??
            'Bất động sản quan tâm';
        final message =
            item['message'] ?? item['content'] ?? 'Đã gửi tin nhắn tư vấn';
        final time =
            item['createdAt'] ??
            item['createdDate'] ??
            item['timestamp'] ??
            'Mới đây';

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

      for (var c in localCustomers) {
        final senderId = c['senderId'];
        if (myId != null && senderId == myId) continue;
        final phone = c['phone'];
        final key = senderId != null ? 'id_$senderId' : 'phone_$phone';

        if (!mergedMap.containsKey(key)) {
          mergedMap[key] = c;
        } else {
          mergedMap[key]!['latestMessage'] =
              c['latestMessage'] ?? mergedMap[key]!['latestMessage'];
          mergedMap[key]!['latestTime'] =
              c['latestTime'] ?? mergedMap[key]!['latestTime'];
        }
      }

      final list = mergedMap.values.toList();
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
  Widget build(BuildContext context) => _buildPage(context);
}
