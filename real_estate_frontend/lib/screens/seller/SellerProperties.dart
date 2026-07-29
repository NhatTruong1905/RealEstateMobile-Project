import 'package:flutter/material.dart';
import 'package:real_estate_frontend/dto/PropertyDTO.dart';
import 'package:real_estate_frontend/mixin/api/APIPropertyMixin.dart';
import 'package:real_estate_frontend/utils/PriceFormatter.dart';

class SellerPropertiesScreen extends StatefulWidget {
  final VoidCallback onPostNewProperty;

  const SellerPropertiesScreen({
    super.key,
    required this.onPostNewProperty,
  });

  @override
  State<SellerPropertiesScreen> createState() => _SellerPropertiesScreenState();
}

class _SellerPropertiesScreenState extends State<SellerPropertiesScreen>
    with ApiPropertyMixin {
  bool _isLoading = true;
  List<PropertyDTO> _myProperties = [];
  String _activeTab = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _fetchMyProperties();
  }

  Future<void> _fetchMyProperties() async {
    setState(() => _isLoading = true);
    List<PropertyDTO> list = await fetchProperties();
    if (mounted) {
      setState(() {
        _myProperties = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
            icon: const Icon(Icons.add_circle_outline,
                color: Color(0xFF945331), size: 28),
            onPressed: widget.onPostNewProperty,
          ),
        ],
      ),
      body: Column(
        children: [
          // BỘ LỌC TRẠNG THÁI BÀI ĐĂNG
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                _buildStatusChip('Tất cả'),
                _buildStatusChip('Đang hiển thị'),
                _buildStatusChip('Chờ duyệt'),
                _buildStatusChip('Đã ẩn'),
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
                : _myProperties.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.article_outlined,
                                size: 60, color: Color(0xFF78736D)),
                            const SizedBox(height: 12),
                            const Text(
                              'Bạn chưa có tin đăng nào',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF78736D),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: widget.onPostNewProperty,
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: const Text('Đăng tin ngay',
                                  style: TextStyle(color: Colors.white)),
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
                              horizontal: 20, vertical: 12),
                          itemCount: _myProperties.length,
                          itemBuilder: (context, index) {
                            final item = _myProperties[index];
                            return _buildPropertyPostItem(item);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label) {
    final isSelected = _activeTab == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: const Color(0xFF945331),
        backgroundColor: const Color(0xFFF4EEE6),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF78736D),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide.none,
        ),
        onSelected: (selected) {
          if (selected) {
            setState(() => _activeTab = label);
          }
        },
      ),
    );
  }

  Widget _buildPropertyPostItem(PropertyDTO item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
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
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: (item.image != null && item.image!.isNotEmpty)
                    ? Image.network(
                        item.image!,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 90,
                          height: 90,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.home),
                        ),
                      )
                    : Container(
                        width: 90,
                        height: 90,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.home),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Đang hiển thị',
                            style: TextStyle(
                              color: Color(0xFF2E7D32),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '#${item.id ?? '---'}',
                          style: const TextStyle(
                            color: Color(0xFF78736D),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.title ?? 'Chưa có tiêu đề',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1A1918),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatPropertyPrice(item.price),
                      style: const TextStyle(
                        color: Color(0xFF945331),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'Georgia',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFE8E3DC), height: 1),
          const SizedBox(height: 10),

          // NÚT HÀNH ĐỘNG THAO TÁC BÀI ĐĂNG
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tính năng chỉnh sửa bài đăng!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.edit_outlined,
                    size: 18, color: Color(0xFF1565C0)),
                label: const Text('Sửa tin',
                    style: TextStyle(color: Color(0xFF1565C0))),
              ),
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã ẩn tin đăng khỏi trang tìm kiếm'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.visibility_off_outlined,
                    size: 18, color: Color(0xFF78736D)),
                label: const Text('Ẩn tin',
                    style: TextStyle(color: Color(0xFF78736D))),
              ),
              TextButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Xóa tin đăng thành công!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: Colors.redAccent),
                label: const Text('Xóa',
                    style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
