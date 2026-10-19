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

part 'chat/chat_view.dart';
part 'chat/chat_message_bubble.dart';

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

class _ChatScreenState extends State<ChatScreen>
    with ApiInteractionMixin, ApiPropertyMixin {
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
  int _remainingSeconds = 900;

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
          _chatService.clearLocalAcceptance(
            widget.property.id!,
            _targetReceiverId,
          );
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Hết thời hạn 15 phút chờ xác nhận. Yêu cầu đã được làm mới.',
              ),
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
    final prefs = await SharedPreferences.getInstance();
    final userProfileStr = prefs.getString('user_profile');
    if (userProfileStr != null) {
      try {
        final userMap = jsonDecode(userProfileStr) as Map<String, dynamic>;
        _myUserId = (userMap['id'] as num?)?.toInt();
        _myUserName =
            userMap['fullname'] as String? ?? userMap['username'] as String?;
      } catch (_) {}
    }
    if (widget.currentUserId != null) {
      _myUserId = widget.currentUserId;
    }

    _targetReceiverId = widget.receiverId ?? widget.property.userId;
    _targetReceiverName =
        (widget.receiverName != null && widget.receiverName!.isNotEmpty)
        ? widget.receiverName!
        : (widget.property.userFullname ?? 'Khách hàng quan tâm');

    if (widget.property.id != null) {
      if (_targetReceiverId == null || _targetReceiverId == 0) {
        final fullProp = await fetchPropertyById(widget.property.id!);
        if (fullProp != null && fullProp.userId != null) {
          _targetReceiverId = fullProp.userId;
          if (_targetReceiverName.isEmpty ||
              _targetReceiverName == 'Khách hàng quan tâm') {
            _targetReceiverName = fullProp.userFullname ?? 'Chủ bất động sản';
          }
        }
      }

      ChatService.activeChatPropertyId = widget.property.id;
      ChatService.activeChatReceiverId = _targetReceiverId;

      final acceptState = await _chatService.loadLocalAcceptance(
        widget.property.id!,
        _targetReceiverId,
      );

      final localMsgs = await _chatService.loadLocalChatSession(
        widget.property.id!,
        _targetReceiverId,
      );

      bool hasActiveViewingInDB = false;
      try {
        final list1 = await fetchPropertyInteractions(widget.property.id!);
        final list2 = await fetchUserInteractions();
        final dbInteractions = [...list1, ...list2];

        for (var item in dbInteractions) {
          final pId = (item['propertyId'] as num?)?.toInt();
          if (pId != null && pId != widget.property.id) continue;

          final status = (item['status'] as num?)?.toInt() ?? 0;
          final typeCode = (item['interactionTypeCode'] ?? item['code'] ?? '')
              .toString()
              .toUpperCase();

          final sId = (item['senderId'] as num?)?.toInt();
          final rId = (item['receiverId'] as num?)?.toInt();

          final isCurrentConversation =
              (sId == _myUserId && rId == _targetReceiverId) ||
              (sId == _targetReceiverId && rId == _myUserId);

          if (status == 1 && typeCode == 'MESSAGE' && isCurrentConversation) {
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
        final acceptTimestamp =
            acceptState['acceptTimestamp'] as int? ??
            DateTime.now().millisecondsSinceEpoch;

        final elapsed =
            (DateTime.now().millisecondsSinceEpoch - acceptTimestamp) ~/ 1000;
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

          _messages = localMsgs;
          _isLoadingHistory = false;
        });

        if (localMsgs.isNotEmpty) {
          _syncAcceptanceStateFromMessages();
        }

        if ((_myAccept || _partnerAccept) &&
            !_fullyAccepted &&
            !hasActiveViewingInDB) {
          if (remaining > 0) {
            _startCountdownTimer(remaining);
          } else {
            _myAccept = false;
            _partnerAccept = false;
            _chatService.clearLocalAcceptance(
              widget.property.id!,
              _targetReceiverId,
            );
          }
        }

        if (localMsgs.isNotEmpty) _scrollToBottom();
      }

      await _chatService.connect(
        propertyId: widget.property.id!,
        currentUserId: _myUserId,
      );

      _connSub = _chatService.connectionStream.listen((state) {
        if (mounted) {
          setState(() => _connState = state);
        }
      });
      _connState = _chatService.connectionState;

      _msgSub = _chatService.messageStream.listen((msg) async {
        if (mounted && msg.propertyId == widget.property.id) {
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

    final sent = await _chatService.sendMessage(newMsg);
    if (!sent) {
      debugPrint('Cảnh báo: Tin nhắn gửi qua WS chưa nhận phản hồi');
    }
  }

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
  Widget build(BuildContext context) => _buildPage(context);
}
