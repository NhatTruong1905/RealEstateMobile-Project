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

Future<void> openPropertyDetail(
    BuildContext context, PropertyDTO property) async {
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

  const PropertyDetailScreen({
    super.key,
    required this.propertyId,
  });

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen>
    with ApiPropertyMixin, ApiInteractionMixin {
  bool _isLoading = true;
  PropertyDTO? _property;

  // Interaction & State
  bool _isCallLoading = false;
  bool _alreadyBookedViewing = false;
  bool _isViewingLoading = false;
  bool _hasUnreadFromSeller = false;

  // Chat
  final List<Map<String, dynamic>> _chatMessages = [];
  final TextEditingController _chatInputController = TextEditingController();

  Future<void> _makePhoneCall(PropertyDTO property) async {
    final phone = property.userPhone ?? '';
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.isEmpty) {
      _showContactModal(context, property);
      return;
    }

    setState(() => _isCallLoading = true);

    // 1. Gọi điện thoại
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

    // 2. Ghi interaction với CODE = 'CALL' vào backend
    if (property.id != null && property.userId != null) {
      debugPrint('Tạo interaction CALL (propertyId=${property.id}, receiverId=${property.userId})');
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
            final dayStr = selectedDate.day.toString().padLeft(2, '0');
            final monthStr = selectedDate.month.toString().padLeft(2, '0');
            final yearStr = selectedDate.year.toString();
            final hourStr = selectedTime.hour.toString().padLeft(2, '0');
            final minuteStr = selectedTime.minute.toString().padLeft(2, '0');

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

                  // NÚT CHỌN NGÀY VÀ GIỜ
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 90)),
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
                              border: Border.all(color: const Color(0xFFE8E3DC)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Nguyện vọng ngày:', style: TextStyle(fontSize: 11, color: Color(0xFF78736D))),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16, color: Color(0xFF945331)),
                                    const SizedBox(width: 6),
                                    Text('$dayStr/$monthStr/$yearStr', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                              border: Border.all(color: const Color(0xFFE8E3DC)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Nguyện vọng giờ:', style: TextStyle(fontSize: 11, color: Color(0xFF78736D))),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 16, color: Color(0xFF945331)),
                                    const SizedBox(width: 6),
                                    Text('$hourStr:$minuteStr', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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

                  // Ô NHẬP MESSAGE LỜI NHẮN
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // NÚT ĐẶT LỊCH HẸN
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

    final hourStr = selectedTime.hour.toString().padLeft(2, '0');
    final minuteStr = selectedTime.minute.toString().padLeft(2, '0');
    final dayStr = selectedDate.day.toString().padLeft(2, '0');
    final monthStr = selectedDate.month.toString().padLeft(2, '0');
    final yearStr = selectedDate.year.toString();
    final dateTimeStr = '$hourStr:$minuteStr - Ngày $dayStr/$monthStr/$yearStr';

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

      // Gửi tín hiệu STOMP Realtime tới Seller ngay tức thì
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
            senderName = userMap['fullname'] ?? userMap['username'] ?? 'Khách hàng';
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        if (msg.text == '__SYS_COMPLETE_VIEWING__' || msg.text == '__SYS_CANCEL_APPOINTMENT__') {
          setState(() {
            _alreadyBookedViewing = false;
          });
        } else if (msg.text == '__SYS_ACCEPT_APPOINTMENT__' || msg.text.contains('Lịch hẹn')) {
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
    _chatInputController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);
    
    // Fetch property detail và các interaction của property này song song
    final results = await Future.wait([
      fetchPropertyById(widget.propertyId),
      fetchPropertyInteractions(widget.propertyId),
    ]);

    final detail = results[0] as PropertyDTO?;
    final interactions = results[1] as List<Map<String, dynamic>>;

    // Chỉ tính đã đặt lịch nếu tương tác còn Active (status == 1)
    bool hasViewing = false;
    for (final item in interactions) {
      final status = (item['status'] as num?)?.toInt() ?? 1;
      if (status != 1) continue;

      final codeStr = (
        item['code'] ??
        item['interactionTypeCode'] ??
        item['typeCode'] ??
        item['type'] ??
        (item['interactionType'] is Map ? (item['interactionType']['code'] ?? item['interactionType']['name']) : '') ??
        ''
      ).toString().toUpperCase();

      if (codeStr == 'VIEWING' || codeStr == 'MESSAGE' || codeStr == 'CHAT') {
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

  void _showContactModal(BuildContext context, PropertyDTO property) {
    final sellerName = property.userFullname ?? 'Chủ bất động sản';
    final sellerPhone = property.userPhone ?? '0912 345 678';
    final sellerEmail = property.userEmail ?? 'chubds@gmail.com';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFFF4EEE6),
                child: Text(
                  sellerName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF945331),
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                sellerName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1918),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Chủ sở hữu bất động sản',
                style: TextStyle(color: Color(0xFF78736D), fontSize: 13),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4EEE6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined,
                            color: Color(0xFF2E7D32), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            sellerPhone,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1918),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.email_outlined,
                            color: Color(0xFF1565C0), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            sellerEmail,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1A1918),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _makePhoneCall(property);
                  },
                  icon: const Icon(Icons.phone, color: Colors.white),
                  label: Text(
                    'Gọi ngay $sellerPhone',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showChatBottomSheet(BuildContext context, PropertyDTO property) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(property: property),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final property = _property;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFBFA),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF945331)),
            )
          : property == null
              ? Scaffold(
                  appBar: AppBar(
                    backgroundColor: const Color(0xFFFCFBFA),
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Color(0xFF1A1918)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  body: const Center(
                    child: Text(
                      'Không tìm thấy thông tin bất động sản',
                      style: TextStyle(color: Color(0xFF78736D), fontSize: 16),
                    ),
                  ),
                )
              : Stack(
                  children: [
                    CustomScrollView(
                      slivers: [
                        // 1. BANNER HÌNH ẢNH & NÚT QUAY LẠI
                        SliverAppBar(
                          expandedHeight: 320,
                          pinned: true,
                          backgroundColor: const Color(0xFF945331),
                          leading: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CircleAvatar(
                              backgroundColor:
                                  Colors.black.withValues(alpha: 0.4),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back_ios_new,
                                    color: Colors.white, size: 18),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                          ),
                          actions: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CircleAvatar(
                                backgroundColor:
                                    Colors.black.withValues(alpha: 0.4),
                                child: IconButton(
                                  icon: Icon(
                                    property.isSaved
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: property.isSaved
                                        ? const Color(0xFF945331)
                                        : Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: _toggleSave,
                                ),
                              ),
                            ),
                          ],
                          flexibleSpace: FlexibleSpaceBar(
                            background: Stack(
                              fit: StackFit.expand,
                              children: [
                                (property.image != null &&
                                        property.image!.isNotEmpty)
                                    ? Image.network(
                                        property.image!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                          color: Colors.grey.shade300,
                                          child: const Icon(
                                              Icons.image_not_supported,
                                              size: 50),
                                        ),
                                      )
                                    : Container(
                                        color: Colors.grey.shade300,
                                        child: const Icon(Icons.home,
                                            size: 60, color: Colors.grey),
                                      ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withValues(alpha: 0.4),
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.6),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 20,
                                  left: 20,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: property.typeId == 2
                                          ? const Color(0xFF2E7D32)
                                          : const Color(0xFF945331),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      property.typeId == 2
                                          ? 'Cho Thuê'
                                          : 'Cho Bán',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        fontFamily: 'Plus Jakarta Sans',
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 2. NỘI DUNG CHI TIẾT
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // GIÁ TIỀN & DIỆN TÍCH
                                Text(
                                  formatPropertyPrice(property.price),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF945331),
                                    fontFamily: 'Georgia',
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // TIÊU ĐỀ
                                Text(
                                  property.title ?? 'Chưa có tiêu đề',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1918),
                                    fontFamily: 'Plus Jakarta Sans',
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // ĐỊA CHỈ
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      color: Color(0xFF945331),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        property.addressDetail ??
                                            property.address ??
                                            property.city ??
                                            'Đang cập nhật địa chỉ',
                                        style: const TextStyle(
                                          color: Color(0xFF78736D),
                                          fontSize: 15,
                                          fontFamily: 'Plus Jakarta Sans',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // THÔNG TIN CHỦ TÀI KHOẢN ĐĂNG TIN
                                _buildSellerCard(property),
                                const SizedBox(height: 24),
                                const Divider(color: Color(0xFFE8E3DC)),
                                const SizedBox(height: 16),

                                // LƯỚI THÔNG SỐ ĐẶC TRƯNG
                                const Text(
                                  'Đặc điểm bất động sản',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1918),
                                    fontFamily: 'Georgia',
                                  ),
                                ),
                                const SizedBox(height: 16),

                                Row(
                                  children: [
                                    _buildFeatureCard(
                                      icon: Icons.bed_outlined,
                                      title: 'Phòng ngủ',
                                      value: '${property.bedroomCount ?? 0} phòng',
                                    ),
                                    const SizedBox(width: 12),
                                    _buildFeatureCard(
                                      icon: Icons.bathtub_outlined,
                                      title: 'Phòng tắm',
                                      value: '${property.bathroomCount ?? 0} phòng',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    _buildFeatureCard(
                                      icon: Icons.crop_free,
                                      title: 'Diện tích',
                                      value: property.area != null
                                          ? '${property.area!.toStringAsFixed(0)} m²'
                                          : 'N/A',
                                    ),
                                    const SizedBox(width: 12),
                                    _buildFeatureCard(
                                      icon: Icons.layers_outlined,
                                      title: 'Số tầng',
                                      value: property.floorCount != null
                                          ? '${property.floorCount} tầng'
                                          : 'N/A',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                const Divider(color: Color(0xFFE8E3DC)),
                                const SizedBox(height: 16),

                                // BẢNG THÔNG TIN CHI TIẾT
                                const Text(
                                  'Thông tin chi tiết',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1918),
                                    fontFamily: 'Georgia',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF4EEE6),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    children: [
                                      _buildInfoRow('Mã tin đăng', '#${property.id ?? '---'}'),
                                      _buildInfoRow('Loại giao dịch', property.typeId == 2 ? 'Cho thuê' : 'Cho bán'),
                                      _buildInfoRow('Hướng nhà', property.direction ?? 'Chưa cập nhật'),
                                      _buildInfoRow('Giấy tờ pháp lý', property.legal ?? 'Chưa cập nhật'),
                                      _buildInfoRow('Trạng thái', property.status ?? 'Đã đăng tin', isLast: true),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),
                                const Divider(color: Color(0xFFE8E3DC)),
                                const SizedBox(height: 16),

                                // MÔ TẢ CHI TIẾT
                                const Text(
                                  'Mô tả chi tiết',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1918),
                                    fontFamily: 'Georgia',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  property.description ??
                                      'Chưa có thông tin mô tả chi tiết cho bất động sản này.',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF78736D),
                                    fontFamily: 'Plus Jakarta Sans',
                                    height: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 100),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // 3. THANH HÀNH ĐỘNG 2 NÚT (LIÊN HỆ | VIEWING)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCFBFA),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // NÚT 1: GỌI ĐIỆN (có loading)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isCallLoading
                                    ? null
                                    : () => _makePhoneCall(property),
                                icon: _isCallLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF2E7D32),
                                        ),
                                      )
                                    : const Icon(Icons.phone,
                                        color: Color(0xFF2E7D32), size: 18),
                                label: Text(
                                  property.userPhone != null &&
                                          property.userPhone!.isNotEmpty
                                      ? property.userPhone!
                                      : 'Gọi điện',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF2E7D32),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16, horizontal: 8),
                                  side: const BorderSide(
                                      color: Color(0xFF2E7D32), width: 1.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // NÚT 2: VIEWING (HẸN XEM NHÀ) - KHÓA TUYỆT ĐỐI NẾU ĐÃ ĐẶT
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isViewingLoading
                                    ? null
                                    : () {
                                        if (_alreadyBookedViewing) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Bạn đã đặt lịch xem bất động sản này rồi! Đang chờ chủ nhà xác nhận.'),
                                              backgroundColor: Color(0xFFE65100),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        } else {
                                          _handleViewing(property);
                                        }
                                      },
                                icon: _isViewingLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Icon(
                                        _alreadyBookedViewing
                                            ? Icons.check_circle
                                            : Icons.calendar_month_outlined,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                label: Text(
                                  _alreadyBookedViewing ? 'Đã đặt lịch xem' : 'Hẹn xem nhà',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16, horizontal: 8),
                                  backgroundColor: _alreadyBookedViewing
                                      ? const Color(0xFF2E7D32)
                                      : const Color(0xFF945331),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 4. NÚT TRÒN MESSAGE (FAB góc dưới phải) - Hiển thị chấm đỏ & sáng lên khi Seller nhắn tin
                    Positioned(
                      bottom: 90,
                      right: 16,
                      child: GestureDetector(
                        onTap: () {
                          if (mounted) {
                            setState(() => _hasUnreadFromSeller = false);
                          }
                          _showChatBottomSheet(context, property);
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: _hasUnreadFromSeller
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFF945331),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (_hasUnreadFromSeller
                                            ? const Color(0xFFDC2626)
                                            : const Color(0xFF945331))
                                        .withValues(alpha: 0.5),
                                    blurRadius: _hasUnreadFromSeller ? 16 : 12,
                                    spreadRadius: _hasUnreadFromSeller ? 3 : 0,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.chat_bubble_outline,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            if (_hasUnreadFromSeller)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
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

  Widget _buildSellerCard(PropertyDTO property) {
    final sellerName = property.userFullname ?? 'Chủ bất động sản';
    final sellerPhone = property.userPhone ?? 'Chưa cập nhật SĐT';
    final sellerEmail = property.userEmail ?? 'Chưa cập nhật Email';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8E3DC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFF4EEE6),
            child: Text(
              sellerName.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF945331),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sellerName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1918),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$sellerPhone • $sellerEmail',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF78736D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF4EEE6),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF945331), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF78736D),
                      fontSize: 12,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Color(0xFF1A1918),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF78736D),
              fontSize: 14,
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1A1918),
              fontWeight: FontWeight.bold,
              fontSize: 14,
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
        ],
      ),
    );
  }
}
