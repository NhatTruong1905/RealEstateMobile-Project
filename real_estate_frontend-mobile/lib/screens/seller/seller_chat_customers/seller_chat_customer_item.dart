part of '../SellerChatCustomersScreen.dart';

extension SellerChatCustomerItem on _SellerChatCustomersScreenState {
  Widget _buildCustomerChatItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E3DC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFF4EEE6),
                child: Text(
                  item['name'].toString().substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF945331),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item['name'] ?? 'Khách hàng',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1A1918),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF1565C0,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '💬 Mới nhất',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF1565C0),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item['phone']} • ${item['latestTime'] ?? 'Mới đây'}',
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
          const SizedBox(height: 10),
          const Divider(color: Color(0xFFE8E3DC), height: 1),
          const SizedBox(height: 10),

          Text(
            'BĐS quan tâm: ${item['latestPropertyTitle'] ?? 'Bất động sản'}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1918),
            ),
          ),
          const SizedBox(height: 6),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF4EEE6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline,
                  size: 16,
                  color: Color(0xFF945331),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item['latestMessage'] ?? 'Nội dung tin nhắn',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1A1918),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final dummyProperty = PropertyDTO(
                      id: item['latestPropertyId'] ?? 1,
                      title:
                          item['latestPropertyTitle'] ??
                          'Bất động sản quan tâm',
                      price: 2500000000,
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          property: dummyProperty,
                          receiverId: item['senderId'],
                          receiverName: item['name'],
                          isSeller: true,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.chat,
                    color: Color(0xFF945331),
                    size: 16,
                  ),
                  label: const Text(
                    'Trò chuyện',
                    style: TextStyle(
                      color: Color(0xFF945331),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: const BorderSide(color: Color(0xFF945331)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (item['hasActiveViewing'] == true) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final propId =
                          (item['latestPropertyId'] ?? item['propertyId'] ?? 1)
                              as int;
                      final customerId =
                          (item['senderId'] ?? item['userId'] ?? 0) as int;
                      try {
                        await markInteractionCompleted(
                          propertyId: propId,
                          senderId: customerId,
                          receiverId: _chatService.currentUserId ?? 0,
                          interactionTypeId: 2,
                          interactionTypeCode: 'MESSAGE',
                          completeBoth: true,
                        );
                        _loadChatCustomers();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Đã cập nhật hoàn tất lượt xem nhà cho khách hàng này!',
                              ),
                              backgroundColor: Color(0xFF2E7D32),
                            ),
                          );
                        }
                      } catch (e) {
                        debugPrint('Lỗi hoàn tất xem nhà: $e');
                      }
                    },
                    icon: const Icon(
                      Icons.task_alt_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    label: const Text(
                      'Đã xem nhà xong',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
