// ignore_for_file: invalid_use_of_protected_member

part of '../PropertyList.dart';

extension PropertyListFilter on _PropertyListScreenState {
  void _showFilterBottomSheet() {
    final titleController = TextEditingController(
      text: _filterRequest.title ?? '',
    );
    final addressController = TextEditingController(
      text: _filterRequest.address ?? '',
    );
    final fromPriceController = TextEditingController(
      text: _filterRequest.fromPrice != null
          ? _filterRequest.fromPrice!.toStringAsFixed(0)
          : '',
    );
    final toPriceController = TextEditingController(
      text: _filterRequest.toPrice != null
          ? _filterRequest.toPrice!.toStringAsFixed(0)
          : '',
    );
    final areaController = TextEditingController(
      text: _filterRequest.area != null
          ? _filterRequest.area!.toStringAsFixed(0)
          : '',
    );
    final floorController = TextEditingController(
      text: _filterRequest.floorCount != null
          ? _filterRequest.floorCount!.toString()
          : '',
    );

    int? tempBedroom = _filterRequest.bedroomCount;
    int? tempBathroom = _filterRequest.bathroomCount;
    String? tempDirection = _filterRequest.direction;
    String? tempLegal = _filterRequest.legal;

    final List<String> directions = [
      'Đông',
      'Tây',
      'Nam',
      'Bắc',
      'Đông Nam',
      'Đông Bắc',
      'Tây Nam',
      'Tây Bắc',
    ];

    final List<String> legals = [
      'Sổ hồng',
      'Sổ đỏ',
      'Hợp đồng mua bán',
      'Giấy tờ hợp lệ',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88,
              ),
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFFFCFBFA),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Bộ lọc tìm kiếm',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1918),
                            fontFamily: 'Georgia',
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    const Text(
                      'Tên / Tiêu đề bất động sản',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1918),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: 'Nhập tiêu đề tìm kiếm...',
                        filled: true,
                        fillColor: const Color(0xFFF4EEE6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Địa chỉ / Khu vực',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1918),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: addressController,
                      decoration: InputDecoration(
                        hintText:
                            'Ví dụ: Quận 1, Nguyễn Trãi, TP. Hồ Chí Minh...',
                        filled: true,
                        fillColor: const Color(0xFFF4EEE6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Khoảng giá (VNĐ)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1918),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: fromPriceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Giá từ (VNĐ)',
                              filled: true,
                              fillColor: const Color(0xFFF4EEE6),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: toPriceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Giá đến (VNĐ)',
                              filled: true,
                              fillColor: const Color(0xFFF4EEE6),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Diện tích (m²)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1918),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: areaController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'VD: 100',
                                  filled: true,
                                  fillColor: const Color(0xFFF4EEE6),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Số tầng',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1918),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: floorController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'VD: 2',
                                  filled: true,
                                  fillColor: const Color(0xFFF4EEE6),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Số phòng ngủ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1918),
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<int>(
                                isExpanded: true,
                                initialValue: tempBedroom,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFFF4EEE6),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                hint: const Text(
                                  'Bất kỳ',
                                  overflow: TextOverflow.ellipsis,
                                ),
                                items: [1, 2, 3, 4, 5]
                                    .map(
                                      (n) => DropdownMenuItem(
                                        value: n,
                                        child: Text(
                                          '$n phòng',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) =>
                                    setModalState(() => tempBedroom = val),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Số phòng tắm',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1918),
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<int>(
                                isExpanded: true,
                                initialValue: tempBathroom,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFFF4EEE6),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                hint: const Text(
                                  'Bất kỳ',
                                  overflow: TextOverflow.ellipsis,
                                ),
                                items: [1, 2, 3, 4, 5]
                                    .map(
                                      (n) => DropdownMenuItem(
                                        value: n,
                                        child: Text(
                                          '$n phòng',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) =>
                                    setModalState(() => tempBathroom = val),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Hướng nhà',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1918),
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: tempDirection,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFFF4EEE6),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                hint: const Text(
                                  'Tất cả',
                                  overflow: TextOverflow.ellipsis,
                                ),
                                items: directions
                                    .map(
                                      (d) => DropdownMenuItem(
                                        value: d,
                                        child: Text(
                                          d,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) =>
                                    setModalState(() => tempDirection = val),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pháp lý',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1918),
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: tempLegal,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFFF4EEE6),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                hint: const Text(
                                  'Tất cả',
                                  overflow: TextOverflow.ellipsis,
                                ),
                                items: legals
                                    .map(
                                      (l) => DropdownMenuItem(
                                        value: l,
                                        child: Text(
                                          l,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) =>
                                    setModalState(() => tempLegal = val),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setModalState(() {
                                titleController.clear();
                                addressController.clear();
                                fromPriceController.clear();
                                toPriceController.clear();
                                areaController.clear();
                                floorController.clear();
                                tempBedroom = null;
                                tempBathroom = null;
                                tempDirection = null;
                                tempLegal = null;
                              });
                              _filterRequest = PropertyRequestDTO(
                                typeId: _selectedTypeId,
                                page: 1,
                                limit: 6,
                              );
                              setState(() {
                                _searchController.clear();
                              });
                              _loadData(isReset: true);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Color(0xFF78736D)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Đặt lại',
                              style: TextStyle(
                                color: Color(0xFF1A1918),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final fromP = double.tryParse(
                                fromPriceController.text.trim(),
                              );
                              final toP = double.tryParse(
                                toPriceController.text.trim(),
                              );
                              final ar = double.tryParse(
                                areaController.text.trim(),
                              );
                              final fl = int.tryParse(
                                floorController.text.trim(),
                              );

                              _filterRequest = PropertyRequestDTO(
                                typeId: _selectedTypeId,
                                title: titleController.text.trim().isNotEmpty
                                    ? titleController.text.trim()
                                    : null,
                                address:
                                    addressController.text.trim().isNotEmpty
                                    ? addressController.text.trim()
                                    : null,
                                fromPrice: fromP,
                                toPrice: toP,
                                area: ar,
                                floorCount: fl,
                                bedroomCount: tempBedroom,
                                bathroomCount: tempBathroom,
                                direction: tempDirection,
                                legal: tempLegal,
                                page: 1,
                                limit: 6,
                              );

                              if (titleController.text.isNotEmpty) {
                                _searchController.text = titleController.text;
                              }

                              Navigator.pop(context);
                              _loadData(isReset: true);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: const Color(0xFF945331),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Áp dụng',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
