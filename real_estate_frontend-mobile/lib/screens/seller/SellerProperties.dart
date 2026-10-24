import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:real_estate_frontend/dto/PropertyDTO.dart';
import 'package:real_estate_frontend/mixin/api/APIPropertyMixin.dart';
import 'package:real_estate_frontend/screens/seller/PostProperty.dart';
import 'package:real_estate_frontend/utils/PriceFormatter.dart';

part 'seller_properties/seller_properties_view.dart';
part 'seller_properties/seller_properties_components.dart';

class SellerPropertiesScreen extends StatefulWidget {
  final VoidCallback onPostNewProperty;
  final http.Client? client;

  const SellerPropertiesScreen({
    super.key,
    required this.onPostNewProperty,
    this.client,
  });

  @override
  State<SellerPropertiesScreen> createState() => _SellerPropertiesScreenState();
}

class _SellerPropertiesScreenState extends State<SellerPropertiesScreen>
    with ApiPropertyMixin {
  @override
  http.Client? get propertyClient => widget.client;
  bool _isLoading = true;
  String? _error;
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
    try {
      final list = await fetchMyProperties();
      if (mounted) {
        setState(() {
          _myProperties = list;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<PropertyDTO> get _filteredProperties {
    List<PropertyDTO> list = _myProperties;

    const statuses = {
      'Đã được duyệt': 'Đang mở bán',
      'Đang chờ duyệt': 'Chờ duyệt',
      'Bị từ chối': 'Từ chối',
      'Đã xóa': 'Đã xóa',
    };
    if (statuses.containsKey(_activeTab)) {
      list = list.where((p) => p.status == statuses[_activeTab]).toList();
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
