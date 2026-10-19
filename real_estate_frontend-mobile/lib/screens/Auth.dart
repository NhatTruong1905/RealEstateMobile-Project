import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:real_estate_frontend/mixin/api/ApiLoginMixin.dart';
import 'package:real_estate_frontend/mixin/validation/ValidationMixin.dart';
import 'package:real_estate_frontend/screens/ForgotPassword.dart';

part 'auth/auth_view.dart';
part 'auth/auth_form_field.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;

  const AuthScreen({super.key, this.onLoginSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with ApiLoginMixin, ValidationMixin {
  final _formKey = GlobalKey<FormState>();

  bool _isLogin = true;
  bool _isLoading = false;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isAgreedToTerms = false;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _fullNameController.addListener(_validateInput);
    _usernameController.addListener(_validateInput);
    _passwordController.addListener(_validateInput);
    _emailController.addListener(_validateInput);
    _phoneController.addListener(_validateInput);
    _confirmPasswordController.addListener(_validateInput);
  }

  void _validateInput() {
    setState(() {});
  }

  bool get _isButtonEnabled {
    if (_isLogin) {
      return _usernameController.text.trim().isNotEmpty &&
          _passwordController.text.isNotEmpty;
    } else {
      return _fullNameController.text.trim().isNotEmpty &&
          _usernameController.text.trim().isNotEmpty &&
          _emailController.text.trim().isNotEmpty &&
          _phoneController.text.trim().isNotEmpty &&
          _passwordController.text.isNotEmpty &&
          _confirmPasswordController.text.isNotEmpty &&
          _isAgreedToTerms;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);

    if (_isLogin) {
      bool success = await login(username, password);
      setState(() => _isLoading = false);

      if (success && mounted) {
        _showSnackBar('Đăng nhập thành công!', isError: false);
        Navigator.pop(context);
        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess!();
        }
      } else if (mounted) {
        _showSnackBar('Mật khẩu hoặc tên đăng nhập không chính xác!');
      }
    } else {
      final fullname = _fullNameController.text.trim();
      final email = _emailController.text.trim();
      final phone = _phoneController.text.trim();

      String? errorMessage = await registerUser(
        fullname: fullname,
        username: username,
        password: password,
        email: email,
        phone: phone,
      );

      setState(() => _isLoading = false);

      if (errorMessage == null && mounted) {
        _showSnackBar(
          'Đăng ký thành công! Vui lòng đăng nhập.',
          isError: false,
        );

        _passwordController.clear();
        _confirmPasswordController.clear();
        setState(() {
          _isLogin = true;
          _isAgreedToTerms = false;
        });
      } else if (mounted) {
        _showSnackBar(errorMessage ?? 'Đăng ký thất bại!');
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final res = await loginWithGoogle();

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (res['success'] == true) {
      _showSnackBar(
        res['message'] ?? 'Đăng nhập Google thành công!',
        isError: false,
      );
      Navigator.pop(context);
      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!();
      }
    } else {
      _showSnackBar(res['message'] ?? 'Đăng nhập Google thất bại!');
    }
  }

  Future<void> _handleFacebookLogin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final res = await loginWithFacebook();

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (res['success'] == true) {
      _showSnackBar(
        res['message'] ?? 'Đăng nhập Facebook thành công!',
        isError: false,
      );
      Navigator.pop(context);
      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!();
      }
    } else {
      _showSnackBar(res['message'] ?? 'Đăng nhập Facebook thất bại!');
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Colors.red.shade700
            : const Color(0xFF945331),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
