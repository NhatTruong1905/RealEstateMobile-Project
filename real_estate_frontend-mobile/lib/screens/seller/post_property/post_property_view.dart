// ignore_for_file: invalid_use_of_protected_member

part of '../PostProperty.dart';

extension PostPropertyView on _PostPropertyScreenState {
  Widget _buildPage(BuildContext context) {
    final isEdit = (widget.propertyId != null || widget.property?.id != null);
    final totalImages = _selectedFiles.length + _existingImageUrls.length;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFBFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCFBFA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF1A1918)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEdit ? 'Chỉnh sửa Tin đăng' : 'Đăng tin Bất động sản',
          style: const TextStyle(
            color: Color(0xFF1A1918),
            fontWeight: FontWeight.bold,
            fontFamily: 'Georgia',
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: _isFetchingDetail
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF945331)),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Loại giao dịch *'),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Cho Bán')),
                              selected: _typeId == 1,
                              selectedColor: const Color(0xFF945331),
                              backgroundColor: const Color(0xFFF4EEE6),
                              labelStyle: TextStyle(
                                color: _typeId == 1
                                    ? Colors.white
                                    : const Color(0xFF78736D),
                                fontWeight: FontWeight.bold,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              onSelected: (val) {
                                if (val) setState(() => _typeId = 1);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('Cho Thuê')),
                              selected: _typeId == 2,
                              selectedColor: const Color(0xFF2E7D32),
                              backgroundColor: const Color(0xFFF4EEE6),
                              labelStyle: TextStyle(
                                color: _typeId == 2
                                    ? Colors.white
                                    : const Color(0xFF78736D),
                                fontWeight: FontWeight.bold,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              onSelected: (val) {
                                if (val) setState(() => _typeId = 2);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildSectionTitle('Phân khúc / Loại BĐS *'),
                      DropdownButtonFormField<int>(
                        initialValue: _categoryId,
                        isExpanded: true,
                        decoration: _buildInputDecoration(
                          hint: 'Chọn loại bất động sản',
                          icon: Icons.category_outlined,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 1,
                            child: Text('Căn hộ / Chung cư'),
                          ),
                          DropdownMenuItem(
                            value: 2,
                            child: Text('Nhà riêng / Nhà phố'),
                          ),
                          DropdownMenuItem(
                            value: 3,
                            child: Text('Biệt thự / Sân vườn'),
                          ),
                          DropdownMenuItem(
                            value: 4,
                            child: Text('Đất nền / Đất thổ cư'),
                          ),
                          DropdownMenuItem(
                            value: 5,
                            child: Text('Mặt bằng / Văn phòng / Shop'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _categoryId = val);
                        },
                      ),
                      const SizedBox(height: 20),

                      _buildSectionTitle('Tiêu đề bài đăng *'),
                      TextFormField(
                        controller: _titleController,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Vui lòng nhập tiêu đề'
                            : null,
                        decoration: _buildInputDecoration(
                          hint: 'VD: Căn hộ cao cấp 2PN view sông...',
                          icon: Icons.title,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('Giá (VNĐ) *'),
                                TextFormField(
                                  controller: _priceController,
                                  keyboardType: TextInputType.number,
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Nhập giá'
                                      : null,
                                  decoration: _buildInputDecoration(
                                    hint: 'VD: 3500000000',
                                    icon: Icons.attach_money,
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
                                _buildSectionTitle('Diện tích (m²) *'),
                                TextFormField(
                                  controller: _areaController,
                                  keyboardType: TextInputType.number,
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Nhập diện tích'
                                      : null,
                                  decoration: _buildInputDecoration(
                                    hint: 'VD: 85',
                                    icon: Icons.crop_free,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildSectionTitle('Địa chỉ bất động sản *'),
                      TextFormField(
                        controller: _addressController,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Vui lòng nhập địa chỉ'
                            : null,
                        decoration: _buildInputDecoration(
                          hint:
                              'VD: 221/45E Lê Văn Sỹ, Phường 13, Quận 3, TP.HCM',
                          icon: Icons.location_on_outlined,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('Số phòng ngủ'),
                                TextFormField(
                                  controller: _bedroomController,
                                  keyboardType: TextInputType.number,
                                  decoration: _buildInputDecoration(
                                    hint: '2',
                                    icon: Icons.bed_outlined,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('Số phòng tắm'),
                                TextFormField(
                                  controller: _bathroomController,
                                  keyboardType: TextInputType.number,
                                  decoration: _buildInputDecoration(
                                    hint: '2',
                                    icon: Icons.bathtub_outlined,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle('Số tầng'),
                                TextFormField(
                                  controller: _floorController,
                                  keyboardType: TextInputType.number,
                                  decoration: _buildInputDecoration(
                                    hint: '1',
                                    icon: Icons.layers_outlined,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildSectionTitle('Hướng nhà'),
                      DropdownButtonFormField<String>(
                        initialValue: _direction,
                        isExpanded: true,
                        decoration: _buildInputDecoration(
                          hint: 'Chọn hướng nhà',
                          icon: Icons.explore_outlined,
                        ),
                        items: _directions
                            .map(
                              (d) => DropdownMenuItem(
                                value: d,
                                child: Text(d, overflow: TextOverflow.ellipsis),
                              ),
                            )
                            .toList(),
                        onChanged: (val) => setState(() => _direction = val),
                      ),
                      const SizedBox(height: 16),

                      _buildSectionTitle('Giấy tờ pháp lý *'),
                      DropdownButtonFormField<String>(
                        initialValue: _legal,
                        isExpanded: true,
                        decoration: _buildInputDecoration(
                          hint: 'Chọn giấy tờ pháp lý',
                          icon: Icons.gavel_outlined,
                        ),
                        items: _legals
                            .map(
                              (l) => DropdownMenuItem(
                                value: l,
                                child: Text(l, overflow: TextOverflow.ellipsis),
                              ),
                            )
                            .toList(),
                        onChanged: (val) => setState(() => _legal = val),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: _showImagePickerOptions,
                            child: _buildSectionTitle(
                              'Hình ảnh BĐS (Tối đa 5 ảnh)',
                            ),
                          ),
                          Text(
                            '$totalImages / 5',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: totalImages == 5
                                  ? Colors.redAccent
                                  : const Color(0xFF945331),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (totalImages < 5)
                              InkWell(
                                onTap: _showImagePickerOptions,
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF4EEE6),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFF945331),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_a_photo_outlined,
                                        color: Color(0xFF945331),
                                        size: 28,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Thêm ảnh',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF945331),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            ..._existingImageUrls.asMap().entries.map((entry) {
                              final index = entry.key;
                              final url = entry.value;
                              return Container(
                                margin: const EdgeInsets.only(left: 10),
                                width: 90,
                                height: 90,
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.network(
                                        url,
                                        width: 90,
                                        height: 90,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stack) =>
                                            Container(
                                              color: Colors.grey.shade300,
                                              child: const Icon(
                                                Icons.broken_image,
                                              ),
                                            ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () =>
                                            _removeExistingImage(index),
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(3),
                                          child: const Icon(
                                            Icons.close,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),

                            ..._selectedFiles.asMap().entries.map((entry) {
                              final index = entry.key;
                              final file = entry.value;
                              return Container(
                                margin: const EdgeInsets.only(left: 10),
                                width: 90,
                                height: 90,
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.file(
                                        file,
                                        width: 90,
                                        height: 90,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => _removeSelectedFile(index),
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(3),
                                          child: const Icon(
                                            Icons.close,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      _buildSectionTitle('Mô tả chi tiết'),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: _buildInputDecoration(
                          hint: 'Nhập thông tin mô tả chi tiết bài đăng...',
                          icon: Icons.notes,
                        ),
                      ),
                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF945331),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  isEdit
                                      ? 'Lưu thay đổi bài đăng'
                                      : 'Đăng tin bài đăng ngay',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
