// ignore_for_file: invalid_use_of_protected_member

part of '../ForgotPassword.dart';

extension ForgotPasswordView on _ForgotPasswordScreenState {
  Widget _buildPage(BuildContext context) {
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
}
