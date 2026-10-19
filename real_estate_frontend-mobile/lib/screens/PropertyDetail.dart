import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:real_estate_frontend/dto/ChatMessageDTO.dart';
import 'package:real_estate_frontend/dto/PropertyDTO.dart';
import 'package:real_estate_frontend/mixin/api/APIInteractionMixin.dart';
import 'package:real_estate_frontend/mixin/api/APIPropertyMixin.dart';
import 'package:real_estate_frontend/screens/Auth.dart';
import 'package:real_estate_frontend/screens/ChatScreen.dart';
import 'package:real_estate_frontend/services/ChatService.dart';
import 'package:real_estate_frontend/utils/PriceFormatter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

part 'property_detail/property_detail_gallery.dart';
part 'property_detail/property_detail_view.dart';
part 'property_detail/property_detail_components.dart';

Future<void> openPropertyDetail(
  BuildContext context,
  PropertyDTO property,
) async {
  if (property.id == null) return;

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');

  if (token != null && token.isNotEmpty) {
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PropertyDetailScreen(propertyId: property.id!),
        ),
      );
    }
  } else {
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AuthScreen(
            onLoginSuccess: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PropertyDetailScreen(propertyId: property.id!),
                ),
              );
            },
          ),
        ),
      );
    }
  }
}

class PropertyDetailScreen extends StatefulWidget {
  final int propertyId;

  const PropertyDetailScreen({super.key, required this.propertyId});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen>
    with ApiPropertyMixin, ApiInteractionMixin {
  bool _isLoading = true;
  PropertyDTO? _property;

  final PageController _imagePageController = PageController();
  int _currentImageIndex = 0;

  bool _isCallLoading = false;
  bool _alreadyBookedViewing = false;
  bool _isViewingLoading = false;
  bool _hasUnreadFromSeller = false;

  final List<Map<String, dynamic>> _chatMessages = [];
  final TextEditingController _chatInputController = TextEditingController();

  Future<void> _makePhoneCall(PropertyDTO property) async {
    final phone = property.userPhone ?? '';
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Chủ bất động sản chưa cập nhật số điện thoại liên hệ.',
          ),
          backgroundColor: Color(0xFFE65100),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isCallLoading = true);

    final Uri launchUri = Uri.parse('tel:$cleanPhone');
    try {
      final launched = await launchUrl(
        launchUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) await launchUrl(launchUri);
    } catch (e) {
      debugPrint('Lỗi thực hiện cuộc gọi: $e');
    }

    if (property.id != null && property.userId != null) {
      debugPrint(
        'Tạo interaction CALL (propertyId=${property.id}, receiverId=${property.userId})',
      );
      await createInteraction(
        propertyId: property.id!,
        receiverId: property.userId!,
        code: 'CALL',
      );
    }

