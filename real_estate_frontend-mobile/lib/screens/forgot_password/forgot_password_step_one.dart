part of '../ForgotPassword.dart';

extension ForgotPasswordStepOne on _ForgotPasswordScreenState {
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
}
