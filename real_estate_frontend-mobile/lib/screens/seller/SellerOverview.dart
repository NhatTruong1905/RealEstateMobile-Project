import 'package:flutter/material.dart';
import 'package:real_estate_frontend/dto/PropertyDTO.dart';
import 'package:real_estate_frontend/dto/UserDTO.dart';
import 'package:real_estate_frontend/mixin/api/APIPropertyMixin.dart';
import 'package:real_estate_frontend/mixin/api/APIInteractionMixin.dart';
import 'package:real_estate_frontend/services/ChatService.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

part 'seller_overview/seller_overview_view.dart';
part 'seller_overview/seller_overview_sections.dart';
part 'seller_overview/seller_overview_cards.dart';

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
    await Future.wait([_loadMyProperties(), _loadInteractions()]);
  }

  Future<void> _loadMyProperties() async {
    final list = await fetchMyProperties().catchError((Object e) {
      debugPrint(e.toString());
      return <PropertyDTO>[];
    });
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
      final receiverObj = item['receiver'] is Map
          ? item['receiver'] as Map
          : null;

      final senderId = item['senderId'] ?? senderObj?['id'];
      final sUser = (item['senderUsername'] ?? senderObj?['username'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      final sName =
          (item['senderName'] ??
                  item['senderFullname'] ??
                  senderObj?['fullname'] ??
                  '')
              .toString()
              .trim()
              .toLowerCase();

      final receiverId = item['receiverId'] ?? receiverObj?['id'];
      final rUser = (item['receiverUsername'] ?? receiverObj?['username'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      final rName =
          (item['receiverName'] ??
                  item['receiverFullname'] ??
                  receiverObj?['fullname'] ??
                  '')
              .toString()
              .trim()
              .toLowerCase();
      final isSenderMe =
          (myId != null && senderId == myId) ||
          (myUsername != null &&
              myUsername.isNotEmpty &&
              sUser == myUsername) ||
          (myFullname != null && myFullname.isNotEmpty && sName == myFullname);

      final isReceiverMe =
          (myId != null && receiverId == myId) ||
          (myUsername != null &&
              myUsername.isNotEmpty &&
              rUser == myUsername) ||
          (myFullname != null && myFullname.isNotEmpty && rName == myFullname);

      if (isSenderMe && isReceiverMe) continue;

      if (isSenderMe) {
        if (myId != null && receiverId == myId) continue;
        if (myFullname != null && myFullname.isNotEmpty && rName == myFullname)
          continue;
        if (myUsername != null && myUsername.isNotEmpty && rUser == myUsername)
          continue;
      } else {
        if (myId != null && senderId == myId) continue;
        if (myFullname != null && myFullname.isNotEmpty && sName == myFullname)
          continue;
        if (myUsername != null && myUsername.isNotEmpty && sUser == myUsername)
          continue;
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
      final receiverObj = item['receiver'] is Map
          ? item['receiver'] as Map
          : null;

      final senderId = item['senderId'] ?? senderObj?['id'];
      final sUser = (item['senderUsername'] ?? senderObj?['username'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      final sName =
          (item['senderName'] ??
                  item['senderFullname'] ??
                  senderObj?['fullname'] ??
                  '')
              .toString()
              .trim()
              .toLowerCase();

      final isSenderMe =
          (myId != null && senderId == myId) ||
          (myUsername != null &&
              myUsername.isNotEmpty &&
              sUser == myUsername) ||
          (myFullname != null && myFullname.isNotEmpty && sName == myFullname);

      dynamic custIdentifier;
      if (isSenderMe) {
        custIdentifier =
            item['receiverId'] ??
            receiverObj?['id'] ??
            item['receiverPhone'] ??
            receiverObj?['phone'] ??
            item['receiverName'] ??
            receiverObj?['fullname'];
      } else {
        custIdentifier =
            senderId ??
            item['senderPhone'] ??
            senderObj?['phone'] ??
            item['senderName'] ??
            senderObj?['fullname'];
      }
      if (custIdentifier != null) {
        final strId = custIdentifier.toString().trim().toLowerCase();
        if (myFullname != null && myFullname.isNotEmpty && strId == myFullname)
          continue;
        if (myUsername != null && myUsername.isNotEmpty && strId == myUsername)
          continue;
        customerIds.add(custIdentifier);
      }
    }
    return customerIds.length;
  }

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