    if (mounted) setState(() => _isCallLoading = false);
  }

  Future<void> _handleViewing(PropertyDTO property) async {
    if (_alreadyBookedViewing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn đã đặt lịch xem bất động sản này trước đó rồi!'),
          backgroundColor: Color(0xFFE65100),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_isViewingLoading) return;

    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
    final TextEditingController noteController = TextEditingController();

    String formatDate(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    String formatTime(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Đặt lịch hẹn xem nhà',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1918),
                          fontFamily: 'Georgia',
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context, false),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFFE8E3DC)),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 90),
                              ),
                            );
                            if (picked != null) {
                              setModalState(() => selectedDate = picked);
                            }
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4EEE6),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFE8E3DC),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Nguyện vọng ngày:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF78736D),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: Color(0xFF945331),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      formatDate(selectedDate),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (picked != null) {
                              setModalState(() => selectedTime = picked);
                            }
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4EEE6),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFE8E3DC),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Nguyện vọng giờ:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF78736D),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: Color(0xFF945331),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      formatTime(selectedTime),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Lời nhắn cho chủ nhà (không bắt buộc):',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1918),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Nhập ghi chú yêu cầu thêm cho chủ nhà...',
                      filled: true,
                      fillColor: const Color(0xFFF4EEE6),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF945331),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Xác nhận đặt lịch xem',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != true || !mounted) return;

    final dateTimeStr =
        '${formatTime(selectedTime)} - Ngày ${formatDate(selectedDate)}';

    final userNote = noteController.text.trim();
    final String appointmentMessage;

    if (userNote.isNotEmpty) {
      appointmentMessage = '$userNote (Lịch hẹn: $dateTimeStr)';
    } else {
      appointmentMessage = 'Lịch hẹn xem nhà: $dateTimeStr';
    }

    setState(() => _isViewingLoading = true);

    if (property.id != null && property.userId != null) {
      debugPrint('Tạo interaction VIEWING: $appointmentMessage');
      await createInteraction(
        propertyId: property.id!,
        receiverId: property.userId!,
        code: 'VIEWING',
        message: appointmentMessage,
      );

      try {
        final chatService = ChatService();
        final prefs = await SharedPreferences.getInstance();
        int? senderId = chatService.currentUserId;
        String senderName = 'Khách hàng';

        final profileStr = prefs.getString('user_profile');
        if (profileStr != null) {
          try {
            final userMap = jsonDecode(profileStr);
            senderId ??= (userMap['id'] as num?)?.toInt();
            senderName =
                userMap['fullname'] ?? userMap['username'] ?? 'Khách hàng';
          } catch (_) {}
        }

        final sysMsg = ChatMessageDTO(
          id: DateTime.now().millisecondsSinceEpoch % 1000000000,
          propertyId: property.id,
          senderId: senderId,
          receiverId: property.userId,
          message: appointmentMessage,
          timestamp: DateTime.now().toIso8601String(),
          senderName: senderName,
        );

        await chatService.sendMessage(sysMsg);
        await chatService.sendAcceptanceSignal(
          propertyId: property.id!,
          senderId: senderId ?? 0,
          receiverId: property.userId!,
        );
      } catch (e) {
        debugPrint('Lỗi gửi tín hiệu STOMP hẹn xem nhà: $e');
      }
    }

    if (mounted) {
      await _loadDetail();
      if (!mounted) return;
      setState(() {
        _isViewingLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã gửi đặt lịch xem nhà lúc $dateTimeStr!'),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  StreamSubscription<ChatMessageDTO>? _msgSub;

  @override
  void initState() {
    super.initState();
    _loadDetail();

    _msgSub = ChatService().messageStream.listen((msg) {
      if (!mounted) return;
      if (msg.propertyId == widget.propertyId) {
        if (msg.text == '__SYS_COMPLETE_VIEWING__' ||
            msg.text == '__SYS_CANCEL_APPOINTMENT__') {
          setState(() {
            _alreadyBookedViewing = false;
          });
        } else if (msg.text == '__SYS_ACCEPT_APPOINTMENT__' ||
            msg.text.contains('Lịch hẹn')) {
          setState(() {
            _alreadyBookedViewing = true;
          });
        } else {
          final myId = ChatService().currentUserId;
          if (myId != null && msg.getSenderId != myId) {
            setState(() {
              _hasUnreadFromSeller = true;
            });
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _imagePageController.dispose();
    _chatInputController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      fetchPropertyById(widget.propertyId),
      fetchPropertyInteractions(widget.propertyId),
    ]);

    final detail = results[0] as PropertyDTO?;
    final interactions = results[1] as List<Map<String, dynamic>>;

    bool hasViewing = false;
    for (final item in interactions) {
      final status = (item['status'] as num?)?.toInt() ?? 1;
      if (status != 1) continue;

      final codeStr = (item['interactionTypeCode'] ?? '')
          .toString()
          .toUpperCase();

      if (codeStr == 'VIEWING' || codeStr == 'MESSAGE') {
        hasViewing = true;
        break;
      }
    }

    if (mounted) {
      setState(() {
        _property = detail;
        _alreadyBookedViewing = hasViewing;
        _isLoading = false;
        if (detail != null) {
          _chatMessages.clear();
          _chatMessages.add({
            'sender': 'seller',
            'text':
                'Xin chào! Tôi là ${detail.userFullname ?? "chủ bất động sản"}. Tôi có thể hỗ trợ thông tin gì cho bạn về bài đăng "${detail.title ?? "bất động sản"}"?',
            'time': 'Vừa xong',
          });
        }
      });
    }
  }

  Future<void> _toggleSave() async {
    if (_property == null || _property!.id == null) return;

    setState(() {
      _property!.isSaved = !_property!.isSaved;
      if (_property!.isSaved) {
        userFavoriteIds.add(_property!.id!);
      } else {
        userFavoriteIds.remove(_property!.id!);
      }
    });

    await syncFavoriteProperties(userFavoriteIds.toList());
  }

  void _showChatBottomSheet(BuildContext context, PropertyDTO property) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatScreen(property: property)),
    );
  }

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
