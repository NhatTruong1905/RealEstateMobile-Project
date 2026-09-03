import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:real_estate_frontend/dto/PropertyDTO.dart';
import 'package:real_estate_frontend/mixin/api/APIPropertyMixin.dart';

class PostPropertyScreen extends StatefulWidget {
  final int? propertyId;
  final PropertyDTO? property;

  const PostPropertyScreen({super.key, this.propertyId, this.property});

  @override
  State<PostPropertyScreen> createState() => _PostPropertyScreenState();
}

class _PostPropertyScreenState extends State<PostPropertyScreen>
    with ApiPropertyMixin {
  final _formKey = GlobalKey<FormState>();

  int _typeId = 1;
  int _categoryId = 1;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _bedroomController = TextEditingController();
  final TextEditingController _bathroomController = TextEditingController();
  final TextEditingController _floorController = TextEditingController();

  String? _direction = 'Đông Nam';
  String? _legal = 'Sổ hồng riêng';
  bool _isLoading = false;
  bool _isFetchingDetail = false;

  final ImagePicker _picker = ImagePicker();
  final List<File> _selectedFiles = [];
  List<String> _existingImageUrls = [];

  final List<String> _directions = [
    'Đông',
    'Tây',
    'Nam',
    'Bắc',
    'Đông Nam',
    'Đông Bắc',
    'Tây Nam',
    'Tây Bắc',
  ];

  final List<String> _legals = [
    'Sổ hồng riêng',
    'Sổ đỏ',
    'Hợp đồng mua bán',
    'Đang chờ sổ',
    'Giấy tờ hợp lệ',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.property != null) {
      _fillData(widget.property!);
    } else if (widget.propertyId != null) {
      _loadPropertyDetail(widget.propertyId!);
    }
  }

  void _fillData(PropertyDTO property) {
    _typeId = property.typeId ?? 1;
    _categoryId = property.categoryId ?? 1;
    _titleController.text = property.title ?? '';
    _priceController.text = property.price != null
        ? property.price!.toStringAsFixed(0)
        : '';
    _areaController.text = property.area != null
        ? property.area!.toStringAsFixed(0)
        : '';
    _addressController.text = property.addressDetail ?? property.address ?? '';
    _descriptionController.text = property.description ?? '';
    _bedroomController.text = property.bedroomCount?.toString() ?? '';
    _bathroomController.text = property.bathroomCount?.toString() ?? '';
    _floorController.text = property.floorCount?.toString() ?? '';

    if (property.direction != null &&
        _directions.contains(property.direction)) {
      _direction = property.direction;
    }
    if (property.legal != null && _legals.contains(property.legal)) {
      _legal = property.legal;
    }

    if (property.images != null && property.images!.isNotEmpty) {
      _existingImageUrls = List.from(property.images!);
    } else if (property.image != null && property.image!.isNotEmpty) {
      _existingImageUrls = [property.image!];
    }
  }

  Future<void> _loadPropertyDetail(int id) async {
    setState(() => _isFetchingDetail = true);
    PropertyDTO? detail = await fetchPropertyById(id);
    if (mounted) {
      if (detail != null) {
        _fillData(detail);
      }
      setState(() => _isFetchingDetail = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _areaController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _bedroomController.dispose();
    _bathroomController.dispose();
    _floorController.dispose();
    super.dispose();
  }

  Future<void> _pickImagesFromSource(ImageSource source) async {
    final currentTotal = _selectedFiles.length + _existingImageUrls.length;
    if (currentTotal >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tối đa chỉ được tải lên 5 hình ảnh!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final remainingSlot = 5 - currentTotal;

    if (source == ImageSource.gallery) {
      try {
        final List<XFile> images = await _picker.pickMultiImage();
        if (images.isNotEmpty) {
          final selectedList = images
              .take(remainingSlot)
              .map((x) => File(x.path))
              .toList();
          setState(() {
            _selectedFiles.addAll(selectedList);
          });
        }
      } catch (e) {
        debugPrint('Lỗi chọn ảnh từ thư viện: $e');
      }
    } else if (source == ImageSource.camera) {
      try {
        final XFile? image = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1200,
          imageQuality: 85,
        );
        if (image != null) {
          setState(() {
            _selectedFiles.add(File(image.path));
          });
        }
      } catch (e) {
        debugPrint('Lỗi chụp ảnh từ camera: $e');
      }
    }
  }

  void _showImagePickerOptions() {
    final currentTotal = _selectedFiles.length + _existingImageUrls.length;
    if (currentTotal >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tối đa chỉ được tải lên 5 hình ảnh!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(
                  top: 16,
                  left: 20,
                  right: 20,
                  bottom: 8,
                ),
                child: Text(
                  'Thêm hình ảnh BĐS ($currentTotal/5)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1918),
                    fontFamily: 'Georgia',
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: Color(0xFF945331),
                ),
                title: const Text('Chọn từ thư viện'),
                subtitle: const Text('Chọn 1 hoặc nhiều hình ảnh từ máy'),
                onTap: () async {
                  Navigator.of(bc).pop();
                  await Future.delayed(const Duration(milliseconds: 250));
                  _pickImagesFromSource(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_camera_outlined,
                  color: Color(0xFF2E7D32),
                ),
                title: const Text('Chụp ảnh mới'),
                subtitle: const Text('Mở máy ảnh chụp bất động sản'),
                onTap: () async {
                  Navigator.of(bc).pop();
                  await Future.delayed(const Duration(milliseconds: 250));
                  _pickImagesFromSource(ImageSource.camera);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _removeSelectedFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final double? priceVal = double.tryParse(_priceController.text.trim());
    final double? areaVal = double.tryParse(_areaController.text.trim());

    if (priceVal == null || priceVal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giá bất động sản phải lớn hơn 0')),
      );
      setState(() => _isLoading = false);
      return;
    }

    if (areaVal == null || areaVal <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Diện tích phải lớn hơn 0')));
      setState(() => _isLoading = false);
      return;
    }

    final propertyDto = PropertyDTO(
      id: widget.propertyId ?? widget.property?.id,
      typeId: _typeId,
      categoryId: _categoryId,
      title: _titleController.text.trim(),
      price: priceVal,
      area: areaVal,
      address: _addressController.text.trim(),
      addressDetail: _addressController.text.trim(),
      description: _descriptionController.text.trim(),
      bedroomCount: int.tryParse(_bedroomController.text.trim()),
      bathroomCount: int.tryParse(_bathroomController.text.trim()),
      floorCount: int.tryParse(_floorController.text.trim()),
      direction: _direction,
      legal: _legal,
      images: _existingImageUrls,
    );

    final result = await saveProperty(propertyDto, imageFiles: _selectedFiles);

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success'] == true) {
        final isEdit =
            (widget.propertyId != null || widget.property?.id != null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? 'Cập nhật tin đăng thành công!'
                  : 'Đăng tin bất động sản thành công!',
            ),
            backgroundColor: const Color(0xFF945331),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Thao tác thất bại!'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A1918),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF78736D), fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF78736D), size: 20),
      filled: true,
      fillColor: const Color(0xFFF4EEE6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF945331), width: 1.5),
      ),
    );
  }
}
