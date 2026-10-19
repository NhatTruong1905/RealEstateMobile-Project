part of '../SellerCustomers.dart';

extension SellerCustomerHistory on _SellerCustomersScreenState {
  void _showInteractionHistoryBottomSheet(
    BuildContext context,
    Map<String, dynamic> customer,
  ) {
    final historyList =
        (customer['history'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 520,
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
                  const SizedBox(width: 12),
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
                        Text(
                          '${customer['phone']} • Lịch sử ${historyList.length} lần tương tác',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF78736D),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: Color(0xFFE8E3DC)),
              const SizedBox(height: 8),
              const Text(
                'Lịch sử chi tiết (Cuộc gọi, Tin nhắn & Hẹn xem nhà):',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1918),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: historyList.length,
                  itemBuilder: (context, index) {
                    final h = historyList[index];
                    final code = h['code'] ?? '';
                    final IconData iconData = code == 'CALL'
                        ? Icons.phone_callback
                        : (code == 'VIEWING'
                              ? Icons.calendar_today
                              : Icons.chat_bubble_outline);
                    final Color iconColor = code == 'CALL'
                        ? const Color(0xFFD32F2F)
                        : (code == 'VIEWING'
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFF1565C0));
                    final String typeLabel = code == 'CALL'
                        ? 'Cuộc gọi'
                        : (code == 'VIEWING'
                              ? 'Lịch hẹn xem nhà'
                              : 'Tin nhắn / Tư vấn');

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F6F0),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE8E3DC)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: iconColor.withValues(alpha: 0.15),
                            child: Icon(iconData, size: 18, color: iconColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      typeLabel,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: iconColor,
                                      ),
                                    ),
                                    Text(
                                      h['time'] ?? 'Mới đây',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF78736D),
                                      ),
                                    ),
                                  ],
                                ),
                                if (h['propertyTitle'] != null &&
                                    h['propertyTitle']
                                        .toString()
                                        .isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'BĐS: ${h['propertyTitle']}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A1918),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  h['message'] ?? 'Tương tác',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF4A4A4A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
