import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:real_estate_frontend/dto/UserDTO.dart';
import 'package:real_estate_frontend/mixin/api/ApiLoginMixin.dart';
import 'package:real_estate_frontend/screens/Auth.dart';
import 'package:real_estate_frontend/screens/ChangePassword.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:real_estate_frontend/screens/FAQ.dart';
import 'package:real_estate_frontend/screens/PrivacyPolicy.dart';
import 'package:real_estate_frontend/screens/Terms.dart';

import 'package:real_estate_frontend/screens/UserProfile.dart';
import 'package:real_estate_frontend/screens/Home.dart';

part 'account/account_view.dart';
part 'account/account_components.dart';

class AccountScreen extends StatefulWidget {
  final bool isSellerMode;
  final Function(bool isSellerMode)? onSwitchMode;

  const AccountScreen({
    super.key,
    this.isSellerMode = false,
    this.onSwitchMode,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> with ApiLoginMixin {
  bool isLoggedIn = false;
  String currentUsername = '';

  UserDTO? currentUserProfile;
  bool isLoadingProfile = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    bool loggedIn = prefs.getBool('is_logged_in') ?? false;

    if (loggedIn) {
      String? userJsonString = prefs.getString('user_profile');

      if (mounted) {
        setState(() {
          isLoggedIn = true;

          if (userJsonString != null) {
            Map<String, dynamic> userMap = jsonDecode(userJsonString);
            currentUserProfile = UserDTO.fromJson(userMap);
            currentUsername = currentUserProfile?.username ?? '';
          }

          isLoadingProfile = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => isLoggedIn = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    await logout();
    for (var p in globalProperties) {
      p.isSaved = false;
    }
    if (mounted) {
      setState(() {
        isLoggedIn = false;
        currentUsername = '';
        currentUserProfile = null;
      });
      widget.onSwitchMode?.call(false);
    }
  }

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
