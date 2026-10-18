import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:real_estate_frontend/mixin/api/ApiLoginMixin.dart';
import 'package:real_estate_frontend/mixin/validation/ValidationMixin.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with ApiLoginMixin, ValidationMixin {
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep3 = GlobalKey<FormState>();

  int _currentStep = 1;
  bool _isLoading = false;

  // Giai đoạn 1 tìm tài khoản
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _requireEmail = false;

  // Giai đoạn 2 nhập OTP với 6 ô số
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );
  Timer? _countdownTimer;
  int _countdownSeconds = 60;
  bool _canResend = false;
  String _maskedEmail = '';
  String _resetToken = '';

  // Giai đoạn 3 setup lại mật khẩu
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _emailController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _countdownSeconds = 60;
      _canResend = false;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 1) {
        setState(() => _countdownSeconds--);
      } else {
        timer.cancel();
        setState(() => _canResend = true);
      }
    });
  }

  String get _enteredOtp {
    return _otpControllers.map((c) => c.text.trim()).join();
  }

  Future<void> _handleSendOtp() async {
    if (_currentStep == 1) {
      if (_formKeyStep1.currentState != null &&
          !_formKeyStep1.currentState!.validate()) {
        return;
      }
    }

    final identifier = _identifierController.text.trim();
    final email = _requireEmail ? _emailController.text.trim() : null;

    setState(() => _isLoading = true);

    final res = await forgotPassword(identifier, email: email);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (res['success'] == true) {
      final status = res['status'];
      if (status == 'REQUIRE_EMAIL') {
        setState(() {
          _requireEmail = true;
        });
        _showSnackBar(
          'Tài khoản chưa có email. Vui lòng nhập email để nhận mã OTP!',
          isWarning: true,
        );
      } else if (status == 'OTP_SENT') {
        for (var controller in _otpControllers) {
          controller.clear();
        }
        if (_otpFocusNodes.isNotEmpty && _currentStep == 2) {
          _otpFocusNodes[0].requestFocus();
        }
        setState(() {
          _maskedEmail = res['maskedEmail'] ?? (email ?? '');
          _currentStep = 2;
        });
        _startCountdown();
        _showSnackBar(
          'Mã OTP 6 số đã được gửi đến email của bạn!',
          isSuccess: true,
        );
      }
    } else {
      _showSnackBar(res['message'] ?? 'Không tìm thấy tài khoản!');
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _enteredOtp;
    if (otp.length < 6) {
      _showSnackBar('Vui lòng nhập đầy đủ 6 số OTP');
      return;
    }

    final identifier = _identifierController.text.trim();
    final email = _requireEmail ? _emailController.text.trim() : null;

    setState(() => _isLoading = true);

    final res = await verifyOtp(identifier, otp, email: email);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (res['success'] == true) {
      setState(() {
        _resetToken = res['resetToken'] ?? '';
        _currentStep = 3;
      });
      _showSnackBar('Xác thực OTP thành công!', isSuccess: true);
    } else {
      _showSnackBar(res['message'] ?? 'Mã OTP không hợp lệ!');
    }
  }

  Future<void> _handleResetPassword() async {
    if (!_formKeyStep3.currentState!.validate()) return;

    final identifier = _identifierController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final email = _requireEmail ? _emailController.text.trim() : null;

    setState(() => _isLoading = true);

    final res = await resetPassword(
      identifier,
      _resetToken,
      newPassword,
      email: email,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (res['success'] == true) {
      _showSuccessDialog();
    } else {
      _showSnackBar(res['message'] ?? 'Đặt lại mật khẩu thất bại!');
    }
  }

  void _showSnackBar(
    String message, {
    bool isSuccess = false,
    bool isWarning = false,
  }) {
    Color bg = const Color(0xFFD32F2F);
    IconData icon = Icons.error_outline;

    if (isSuccess) {
      bg = const Color(0xFF2E7D32);
      icon = Icons.check_circle_outline;
    } else if (isWarning) {
      bg = const Color(0xFFEF6C00);
      icon = Icons.warning_amber_rounded;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Color(0xFF2E7D32),
                size: 44,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Đặt lại mật khẩu thành công!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1918),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Mật khẩu của bạn đã được cập nhật. Vui lòng đăng nhập bằng mật khẩu mới.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF78736D),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF945331),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Đăng nhập ngay',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A1918)),
          onPressed: () {
            if (_currentStep > 1) {
              setState(() => _currentStep--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Khôi phục mật khẩu',
          style: TextStyle(
            color: Color(0xFF1A1918),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepIndicator(),
              const SizedBox(height: 28),
              if (_currentStep == 1) _buildStep1UI(),
              if (_currentStep == 2) _buildStep2UI(),
              if (_currentStep == 3) _buildStep3UI(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _buildStepBadge(1, 'Tìm tài khoản'),
        _buildStepLine(1),
        _buildStepBadge(2, 'Nhập OTP'),
        _buildStepLine(2),
        _buildStepBadge(3, 'Đổi mật khẩu'),
      ],
    );
  }

  Widget _buildStepBadge(int step, String label) {
    bool isActive = _currentStep >= step;
    bool isCurrent = _currentStep == step;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF945331)
                  : const Color(0xFFE0DDD5),
              shape: BoxShape.circle,
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: const Color(0xFF945331).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: isActive && _currentStep > step
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : Text(
                      '$step',
                      style: TextStyle(
                        color: isActive
                            ? Colors.white
                            : const Color(0xFF78736D),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
              color: isCurrent
                  ? const Color(0xFF945331)
                  : const Color(0xFF78736D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int afterStep) {
    bool isCompleted = _currentStep > afterStep;
    return Container(
      width: 24,
      height: 2,
      margin: const EdgeInsets.only(bottom: 18),
      color: isCompleted ? const Color(0xFF945331) : const Color(0xFFE0DDD5),
    );
  }

  Widget _buildStep1UI() {
    return Form(
      key: _formKeyStep1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quên mật khẩu?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1918),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nhập Tên đăng nhập, Số điện thoại hoặc Email đã đăng ký để nhận mã xác thực OTP.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF78736D),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          _buildInputField(
            controller: _identifierController,
            icon: Icons.person_outline,
            label: 'Tên đăng nhập / Số điện thoại / Email',
            hintText: 'Nhập thông tin tài khoản...',
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Vui lòng nhập tên đăng nhập, số điện thoại hoặc email';
              }
              return null;
            },
          ),
          if (_requireEmail) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFB74D)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.info_outline, color: Color(0xFFE65100), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tài khoản của bạn chưa có email liên kết. Vui lòng nhập email bên dưới để nhận mã OTP và cập nhật vào tài khoản.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFFE65100),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _emailController,
              icon: Icons.email_outlined,
              label: 'Email nhận mã OTP',
              hintText: 'vidu@gmail.com',
              keyboardType: TextInputType.emailAddress,
              validator: validateEmail,
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSendOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF945331),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _requireEmail ? 'Gửi mã OTP đến Email' : 'Tiếp tục',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2UI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Xác thực mã OTP',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1918),
          ),
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            text: 'Mã xác thực gồm 6 chữ số đã được gửi đến email: ',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF78736D),
              height: 1.4,
            ),
            children: [
              TextSpan(
                text: _maskedEmail.isNotEmpty ? _maskedEmail : 'của bạn',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF945331),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) => _buildOtpDigitBox(index)),
        ),
        const SizedBox(height: 24),
        Center(
          child: _canResend
              ? TextButton.icon(
                  onPressed: _isLoading ? null : _handleSendOtp,
                  icon: const Icon(
                    Icons.refresh,
                    color: Color(0xFF945331),
                    size: 18,
                  ),
                  label: const Text(
                    'Gửi lại mã OTP',
                    style: TextStyle(
                      color: Color(0xFF945331),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                )
              : Text(
                  'Gửi lại mã sau $_countdownSeconds giây',
                  style: const TextStyle(
                    color: Color(0xFF78736D),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleVerifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF945331),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Xác nhận mã OTP',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpDigitBox(int index) {
    return SizedBox(
      width: 46,
      height: 54,
      child: TextFormField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A1918),
        ),
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0DDD5), width: 1.2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0DDD5), width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF945331), width: 2),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            if (index < 5) {
              _otpFocusNodes[index + 1].requestFocus();
            } else {
              _otpFocusNodes[index].unfocus();
              _handleVerifyOtp();
            }
          } else if (value.isEmpty && index > 0) {
            _otpFocusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }

  Widget _buildStep3UI() {
    return Form(
      key: _formKeyStep3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Đặt lại mật khẩu',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1918),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tạo mật khẩu mới cho tài khoản của bạn. Mật khẩu phải có ít nhất 6 ký tự.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF78736D),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          _buildInputField(
            controller: _newPasswordController,
            icon: Icons.lock_outline,
            label: 'Mật khẩu mới',
            hintText: 'Nhập mật khẩu mới...',
            isPassword: true,
            obscureText: _obscureNewPassword,
            onToggleVisibility: () =>
                setState(() => _obscureNewPassword = !_obscureNewPassword),
            validator: (val) => validatePassword(val, isLogin: false),
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _confirmPasswordController,
            icon: Icons.lock_reset_outlined,
            label: 'Xác nhận mật khẩu mới',
            hintText: 'Nhập lại mật khẩu mới...',
            isPassword: true,
            obscureText: _obscureConfirmPassword,
            onToggleVisibility: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword,
            ),
            validator: (val) {
              if (val == null || val.isEmpty) {
                return 'Vui lòng xác nhận mật khẩu';
              }
              if (val != _newPasswordController.text) {
                return 'Mật khẩu xác nhận không khớp';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleResetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF945331),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Xác nhận đổi mật khẩu',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1918),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          style: const TextStyle(fontSize: 15, color: Color(0xFF1A1918)),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Color(0xFFA8A29E), fontSize: 14),
            prefixIcon: Icon(icon, color: const Color(0xFF945331), size: 20),
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
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFE0DDD5),
                width: 1.2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFE0DDD5),
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF945331),
                width: 1.8,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }
}

