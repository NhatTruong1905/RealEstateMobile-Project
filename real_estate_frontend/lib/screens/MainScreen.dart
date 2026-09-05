import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:real_estate_frontend/dto/ChatMessageDTO.dart';
import 'package:real_estate_frontend/layout/Footer.dart';
import 'package:real_estate_frontend/screens/Account.dart';
import 'package:real_estate_frontend/screens/Home.dart';
import 'package:real_estate_frontend/screens/SaveNews.dart';
import 'package:real_estate_frontend/screens/seller/PostProperty.dart';
import 'package:real_estate_frontend/screens/seller/SellerCustomers.dart';
import 'package:real_estate_frontend/screens/seller/SellerOverview.dart';
import 'package:real_estate_frontend/screens/seller/SellerProperties.dart';
import 'package:real_estate_frontend/services/ChatService.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _isSellerMode = false;
  int _buyerIndex = 0;
  int _sellerIndex = 0;

  final ChatService _chatService = ChatService();
  StreamSubscription<ChatMessageDTO>? _globalMsgSubscription;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initGlobalWebSocket();
  }

  Future<void> _initGlobalWebSocket() async {
    final prefs = await SharedPreferences.getInstance();
    final profileStr = prefs.getString('user_profile');
    if (profileStr != null) {
      try {
        final userMap = jsonDecode(profileStr);
        _currentUserId = (userMap['id'] as num?)?.toInt();
      } catch (_) {}
    }

    await _chatService.initGlobalConnection();

    _globalMsgSubscription = _chatService.messageStream.listen((msg) {
      if (!mounted) return;
      final text = msg.text;
      if (text.isEmpty || text.startsWith('__SYS_')) return;

      final myId = _currentUserId ?? _chatService.currentUserId;

      if (myId != null && msg.getSenderId == myId) return;

      if (ChatService.isChatActive(msg.propertyId, msg.getSenderId)) {
        return;
      }

      ChatService.hasUnreadNotification.value = true;
    });
  }

  @override
  void dispose() {
    _globalMsgSubscription?.cancel();
    super.dispose();
  }

  Future<void> _openPostModal() async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PostPropertyScreen()),
    );
    if (res == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _toggleMode(bool isSeller) async {
    if (isSeller) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Vui lòng đăng nhập để sử dụng giao diện Người bán!',
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }
    }

    if (mounted) {
      setState(() {
        _isSellerMode = isSeller;
        if (isSeller) {
          _sellerIndex = 0;
        } else {
          _buyerIndex = 0;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSellerMode) {
      return Scaffold(
        body: IndexedStack(
          index: _buyerIndex,
          children: [
            HomeScreen(key: ValueKey('home_$_buyerIndex')),
            SavedNewsScreen(key: ValueKey('saved_$_buyerIndex')),
            AccountScreen(
              key: ValueKey('account_$_buyerIndex'),
              isSellerMode: false,
              onSwitchMode: _toggleMode,
            ),
          ],
        ),
        bottomNavigationBar: Footer(
          currentIndex: _buyerIndex,
          isSellerMode: false,
          onTap: (index) {
            setState(() {
              _buyerIndex = index;
            });
          },
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _sellerIndex,
        children: [
          SellerOverviewScreen(
            key: ValueKey('seller_overview_$_sellerIndex'),
            onPostNewProperty: _openPostModal,
            onManageProperties: () => setState(() => _sellerIndex = 1),
            onManageCustomers: () => setState(() => _sellerIndex = 3),
          ),
          SellerPropertiesScreen(
            key: ValueKey('seller_properties_$_sellerIndex'),
            onPostNewProperty: _openPostModal,
          ),
          SellerOverviewScreen(
            key: ValueKey('seller_dummy_$_sellerIndex'),
            onPostNewProperty: _openPostModal,
            onManageProperties: () => setState(() => _sellerIndex = 1),
            onManageCustomers: () => setState(() => _sellerIndex = 3),
          ),
          SellerCustomersScreen(
            key: ValueKey('seller_customers_$_sellerIndex'),
          ),
          AccountScreen(
            key: ValueKey('seller_account_$_sellerIndex'),
            isSellerMode: true,
            onSwitchMode: _toggleMode,
          ),
        ],
      ),
      bottomNavigationBar: Footer(
        currentIndex: _sellerIndex,
        isSellerMode: true,
        onTap: (index) {
          setState(() {
            _sellerIndex = index;
          });
        },
        onPostTap: _openPostModal,
      ),
    );
  }
}
