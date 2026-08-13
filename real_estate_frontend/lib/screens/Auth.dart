import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:real_estate_frontend/mixin/api/ApiLoginMixin.dart';
import 'package:real_estate_frontend/mixin/validation/ValidationMixin.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFBFA),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE8E3DC),
                      width: 1.5,
                    ),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.close,
                      color: Color(0xFF1A1918),
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                    splashRadius: 20,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF945331,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.apartment_rounded,
                            color: Color(0xFF945331),
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 32),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            _isLogin ? 'Mừng bạn trở lại' : 'Tạo tài khoản',
                            key: ValueKey<bool>(_isLogin),
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1918),
                              fontFamily: 'Georgia',
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isLogin
                              ? 'Đăng nhập để tiếp tục khám phá bất động sản'
                              : 'Tham gia cộng đồng bất động sản hàng đầu',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF78736D),
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                        const SizedBox(height: 32),

                        if (!_isLogin) ...[
                          _buildFormInputField(
                            controller: _fullNameController,
                            icon: Icons.person_outline,
                            hintText: 'Họ và tên',
                            validator: validateFullName,
                          ),
                          const SizedBox(height: 16),

                          _buildFormInputField(
                            controller: _emailController,
                            icon: Icons.email_outlined,
                            hintText: 'Email',
                            keyboardType: TextInputType.emailAddress,
                            inputFormatters: [
                              FilteringTextInputFormatter.deny(RegExp(r'\s')),
                            ],
                            validator: validateEmail,
                          ),
                          const SizedBox(height: 16),

                          _buildFormInputField(
                            controller: _phoneController,
                            icon: Icons.phone_outlined,
                            hintText: 'Số điện thoại',
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            validator: validatePhone,
                          ),
                          const SizedBox(height: 16),
                        ],

                        _buildFormInputField(
                          controller: _usernameController,
                          icon: Icons.account_circle_outlined,
                          hintText: 'Tên đăng nhập',
                          keyboardType: TextInputType.text,
                          validator: validateUsername,
                        ),
                        const SizedBox(height: 16),

                        _buildFormInputField(
                          controller: _passwordController,
                          icon: Icons.lock_outline,
                          hintText: 'Mật khẩu',
                          isPassword: true,
                          obscureText: _obscurePassword,
                          onToggleVisibility: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          validator: (value) =>
                              validatePassword(value, isLogin: _isLogin),
                        ),

                        if (!_isLogin) ...[
                          const SizedBox(height: 16),
                          _buildFormInputField(
                            controller: _confirmPasswordController,
                            icon: Icons.check_circle_outline,
                            hintText: 'Xác nhận mật khẩu',
                            isPassword: true,
                            obscureText: _obscureConfirmPassword,
                            onToggleVisibility: () => setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng xác nhận mật khẩu';
                              }
                              if (value != _passwordController.text) {
                                return 'Mật khẩu xác nhận không khớp';
                              }
                              return null;
                            },
                          ),
                        ],

                        if (_isLogin)
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: TextButton(
                                onPressed: () {},
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Quên mật khẩu?',
                                  style: TextStyle(
                                    color: Color(0xFF945331),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _isAgreedToTerms,
                                    onChanged: (value) {
                                      setState(() {
                                        _isAgreedToTerms = value ?? false;
                                      });
                                    },
                                    activeColor: const Color(0xFF945331),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    side: const BorderSide(
                                      color: Color(0xFF78736D),
                                      width: 1.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      text: 'Tôi đã đọc và đồng ý với ',
                                      style: const TextStyle(
                                        color: Color(0xFF78736D),
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                      children: const [
                                        TextSpan(
                                          text:
                                              'Điều khoản sử dụng, Chính sách bảo mật, Quy chế, Chính sách',
                                          style: TextStyle(
                                            color: Color(0xFF1A1918),
                                            fontWeight: FontWeight.bold,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                        TextSpan(text: ' của PropertySumDev.'),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 32),

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: (!_isButtonEnabled || _isLoading)
                                ? null
                                : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF945331),
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: const Color(
                                0xFF945331,
                              ).withValues(alpha: 0.3),
                              disabledBackgroundColor: const Color(0xFFE8E3DC),
                              disabledForegroundColor: const Color(0xFF78736D),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _isLogin ? 'Đăng nhập' : 'Đăng ký',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        Row(
                          children: [
                            const Expanded(
                              child: Divider(
                                color: Color(0xFFE8E3DC),
                                thickness: 1.5,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                _isLogin
                                    ? 'Hoặc đăng nhập với'
                                    : 'Hoặc đăng ký với',
                                style: const TextStyle(
                                  color: Color(0xFF78736D),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Divider(
                                color: Color(0xFFE8E3DC),
                                thickness: 1.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isLoading ? null : _handleGoogleLogin,
                                icon: Image.network(
                                  'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png',
                                  height: 22,
                                ),
                                label: const Text(
                                  'Google',
                                  style: TextStyle(
                                    color: Color(0xFF1A1918),
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  side: const BorderSide(
                                    color: Color(0xFFE8E3DC),
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isLoading ? null : _handleFacebookLogin,
                                icon: const Icon(
                                  Icons.facebook,
                                  color: Color(0xFF1877F2),
                                  size: 26,
                                ),
                                label: const Text(
                                  'Facebook',
                                  style: TextStyle(
                                    color: Color(0xFF1A1918),
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  side: const BorderSide(
                                    color: Color(0xFFE8E3DC),
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isLogin
                                  ? 'Chưa có tài khoản? '
                                  : 'Đã có tài khoản? ',
                              style: const TextStyle(
                                color: Color(0xFF78736D),
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                _formKey.currentState?.reset();
                                _fullNameController.clear();
                                _usernameController.clear();
                                _passwordController.clear();
                                _emailController.clear();
                                _phoneController.clear();
                                _confirmPasswordController.clear();
                                setState(() {
                                  _isLogin = !_isLogin;
                                  _isAgreedToTerms = false;
                                });
                              },
                              child: Text(
                                _isLogin ? 'Đăng ký ngay' : 'Đăng nhập',
                                style: const TextStyle(
                                  color: Color(0xFF945331),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormInputField({
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    required String? Function(String?) validator,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? obscureText : false,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(color: Color(0xFF1A1918), fontSize: 15),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF78736D), fontSize: 15),
        prefixIcon: Icon(icon, color: const Color(0xFF78736D), size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFF78736D),
                  size: 20,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF4EEE6),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF945331), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }
}
