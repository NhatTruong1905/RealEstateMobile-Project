class ChatMessageDTO {
  final int? id;
  final int? senderId;
  final int? receiverId;
  final int? propertyId;
  final String? message;
  final String? timestamp;
  final String? senderName;

  ChatMessageDTO({
    this.id,
    this.senderId,
    this.receiverId,
    this.propertyId,
    this.message,
    this.timestamp,
    this.senderName,
  });

  String get text => message ?? '';

  int? get getSenderId => senderId;

  int? get getReceiverId => receiverId;

  factory ChatMessageDTO.fromJson(Map<String, dynamic> json) {
    return ChatMessageDTO(
      id: (json['id'] as num?)?.toInt(),
      senderId:
          (json['senderId'] as num?)?.toInt() ??
          (json['sender'] is num
              ? (json['sender'] as num).toInt()
              : (json['sender'] is Map
                    ? (json['sender']['id'] as num?)?.toInt()
                    : null)),
      receiverId:
          (json['receiverId'] as num?)?.toInt() ??
          (json['receiver'] is num
              ? (json['receiver'] as num).toInt()
              : (json['receiver'] is Map
                    ? (json['receiver']['id'] as num?)?.toInt()
                    : null)),
      propertyId: (json['propertyId'] as num?)?.toInt(),
      message: (json['message'] as String?) ?? (json['content'] as String?),
      timestamp: json['timestamp'] as String?,
      senderName:
          (json['senderName'] as String?) ??
          (json['sender'] is Map
              ? (json['sender']['fullname'] as String? ??
                    json['sender']['username'] as String?)
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'propertyId': propertyId,
      'message': message ?? '',
      if (timestamp != null) 'timestamp': timestamp,
      if (senderName != null) 'senderName': senderName,
    };
  }
}
