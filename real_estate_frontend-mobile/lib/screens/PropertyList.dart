import 'package:flutter/material.dart';
import 'package:real_estate_frontend/dto/PropertyDTO.dart';
import 'package:real_estate_frontend/dto/PropertyPageResponseDTO.dart';
import 'package:real_estate_frontend/dto/PropertyRequestDTO.dart';
import 'package:real_estate_frontend/mixin/api/APIPropertyMixin.dart';
import 'package:real_estate_frontend/screens/Auth.dart';
import 'package:real_estate_frontend/screens/Home.dart';
import 'package:real_estate_frontend/screens/PropertyDetail.dart';
import 'package:real_estate_frontend/utils/PriceFormatter.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'property_list/property_list_filter.dart';
part 'property_list/property_list_view.dart';
part 'property_list/property_list_components.dart';

class PropertyListScreen extends StatefulWidget {
  final String pageTitle;
  final int? initialTypeId;
  final String? initialSearchTitle;

  const PropertyListScreen({
    super.key,
    this.pageTitle = 'Danh sách Bất động sản',
    this.initialTypeId,
    this.initialSearchTitle,
  });

  @override
  State<PropertyListScreen> createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends State<PropertyListScreen>
    with ApiPropertyMixin {
  late int? _selectedTypeId;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _isLoggedIn = false;
  bool _showScrollToTop = false;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;

  List<PropertyDTO> _properties = [];

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  late PropertyRequestDTO _filterRequest;

  @override
  void initState() {
    super.initState();
    _selectedTypeId = widget.initialTypeId;
    if (widget.initialSearchTitle != null) {
      _searchController.text = widget.initialSearchTitle!;
    }

    _filterRequest = PropertyRequestDTO(
      typeId: _selectedTypeId,
      title: _searchController.text.trim().isNotEmpty
          ? _searchController.text.trim()
          : null,
      page: 1,
      limit: 6,
    );

    _scrollController.addListener(_onScroll);
    _loadData(isReset: true);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final showTop =
        _scrollController.hasClients && _scrollController.offset > 300;
    if (showTop != _showScrollToTop) {
      setState(() => _showScrollToTop = showTop);
    }

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && !_isLoadingMore && _hasMore) {
        _loadMoreData();
      }
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _loadData({bool isReset = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    _isLoggedIn = token != null && token.isNotEmpty;

    if (!_isLoggedIn) {
      userFavoriteIds.clear();
    } else {
      await fetchFavoriteProperties();
    }

    _currentPage = 1;
    _totalPages = 1;
    _totalItems = 0;
    _hasMore = true;
    _filterRequest.page = 1;
    _filterRequest.limit = 6;
    _filterRequest.typeId = _selectedTypeId;

    if (mounted) {
      setState(() => _isLoading = true);
    }

    PropertyPageResponseDTO? pageResponse = await fetchPropertiesPage(
      request: _filterRequest,
    );

    List<PropertyDTO> fetched = pageResponse?.content ?? [];
    _currentPage = pageResponse?.currentPage ?? 1;
    _totalPages = pageResponse?.totalPages ?? 1;
    _totalItems = pageResponse?.totalItems ?? 0;
    _hasMore = _currentPage < _totalPages;

    if (_isLoggedIn && fetched.isNotEmpty) {
      for (var p in fetched) {
        if (p.id != null) {
          p.isSaved = userFavoriteIds.contains(p.id);
        }
      }
    }

    if (mounted) {
      setState(() {
        _properties = fetched;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMore || _currentPage >= _totalPages) return;

    if (mounted) {
      setState(() => _isLoadingMore = true);
    }

    int nextPage = _currentPage + 1;
    _filterRequest.page = nextPage;
    _filterRequest.typeId = _selectedTypeId;

    PropertyPageResponseDTO? pageResponse = await fetchPropertiesPage(
      request: _filterRequest,
    );

    List<PropertyDTO> fetched = pageResponse?.content ?? [];
    if (pageResponse != null) {
      _currentPage = pageResponse.currentPage;
      _totalPages = pageResponse.totalPages;
      _totalItems = pageResponse.totalItems;
      _hasMore = _currentPage < _totalPages;
    } else {
      _hasMore = false;
    }

    if (_isLoggedIn && fetched.isNotEmpty) {
      for (var p in fetched) {
        if (p.id != null) {
          p.isSaved = userFavoriteIds.contains(p.id);
        }
      }
    }

    if (mounted) {
      setState(() {
        _properties.addAll(fetched);
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadData(isReset: true);
  }

  Future<void> _toggleSave(PropertyDTO property) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    _isLoggedIn = token != null && token.isNotEmpty;

    if (!_isLoggedIn) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        ).then((_) {
          _loadData(isReset: true);
        });
      }
      return;
    }

    if (property.id == null) return;

    setState(() {
      property.isSaved = !property.isSaved;
      if (property.isSaved) {
        userFavoriteIds.add(property.id!);
      } else {
        userFavoriteIds.remove(property.id!);
      }

      for (var p in globalProperties) {
        if (p.id == property.id) {
          p.isSaved = property.isSaved;
        }
      }
    });

    await syncFavoriteProperties(userFavoriteIds.toList());
  }

  void _triggerSearch() {
    String query = _searchController.text.trim();
    _filterRequest.title = query.isNotEmpty ? query : null;
    _loadData(isReset: true);
  }

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
