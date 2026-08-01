import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:real_estate_frontend/dto/ChatMessageDTO.dart';

enum ChatConnectionState {
  disconnected,
  connecting,
  connected,
}

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  WebSocket? _webSocket;
  ChatConnectionState _connectionState = ChatConnectionState.disconnected;
  final StreamController<ChatMessageDTO> _messageStreamController =
      StreamController<ChatMessageDTO>.broadcast();
  final StreamController<ChatConnectionState> _connectionStreamController =
      StreamController<ChatConnectionState>.broadcast();

  String _baseUrl = "http://10.0.2.2:8080/api";
  String _wsUrl = "ws://10.0.2.2:8080/ws";

  int? _currentUserId;
  int? _currentPropertyId;
  String? _jwtToken;

  int? get currentUserId => _currentUserId;
  int? get currentPropertyId => _currentPropertyId;

  static int? activeChatPropertyId;
  static int? activeChatReceiverId;

  /// Kiểm tra xem người dùng có đang mở màn hình Chat với đối phương & BĐS này hay không
  static bool isChatActive(int? propertyId, int? senderId) {
    if (activeChatPropertyId == null || activeChatReceiverId == null) return false;
    if (propertyId == null || senderId == null) return false;
    return activeChatPropertyId == propertyId && activeChatReceiverId == senderId;
  }

  Stream<ChatMessageDTO> get messageStream => _messageStreamController.stream;
  Stream<ChatConnectionState> get connectionStream =>
      _connectionStreamController.stream;
  ChatConnectionState get connectionState => _connectionState;

  /// Đặt cấu hình Host (ví dụ đổi IP nếu không dùng Emulator 10.0.2.2)
  void configureHost(String host, {int port = 8080}) {
    _baseUrl = "http://$host:$port/api";
    _wsUrl = "ws://$host:$port/ws";
  }

  /// Khởi tạo kết nối WebSocket toàn cục cho người dùng hiện tại
  Future<void> initGlobalConnection() async {
    final prefs = await SharedPreferences.getInstance();
    final profileStr = prefs.getString('user_profile');
    int? userId;
    if (profileStr != null) {
      try {
        final userMap = jsonDecode(profileStr);
        userId = (userMap['id'] as num?)?.toInt();
      } catch (_) {}
    }
    await connect(currentUserId: userId);
  }

  /// Ngắt kết nối WebSocket và dọn dẹp phiên khi Đăng xuất
  Future<void> disconnect() async {
    _currentUserId = null;
    _currentPropertyId = null;
    _jwtToken = null;
    hasUnreadNotification.value = false;
    _processedMessageKeys.clear();

    if (_webSocket != null) {
      try {
        await _webSocket!.close();
      } catch (e) {
        debugPrint('Lỗi ngắt kết nối WebSocket: $e');
      }
      _webSocket = null;
    }
    _updateState(ChatConnectionState.disconnected);
  }

  /// Khởi tạo kết nối WebSocket với thông tin người dùng và bất động sản (nếu có)
  Future<void> connect({
    int? propertyId,
    int? currentUserId,
  }) async {
    if (propertyId != null) {
      _currentPropertyId = propertyId;
    }

    // Nếu đổi tài khoản người dùng khác -> Bắt buộc ngắt kết nối cũ để đăng ký lại topic mới
    if (currentUserId != null && _currentUserId != null && currentUserId != _currentUserId) {
      debugPrint('Đổi tài khoản từ $_currentUserId sang $currentUserId. Thực hiện ngắt phiên cũ...');
      await disconnect();
    }

    // Đọc token và user_profile từ SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    _jwtToken = prefs.getString('jwt_token');

    if (currentUserId != null) {
      _currentUserId = currentUserId;
    } else {
      final profileStr = prefs.getString('user_profile');
      if (profileStr != null) {
        try {
          final userMap = jsonDecode(profileStr);
          _currentUserId = (userMap['id'] as num?)?.toInt();
        } catch (_) {}
      }
    }

    if (_webSocket != null && _connectionState == ChatConnectionState.connected) {
      // Đã kết nối đúng tài khoản hiện tại, gửi khung SUBSCRIBE thêm cho propertyId (nếu có)
      _subscribeStompTopic(propertyId);
      return;
    }

    _updateState(ChatConnectionState.connecting);

    final wsCandidates = [
      _wsUrl,
      _wsUrl.replaceAll('/ws', '/ws-chat'),
      _wsUrl.replaceAll('/ws', '/chat'),
      "ws://10.0.2.2:8080/ws-chat",
      "ws://10.0.2.2:8080/chat",
      "ws://localhost:8080/ws",
    ];

    bool success = false;
    for (final url in wsCandidates) {
      try {
        debugPrint('Thử kết nối WebSocket tới: $url');
        _webSocket = await WebSocket.connect(url).timeout(
          const Duration(seconds: 4),
        );
        debugPrint('Đã mở WebSocket socket tới: $url');
        success = true;
        _wsUrl = url;
        break;
      } catch (e) {
        debugPrint('Không thể kết nối WS tại $url: $e');
      }
    }

    if (!success || _webSocket == null) {
      debugPrint('WebSocket kết nối thất bại. Chuyển sang chế độ REST API Fallback.');
      _updateState(ChatConnectionState.disconnected);
      return;
    }

    _updateState(ChatConnectionState.connected);

    // Lắng nghe dữ liệu nhận về từ WebSocket
    _webSocket!.listen(
      (data) {
        _handleIncomingData(data.toString());
      },
      onError: (err) {
        debugPrint('Lỗi WebSocket: $err');
        _updateState(ChatConnectionState.disconnected);
      },
      onDone: () {
        debugPrint('WebSocket đã ngắt kết nối');
        _updateState(ChatConnectionState.disconnected);
      },
    );

    // Gửi lệnh CONNECT của giao thức STOMP
    _sendStompConnect();
    
    // Subscribe dự phòng (nếu server phản hồi nhanh)
    _subscribeStompTopic(propertyId);
  }

  /// Gửi STOMP CONNECT frame
  void _sendStompConnect() {
    if (_webSocket == null) return;
    final connectFrame = StringBuffer();
    connectFrame.write("CONNECT\n");
    connectFrame.write("accept-version:1.1,1.2\n");
    connectFrame.write("heart-beat:10000,10000\n");
    if (_jwtToken != null && _jwtToken!.isNotEmpty) {
      connectFrame.write("Authorization:Bearer $_jwtToken\n");
    }
    connectFrame.write("\n");
    connectFrame.write("\x00");

    try {
      _webSocket!.add(connectFrame.toString());
    } catch (e) {
      debugPrint('Lỗi gửi STOMP CONNECT: $e');
    }
  }

  /// Subscribe các STOMP Topic cho propertyId và user
  void _subscribeStompTopic(int? propertyId) {
    if (_webSocket == null) return;
    
    final topics = <String>[];
    if (propertyId != null && propertyId > 0) {
      topics.add("/topic/chat/$propertyId");
    }

    if (_currentUserId != null) {
      topics.add("/topic/user/$_currentUserId");
    }

    for (int i = 0; i < topics.length; i++) {
      final subFrame = StringBuffer();
      subFrame.write("SUBSCRIBE\n");
      subFrame.write("id:sub-$i\n");
      subFrame.write("destination:${topics[i]}\n");
      subFrame.write("\n");
      subFrame.write("\x00");

      try {
        _webSocket!.add(subFrame.toString());
        debugPrint('Đã SUBSCRIBE topic thành công: ${topics[i]}');
      } catch (e) {
        debugPrint('Lỗi gửi SUBSCRIBE topic ${topics[i]}: $e');
      }
    }
  }

  /// Xử lý tin nhắn đến từ WebSocket (STOMP message hoặc JSON raw)
  void _handleIncomingData(String rawData) {
    debugPrint('WebSocket Nhận: $rawData');

    final frames = rawData.split('\x00');
    for (var rawFrame in frames) {
      final frame = rawFrame.trim();
      if (frame.isEmpty) continue;

      if (frame.startsWith('CONNECTED')) {
        debugPrint('Đã nhận phản hồi STOMP CONNECTED! Subscribe topics ngay...');
        _subscribeStompTopic(_currentPropertyId);
      } else if (frame.startsWith('MESSAGE')) {
        var bodyIndex = frame.indexOf('\n\n');
        if (bodyIndex != -1) {
          var body = frame.substring(bodyIndex + 2).trim();
          _parseAndEmitMessage(body);
        } else {
          var rnrnIndex = frame.indexOf('\r\n\r\n');
          if (rnrnIndex != -1) {
            var body = frame.substring(rnrnIndex + 4).trim();
            _parseAndEmitMessage(body);
          }
        }
      } else if (frame.startsWith('{')) {
        _parseAndEmitMessage(frame);
      }
    }
  }

  static final ValueNotifier<bool> hasUnreadNotification = ValueNotifier<bool>(false);
  final Set<String> _processedMessageKeys = {};

  void _parseAndEmitMessage(String jsonStr) {
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      final msg = ChatMessageDTO.fromJson(map);

      final senderId = msg.getSenderId;
      final receiverId = msg.getReceiverId;

      // KIỂM TRA BẢO MẬT & BẢO MẬT TỰ ĐỘNG:
      // Bỏ qua tất cả tin nhắn KHÔNG thuộc về user hiện tại (không là sender và cũng không là receiver)
      if (_currentUserId != null && _currentUserId! > 0) {
        final isForMe = (senderId == _currentUserId || receiverId == _currentUserId);
        if (!isForMe) {
          debugPrint('Bỏ qua tin nhắn riêng tư không thuộc về User hiện tại (MyID: $_currentUserId, Sender: $senderId, Receiver: $receiverId)');
          return;
        }
      }

      // Chỉ lọc trùng lặp nếu tin nhắn có id duy nhất từ server
      if (msg.id != null) {
        final msgKey = "id_${msg.id}";
        if (_processedMessageKeys.contains(msgKey)) {
          debugPrint('Bỏ qua tin nhắn trùng lặp theo ID từ WebSocket: $msgKey');
          return;
        }
        _processedMessageKeys.add(msgKey);
        if (_processedMessageKeys.length > 300) {
          _processedMessageKeys.clear();
        }
      }

      _messageStreamController.add(msg);

      if (msg.text.isNotEmpty && !msg.text.startsWith('__SYS_')) {
        hasUnreadNotification.value = true;
        _appendMessageToLocalSession(msg);
      }
    } catch (e) {
      debugPrint('Lỗi parse ChatMessageDTO từ WS: $e');
    }
  }

  /// Tự động thêm tin nhắn đến vào Local Session của thiết bị
  Future<void> _appendMessageToLocalSession(ChatMessageDTO msg) async {
    final propId = msg.propertyId;
    final senderId = msg.getSenderId;
    if (propId == null || senderId == null) return;

    try {
      final key = _getSessionKey(propId, senderId);
      final prefs = await SharedPreferences.getInstance();
      final existingStr = prefs.getString(key);

      List<ChatMessageDTO> messages = [];
      int startTime = DateTime.now().millisecondsSinceEpoch;
      String? existingPartnerName;

      if (existingStr != null) {
        try {
          final existingMap = jsonDecode(existingStr);
          if (existingMap['startTime'] != null) {
            startTime = existingMap['startTime'] as int;
          }
          if (existingMap['partnerName'] != null) {
            existingPartnerName = existingMap['partnerName'] as String;
          }
          final rawMsgs = existingMap['messages'] as List?;
          if (rawMsgs != null) {
            messages = rawMsgs.map((m) => ChatMessageDTO.fromJson(m)).toList();
          }
        } catch (_) {}
      }

      bool exists = messages.any((m) {
        if (msg.id != null && m.id != null) {
          return m.id == msg.id;
        }
        if (_currentUserId != null && msg.getSenderId == _currentUserId) {
          return m.text == msg.text &&
              m.timestamp == msg.timestamp &&
              m.getSenderId == msg.getSenderId;
        }
        return false;
      });

      if (!exists) {
        messages.add(msg);
        final partnerName = (msg.senderName != null && msg.senderName!.isNotEmpty)
            ? msg.senderName
            : existingPartnerName;

        final sessionData = {
          'startTime': startTime,
          'propertyId': propId,
          'receiverId': senderId,
          'partnerId': senderId,
          if (partnerName != null) 'partnerName': partnerName,
          'messages': messages.map((m) => m.toJson()).toList(),
        };
        await prefs.setString(key, jsonEncode(sessionData));
        debugPrint('Đã tự động lưu tin nhắn đến vào local session $key');
      }
    } catch (e) {
      debugPrint('Lỗi _appendMessageToLocalSession: $e');
    }
  }

  /// Gửi tin nhắn Realtime qua WebSocket STOMP (KHÔNG lưu DB từng tin)
  Future<bool> sendMessage(ChatMessageDTO message) async {
    final jsonMap = message.toJson();
    final jsonStr = jsonEncode(jsonMap);

    if (_webSocket != null && _connectionState == ChatConnectionState.connected) {
      try {
        final sendFrame = StringBuffer();
        sendFrame.write("SEND\n");
        sendFrame.write("destination:/app/chat\n");
        sendFrame.write("content-type:application/json\n");
        sendFrame.write("\n");
        sendFrame.write(jsonStr);
        sendFrame.write("\x00");

        _webSocket!.add(sendFrame.toString());
        debugPrint('Đã chuyển tiếp tin nhắn qua WebSocket STOMP: $jsonStr');
        return true;
      } catch (e) {
        debugPrint('Lỗi gửi WebSocket STOMP: $e');
      }
    }
    return false;
  }

  /// Giải mã đoạn chat tổng hợp từ DB thành các tin nhắn riêng lẻ
  List<ChatMessageDTO> parseConsolidatedMessages({
    required String fullMessage,
    required int propertyId,
    required int defaultSenderId,
    required int defaultReceiverId,
  }) {
    final List<ChatMessageDTO> parsed = [];
    final lines = fullMessage.split('\n');
    final RegExp regex = RegExp(r'^\[(.*?)\]\s*(Người dùng|Chủ BĐS\/Đối tác|Khách hàng.*?):\s*(.*)$');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty ||
          trimmed.startsWith('===') ||
          trimmed.startsWith('--->') ||
          trimmed.contains('ĐÃ XÁC NHẬN CHẤP NHẬN') ||
          trimmed.contains('TỰ ĐỘNG LƯU SAU 24 GIỜ')) {
        continue;
      }

      final match = regex.firstMatch(trimmed);
      if (match != null) {
        final timeStr = match.group(1);
        final tag = match.group(2);
        final text = match.group(3);

        final int msgSenderId = (tag != null && tag.contains('Người dùng')) ? defaultSenderId : defaultReceiverId;
        final int msgReceiverId = (msgSenderId == defaultSenderId) ? defaultReceiverId : defaultSenderId;

        parsed.add(ChatMessageDTO(
          propertyId: propertyId,
          senderId: msgSenderId,
          receiverId: msgReceiverId,
          message: text,
          timestamp: timeStr,
        ));
      } else if (!trimmed.startsWith('[')) {
        parsed.add(ChatMessageDTO(
          propertyId: propertyId,
          senderId: defaultSenderId,
          receiverId: defaultReceiverId,
          message: trimmed,
          timestamp: DateFormat('HH:mm').format(DateTime.now()),
        ));
      }
    }
    return parsed;
  }

  /// Tải lịch sử tin nhắn từ Backend API
  Future<List<ChatMessageDTO>> fetchMessageHistory({
    required int propertyId,
    int? receiverId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final urlsToTry = [
      "$_baseUrl/chat/history/$propertyId",
      if (receiverId != null) "$_baseUrl/chat/history/$propertyId/$receiverId",
      "$_baseUrl/chat/$propertyId",
      "$_baseUrl/secure/chat/$propertyId",
    ];

    for (final url in urlsToTry) {
      try {
        final res = await http.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        );

        if (res.statusCode == 200) {
          final decoded = utf8.decode(res.bodyBytes);
          final json = jsonDecode(decoded);
          final dynamic data = json['data'] ?? json;
          if (data is List) {
            final List<ChatMessageDTO> historyList = [];
            for (var item in data) {
              if (item is Map<String, dynamic>) {
                final rawMsg = (item['message'] ?? item['content'] ?? '').toString();
                final propId = (item['propertyId'] ?? (item['property'] is Map ? item['property']['id'] : null) ?? propertyId) as int;
                final sId = (item['senderId'] ?? (item['sender'] is Map ? item['sender']['id'] : null) ?? 0) as int;
                final rId = (item['receiverId'] ?? (item['receiver'] is Map ? item['receiver']['id'] : null) ?? receiverId ?? 0) as int;

                if (rawMsg.contains('=== ĐOẠN CHAT') || rawMsg.contains('--->')) {
                  final parsedMsgs = parseConsolidatedMessages(
                    fullMessage: rawMsg,
                    propertyId: propId,
                    defaultSenderId: sId,
                    defaultReceiverId: rId,
                  );
                  historyList.addAll(parsedMsgs);
                } else {
                  historyList.add(ChatMessageDTO.fromJson(item));
                }
              }
            }
            return historyList;
          }
        }
      } catch (e) {
        debugPrint('Lỗi fetchMessageHistory tại $url: $e');
      }
    }

    return [];
  }

  // =========================================================================
  // BỘ BỘ NHỚ CỤC BỘ (LOCAL STORAGE 24h) & TỰ ĐỘNG GỘP LƯU DB INTERACTION
  // =========================================================================

  String _getSessionKey(int propertyId, int? receiverId) {
    return 'chat_session_${propertyId}_${receiverId ?? 0}';
  }

  /// Lưu danh sách tin nhắn vào SharedPreferences (lưu tạm trong vòng 24h)
  Future<void> saveLocalChatSession(
    int propertyId,
    int? receiverId,
    List<ChatMessageDTO> messages, {
    String? partnerName,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getSessionKey(propertyId, receiverId);
      final existingStr = prefs.getString(key);

      int startTime = DateTime.now().millisecondsSinceEpoch;
      String? existingPartnerName;

      if (existingStr != null) {
        try {
          final existingMap = jsonDecode(existingStr);
          if (existingMap['startTime'] != null) {
            startTime = existingMap['startTime'] as int;
          }
          if (existingMap['partnerName'] != null) {
            existingPartnerName = existingMap['partnerName'] as String;
          }
        } catch (_) {}
      }

      final finalPartnerName = (partnerName != null && partnerName.isNotEmpty)
          ? partnerName
          : existingPartnerName;

      final sessionData = {
        'startTime': startTime,
        'propertyId': propertyId,
        'receiverId': receiverId,
        'partnerId': receiverId,
        if (finalPartnerName != null) 'partnerName': finalPartnerName,
        'messages': messages.map((m) => m.toJson()).toList(),
      };

      await prefs.setString(key, jsonEncode(sessionData));
      debugPrint('Đã lưu phiên chat tạm thời vào Local Storage: $key (${messages.length} tin)');
    } catch (e) {
      debugPrint('Lỗi saveLocalChatSession: $e');
    }
  }

  /// Nạp danh sách tin nhắn từ SharedPreferences (nếu còn trong vòng 24h)
  Future<List<ChatMessageDTO>> loadLocalChatSession(
    int propertyId,
    int? receiverId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getSessionKey(propertyId, receiverId);
      final str = prefs.getString(key);
      if (str == null || str.isEmpty) return [];

      final map = jsonDecode(str) as Map<String, dynamic>;
      final startTime = map['startTime'] as int? ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Hết hạn 24h (86,400,000 ms) -> Tự động đồng bộ lên DB và xóa local session
      if (now - startTime > 86400000) {
        debugPrint('Phiên chat local $key đã hết hạn 24h. Tiến hành tự động lưu DB...');
        final rawMsgs = map['messages'] as List?;
        if (rawMsgs != null && rawMsgs.isNotEmpty) {
          final msgs = rawMsgs.map((m) => ChatMessageDTO.fromJson(m)).toList();
          final senderId = _currentUserId ?? msgs.first.getSenderId ?? 0;
          await consolidateAndSaveInteraction(
            propertyId: propertyId,
            senderId: senderId,
            receiverId: receiverId ?? 0,
            messages: msgs,
            isAppointmentAccepted: false,
          );
        }
        await prefs.remove(key);
        return [];
      }

      final rawMsgs = map['messages'] as List?;
      if (rawMsgs != null) {
        return rawMsgs.map((m) => ChatMessageDTO.fromJson(m)).toList();
      }
    } catch (e) {
      debugPrint('Lỗi loadLocalChatSession: $e');
    }
    return [];
  }

  /// Xóa bộ nhớ chat local khi người dùng nhấn Chấp nhận hoặc đã lưu xong
  Future<void> clearLocalChatSession(int propertyId, int? receiverId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getSessionKey(propertyId, receiverId);
      await prefs.remove(key);
      debugPrint('Đã làm sạch bộ nhớ tạm local chat $key');
    } catch (e) {
      debugPrint('Lỗi clearLocalChatSession: $e');
    }
  }

  /// Gửi tín hiệu Chấp nhận đi xem BĐS qua WebSocket Realtime
  Future<bool> sendAcceptanceSignal({
    required int propertyId,
    required int senderId,
    required int receiverId,
  }) async {
    final acceptMsg = ChatMessageDTO(
      id: DateTime.now().millisecondsSinceEpoch % 1000000000,
      propertyId: propertyId,
      senderId: senderId,
      receiverId: receiverId,
      message: "__SYS_ACCEPT_APPOINTMENT__",
      timestamp: DateFormat('HH:mm').format(DateTime.now()),
    );
    return await sendMessage(acceptMsg);
  }

  /// Gửi tín hiệu Hủy chấp nhận đi xem BĐS qua WebSocket Realtime
  Future<bool> sendCancelAcceptanceSignal({
    required int propertyId,
    required int senderId,
    required int receiverId,
  }) async {
    final cancelMsg = ChatMessageDTO(
      id: DateTime.now().millisecondsSinceEpoch % 1000000000,
      propertyId: propertyId,
      senderId: senderId,
      receiverId: receiverId,
      message: "__SYS_CANCEL_APPOINTMENT__",
      timestamp: DateFormat('HH:mm').format(DateTime.now()),
    );
    return await sendMessage(cancelMsg);
  }

  /// Gửi tín hiệu Hoàn tất lượt xem nhà qua WebSocket Realtime (Seller kích hoạt)
  Future<bool> sendCompleteViewingSignal({
    required int propertyId,
    required int senderId,
    required int receiverId,
  }) async {
    final completeMsg = ChatMessageDTO(
      id: DateTime.now().millisecondsSinceEpoch % 1000000000,
      propertyId: propertyId,
      senderId: senderId,
      receiverId: receiverId,
      message: "__SYS_COMPLETE_VIEWING__",
      timestamp: DateFormat('HH:mm').format(DateTime.now()),
    );
    return await sendMessage(completeMsg);
  }

  String _getAcceptanceKey(int propertyId, int? receiverId) {
    if (receiverId == null || receiverId == 0) return '';
    return 'accept_state_${propertyId}_$receiverId';
  }

  /// Lấy tất cả các khách hàng từ phiên chat local trên máy
  Future<List<Map<String, dynamic>>> getAllChatCustomers() async {
    final List<Map<String, dynamic>> chatCustomers = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('chat_session_')).toList();

      for (final key in keys) {
        final str = prefs.getString(key);
        if (str == null || str.isEmpty) continue;
        try {
          final map = jsonDecode(str) as Map<String, dynamic>;
          final propertyId = map['propertyId'] as int?;
          final receiverId = map['receiverId'] as int?;
          final partnerId = map['partnerId'] as int? ?? receiverId;
          final storedPartnerName = map['partnerName'] as String?;

          final rawMsgs = map['messages'] as List?;
          if (rawMsgs == null || rawMsgs.isEmpty) continue;

          final msgs = rawMsgs.map((m) => ChatMessageDTO.fromJson(m)).toList();

          final normalMsgs = msgs.where((m) =>
            !m.text.startsWith('__SYS_')
          ).toList();

          if (normalMsgs.isEmpty) continue;
          final displayMsg = normalMsgs.last;

          // Tìm tin nhắn từ phía đối phương để lấy tên nếu chưa có
          final partnerMsg = msgs.firstWhere(
            (m) => m.getSenderId != null && m.getSenderId != _currentUserId,
            orElse: () => displayMsg,
          );

          final customerId = (partnerId != null && partnerId != _currentUserId)
              ? partnerId
              : (partnerMsg.getSenderId != _currentUserId ? partnerMsg.getSenderId : receiverId);

          if (customerId == null || customerId == _currentUserId) continue;

          final customerName = (storedPartnerName != null && storedPartnerName.isNotEmpty)
              ? storedPartnerName
              : ((partnerMsg.senderName != null && partnerMsg.senderName!.isNotEmpty)
                  ? partnerMsg.senderName!
                  : 'Khách hàng #$customerId');

          chatCustomers.add({
            'senderId': customerId,
            'phone': 'Chưa cập nhật SĐT',
            'name': customerName,
            'latestPropertyId': propertyId,
            'latestPropertyTitle': 'Bất động sản quan tâm',
            'latestMessage': displayMsg.text,
            'latestTime': displayMsg.timestamp ?? 'Mới đây',
            'messageCount': normalMsgs.length,
          });
        } catch (e) {
          debugPrint('Lỗi parse chat session $key: $e');
        }
      }
    } catch (e) {
      debugPrint('Lỗi getAllChatCustomers: $e');
    }
    return chatCustomers;
  }

  /// Đánh dấu đã xem nhà xong (mở lại nút chấp nhận cho lượt xem mới)
  Future<void> markViewingCompleted(int propertyId, int? receiverId) async {
    try {
      final key = _getAcceptanceKey(propertyId, receiverId);
      if (key.isEmpty) return;
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'myAccept': false,
        'partnerAccept': false,
        'fullyAccepted': false,
        'isCompleted': true,
        'acceptTimestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(key, jsonEncode(data));
      debugPrint('Đã đánh dấu hoàn tất lượt xem nhà ($key)');
    } catch (e) {
      debugPrint('Lỗi markViewingCompleted: $e');
    }
  }

  /// Lưu trạng thái Chấp nhận đi xem BĐS vào SharedPreferences (kèm timestamp)
  Future<void> saveLocalAcceptance(
    int propertyId,
    int? receiverId, {
    bool? myAccept,
    bool? partnerAccept,
    bool? fullyAccepted,
  }) async {
    try {
      final key = _getAcceptanceKey(propertyId, receiverId);
      if (key.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final existingStr = prefs.getString(key);

      bool currentMy = false;
      bool currentPartner = false;
      bool currentFully = false;
      int acceptTimestamp = DateTime.now().millisecondsSinceEpoch;

      if (existingStr != null) {
        try {
          final map = jsonDecode(existingStr);
          currentMy = map['myAccept'] as bool? ?? false;
          currentPartner = map['partnerAccept'] as bool? ?? false;
          currentFully = map['fullyAccepted'] as bool? ?? false;
          if (map['acceptTimestamp'] != null) {
            acceptTimestamp = map['acceptTimestamp'] as int;
          }
        } catch (_) {}
      }

      if (myAccept != null) currentMy = myAccept;
      if (partnerAccept != null) currentPartner = partnerAccept;
      if (fullyAccepted != null) currentFully = fullyAccepted;

      final data = {
        'myAccept': currentMy,
        'partnerAccept': currentPartner,
        'fullyAccepted': currentFully || (currentMy && currentPartner),
        'isCompleted': false,
        'acceptTimestamp': acceptTimestamp,
      };

      await prefs.setString(key, jsonEncode(data));
      debugPrint('Đã lưu trạng thái chấp nhận 2 bên ($key): $data');
    } catch (e) {
      debugPrint('Lỗi saveLocalAcceptance: $e');
    }
  }

  /// Nạp trạng thái Chấp nhận 2 chiều từ SharedPreferences
  Future<Map<String, dynamic>> loadLocalAcceptance(
    int propertyId,
    int? receiverId,
  ) async {
    try {
      final key = _getAcceptanceKey(propertyId, receiverId);
      if (key.isEmpty) {
        return {
          'myAccept': false,
          'partnerAccept': false,
          'fullyAccepted': false,
          'isCompleted': false,
          'acceptTimestamp': DateTime.now().millisecondsSinceEpoch,
        };
      }

      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(key);
      if (str != null) {
        final map = jsonDecode(str) as Map<String, dynamic>;
        final isCompleted = map['isCompleted'] as bool? ?? false;
        if (isCompleted) {
          return {
            'myAccept': false,
            'partnerAccept': false,
            'fullyAccepted': false,
            'isCompleted': true,
            'acceptTimestamp': DateTime.now().millisecondsSinceEpoch,
          };
        }

        final myAccept = map['myAccept'] as bool? ?? false;
        final partnerAccept = map['partnerAccept'] as bool? ?? false;
        final fullyAccepted = map['fullyAccepted'] as bool? ?? (myAccept && partnerAccept);
        final acceptTimestamp = map['acceptTimestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch;
        return {
          'myAccept': myAccept,
          'partnerAccept': partnerAccept,
          'fullyAccepted': fullyAccepted,
          'isCompleted': false,
          'acceptTimestamp': acceptTimestamp,
        };
      }
    } catch (e) {
      debugPrint('Lỗi loadLocalAcceptance: $e');
    }
    return {
      'myAccept': false,
      'partnerAccept': false,
      'fullyAccepted': false,
      'isCompleted': false,
      'acceptTimestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Xóa trạng thái chấp nhận (khi hết hạn 15 phút hoặc đã hoàn tất)
  Future<void> clearLocalAcceptance(int propertyId, int? receiverId) async {
    try {
      final key = _getAcceptanceKey(propertyId, receiverId);
      if (key.isEmpty) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      debugPrint('Đã xóa trạng thái chấp nhận $key');
    } catch (e) {
      debugPrint('Lỗi clearLocalAcceptance: $e');
    }
  }

  /// Gộp toàn bộ nội dung đoạn chat thành 1 bản ghi Interaction và lưu vào DB
  Future<bool> consolidateAndSaveInteraction({
    required int propertyId,
    required int senderId,
    required int receiverId,
    required List<ChatMessageDTO> messages,
    bool isAppointmentAccepted = true,
  }) async {
    if (messages.isEmpty) return false;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    final sb = StringBuffer();
    for (final m in messages) {
      if (m.text == '__SYS_ACCEPT_APPOINTMENT__' ||
          m.text == '__SYS_CANCEL_APPOINTMENT__' ||
          m.text == '__SYS_COMPLETE_VIEWING__') {
        continue;
      }
      final timeStr = m.timestamp ?? '';
      final senderTag = (m.getSenderId == senderId) ? "Người dùng" : "Chủ BĐS/Đối tác";
      if (sb.isNotEmpty) sb.writeln();
      sb.write("[$timeStr] $senderTag: ${m.text}");
    }

    final interactionBody = {
      'propertyId': propertyId,
      'senderId': senderId,
      'receiverId': receiverId,
      'interactionTypeCode': 'MESSAGE',
      'code': 'MESSAGE',
      'interactionTypeId': 2,
      'message': sb.toString(),
    };

    final url = "$_baseUrl/secure/interactions";
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(interactionBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Đã lưu thành công bản ghi Interaction tổng hợp vào DB!');
        await clearLocalChatSession(propertyId, receiverId);
        final key = _getAcceptanceKey(propertyId, receiverId);
        await prefs.remove(key);
        return true;
      }
    } catch (e) {
      debugPrint('Lỗi consolidateAndSaveInteraction: $e');
    }
    return false;
  }

  void _updateState(ChatConnectionState state) {
    _connectionState = state;
    _connectionStreamController.add(state);
  }
}
