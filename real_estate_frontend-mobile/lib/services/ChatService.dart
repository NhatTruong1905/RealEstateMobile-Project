import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:real_estate_frontend/dto/ChatMessageDTO.dart';
import 'package:real_estate_frontend/config/AppConfig.dart';

part 'chat/chat_local_sessions.dart';
part 'chat/chat_acceptance_store.dart';
part 'chat/chat_interaction_sync.dart';

enum ChatConnectionState { disconnected, connecting, connected }

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

  String _baseUrl = AppConfig.springBootBaseUrl;
  String _wsUrl = AppConfig.springBootWsUrl;

  int? _currentUserId;
  int? _currentPropertyId;
  String? _jwtToken;

  int? get currentUserId => _currentUserId;

  int? get currentPropertyId => _currentPropertyId;

  static int? activeChatPropertyId;
  static int? activeChatReceiverId;

  static bool isChatActive(int? propertyId, int? senderId) {
    if (activeChatPropertyId == null || activeChatReceiverId == null)
      return false;
    if (propertyId == null || senderId == null) return false;
    return activeChatPropertyId == propertyId &&
        activeChatReceiverId == senderId;
  }

  Stream<ChatMessageDTO> get messageStream => _messageStreamController.stream;
  Stream<ChatConnectionState> get connectionStream =>
      _connectionStreamController.stream;

  ChatConnectionState get connectionState => _connectionState;

  String get baseUrl => _baseUrl;

  String get wsUrl => _wsUrl;

  void configureHost(String host, {int port = 8080}) {
    _baseUrl = "http://$host:$port/api";
    _wsUrl = "ws://$host:$port/ws";
  }

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

  Future<void> connect({int? propertyId, int? currentUserId}) async {
    if (propertyId != null) {
      _currentPropertyId = propertyId;
    }
    if (currentUserId != null &&
        _currentUserId != null &&
        currentUserId != _currentUserId) {
      debugPrint(
        'Đổi tài khoản từ $_currentUserId sang $currentUserId. Thực hiện ngắt phiên cũ...',
      );
      await disconnect();
    }

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

    if (_webSocket != null &&
        _connectionState == ChatConnectionState.connected) {
      _subscribeStompTopic(propertyId);
      return;
    }

    _updateState(ChatConnectionState.connecting);

    try {
      debugPrint('Thử kết nối WebSocket tới: $_wsUrl');
      _webSocket = await WebSocket.connect(
        _wsUrl,
      ).timeout(const Duration(seconds: 5));
      debugPrint('Đã mở WebSocket socket tới: $_wsUrl');
    } catch (e) {
      debugPrint('Không thể kết nối WS tại $_wsUrl: $e');
      debugPrint(
        'WebSocket kết nối thất bại. Chuyển sang chế độ REST API Fallback.',
      );
      _updateState(ChatConnectionState.disconnected);
      return;
    }

    _updateState(ChatConnectionState.connected);

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

    _sendStompConnect();
    _subscribeStompTopic(propertyId);
  }

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

  void _handleIncomingData(String rawData) {
    debugPrint('WebSocket Nhận: $rawData');

    final frames = rawData.split('\x00');
    for (var rawFrame in frames) {
      final frame = rawFrame.trim();
      if (frame.isEmpty) continue;

      if (frame.startsWith('CONNECTED')) {
        debugPrint(
          'Đã nhận phản hồi STOMP CONNECTED! Subscribe topics ngay...',
        );
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

  static final ValueNotifier<bool> hasUnreadNotification = ValueNotifier<bool>(
    false,
  );
  final Set<String> _processedMessageKeys = {};

  void _parseAndEmitMessage(String jsonStr) {
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      final msg = ChatMessageDTO.fromJson(map);

      final senderId = msg.getSenderId;
      final receiverId = msg.getReceiverId;

      if (_currentUserId != null && _currentUserId! > 0) {
        final isForMe =
            (senderId == _currentUserId || receiverId == _currentUserId);
        if (!isForMe) {
          debugPrint(
            'Bỏ qua tin nhắn riêng tư không thuộc về User hiện tại (MyID: $_currentUserId, Sender: $senderId, Receiver: $receiverId)',
          );
          return;
        }
      }

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
        final partnerName =
            (msg.senderName != null && msg.senderName!.isNotEmpty)
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

  Future<bool> sendMessage(ChatMessageDTO message) async {
    final jsonMap = message.toJson();
    final jsonStr = jsonEncode(jsonMap);

    if (_webSocket != null &&
        _connectionState == ChatConnectionState.connected) {
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

  void _updateState(ChatConnectionState state) {
    _connectionState = state;
    _connectionStreamController.add(state);
  }
}
