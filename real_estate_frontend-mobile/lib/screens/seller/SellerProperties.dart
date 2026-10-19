import 'package:flutter/material.dart';
import 'package:real_estate_frontend/dto/PropertyDTO.dart';
import 'package:real_estate_frontend/mixin/api/APIPropertyMixin.dart';
import 'package:real_estate_frontend/screens/seller/PostProperty.dart';
import 'package:real_estate_frontend/utils/PriceFormatter.dart';

part 'seller_properties/seller_properties_view.dart';
part 'seller_properties/seller_properties_components.dart';

class SellerPropertiesScreen extends StatefulWidget {
  final VoidCallback onPostNewProperty;

  const SellerPropertiesScreen({super.key, required this.onPostNewProperty});

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
        return s == 'đã xóa' ||
            s == 'deleted' ||
            s == 'từ chối' ||
            s == 'rejected' ||
            s == 'đã ẩn';
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
  Widget build(BuildContext context) => _buildPage(context);
}
