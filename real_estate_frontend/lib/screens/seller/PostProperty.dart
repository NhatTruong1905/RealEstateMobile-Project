import 'package:flutter/material.dart';

class PostPropertyScreen extends StatefulWidget {
  const PostPropertyScreen({super.key});

  @override
  State<PostPropertyScreen> createState() => _PostPropertyScreenState();
}

class _PostPropertyScreenState extends State<PostPropertyScreen> {
  final _formKey = GlobalKey<FormState>();

  int _typeId = 1; // 1: Cho Bán, 2: Cho Thuê
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _bedroomController = TextEditingController();
  final TextEditingController _bathroomController = TextEditingController();
  final TextEditingController _floorController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();

  String? _direction = 'Đông Nam';
  String? _legal = 'Sổ hồng riêng';
  bool _isLoading = false;

  final List<String> _directions = [
    'Đông',
    'Tây',
    'Nam',
    'Bắc',
    'Đông Nam',
    'Đông Bắc',
    'Tây Nam',
    'Tây Bắc'
  ];

  final List<String> _legals = [
    'Sổ hồng riêng',
    'Sổ đỏ',
    'Hợp đồng mua bán',
    'Đang chờ sổ',
    'Giấy tờ hợp lệ'
  ];

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
    _imageController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đăng tin bất động sản thành công!'),
            backgroundColor: const Color(0xFF945331),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context, true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFBFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCFBFA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF1A1918)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Đăng tin Bất động sản',
          style: TextStyle(
            color: Color(0xFF1A1918),
            fontWeight: FontWeight.bold,
            fontFamily: 'Georgia',
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LOẠI GIAO DỊCH
                _buildSectionTitle('Loại giao dịch'),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Cho Bán')),
                        selected: _typeId == 1,
                        selectedColor: const Color(0xFF945331),
                        backgroundColor: const Color(0xFFF4EEE6),
                        labelStyle: TextStyle(
                          color: _typeId == 1 ? Colors.white : const Color(0xFF78736D),
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
                          color: _typeId == 2 ? Colors.white : const Color(0xFF78736D),
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
                const SizedBox(height: 20),

                // TIÊU ĐỀ
                _buildSectionTitle('Tiêu đề bài đăng *'),
                TextFormField(
                  controller: _titleController,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tiêu đề' : null,
                  decoration: _buildInputDecoration(
                      hint: 'VD: Căn hộ cao cấp 2PN view sông...', icon: Icons.title),
                ),
                const SizedBox(height: 16),

                // GIÁ VÀ DIỆN TÍCH
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
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Nhập giá'
                                : null,
                            decoration: _buildInputDecoration(
                                hint: 'VD: 3500000000', icon: Icons.attach_money),
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
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Nhập diện tích'
                                : null,
                            decoration: _buildInputDecoration(
                                hint: 'VD: 85', icon: Icons.crop_free),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ĐỊA CHỈ
                _buildSectionTitle('Địa chỉ bất động sản *'),
                TextFormField(
                  controller: _addressController,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Vui lòng nhập địa chỉ' : null,
                  decoration: _buildInputDecoration(
                      hint: 'VD: Đường Lê Văn Sỹ, Phường 13, Quận 3, TP.HCM',
                      icon: Icons.location_on_outlined),
                ),
                const SizedBox(height: 16),

                // THÔNG SỐ CHI TIẾT
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
                                hint: '2', icon: Icons.bed_outlined),
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
                                hint: '2', icon: Icons.bathtub_outlined),
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
                                hint: '1', icon: Icons.layers_outlined),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // HƯỚNG NHÀ
                _buildSectionTitle('Hướng nhà'),
                DropdownButtonFormField<String>(
                  initialValue: _direction,
                  isExpanded: true,
                  decoration: _buildInputDecoration(
                      hint: 'Chọn hướng nhà', icon: Icons.explore_outlined),
                  items: _directions
                      .map((d) => DropdownMenuItem(
                            value: d,
                            child: Text(d, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _direction = val),
                ),
                const SizedBox(height: 16),

                // PHÁP LÝ
                _buildSectionTitle('Giấy tờ pháp lý'),
                DropdownButtonFormField<String>(
                  initialValue: _legal,
                  isExpanded: true,
                  decoration: _buildInputDecoration(
                      hint: 'Chọn giấy tờ pháp lý', icon: Icons.gavel_outlined),
                  items: _legals
                      .map((l) => DropdownMenuItem(
                            value: l,
                            child: Text(l, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => _legal = val),
                ),
                const SizedBox(height: 16),

                // URL HÌNH ẢNH
                _buildSectionTitle('Link hình ảnh BĐS (URL)'),
                TextFormField(
                  controller: _imageController,
                  decoration: _buildInputDecoration(
                      hint: 'https://images.unsplash.com/photo...', icon: Icons.image_outlined),
                ),
                const SizedBox(height: 16),

                // MÔ TẢ
                _buildSectionTitle('Mô tả chi tiết'),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: _buildInputDecoration(
                      hint: 'Nhập thông tin mô tả chi tiết bài đăng...',
                      icon: Icons.notes),
                ),
                const SizedBox(height: 32),

                // NÚT ĐĂNG TIN
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
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Đăng tin bài đăng ngay',
                            style: TextStyle(
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

  InputDecoration _buildInputDecoration(
      {required String hint, required IconData icon}) {
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
