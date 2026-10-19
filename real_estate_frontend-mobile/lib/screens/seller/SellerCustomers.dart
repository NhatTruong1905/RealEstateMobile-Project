import 'dart:async';
import 'package:flutter/material.dart';
import 'package:real_estate_frontend/dto/ChatMessageDTO.dart';
import 'package:real_estate_frontend/dto/PropertyDTO.dart';
import 'package:real_estate_frontend/mixin/api/APIInteractionMixin.dart';
import 'package:real_estate_frontend/screens/ChatScreen.dart';
import 'package:real_estate_frontend/screens/seller/SellerChatCustomersScreen.dart';
import 'package:real_estate_frontend/services/ChatService.dart';
import 'package:url_launcher/url_launcher.dart';

part 'seller_customers/seller_customers_view.dart';
part 'seller_customers/seller_customer_history.dart';
part 'seller_customers/seller_customer_items.dart';

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
        final code =
            (item['interactionTypeCode'] ?? item['code'] ?? item['type'] ?? '')
                .toString()
                .toUpperCase();

        final myId = _chatService.currentUserId;
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
            'Khách hàng quan tâm';

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
        final email =
            item['senderEmail'] ?? senderObj?['email'] ?? item['email'] ?? '';
        final propertyTitle =
            item['propertyTitle'] ??
            propObj?['title'] ??
            'Bất động sản quan tâm';
        final message =
            item['message'] ?? item['content'] ?? 'Khách hàng đã tương tác';
        final time =
            item['createdAt'] ??
            item['createdDate'] ??
            item['timestamp'] ??
            'Mới đây';

        final status = (item['status'] as num?)?.toInt() ?? 0;
        final isActiveViewing =
            (status == 1) &&
            (code == 'MESSAGE' || code == 'CHAT' || code == 'VIEWING');

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
              },
            ],
          };
        } else {
          final group = groupedMap[groupKey]!;
          final currentMsgCount = (group['messageCount'] as int? ?? 0);
          if (currentMsgCount == 0) {
            group['messageCount'] = c['messageCount'] ?? 1;
            group['latestMessage'] =
                c['latestMessage'] ?? group['latestMessage'];
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
  Widget build(BuildContext context) => _buildPage(context);
}
