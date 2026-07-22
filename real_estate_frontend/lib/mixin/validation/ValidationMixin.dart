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
}