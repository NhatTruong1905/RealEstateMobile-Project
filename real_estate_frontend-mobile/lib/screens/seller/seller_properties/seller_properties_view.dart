// ignore_for_file: invalid_use_of_protected_member

part of '../SellerProperties.dart';

extension SellerPropertiesView on _SellerPropertiesScreenState {
  Widget _buildPage(BuildContext context) {
    final displayList = _filteredProperties;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFBFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCFBFA),
        elevation: 0,
        title: const Text(
          'Quản lý Tin đăng',
          style: TextStyle(
            color: Color(0xFF1A1918),
            fontWeight: FontWeight.bold,
            fontFamily: 'Georgia',
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: Color(0xFF945331),
              size: 28,
            ),
            onPressed: widget.onPostNewProperty,
          ),
        ],
      ),
      body: Column(
        children: [
          // Ô TÌM KIẾM THEO TIÊU ĐỀ
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: 'Tìm kiếm tin đăng theo tiêu đề...',
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9E9E9E),
                ),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF945331)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Color(0xFF78736D)),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                filled: true,
                fillColor: const Color(0xFFF4EEE6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // BỘ LỌC TRẠNG THÁI BÀI ĐĂNG
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                _buildStatusChip('Tất cả'),
                _buildStatusChip('Đang hiển thị'),
                _buildStatusChip('Chờ duyệt'),
                _buildStatusChip('Đã xóa'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // DANH SÁCH BÀI ĐĂNG
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF945331)),
                  )
                : displayList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.article_outlined,
                          size: 60,
                          color: Color(0xFF78736D),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _myProperties.isEmpty
                              ? 'Bạn chưa có tin đăng nào'
                              : _searchQuery.isNotEmpty
                              ? 'Không tìm thấy tin đăng khớp với "$_searchQuery"'
                              : 'Không có tin đăng nào ở mục này',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF78736D),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: widget.onPostNewProperty,
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text(
                            'Đăng tin ngay',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF945331),
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchMyProperties,
                    color: const Color(0xFF945331),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      itemCount: displayList.length,
                      itemBuilder: (context, index) {
                        final item = displayList[index];
                        return _buildPropertyPostItem(item);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
