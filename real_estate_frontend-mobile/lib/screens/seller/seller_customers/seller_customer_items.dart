part of '../SellerCustomers.dart';

extension SellerCustomerItems on _SellerCustomersScreenState {
  Widget _buildCustomerItem(Map<String, dynamic> customer) {
    final historyList = (customer['history'] as List?) ?? [];
    final int callCount = customer['callCount'] ?? 0;
    final int messageCount = customer['messageCount'] ?? 0;
    final int viewingCount = customer['viewingCount'] ?? 0;
    final int totalCount = historyList.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFF4EEE6),
                child: Text(
                  customer['name'].toString().substring(0, 1).toUpperCase(),
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
                      customer['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1A1918),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${customer['phone']} • ${customer['latestTime'] ?? 'Mới đây'}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF78736D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F6F0),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8E3DC)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatBadge(
                  icon: Icons.phone_callback,
                  color: const Color(0xFFD32F2F),
                  label: 'Cuộc gọi',
                  count: callCount,
                ),
                Container(width: 1, height: 22, color: const Color(0xFFE8E3DC)),
                _buildStatBadge(
                  icon: Icons.chat_bubble_outline,
                  color: const Color(0xFF1565C0),
                  label: 'Tin nhắn',
                  count: messageCount,
                ),
                Container(width: 1, height: 22, color: const Color(0xFFE8E3DC)),
                _buildStatBadge(
                  icon: Icons.calendar_today,
                  color: const Color(0xFF2E7D32),
                  label: 'Hẹn xem',
                  count: viewingCount,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (customer['latestPropertyTitle'] != null) ...[
            const Text(
              'BĐS quan tâm:',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF78736D),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              customer['latestPropertyTitle'],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1918),
              ),
            ),
            const SizedBox(height: 8),
          ],

          if (customer['latestMessage'] != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4EEE6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.format_quote,
                    color: Color(0xFF945331),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      customer['latestMessage'],
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1A1918),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 10),

          InkWell(
            onTap: () => _showInteractionHistoryBottomSheet(context, customer),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF945331).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.history, size: 16, color: Color(0xFF945331)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Xem toàn bộ lịch sử tương tác ($totalCount lần)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF945331),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: Color(0xFF945331),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _makePhoneCall(customer['phone']);
                  },
                  icon: const Icon(Icons.phone, color: Colors.white, size: 15),
                  label: const Text(
                    'Gọi điện',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final dummyProperty = PropertyDTO(
                      id: customer['latestPropertyId'] ?? 1,
                      title:
                          customer['latestPropertyTitle'] ??
                          'Bất động sản quan tâm',
                      price: 2500000000,
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          property: dummyProperty,
                          receiverId:
                              customer['senderId'] ?? customer['userId'],
                          receiverName: customer['name'],
                          isSeller: true,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.chat_bubble_outline,
                    color: Color(0xFF945331),
                    size: 15,
                  ),
                  label: const Text(
                    'Nhắn tin',
                    style: TextStyle(
                      color: Color(0xFF945331),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 4,
                    ),
                    side: const BorderSide(color: Color(0xFF945331)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (customer['hasActiveViewing'] == true) ...[
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final propId = (customer['latestPropertyId'] ?? 1) as int;
                      final customerId =
                          (customer['senderId'] ?? customer['userId'] ?? 0)
                              as int;
                      try {
                        await markInteractionCompleted(
                          propertyId: propId,
                          senderId: customerId,
                          receiverId: _chatService.currentUserId ?? 0,
                          interactionTypeId: 2,
                          interactionTypeCode: 'MESSAGE',
                          completeBoth: true,
                        );
                        _loadInteractions();
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
                      size: 15,
                    ),
                    label: const Text(
                      'Đã xem xong',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 4,
                      ),
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

  Widget _buildStatBadge({
    required IconData icon,
    required Color color,
    required String label,
    required int count,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          '$count $label',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: count > 0
                ? const Color(0xFF1A1918)
                : const Color(0xFF9E9E9E),
          ),
        ),
      ],
    );
  }
}
