// ignore_for_file: invalid_use_of_protected_member

part of '../PropertyDetail.dart';

extension PropertyDetailView on _PropertyDetailScreenState {
  Widget _buildPage(BuildContext context) {
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
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Color(0xFF1A1918),
                  ),
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
                    SliverAppBar(
                      expandedHeight: 320,
                      pinned: true,
                      backgroundColor: const Color(0xFF945331),
                      leading: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CircleAvatar(
                          backgroundColor: Colors.black.withValues(alpha: 0.4),
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size: 18,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                      actions: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CircleAvatar(
                            backgroundColor: Colors.black.withValues(
                              alpha: 0.4,
                            ),
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
                        background: _buildPropertyImageHeader(property),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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

                            _buildSellerCard(property),
                            const SizedBox(height: 24),
                            const Divider(color: Color(0xFFE8E3DC)),
                            const SizedBox(height: 16),

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
                                  _buildInfoRow(
                                    'Mã tin đăng',
                                    '#${property.id ?? '---'}',
                                  ),
                                  _buildInfoRow(
                                    'Loại giao dịch',
                                    property.typeId == 2
                                        ? 'Cho thuê'
                                        : 'Cho bán',
                                  ),
                                  _buildInfoRow(
                                    'Hướng nhà',
                                    property.direction ?? 'Chưa cập nhật',
                                  ),
                                  _buildInfoRow(
                                    'Giấy tờ pháp lý',
                                    property.legal ?? 'Chưa cập nhật',
                                  ),
                                  _buildInfoRow(
                                    'Trạng thái',
                                    property.status ?? 'Đã đăng tin',
                                    isLast: true,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),
                            const Divider(color: Color(0xFFE8E3DC)),
                            const SizedBox(height: 16),

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

                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
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
                                : const Icon(
                                    Icons.phone,
                                    color: Color(0xFF2E7D32),
                                    size: 18,
                                  ),
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
                                vertical: 16,
                                horizontal: 8,
                              ),
                              side: const BorderSide(
                                color: Color(0xFF2E7D32),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isViewingLoading
                                ? null
                                : () {
                                    if (_alreadyBookedViewing) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Bạn đã đặt lịch xem bất động sản này rồi! Đang chờ chủ nhà xác nhận.',
                                          ),
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
                              _alreadyBookedViewing
                                  ? 'Đã đặt lịch xem'
                                  : 'Hẹn xem nhà',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 8,
                              ),
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
                                color:
                                    (_hasUnreadFromSeller
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
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
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
}
