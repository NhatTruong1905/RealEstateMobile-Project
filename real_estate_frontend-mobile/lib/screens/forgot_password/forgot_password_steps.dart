part of '../ForgotPassword.dart';

extension ForgotPasswordSteps on _ForgotPasswordScreenState {
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
}
