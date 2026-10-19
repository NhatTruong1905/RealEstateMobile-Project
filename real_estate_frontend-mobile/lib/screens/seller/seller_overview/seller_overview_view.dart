part of '../SellerOverview.dart';

extension SellerOverviewView on _SellerOverviewScreenState {
  Widget _buildPage(BuildContext context) {
    final userName =
        _userProfile?.fullname ?? _userProfile?.username ?? 'Chủ tin đăng';
    final publishedCount = _myProperties.where((p) {
      final s = (p.status ?? '').toLowerCase();
      return s == 'đang mở bán' || s == 'published' || s == 'đang hiển thị';
    }).length;
    final uniqueCustomers = _uniqueCustomerCount;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFBFA),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF945331),
          onRefresh: _loadAllData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Xin chào, $userName!',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1918),
                              fontFamily: 'Georgia',
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Tổng quan hoạt động kinh doanh bất động sản',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF78736D),
                              fontFamily: 'Plus Jakarta Sans',
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        ValueListenableBuilder<bool>(
                          valueListenable: ChatService.hasUnreadNotification,
                          builder: (context, hasUnread, child) {
                            return InkWell(
                              onTap: () {
                                ChatService.hasUnreadNotification.value = false;
                                widget.onManageCustomers();
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (hasUnread) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDC2626),
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x29DC2626),
                                            blurRadius: 6,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.chat_bubble_outline_rounded,
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Tin nhắn mới',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.notifications_none_outlined,
                                          color: Color(0xFF1A1918),
                                          size: 26,
                                        ),
                                        onPressed: () {
                                          ChatService
                                                  .hasUnreadNotification
                                                  .value =
                                              false;
                                          widget.onManageCustomers();
                                        },
                                      ),
                                      if (hasUnread)
                                        Positioned(
                                          top: 10,
                                          right: 10,
                                          child: Container(
                                            width: 9,
                                            height: 9,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFDC2626),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 1.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 6),
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: const Color(0xFFF4EEE6),
                          backgroundImage:
                              (_userProfile?.avatar != null &&
                                  _userProfile!.avatar!.isNotEmpty)
                              ? NetworkImage(_userProfile!.avatar!)
                              : null,
                          child:
                              (_userProfile?.avatar == null ||
                                  _userProfile!.avatar!.isEmpty)
                              ? const Icon(
                                  Icons.person,
                                  color: Color(0xFF945331),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        icon: Icons.article_outlined,
                        title: 'Tổng bài đăng',
                        value: _isLoadingProperties
                            ? '...'
                            : '${_myProperties.length}',
                        subtitle: _isLoadingProperties
                            ? 'Đang tải...'
                            : '$publishedCount đang hiển thị',
                        color: const Color(0xFF945331),
                        onTap: widget.onManageProperties,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        icon: Icons.people_alt_outlined,
                        title: 'Khách liên hệ',
                        value: _isLoadingInteractions
                            ? '...'
                            : '$uniqueCustomers',
                        subtitle: _isLoadingInteractions
                            ? 'Đang tải...'
                            : (uniqueCustomers == 0
                                  ? 'Chưa có khách mới'
                                  : '$uniqueCustomers khách hàng'),
                        color: const Color(0xFF2E7D32),
                        onTap: widget.onManageCustomers,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                const Text(
                  'Thao tác nhanh',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1918),
                    fontFamily: 'Georgia',
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: widget.onPostNewProperty,
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: const Text(
                          'Đăng tin mới',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFF945331),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onManageProperties,
                        icon: const Icon(
                          Icons.list_alt,
                          color: Color(0xFF1A1918),
                          size: 20,
                        ),
                        label: const Text(
                          'Quản lý bài',
                          style: TextStyle(
                            color: Color(0xFF1A1918),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFE8E3DC)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Khách hàng mới liên hệ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1918),
                        fontFamily: 'Georgia',
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onManageCustomers,
                      child: const Text(
                        'Xem tất cả',
                        style: TextStyle(
                          color: Color(0xFF945331),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                _buildCustomerSection(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
