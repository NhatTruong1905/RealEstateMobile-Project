import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:real_estate_frontend/mixin/api/ApiLoginMixin.dart';
import 'package:real_estate_frontend/mixin/validation/ValidationMixin.dart';

part 'forgot_password/forgot_password_view.dart';
part 'forgot_password/forgot_password_steps.dart';
part 'forgot_password/forgot_password_step_one.dart';
part 'forgot_password/forgot_password_step_two.dart';
part 'forgot_password/forgot_password_step_three.dart';

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
  Widget build(BuildContext context) => _buildPage(context);
}
