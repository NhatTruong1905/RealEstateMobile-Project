import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:real_estate_frontend/dto/PropertyDTO.dart';
import 'package:real_estate_frontend/mixin/api/APIPropertyMixin.dart';

part 'post_property/post_property_view.dart';
part 'post_property/post_property_components.dart';

class PostPropertyScreen extends StatefulWidget {
  final int? propertyId;
  final PropertyDTO? property;
  final http.Client? client;

  const PostPropertyScreen({
    super.key,
    this.propertyId,
    this.property,
    this.client,
  });

  @override
  State<PostPropertyScreen> createState() => _PostPropertyScreenState();
}

class _PostPropertyScreenState extends State<PostPropertyScreen>
    with ApiPropertyMixin {
  @override
  http.Client? get propertyClient => widget.client;
  final _formKey = GlobalKey<FormState>();

  int? _typeId;
  int? _categoryId;
  int? _wardId;
  Map<String, dynamic>? _options;
  String? _optionsError;
  bool _optionsLoading = true;
  String? _submitError;
  Future<void> _loadOptions() async {
    setState(() {
      _optionsLoading = true;
      _optionsError = null;
    });
    try {
      final options = await fetchPropertyOptions();
      if (mounted) setState(() => _options = options);
    } catch (e) {
      if (mounted) setState(() => _optionsError = e.toString());
    } finally {
      if (mounted) setState(() => _optionsLoading = false);
    }
  }

  Widget _optionField(
    String key,
    String label,
    int? value,
    ValueChanged<int?> changed, {
    bool optional = false,
  }) {
    final items = (_options?[key] as List? ?? []).cast<Map<String, dynamic>>();
    final validValue = items.any((item) => item['id'] == value) ? value : null;
    return DropdownButtonFormField<int>(
      key: ValueKey('$key-$validValue'),
      initialValue: validValue,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        if (optional)
          const DropdownMenuItem<int>(
            value: null,
            child: Text('Xác định từ địa chỉ'),
          ),
        ...items.map(
          (item) => DropdownMenuItem<int>(
            value: (item['id'] as num).toInt(),
            child: Text(
              '${item['name']}${item['districtName'] == null ? '' : ' - ${item['districtName']}'}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: _isLoading ? null : changed,
      validator: (v) => !optional && v == null ? 'Vui lòng chọn $label' : null,
    );
  }

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
    _loadOptions();
    if (widget.property != null) {
      _fillData(widget.property!);
    } else if (widget.propertyId != null) {
      _loadPropertyDetail(widget.propertyId!);
    }
  }

  void _fillData(PropertyDTO property) {
    _typeId = property.typeId;
    _categoryId = property.categoryId;
    _wardId = property.wardId;
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
    if (_isLoading ||
        _optionsLoading ||
        _optionsError != null ||
        _options == null) {
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitError = null);

    setState(() => _isLoading = true);

    final double? priceVal = double.tryParse(_priceController.text.trim());
    final double? areaVal = double.tryParse(_areaController.text.trim());
    for (final controller in [
      _bedroomController,
      _bathroomController,
      _floorController,
    ]) {
      final text = controller.text.trim();
      if (text.isNotEmpty &&
          (int.tryParse(text) == null || int.parse(text) < 0)) {
        setState(() {
          _isLoading = false;
          _submitError = 'Số phòng và số tầng phải là số nguyên từ 0 trở lên.';
        });
        return;
      }
    }

    if (priceVal == null || !priceVal.isFinite || priceVal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giá bất động sản phải lớn hơn 0')),
      );
      setState(() => _isLoading = false);
      return;
    }

    if (areaVal == null || !areaVal.isFinite || areaVal <= 0) {
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
      wardId: _wardId,
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
                  : (result['data']?['status'] == 'Chờ duyệt'
                        ? receivedPropertyMessage
                        : 'Tin đã được lưu. Vui lòng kiểm tra trạng thái trong Tin đăng.'),
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
        setState(
          () => _submitError =
              result['message']?.toString() ?? 'Thao tác thất bại',
        );
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
  Widget build(BuildContext context) => _buildPage(context);
}
