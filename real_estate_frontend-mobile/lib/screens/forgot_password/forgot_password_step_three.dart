// ignore_for_file: invalid_use_of_protected_member

part of '../ForgotPassword.dart';

extension ForgotPasswordStepThree on _ForgotPasswordScreenState {
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
