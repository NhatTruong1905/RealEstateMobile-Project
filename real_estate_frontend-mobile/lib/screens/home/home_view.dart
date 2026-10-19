// ignore_for_file: invalid_use_of_protected_member

part of '../Home.dart';

extension HomeView on _HomeScreenState {
  Widget _buildPage(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFBFA),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: _showScrollToTop ? 1.0 : 0.0,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 250),
              scale: _showScrollToTop ? 1.0 : 0.0,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: _showScrollToTop ? _scrollToTop : null,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.45),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_upward_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),
          FloatingActionButton(
            heroTag: 'homeAiAssistant',
            onPressed: () => RagChatModal.show(context),
            backgroundColor: const Color(0xFF1E293B),
            elevation: 6,
            shape: const CircleBorder(),
            tooltip: 'AI Gợi ý Tòa nhà',
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF334155)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.support_agent_rounded,
                    color: Color(0xFFFFD700),
                    size: 28,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      radius: 3.5,
                      backgroundColor: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF945331)),
            )
          : SafeArea(
              child: RefreshIndicator(
                color: const Color(0xFF945331),
                onRefresh: _refreshData,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 24,
                          right: 24,
                          top: 24,
                          bottom: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Vị trí hiện tại',
                                    style: TextStyle(
                                      color: Color(0xFF78736D),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Plus Jakarta Sans',
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: const [
                                      Icon(
                                        Icons.location_on_outlined,
                                        color: Color(0xFF945331),
                                        size: 18,
                                      ),
                                      SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          'TP. Hồ Chí Minh',
                                          style: TextStyle(
                                            color: Color(0xFF1A1918),
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Georgia',
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ValueListenableBuilder<bool>(
                              valueListenable:
                                  ChatService.hasUnreadNotification,
                              builder: (context, hasUnread, child) {
                                return InkWell(
                                  onTap: () {
                                    ChatService.hasUnreadNotification.value =
                                        false;
                                  },
                                  borderRadius: BorderRadius.circular(24),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (hasUnread) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFDC2626),
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
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
                                                Icons
                                                    .chat_bubble_outline_rounded,
                                                color: Colors.white,
                                                size: 11,
                                              ),
                                              SizedBox(width: 3),
                                              Text(
                                                'Tin nhắn mới',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                      Stack(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFF4EEE6),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.notifications_none_outlined,
                                              color: Color(0xFF1A1918),
                                              size: 20,
                                            ),
                                          ),
                                          if (hasUnread)
                                            Positioned(
                                              top: 6,
                                              right: 8,
                                              child: Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFFDC2626),
                                                  shape: BoxShape.circle,
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
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 56,
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  right: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4EEE6),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _searchController,
                                        onSubmitted: (value) {
                                          _filterRequest.title =
                                              value.trim().isNotEmpty
                                              ? value.trim()
                                              : null;
                                          _loadData(isReset: true);
                                        },
                                        textInputAction: TextInputAction.search,
                                        style: const TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          fontSize: 15,
                                        ),
                                        decoration: const InputDecoration(
                                          hintText: 'Tìm kiếm bất động sản...',
                                          border: InputBorder.none,
                                          hintStyle: TextStyle(
                                            color: Color(0xFF78736D),
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (_searchController.text.isNotEmpty)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.cancel,
                                          size: 18,
                                          color: Color(0xFF78736D),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _searchController.clear();
                                            _filterRequest.title = null;
                                          });
                                          _loadData(isReset: true);
                                        },
                                      ),
                                    GestureDetector(
                                      onTap: () {
                                        String val = _searchController.text
                                            .trim();
                                        _filterRequest.title = val.isNotEmpty
                                            ? val
                                            : null;
                                        _loadData(isReset: true);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF945331),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.search,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: _showFilterBottomSheet,
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF945331),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Icon(
                                  Icons.tune_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const PropertyListScreen(
                                            pageTitle: 'Bất động sản Mua Bán',
                                            initialTypeId: 1,
                                          ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF4EEE6),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFFE8E3DC),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Icons.house_outlined,
                                        color: Color(0xFF945331),
                                        size: 22,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Cho Bán',
                                        style: TextStyle(
                                          color: Color(0xFF1A1918),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          fontFamily: 'Plus Jakarta Sans',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const PropertyListScreen(
                                            pageTitle: 'Bất động sản Cho Thuê',
                                            initialTypeId: 2,
                                          ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF4EEE6),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFFE8E3DC),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Icons.key_outlined,
                                        color: Color(0xFF945331),
                                        size: 22,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Cho Thuê',
                                        style: TextStyle(
                                          color: Color(0xFF1A1918),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          fontFamily: 'Plus Jakarta Sans',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),
                      SizedBox(
                        height: 46,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final cat = categories[index];
                            final isSelected = activeCategory == cat;
                            return Container(
                              margin: const EdgeInsets.only(right: 10),
                              child: ChoiceChip(
                                label: Text(cat),
                                selected: isSelected,
                                selectedColor: const Color(0xFF945331),
                                backgroundColor: const Color(0xFFF4EEE6),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF78736D),
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide.none,
                                ),
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      activeCategory = cat;
                                      if (cat == "Tất cả") {
                                        _filterRequest.title = null;
                                      } else {
                                        _filterRequest.title = cat;
                                      }
                                    });
                                    _loadData(isReset: true);
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),

                      if (globalProperties.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 24,
                            right: 24,
                            top: 24,
                            bottom: 16,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Nổi bật',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1918),
                                  fontFamily: 'Georgia',
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const PropertyListScreen(
                                            pageTitle: 'Tất cả Bất động sản',
                                            initialTypeId: null,
                                          ),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Xem tất cả',
                                  style: TextStyle(
                                    color: Color(0xFF945331),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Plus Jakarta Sans',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (globalProperties.isNotEmpty)
                        SizedBox(
                          height: 385,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: globalProperties.length > 5
                                ? 5
                                : globalProperties.length,
                            itemBuilder: (context, index) {
                              final property = globalProperties[index];
                              return _buildHorizontalCard(property);
                            },
                          ),
                        ),

                      Padding(
                        padding: const EdgeInsets.only(
                          left: 24,
                          top: 12,
                          bottom: 16,
                          right: 24,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Đề xuất cho bạn',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1918),
                                fontFamily: 'Georgia',
                              ),
                            ),
                            if (_totalItems > 0)
                              Text(
                                '$_totalItems kết quả',
                                style: const TextStyle(
                                  color: Color(0xFF78736D),
                                  fontSize: 13,
                                  fontFamily: 'Plus Jakarta Sans',
                                ),
                              ),
                          ],
                        ),
                      ),

                      if (globalProperties.isEmpty && !_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text(
                              'Không tìm thấy bất động sản phù hợp',
                              style: TextStyle(
                                color: Color(0xFF78736D),
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),

                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: globalProperties.length,
                        itemBuilder: (context, index) {
                          final property = globalProperties[index];
                          return _buildVerticalCard(property);
                        },
                      ),

                      if (_isLoadingMore)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF945331),
                            ),
                          ),
                        ),

                      if (!_hasMore && globalProperties.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'Đã hiển thị tất cả bất động sản',
                              style: TextStyle(
                                color: Color(0xFF78736D),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
