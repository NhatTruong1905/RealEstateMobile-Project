class UserDTO {
  final int? id;
  final String? username;
  final String? fullname;
  final String? email;
  final String? phone;
  final String? avatar;

  UserDTO({
    this.id,
    this.username,
    this.fullname,
    this.email,
    this.phone,
    this.avatar,
  });

  factory UserDTO.fromJson(Map<String, dynamic> json) {
    return UserDTO(
      id: json['id'],
      username: json['username'],
      fullname: json['fullname'],
      email: json['email'],
      phone: json['phone'],
      avatar: json['avatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'fullname': fullname,
      'email': email,
      'phone': phone,
      'avatar': avatar,
    };
  }
}



