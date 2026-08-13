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
    final showTop = _scrollController.hasClients && _scrollController.offset > 300;
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

    PropertyPageResponseDTO? pageResponse =
        await fetchPropertiesPage(request: _filterRequest);

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

    PropertyPageResponseDTO? pageResponse =
        await fetchPropertiesPage(request: _filterRequest);

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

  void _showFilterBottomSheet() {
    final titleController =
        TextEditingController(text: _filterRequest.title ?? '');
    final addressController =
        TextEditingController(text: _filterRequest.address ?? '');
    final fromPriceController = TextEditingController(
        text: _filterRequest.fromPrice != null
            ? _filterRequest.fromPrice!.toStringAsFixed(0)
            : '');
    final toPriceController = TextEditingController(
        text: _filterRequest.toPrice != null
            ? _filterRequest.toPrice!.toStringAsFixed(0)
            : '');
    final areaController = TextEditingController(
        text: _filterRequest.area != null
            ? _filterRequest.area!.toStringAsFixed(0)
            : '');
    final floorController = TextEditingController(
        text: _filterRequest.floorCount != null
            ? _filterRequest.floorCount!.toString()
            : '');

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
                          color: Color(0xFF1A1918)),
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
                          color: Color(0xFF1A1918)),
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
                          color: Color(0xFF1A1918)),
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
                                    color: Color(0xFF1A1918)),
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
                                    color: Color(0xFF1A1918)),
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
                                    color: Color(0xFF1A1918)),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<int>(
                                initialValue: tempBedroom,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFFF4EEE6),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                hint: const Text('Bất kỳ'),
                                items: [1, 2, 3, 4, 5]
                                    .map((n) => DropdownMenuItem(
                                          value: n,
                                          child: Text('$n phòng'),
                                        ))
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
                                    color: Color(0xFF1A1918)),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<int>(
                                initialValue: tempBathroom,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFFF4EEE6),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                hint: const Text('Bất kỳ'),
                                items: [1, 2, 3, 4, 5]
                                    .map((n) => DropdownMenuItem(
                                          value: n,
                                          child: Text('$n phòng'),
                                        ))
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
                                    color: Color(0xFF1A1918)),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: tempDirection,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFFF4EEE6),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                hint: const Text('Tất cả'),
                                items: directions
                                    .map((d) => DropdownMenuItem(
                                          value: d,
                                          child: Text(d),
                                        ))
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
                                    color: Color(0xFF1A1918)),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: tempLegal,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFFF4EEE6),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                hint: const Text('Tất cả'),
                                items: legals
                                    .map((l) => DropdownMenuItem(
                                          value: l,
                                          child: Text(l),
                                        ))
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
                    // NÚT ĐẶT LẠI & ÁP DỤNG
                    Row(
                      children: [
                        // NÚT ĐẶT LẠI (RESET CÁC FIELD VÀ BỘ LỌC)
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
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('Đặt lại',
                                style: TextStyle(
                                    color: Color(0xFF1A1918),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // NÚT ÁP DỤNG
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final fromP = double.tryParse(
                                  fromPriceController.text.trim());
                              final toP = double.tryParse(
                                  toPriceController.text.trim());
                              final ar = double.tryParse(
                                  areaController.text.trim());
                              final fl = int.tryParse(
                                  floorController.text.trim());

                              _filterRequest = PropertyRequestDTO(
                                typeId: _selectedTypeId,
                                title: titleController.text.trim().isNotEmpty
                                    ? titleController.text.trim()
                                    : null,
                                address: addressController.text.trim().isNotEmpty
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
                                _searchController.text =
                                    titleController.text;
                              }

                              Navigator.pop(context);
                              _loadData(isReset: true);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: const Color(0xFF945331),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('Áp dụng',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFBFA),
      floatingActionButton: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: _showScrollToTop ? 1.0 : 0.0,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 250),
          scale: _showScrollToTop ? 1.0 : 0.0,
          child: GestureDetector(
            onTap: _showScrollToTop ? _scrollToTop : null,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.45),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_upward_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCFBFA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A1918), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.pageTitle,
          style: const TextStyle(
            color: Color(0xFF1A1918),
            fontFamily: 'Georgia',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF945331),
          onRefresh: _refreshData,
          child: Column(
            children: [
              // 1. THANH TÌM KIẾM + NÚT LỌC
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.only(left: 14, right: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4EEE6),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onSubmitted: (_) => _triggerSearch(),
                                textInputAction: TextInputAction.search,
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 14,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Tìm kiếm bất động sản...',
                                  border: InputBorder.none,
                                  isDense: true,
                                  hintStyle: TextStyle(
                                    color: Color(0xFF78736D),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.cancel,
                                    size: 18, color: Color(0xFF78736D)),
                                onPressed: () {
                                  _searchController.clear();
                                  _triggerSearch();
                                },
                              ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: _triggerSearch,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF945331),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.search,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _showFilterBottomSheet,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4EEE6),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFFE8E3DC),
                          ),
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          color: Color(0xFF945331),
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. TAB PHÂN LOẠI NHANH (Tất cả, Mua Bán, Cho Thuê)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    _buildTypeChip('Tất cả', null),
                    const SizedBox(width: 8),
                    _buildTypeChip('Mua Bán', 1),
                    const SizedBox(width: 8),
                    _buildTypeChip('Cho Thuê', 2),
                  ],
                ),
              ),

              // THÔNG TIN SỐ LƯỢNG KẾT QUẢ
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedTypeId == 1
                          ? 'Bất động sản Cho Bán'
                          : _selectedTypeId == 2
                              ? 'Bất động sản Cho Thuê'
                              : 'Tất cả Bất động sản',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1918),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    Text(
                      '$_totalItems kết quả',
                      style: const TextStyle(
                        color: Color(0xFF78736D),
                        fontSize: 13,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // 3. DANH SÁCH BẤT ĐỘNG SẢN (LAZY LOADING)
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF945331),
                        ),
                      )
                    : _properties.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 80),
                              Center(
                                child: Text(
                                  'Không tìm thấy bất động sản phù hợp',
                                  style: TextStyle(
                                    color: Color(0xFF78736D),
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: _properties.length + 1,
                            itemBuilder: (context, index) {
                              if (index == _properties.length) {
                                if (_isLoadingMore) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF945331),
                                      ),
                                    ),
                                  );
                                }
                                if (!_hasMore && _properties.isNotEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    child: Center(
                                      child: Text(
                                        'Đã hiển thị tất cả bất động sản',
                                        style: TextStyle(
                                          color: Color(0xFF78736D),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              }
                              final property = _properties[index];
                              return _buildVerticalCard(property);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String label, int? typeId) {
    final isSelected = _selectedTypeId == typeId;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedTypeId != typeId) {
            setState(() {
              _selectedTypeId = typeId;
            });
            _loadData(isReset: true);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF945331) : const Color(0xFFF4EEE6),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF945331).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF78736D),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalCard(PropertyDTO property) {
    return GestureDetector(
      onTap: () => openPropertyDetail(context, property),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  (property.image != null && property.image!.isNotEmpty)
                      ? Image.network(
                          property.image!,
                          width: 110,
                          height: 110,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 110,
                            height: 110,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.image_not_supported),
                          ),
                        )
                      : Container(
                          width: 110,
                          height: 110,
                          color: Colors.grey.shade300,
                          child: const Icon(
                            Icons.home,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => _toggleSave(property),
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: property.isSaved
                            ? const Color(0xFF945331)
                            : const Color(0xFF1A1918).withValues(alpha: 0.4),
                        child: Icon(
                          property.isSaved
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.title ?? "Chưa có tiêu đề",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1918),
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    formatPropertyPrice(property.price),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: property.typeId == 2
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFF945331),
                      fontFamily: 'Georgia',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Color(0xFF78736D),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property.address ??
                              property.city ??
                              'Đang cập nhật địa chỉ',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF78736D),
                            fontSize: 12,
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.bed_outlined,
                            size: 14,
                            color: Color(0xFF78736D),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${property.bedroomCount ?? 0} PN',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF78736D),
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.bathtub_outlined,
                            size: 14,
                            color: Color(0xFF78736D),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${property.bathroomCount ?? 0} PT',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF78736D),
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.layers_outlined,
                            size: 14,
                            color: Color(0xFF78736D),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${property.floorCount ?? 1} Tầng',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF78736D),
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.crop_free,
                            size: 13,
                            color: Color(0xFF78736D),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            property.area != null
                                ? '${property.area!.toStringAsFixed(0)}m²'
                                : 'N/A',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF78736D),
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
