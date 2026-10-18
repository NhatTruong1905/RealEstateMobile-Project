import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:real_estate_frontend/mixin/api/ApiUserMixin.dart';
import 'package:real_estate_frontend/mixin/api/ApiLoginMixin.dart';

class LoginHelper with ApiLoginMixin {}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen>
    with ApiUserMixin {
  final _formKey = GlobalKey<FormState>();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();

    String? userProfileJson = prefs.getString('user_profile');
    Map<String, dynamic> userMap = {};
    if (userProfileJson != null && userProfileJson.isNotEmpty) {
      userMap = jsonDecode(userProfileJson);
    }

    final username = userMap['username'] ?? prefs.getString('username') ?? '';

    final loginHelper = LoginHelper();
    bool isOldPasswordCorrect = await loginHelper.login(
      username,
      _currentPasswordController.text.trim(),
    );

    if (!isOldPasswordCorrect) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mật khẩu hiện tại không chính xác!'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
      return;
    }

    final fullname = userMap['fullname'] ?? userMap['fullName'] ?? '';
    final phone = userMap['phone'] ?? '';
    final email = userMap['email'] ?? '';

    String? errorMessage = await updateProfile(
      username: username,
      fullname: fullname,
      phone: phone,
      email: email,
      password: _newPasswordController.text.trim(),
    );

    if (errorMessage == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đổi mật khẩu thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đổi mật khẩu'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _currentPasswordController,
                      obscureText: _obscureCurrent,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu hiện tại',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureCurrent
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setState(
                            () => _obscureCurrent = !_obscureCurrent,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Vui lòng nhập mật khẩu hiện tại';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: _obscureNew,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu mới',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.lock_reset),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNew
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () =>
                              setState(() => _obscureNew = !_obscureNew),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Vui lòng nhập mật khẩu mới';
                        if (value.length < 6)
                          return 'Mật khẩu phải từ 6 ký tự trở lên';
                        if (value == _currentPasswordController.text)
                          return 'Mật khẩu mới phải khác mật khẩu hiện tại';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Xác nhận mật khẩu mới',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.check_circle_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Vui lòng xác nhận mật khẩu mới';
                        if (value != _newPasswordController.text)
                          return 'Mật khẩu xác nhận không khớp';
                        return null;
                      },
                    ),
                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _handleChangePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Đổi mật khẩu',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

