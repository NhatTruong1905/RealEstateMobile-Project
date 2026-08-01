import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:real_estate_frontend/dto/ChatMessageDTO.dart';
import 'package:real_estate_frontend/dto/PropertyDTO.dart';
import 'package:real_estate_frontend/mixin/api/APIInteractionMixin.dart';
import 'package:real_estate_frontend/mixin/api/APIPropertyMixin.dart';
import 'package:real_estate_frontend/services/ChatService.dart';
import 'package:real_estate_frontend/utils/PriceFormatter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final PropertyDTO property;
  final int? currentUserId;
  final int? receiverId;
  final String? receiverName;
  final bool? isSeller;

  const ChatScreen({
    super.key,
    required this.property,
    this.currentUserId,
    this.receiverId,
    this.receiverName,
    this.isSeller,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with ApiInteractionMixin, ApiPropertyMixin {
  bool get _isSellerUser {
    if (widget.isSeller != null) return widget.isSeller!;
    if (_myUserId != null && widget.property.userId != null) {
      return _myUserId == widget.property.userId;
    }
    if (_targetReceiverId != null && widget.property.userId != null) {
      return _targetReceiverId != widget.property.userId;
    }
    return false;
  }
  final ChatService _chatService = ChatService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessageDTO> _messages = [];
  bool _isLoadingHistory = true;
  int? _myUserId;
  int? _targetReceiverId;
  String _targetReceiverName = '';

  StreamSubscription<ChatMessageDTO>? _msgSub;
  StreamSubscription<ChatConnectionState>? _connSub;
  ChatConnectionState _connState = ChatConnectionState.disconnected;

  bool _isSubmittingAppointment = false;
  bool _myAccept = false;
  bool _partnerAccept = false;
  bool _fullyAccepted = false;

  Timer? _countdownTimer;
  int _remainingSeconds = 900; // 15 phút đếm ngược
  
  @override
  void initState() {
    super.initState();
    _initChat();
  }

  void _startCountdownTimer(int initialSeconds) {
    _countdownTimer?.cancel();
    _remainingSeconds = initialSeconds;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_fullyAccepted) {
        timer.cancel();
        return;
      }

      if (_remainingSeconds > 1) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
          _myAccept = false;
          _partnerAccept = false;
        });
        if (widget.property.id != null) {
          _chatService.clearLocalAcceptance(widget.property.id!, _targetReceiverId);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hết thời hạn 15 phút chờ xác nhận. Yêu cầu đã được làm mới.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    });
  }

  String _formatCountdown(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _syncAcceptanceStateFromMessages() {
    bool myAcc = _myAccept;
    bool partnerAcc = _partnerAccept;

    for (final msg in _messages) {
      if (msg.text == '__SYS_ACCEPT_APPOINTMENT__') {
        if (msg.getSenderId == _myUserId) {
          myAcc = true;
        } else {
          partnerAcc = true;
        }
      }
    }

    final bool fullyAcc = _fullyAccepted || (myAcc && partnerAcc);

    if (mounted) {
      setState(() {
        _myAccept = myAcc;
        _partnerAccept = partnerAcc;
        _fullyAccepted = fullyAcc;
      });

      if (widget.property.id != null && (myAcc || partnerAcc || fullyAcc)) {
        _chatService.saveLocalAcceptance(
          widget.property.id!,
          _targetReceiverId,
          myAccept: myAcc,
          partnerAccept: partnerAcc,
          fullyAccepted: fullyAcc,
        );
      }
    }
  }

  String? _myUserName;

  Future<void> _initChat() async {
    // 1. Xác định ID người dùng hiện tại
    final prefs = await SharedPreferences.getInstance();
    final userProfileStr = prefs.getString('user_profile');
    if (userProfileStr != null) {
      try {
        final userMap = jsonDecode(userProfileStr) as Map<String, dynamic>;
        _myUserId = (userMap['id'] as num?)?.toInt();
        _myUserName = userMap['fullname'] as String? ?? userMap['username'] as String?;
      } catch (_) {}
    }
    if (widget.currentUserId != null) {
      _myUserId = widget.currentUserId;
    }

    // 2. Xác định ID và tên người nhận tin nhắn (Chủ BĐS hoặc Khách hàng)
    _targetReceiverId = widget.receiverId ?? widget.property.userId;
    _targetReceiverName = (widget.receiverName != null && widget.receiverName!.isNotEmpty)
        ? widget.receiverName!
        : (widget.property.userFullname ?? 'Khách hàng quan tâm');

    if (widget.property.id != null) {
      // 2.1 Nếu chưa có _targetReceiverId, nạp chi tiết BĐS từ API để lấy userId chuẩn xác
      if (_targetReceiverId == null || _targetReceiverId == 0) {
        final fullProp = await fetchPropertyById(widget.property.id!);
        if (fullProp != null && fullProp.userId != null) {
          _targetReceiverId = fullProp.userId;
          if (_targetReceiverName.isEmpty || _targetReceiverName == 'Khách hàng quan tâm') {
            _targetReceiverName = fullProp.userFullname ?? 'Chủ bất động sản';
          }
        }
      }

      // Đánh dấu đang mở màn hình chat với BĐS & đối phương này
      ChatService.activeChatPropertyId = widget.property.id;
      ChatService.activeChatReceiverId = _targetReceiverId;

      // Nạp trạng thái chấp nhận 2 chiều từ local
      final acceptState = await _chatService.loadLocalAcceptance(
        widget.property.id!,
        _targetReceiverId,
      );

      // Nạp từ Bộ nhớ cục bộ Local Storage 24h
      final localMsgs = await _chatService.loadLocalChatSession(
        widget.property.id!,
        _targetReceiverId,
      );

      // Kiểm tra DB xem đã có Interaction loại MESSAGE đang hẹn xem nhà (status == 1) hay chưa
      bool hasActiveViewingInDB = false;
      try {
        final list1 = await fetchPropertyInteractions(widget.property.id!);
        final list2 = await fetchUserInteractions();
        final dbInteractions = [...list1, ...list2];

        for (var item in dbInteractions) {
          final pId = (item['propertyId'] ?? (item['property'] is Map ? item['property']['id'] : null)) as int?;
          if (pId != null && pId != widget.property.id) continue;

          final status = (item['status'] as num?)?.toInt() ?? 0;
          final typeCode = (item['interactionTypeCode'] ?? item['code'] ?? item['type'] ?? '')
              .toString()
              .toUpperCase();

          final sId = (item['senderId'] ?? (item['sender'] is Map ? item['sender']['id'] : null)) as int?;
          final rId = (item['receiverId'] ?? (item['receiver'] is Map ? item['receiver']['id'] : null)) as int?;

          final isCurrentConversation = (sId == _myUserId && rId == _targetReceiverId) ||
              (sId == _targetReceiverId && rId == _myUserId) ||
              (_myUserId != null && (sId == _myUserId || rId == _myUserId));

          if (status == 1 && (typeCode == 'MESSAGE' || typeCode == 'CHAT') && isCurrentConversation) {
            hasActiveViewingInDB = true;
            break;
          }
        }
      } catch (e) {
        debugPrint('Lỗi kiểm tra DB active interaction: $e');
      }

      if (mounted) {
        final myAcc = acceptState['myAccept'] as bool? ?? false;
        final partnerAcc = acceptState['partnerAccept'] as bool? ?? false;
        final fullyAcc = acceptState['fullyAccepted'] as bool? ?? false;
        final acceptTimestamp = acceptState['acceptTimestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch;

        final elapsed = (DateTime.now().millisecondsSinceEpoch - acceptTimestamp) ~/ 1000;
        final remaining = 900 - elapsed;

        setState(() {
          if (hasActiveViewingInDB) {
            _myAccept = true;
            _partnerAccept = true;
            _fullyAccepted = true;
          } else {
            _myAccept = myAcc;
            _partnerAccept = partnerAcc;
            _fullyAccepted = fullyAcc;
          }

          if (localMsgs.isNotEmpty) {
            _messages = localMsgs;
            _isLoadingHistory = false;
          }
        });

        if (localMsgs.isNotEmpty) {
          _syncAcceptanceStateFromMessages();
        }

        if ((_myAccept || _partnerAccept) && !_fullyAccepted && !hasActiveViewingInDB) {
          if (remaining > 0) {
            _startCountdownTimer(remaining);
          } else {
            _myAccept = false;
            _partnerAccept = false;
            _chatService.clearLocalAcceptance(widget.property.id!, _targetReceiverId);
          }
        }

        if (localMsgs.isNotEmpty) _scrollToBottom();
      }

      // 3. Kết nối WebSocket STOMP Realtime
      await _chatService.connect(
        propertyId: widget.property.id!,
        currentUserId: _myUserId,
      );

      // Lắng nghe trạng thái kết nối
      _connSub = _chatService.connectionStream.listen((state) {
        if (mounted) {
          setState(() => _connState = state);
        }
      });
      _connState = _chatService.connectionState;

      // Lắng nghe tin nhắn mới phát từ WebSocket Realtime
      _msgSub = _chatService.messageStream.listen((msg) async {
        if (mounted && msg.propertyId == widget.property.id) {
          // Nếu là tín hiệu Chấp nhận từ đối phương
          if (msg.text == '__SYS_ACCEPT_APPOINTMENT__') {
            if (msg.getSenderId != _myUserId) {
              setState(() {
                _partnerAccept = true;
              });
              await _chatService.saveLocalAcceptance(
                widget.property.id!,
                _targetReceiverId,
                partnerAccept: true,
              );

              _startCountdownTimer(900);

              if (_myAccept) {
                // Cả 2 bên đã bấm Chấp nhận -> Phía bên kia (người bấm thứ 2) đã gửi API lưu DB duy nhất 1 lần.
                // Phía người nhận tín hiệu chỉ cập nhật UI & local storage, KHÔNG gọi thêm API lưu DB bị lặp.
                _countdownTimer?.cancel();
                setState(() => _fullyAccepted = true);
                if (mounted) {
                  await _chatService.saveLocalAcceptance(
                    widget.property.id!,
                    _targetReceiverId,
                    myAccept: true,
                    partnerAccept: true,
                    fullyAccepted: true,
                  );
                }
              }
            }
            return;
          }

          // Nếu là tín hiệu Hủy chấp nhận / Hủy yêu cầu từ đối phương
          if (msg.text == '__SYS_CANCEL_APPOINTMENT__') {
            if (msg.getSenderId != _myUserId) {
              _countdownTimer?.cancel();
              setState(() {
                _myAccept = false;
                _partnerAccept = false;
                _fullyAccepted = false;
              });
              if (widget.property.id != null) {
                await _chatService.clearLocalAcceptance(
                  widget.property.id!,
                  _targetReceiverId,
                );
              }
            }
            return;
          }

          // Nếu là tín hiệu Hoàn tất xem nhà từ Seller
          if (msg.text == '__SYS_COMPLETE_VIEWING__') {
            _countdownTimer?.cancel();
            setState(() {
              _myAccept = false;
              _partnerAccept = false;
              _fullyAccepted = false;
            });
            if (widget.property.id != null) {
              await _chatService.markViewingCompleted(
                widget.property.id!,
                _targetReceiverId,
              );
            }

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Lượt xem nhà đã hoàn tất!'),
                  backgroundColor: Color(0xFF2E7D32),
                  duration: Duration(seconds: 4),
                ),
              );
            }
            return;
          }

          // Tin nhắn văn bản bình thường
          final bool exists = _messages.any((m) {
            if (msg.id != null && m.id != null) {
              return m.id == msg.id;
            }
            if (msg.getSenderId == _myUserId) {
              return m.getSenderId == msg.getSenderId &&
                  m.text == msg.text &&
                  m.timestamp == msg.timestamp;
            }
            return false;
          });
          if (!exists) {
            setState(() {
              _messages.add(msg);
            });
            _chatService.saveLocalChatSession(
              widget.property.id!,
              _targetReceiverId,
              _messages,
            );
            _scrollToBottom();
          }
        }
      });

      // 4. Nếu chưa có tin nhắn local, nạp lịch sử từ Backend API
      if (localMsgs.isEmpty) {
        final history = await _chatService.fetchMessageHistory(
          propertyId: widget.property.id!,
          receiverId: _targetReceiverId,
        );

        if (mounted) {
          setState(() {
            _messages = history;
            _isLoadingHistory = false;
          });
          if (history.isNotEmpty) {
            _chatService.saveLocalChatSession(
              widget.property.id!,
              _targetReceiverId,
              _messages,
            );
          }
          _scrollToBottom();
        }
      }

      // 5. Kiểm tra API interaction trong DB (cho cả Buyer & Seller) xem có tương tác active status = 1 không
      try {
        final List<Map<String, dynamic>> allInteractions = [];

        final propInteractions = await fetchPropertyInteractions(widget.property.id!);
        allInteractions.addAll(propInteractions);

        final userInteractions = await fetchUserInteractions();
        allInteractions.addAll(userInteractions);

        bool hasActiveMessageInteraction = false;

        for (var item in allInteractions) {
          final propId = item['propertyId'] ?? (item['property'] is Map ? item['property']['id'] : null);
          if (propId != null && propId != widget.property.id) continue;

          final senderObj = item['sender'] is Map ? item['sender'] as Map : null;
          final receiverObj = item['receiver'] is Map ? item['receiver'] as Map : null;
          final senderId = item['senderId'] ?? senderObj?['id'];
          final receiverId = item['receiverId'] ?? receiverObj?['id'];

          if (_targetReceiverId != null) {
            final isRelevantUser = (senderId == _targetReceiverId || receiverId == _targetReceiverId);
            if (!isRelevantUser) continue;
          }

          final code = (item['interactionTypeCode'] ?? item['code'] ?? item['type'] ?? '')
              .toString()
              .toUpperCase();
          final status = (item['status'] as num?)?.toInt() ?? 1;

          if (status == 1 && (code == 'MESSAGE' || code == 'CHAT' || code == 'VIEWING')) {
            hasActiveMessageInteraction = true;
            break;
          }
        }

        if (mounted) {
          if (hasActiveMessageInteraction) {
            setState(() {
              _myAccept = true;
              _partnerAccept = true;
              _fullyAccepted = true;
            });
            await _chatService.saveLocalAcceptance(
              widget.property.id!,
              _targetReceiverId,
              myAccept: true,
              partnerAccept: true,
              fullyAccepted: true,
            );
          } else {
            setState(() {
              _myAccept = false;
              _partnerAccept = false;
              _fullyAccepted = false;
            });
            await _chatService.clearLocalAcceptance(
              widget.property.id!,
              _targetReceiverId,
            );
          }
        }
      } catch (e) {
        debugPrint('Lỗi kiểm tra DB interaction VIEWING: $e');
      }
    } else {
      setState(() => _isLoadingHistory = false);
    }
  }

  @override
  void dispose() {
    if (ChatService.activeChatPropertyId == widget.property.id &&
        ChatService.activeChatReceiverId == _targetReceiverId) {
      ChatService.activeChatPropertyId = null;
      ChatService.activeChatReceiverId = null;
    }
    _countdownTimer?.cancel();
    _msgSub?.cancel();
    _connSub?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || widget.property.id == null) return;

    final nowStr = DateFormat('HH:mm').format(DateTime.now());

    final newMsg = ChatMessageDTO(
      id: DateTime.now().millisecondsSinceEpoch % 1000000000,
      propertyId: widget.property.id,
      senderId: _myUserId,
      receiverId: _targetReceiverId,
      message: text,
      timestamp: nowStr,
      senderName: _myUserName,
    );

    // Thêm tin nhắn vào bộ nhớ cục bộ & lưu SharedPreferences
    setState(() {
      _messages.add(newMsg);
      _inputController.clear();
    });
    _scrollToBottom();

    await _chatService.saveLocalChatSession(
      widget.property.id!,
      _targetReceiverId,
      _messages,
      partnerName: _targetReceiverName,
    );

    // Gửi realtime qua WebSocket STOMP (KHÔNG lưu DB)
    final sent = await _chatService.sendMessage(newMsg);
    if (!sent) {
      debugPrint('Cảnh báo: Tin nhắn gửi qua WS chưa nhận phản hồi');
    }
  }

  /// Xử lý sự kiện nhấn nút "Chấp nhận đi xem bất động sản"
  Future<void> _acceptPropertyViewing() async {
    if (_fullyAccepted) return;
    if (_messages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa có nội dung trao đổi để xác nhận lịch xem nhà.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _myAccept = true;
    });

    _startCountdownTimer(900);

    if (widget.property.id != null) {
      await _chatService.saveLocalAcceptance(
        widget.property.id!,
        _targetReceiverId,
        myAccept: true,
      );

      await _chatService.sendAcceptanceSignal(
        propertyId: widget.property.id!,
        senderId: _myUserId ?? 0,
        receiverId: _targetReceiverId ?? 0,
      );
    }

    if (_partnerAccept) {
      _countdownTimer?.cancel();
      setState(() => _isSubmittingAppointment = true);

      // Đảm bảo senderId luôn là ID của User (Buyer), receiverId luôn là ID của Seller
      final int sellerId = _isSellerUser
          ? (_myUserId ?? 0)
          : (_targetReceiverId ?? widget.property.userId ?? 0);
      final int buyerId = _isSellerUser
          ? (_targetReceiverId ?? 0)
          : (_myUserId ?? 0);

      final ok = await _chatService.consolidateAndSaveInteraction(
        propertyId: widget.property.id!,
        senderId: buyerId,
        receiverId: sellerId,
        messages: _messages,
        isAppointmentAccepted: true,
      );

      if (mounted) {
        setState(() {
          _isSubmittingAppointment = false;
          _fullyAccepted = ok;
        });

        if (widget.property.id != null) {
          await _chatService.saveLocalAcceptance(
            widget.property.id!,
            _targetReceiverId,
            myAccept: true,
            partnerAccept: true,
            fullyAccepted: ok,
          );
        }

        if (mounted && ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cả 2 bên đã Chấp nhận!'),
              backgroundColor: Color(0xFF2E7D32),
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã chấp nhận! Đang chờ đối phương cùng xác nhận.'),
            backgroundColor: Color(0xFFE65100),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Xử lý sự kiện nhấn nút "Hủy yêu cầu chấp nhận"
  Future<void> _cancelPropertyViewing() async {
    if (_fullyAccepted) return;

    _countdownTimer?.cancel();

    setState(() {
      _myAccept = false;
      _partnerAccept = false;
      _fullyAccepted = false;
    });

    if (widget.property.id != null) {
      await _chatService.clearLocalAcceptance(
        widget.property.id!,
        _targetReceiverId,
      );

      await _chatService.sendCancelAcceptanceSignal(
        propertyId: widget.property.id!,
        senderId: _myUserId ?? 0,
        receiverId: _targetReceiverId ?? 0,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã hủy yêu cầu chấp nhận xem nhà.'),
          backgroundColor: Color(0xFF6B7280),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  /// Xử lý sự kiện Seller nhấn nút "Đã xem nhà xong"
  Future<void> _completePropertyViewing() async {
    _countdownTimer?.cancel();

    setState(() {
      _myAccept = false;
      _partnerAccept = false;
      _fullyAccepted = false;
    });

    if (widget.property.id != null) {
      await _chatService.clearLocalAcceptance(
        widget.property.id!,
        _targetReceiverId,
      );

      await _chatService.sendCompleteViewingSignal(
        propertyId: widget.property.id!,
        senderId: _myUserId ?? 0,
        receiverId: _targetReceiverId ?? 0,
      );

      // Gọi API Backend /api/secure/interactions/completed để set status = 0
      try {
        final int sellerId = _isSellerUser
            ? (_myUserId ?? 0)
            : (_targetReceiverId ?? widget.property.userId ?? 0);
        final int buyerId = _isSellerUser
            ? (_targetReceiverId ?? 0)
            : (_myUserId ?? 0);

        await markInteractionCompleted(
          propertyId: widget.property.id!,
          senderId: buyerId,
          receiverId: sellerId,
          interactionTypeId: 2,
          interactionTypeCode: 'MESSAGE',
        );
      } catch (e) {
        debugPrint('Lỗi gọi API markInteractionCompleted: $e');
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã hoàn tất lượt xem nhà!'),
          backgroundColor: Color(0xFF2E7D32),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSeller = _isSellerUser;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFBFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A1918), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFF4EEE6),
              child: Text(
                _targetReceiverName.isNotEmpty
                    ? _targetReceiverName.substring(0, 1).toUpperCase()
                    : 'C',
                style: const TextStyle(
                  color: Color(0xFF945331),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _targetReceiverName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1918),
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 4,
                        backgroundColor: _connState == ChatConnectionState.connected
                            ? const Color(0xFF2E7D32)
                            : _connState == ChatConnectionState.connecting
                                ? const Color(0xFFE65100)
                                : const Color(0xFFD32F2F),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _connState == ChatConnectionState.connected
                            ? 'Trực tuyến'
                            : _connState == ChatConnectionState.connecting
                                ? 'Đang kết nối...'
                                : 'Ngoại tuyến',
                        style: TextStyle(
                          fontSize: 11,
                          color: _connState == ChatConnectionState.connected
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFF78736D),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // BANNER BẤT ĐỘNG SẢN LIÊN QUAN
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF4EEE6),
              border: Border(
                bottom: BorderSide(color: Color(0xFFE8E3DC)),
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: (widget.property.image != null &&
                          widget.property.image!.isNotEmpty)
                      ? Image.network(
                          widget.property.image!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 48,
                            height: 48,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.home, size: 24),
                          ),
                        )
                      : Container(
                          width: 48,
                          height: 48,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.home, size: 24),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.property.title ?? 'Bất động sản',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF1A1918),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatPropertyPrice(widget.property.price),
                        style: const TextStyle(
                          color: Color(0xFF945331),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // BANNER HÀNH ĐỘNG CHUYÊN NGHIỆP: XÁC NHẬN ĐI XEM BẤT ĐỘNG SẢN & ĐẾM NGƯỢC 15 PHÚT
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _fullyAccepted
                  ? const Color(0xFFECFDF5)
                  : (_myAccept || _partnerAccept
                      ? const Color(0xFFFFFBEB)
                      : const Color(0xFFFAF5EF)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _fullyAccepted
                    ? const Color(0xFFA7F3D0)
                    : (_myAccept || _partnerAccept
                        ? const Color(0xFFFDE68A)
                        : const Color(0xFFE8DFD5)),
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon chuyên nghiệp thể hiện trạng thái
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _fullyAccepted
                        ? const Color(0xFFD1FAE5)
                        : (_myAccept || _partnerAccept
                            ? const Color(0xFFFEF3C7)
                            : const Color(0xFFF3E8DC)),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _fullyAccepted
                        ? Icons.task_alt_rounded
                        : (_myAccept || _partnerAccept
                            ? Icons.timer_outlined
                            : Icons.edit_calendar_rounded),
                    color: _fullyAccepted
                        ? const Color(0xFF059669)
                        : (_myAccept || _partnerAccept
                            ? const Color(0xFFD97706)
                            : const Color(0xFF945331)),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                // Tiêu đề và Đếm ngược 15p
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _fullyAccepted
                                  ? 'Đã chốt lịch & lưu hệ thống'
                                  : (_myAccept && _partnerAccept
                                      ? 'Cả 2 bên đã đồng ý!'
                                      : (_myAccept
                                          ? 'Đã gửi yêu cầu xác nhận'
                                          : (_partnerAccept
                                              ? 'Đối phương đã chấp nhận!'
                                              : 'Xác nhận hẹn xem BĐS'))),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _fullyAccepted
                                    ? const Color(0xFF065F46)
                                    : (_myAccept || _partnerAccept
                                        ? const Color(0xFF92400E)
                                        : const Color(0xFF1A1918)),
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if ((_myAccept || _partnerAccept) && !_fullyAccepted) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    Border.all(color: const Color(0xFFFDE68A)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.schedule_rounded,
                                    size: 12,
                                    color: Color(0xFFB45309),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    _formatCountdown(_remainingSeconds),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFB45309),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _fullyAccepted
                            ? (isSeller ? 'Đã hẹn lịch xem nhà' : 'Lịch xem nhà đã được chốt')
                            : (_myAccept
                                ? 'Chờ đối phương xác nhận (15p)'
                                : (_partnerAccept
                                    ? 'Nhấn chấp nhận để chốt lịch'
                                    : 'Thống nhất và chốt lịch xem nhà')),
                        style: TextStyle(
                          fontSize: 11,
                          color: _fullyAccepted
                              ? const Color(0xFF047857)
                              : (_myAccept || _partnerAccept
                                  ? const Color(0xFFB45309)
                                  : const Color(0xFF78736D)),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Nút thao tác chuyên nghiệp (Chấp nhận / Hủy yêu cầu / Đã xem nhà xong)
                ElevatedButton.icon(
                  onPressed: _isSubmittingAppointment
                      ? null
                      : (_fullyAccepted
                          ? (isSeller ? _completePropertyViewing : null)
                          : (_myAccept ? _cancelPropertyViewing : _acceptPropertyViewing)),
                  icon: _isSubmittingAppointment
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(
                          _fullyAccepted
                              ? (isSeller ? Icons.task_alt_rounded : Icons.verified_rounded)
                              : (_myAccept
                                  ? Icons.cancel_outlined
                                  : (_partnerAccept
                                      ? Icons.mark_email_unread_rounded
                                      : Icons.approval_rounded)),
                          size: 15,
                          color: Colors.white,
                        ),
                  label: Text(
                    _isSubmittingAppointment
                        ? 'Đang xử lý...'
                        : (_fullyAccepted
                            ? (isSeller ? 'Đã xem nhà xong' : 'Hoàn tất')
                            : (_myAccept
                                ? 'Hủy yêu cầu'
                                : (_partnerAccept ? 'Đồng ý hẹn xem nhà' : 'Hẹn đi xem nhà'))),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _fullyAccepted
                        ? (isSeller ? const Color(0xFF059669) : const Color(0xFF059669))
                        : (_myAccept
                            ? const Color(0xFFDC2626)
                            : (_partnerAccept
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF945331))),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),

          // DANH SÁCH TIN NHẮN REALTIME
          Expanded(
            child: _isLoadingHistory
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF945331),
                    ),
                  )
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.chat_bubble_outline,
                              size: 48,
                              color: Color(0xFF78736D),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Hãy bắt đầu cuộc trò chuyện với $_targetReceiverName',
                              style: const TextStyle(
                                color: Color(0xFF78736D),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg.getSenderId == _myUserId;

                          return _buildMessageBubble(msg, isMe);
                        },
                      ),
          ),

          // Ô NHẬP TIN NHẮN CHAT
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn tư vấn...',
                        filled: true,
                        fillColor: const Color(0xFFF4EEE6),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: _sendMessage,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFF945331),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageDTO msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF945331) : const Color(0xFFF4EEE6),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                color: isMe ? Colors.white : const Color(0xFF1A1918),
                fontSize: 14,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
            if (msg.timestamp != null && msg.timestamp!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  msg.timestamp!,
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : const Color(0xFF78736D),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
