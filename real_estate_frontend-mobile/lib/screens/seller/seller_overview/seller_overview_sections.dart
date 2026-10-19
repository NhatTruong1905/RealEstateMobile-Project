part of '../SellerOverview.dart';

extension SellerOverviewSections on _SellerOverviewScreenState {
  Widget _buildCustomerSection() {
    if (_isLoadingInteractions) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF945331)),
        ),
      );
    }

    final filteredItems = _filteredCustomerInteractions;

    if (filteredItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8E3DC)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.people_outline_rounded,
              size: 40,
              color: Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 10),
            const Text(
              'Chưa có khách hàng liên hệ mới',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF1A1918),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Các lượt đăng ký tư vấn hoặc hẹn xem nhà từ khách hàng sẽ hiển thị tại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF78736D)),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: widget.onPostNewProperty,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF945331),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Đăng tin để tiếp cận khách hàng',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    final displayItems = filteredItems.take(4).toList();

    return Column(
      children: displayItems.map((item) {
        final senderObj = item['sender'] is Map ? item['sender'] as Map : null;
        final receiverObj = item['receiver'] is Map
            ? item['receiver'] as Map
            : null;
        final propObj = item['property'] is Map
            ? item['property'] as Map
            : null;

        final senderId = item['senderId'] ?? senderObj?['id'];
        final sUser = (item['senderUsername'] ?? senderObj?['username'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
        final sName =
            (item['senderName'] ??
                    item['senderFullname'] ??
                    senderObj?['fullname'] ??
                    '')
                .toString()
                .trim()
                .toLowerCase();

        final myId = _userProfile?.id;
        final myFullname = _userProfile?.fullname?.trim().toLowerCase();
        final myUsername = _userProfile?.username?.trim().toLowerCase();

        final isSenderMe =
            (myId != null && senderId == myId) ||
            (myFullname != null &&
                myFullname.isNotEmpty &&
                sName == myFullname) ||
            (myUsername != null &&
                myUsername.isNotEmpty &&
                sUser == myUsername);

        final String name;
        final String phone;

        if (isSenderMe) {
          name =
              (item['receiverName'] ??
                      item['receiverFullname'] ??
                      item['receiverUsername'] ??
                      receiverObj?['fullname'] ??
                      receiverObj?['username'] ??
                      'Khách hàng quan tâm')
                  .toString();

          phone =
              (item['receiverPhone'] ??
                      receiverObj?['phone'] ??
                      receiverObj?['email'] ??
                      'Chưa cập nhật SĐT')
                  .toString();
        } else {
          name =
              (item['senderName'] ??
                      item['senderFullname'] ??
                      item['senderUsername'] ??
                      senderObj?['fullname'] ??
                      senderObj?['username'] ??
                      'Khách hàng quan tâm')
                  .toString();

          phone =
              (item['senderPhone'] ??
                      senderObj?['phone'] ??
                      senderObj?['email'] ??
                      'Chưa cập nhật SĐT')
                  .toString();
        }

        final propertyTitle =
            item['propertyTitle'] ??
            propObj?['title'] ??
            'Bất động sản quan tâm';

        final code =
            (item['interactionTypeCode'] ?? item['code'] ?? item['type'] ?? '')
                .toString()
                .toUpperCase();

        String status = 'Yêu cầu tư vấn';
        Color statusColor = const Color(0xFFE65100);

        if (code == 'VIEWING') {
          status = 'Hẹn xem nhà';
          statusColor = const Color(0xFF2E7D32);
        } else if (code == 'MESSAGE') {
          status = 'Gửi tin nhắn';
          statusColor = const Color(0xFF1565C0);
        } else if (code == 'COMPLETED') {
          status = 'Đã hoàn thành';
          statusColor = const Color(0xFF64748B);
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildRecentCustomerCard(
            name: name,
            phone: phone,
            propertyTitle: propertyTitle,
            time: 'Vừa xong',
            status: status,
            statusColor: statusColor,
            onTap: widget.onManageCustomers,
          ),
        );
      }).toList(),
    );
  }
}
