mixin ValidationMixin {
  String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập họ và tên';
    }
    return null;
  }

  String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập tên đăng nhập / email';
    }
    return null;
  }

  String? validatePassword(String? value, {required bool isLogin}) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (!isLogin && value.length < 6) {
      return 'Mật khẩu phải từ 6 ký tự';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Email không đúng định dạng';
    }
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập số điện thoại';
    }
    if (!RegExp(r'^0\d{9}$').hasMatch(value)) {
      return 'Số điện thoại không hợp lệ (Bắt đầu bằng 0 và đủ 10 số)';
    }
    return null;
  }
}
