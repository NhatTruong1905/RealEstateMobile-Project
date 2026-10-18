import 'package:flutter/material.dart';
import 'package:real_estate_frontend/dto/PropertyDTO.dart';
import 'package:real_estate_frontend/mixin/api/APIPropertyMixin.dart';
import 'package:real_estate_frontend/screens/seller/PostProperty.dart';
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
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchMyProperties();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchMyProperties() async {
    setState(() => _isLoading = true);
    List<PropertyDTO> list = await fetchMyProperties();
    if (mounted) {
      setState(() {
        _myProperties = list;
        _isLoading = false;
      });
    }
  }

  List<PropertyDTO> get _filteredProperties {
    List<PropertyDTO> list = _myProperties;

    if (_activeTab == 'Đang hiển thị') {
      list = list.where((p) {
        final s = (p.status ?? '').toLowerCase();
        return s == 'đang mở bán' || s == 'published' || s == 'đang hiển thị';
      }).toList();
    } else if (_activeTab == 'Chờ duyệt') {
      list = list.where((p) {
        final s = (p.status ?? '').toLowerCase();
        return s == 'chờ duyệt' || s == 'pending';
      }).toList();
    } else if (_activeTab == 'Đã xóa' || _activeTab == 'Đã ẩn') {
      list = list.where((p) {
        final s = (p.status ?? '').toLowerCase();
        return s == 'đã xóa' || s == 'deleted' || s == 'từ chối' || s == 'rejected' || s == 'đã ẩn';
      }).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((p) {
        final title = (p.title ?? '').toLowerCase();
        final address = (p.address ?? '').toLowerCase();
        return title.contains(q) || address.contains(q);
      }).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
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
            icon: const Icon(Icons.add_circle_outline,
                color: Color(0xFF945331), size: 28),
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
                hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)),
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
                            const Icon(Icons.article_outlined,
                                size: 60, color: Color(0xFF78736D)),
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

  Widget _buildStatusTag(String? statusStr) {
    final s = (statusStr ?? '').toLowerCase();
    Color color = const Color(0xFF2E7D32);
    String label = statusStr ?? 'Đang hiển thị';

    if (s == 'chờ duyệt' || s == 'pending') {
      color = const Color(0xFFE65100);
      label = 'Chờ duyệt';
    } else if (s == 'từ chối' || s == 'rejected' || s == 'đã xóa' || s == 'deleted' || s == 'đã ẩn') {
      color = const Color(0xFFC62828);
      if (s == 'từ chối' || s == 'rejected') {
        label = 'Từ chối';
      } else {
        label = 'Đã xóa';
      }
    } else if (s == 'published' || s == 'đang mở bán') {
      color = const Color(0xFF2E7D32);
      label = 'Đang hiển thị';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
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
                        _buildStatusTag(item.status),
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
                onPressed: () async {
                  final res = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostPropertyScreen(
                        propertyId: item.id,
                        property: item,
                      ),
                    ),
                  );
                  if (res == true) {
                    _fetchMyProperties();
                  }
                },
                icon: const Icon(Icons.edit_outlined,
                    size: 18, color: Color(0xFF1565C0)),
                label: const Text('Sửa tin',
                    style: TextStyle(color: Color(0xFF1565C0))),
              ),
              TextButton.icon(
                onPressed: () => _confirmAndDeleteProperty(item),
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

  Future<void> _confirmAndDeleteProperty(PropertyDTO item) async {
    if (item.id == null) return;

    final s = (item.status ?? '').toLowerCase();
    final isAlreadyDeleted = s == 'đã xóa' ||
        s == 'deleted' ||
        s == 'từ chối' ||
        s == 'rejected' ||
        s == 'đã ẩn';

    if (isAlreadyDeleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tin đăng này đã ở trạng thái đã xóa.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Xác nhận xóa',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            fontFamily: 'Georgia',
          ),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa tin "${item.title ?? ''}" không?',
          style: const TextStyle(fontSize: 14, color: Color(0xFF1A1918)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF78736D))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await deleteProperty(item.id!);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xóa tin đăng thành công!'),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _fetchMyProperties();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xóa tin đăng thất bại. Vui lòng thử lại!'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
