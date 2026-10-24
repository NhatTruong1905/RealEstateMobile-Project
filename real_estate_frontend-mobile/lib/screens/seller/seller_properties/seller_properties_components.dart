// ignore_for_file: invalid_use_of_protected_member

part of '../SellerProperties.dart';

extension SellerPropertiesComponents on _SellerPropertiesScreenState {
  Widget _buildStatusTag(String? statusStr) {
    const labels = {
      'Chờ duyệt': 'Đang chờ duyệt',
      'Đang mở bán': 'Đã được duyệt',
      'Từ chối': 'Bị từ chối',
      'Đã xóa': 'Đã xóa',
    };
    final label = labels[statusStr] ?? 'Chưa rõ';
    final color = statusStr == 'Đang mở bán'
        ? const Color(0xFF2E7D32)
        : statusStr == 'Chờ duyệt'
        ? const Color(0xFFE65100)
        : const Color(0xFFC62828);

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
          if (item.createdDate != null)
            Text('Ngày đăng: ${item.createdDate!.toLocal()}'),
          if (item.status == 'Từ chối' && item.rejectionReason != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Lý do từ chối: ${item.rejectionReason}'),
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
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: Color(0xFF1565C0),
                ),
                label: const Text(
                  'Sửa tin',
                  style: TextStyle(color: Color(0xFF1565C0)),
                ),
              ),
              TextButton.icon(
                onPressed: () => _confirmAndDeleteProperty(item),
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.redAccent,
                ),
                label: const Text(
                  'Xóa',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndDeleteProperty(PropertyDTO item) async {
    if (item.id == null) return;

    final isAlreadyDeleted = item.status == 'Đã xóa';

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
            child: const Text(
              'Hủy',
              style: TextStyle(color: Color(0xFF78736D)),
            ),
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
