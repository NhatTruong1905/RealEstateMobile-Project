import 'package:flutter/material.dart';
import 'package:real_estate_frontend/dto/PropertyPageResponseDTO.dart';
import 'package:real_estate_frontend/mixin/api/APIPropertyMixin.dart';
import 'package:real_estate_frontend/screens/PropertyDetail.dart';
import 'package:real_estate_frontend/screens/PropertyList.dart';
import 'package:real_estate_frontend/utils/PriceFormatter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:real_estate_frontend/screens/Auth.dart';
import '../../dto/PropertyDTO.dart';
import '../../dto/PropertyRequestDTO.dart';

// Biến toàn cục chứa danh sách BĐS từ API
List<PropertyDTO> globalProperties = [];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with ApiPropertyMixin {
  String activeCategory = "Tất cả";
  final List<String> categories = [
    "Tất cả",
    "Biệt thự",
    "Căn hộ",
    "Nhà phố",
    "Đất nền",
  ];

  // CÁC BIẾN LOGIC API, PHÂN TRANG & BỘ LỌC
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _isLoggedIn = false;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  PropertyRequestDTO _filterRequest = PropertyRequestDTO(page: 1, limit: 6);

  @override
  void initState() {
    super.initState();
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

  // TỰ ĐỘNG BẮT SỰ KIỆN CUỘN TỚI CUỐI ĐỂ TẢI TIẾP (LAZY LOADING)
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && !_isLoadingMore && _hasMore) {
        _loadMoreData();
      }
    }
  }

  // HÀM TẢI DỮ LIỆU BAN ĐẦU / KHI LỌC LẠI
  Future<void> _loadData({bool isReset = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    _isLoggedIn = token != null && token.isNotEmpty;

    if (!_isLoggedIn) {
      userFavoriteIds.clear();
      for (var p in globalProperties) {
        p.isSaved = false;
      }
    } else {
      await fetchFavoriteProperties();
    }

    if (!isReset && globalProperties.isNotEmpty) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    _currentPage = 1;
    _totalPages = 1;
    _totalItems = 0;
    _hasMore = true;
    _filterRequest.page = 1;
    _filterRequest.limit = 6;

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
        globalProperties = fetched;
        _isLoading = false;
      });
    }
  }

  // HÀM TẢI THÊM TRANG TIẾP THEO
  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMore || _currentPage >= _totalPages) return;

    if (mounted) {
      setState(() => _isLoadingMore = true);
    }

    int nextPage = _currentPage + 1;
    _filterRequest.page = nextPage;

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
        globalProperties.addAll(fetched);
        _isLoadingMore = false;
      });
    }
  }

  // HÀM LÀM MỚI DỮ LIỆU KHI VUỐT XUỐNG (PULL TO REFRESH)
  Future<void> _refreshData() async {
    await _loadData(isReset: true);
  }

  // HÀM XỬ LÝ THẢ TIM
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
          globalProperties.clear();
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
    });

    await syncFavoriteProperties(userFavoriteIds.toList());
  }

  // HIỂN THỊ BẢNG BỘ LỌC TÌM KIẾM ĐA ĐIỀU KIỆN (BOTTOM SHEET)
  void _showFilterBottomSheet() {
    final titleController = TextEditingController(text: _filterRequest.title ?? '');
    final addressController = TextEditingController(text: _filterRequest.address ?? '');
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

                    // Tiêu đề
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

                    // Địa chỉ
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
                        hintText: 'Ví dụ: Quận 1, Nguyễn Trãi, TP. Hồ Chí Minh...',
                        filled: true,
                        fillColor: const Color(0xFFF4EEE6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Khoảng giá
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

                    // Diện tích & Số tầng
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

                    // Số phòng ngủ & Số phòng tắm
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

                    // Hướng & Pháp lý
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
                              _filterRequest =
                                  PropertyRequestDTO(page: 1, limit: 6);
                              setState(() {
                                activeCategory = "Tất cả";
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF945331)),
            )
          : SafeArea(
              child: RefreshIndicator(
                color: const Color(0xFF945331),
                onRefresh: _refreshData,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. HEADER
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 24,
                          right: 24,
                          top: 24,
                          bottom: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Vị trí hiện tại',
                                  style: TextStyle(
                                    color: Color(0xFF78736D),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Plus Jakarta Sans',
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: const [
                                    Icon(
                                      Icons.location_on_outlined,
                                      color: Color(0xFF945331),
                                      size: 20,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'TP. Hồ Chí Minh',
                                      style: TextStyle(
                                        color: Color(0xFF1A1918),
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Georgia',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Stack(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF4EEE6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.notifications_none_outlined,
                                    color: Color(0xFF1A1918),
                                    size: 22,
                                  ),
                                ),
                                Positioned(
                                  top: 13,
                                  right: 14,
                                  child: Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF945331),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // 2. SEARCH BOX & FILTER BUTTON
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 56,
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  right: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4EEE6),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _searchController,
                                        onSubmitted: (value) {
                                          _filterRequest.title =
                                              value.trim().isNotEmpty
                                                  ? value.trim()
                                                  : null;
                                          _loadData(isReset: true);
                                        },
                                        textInputAction: TextInputAction.search,
                                        style: const TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          fontSize: 15,
                                        ),
                                        decoration: const InputDecoration(
                                          hintText:
                                              'Tìm kiếm bất động sản...',
                                          border: InputBorder.none,
                                          hintStyle: TextStyle(
                                            color: Color(0xFF78736D),
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (_searchController.text.isNotEmpty)
                                      IconButton(
                                        icon: const Icon(Icons.cancel,
                                            size: 18,
                                            color: Color(0xFF78736D)),
                                        onPressed: () {
                                          setState(() {
                                            _searchController.clear();
                                            _filterRequest.title = null;
                                          });
                                          _loadData(isReset: true);
                                        },
                                      ),
                                    GestureDetector(
                                      onTap: () {
                                        String val =
                                            _searchController.text.trim();
                                        _filterRequest.title =
                                            val.isNotEmpty ? val : null;
                                        _loadData(isReset: true);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF945331),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: const Icon(
                                          Icons.search,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: _showFilterBottomSheet,
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF945331),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Icon(
                                  Icons.tune_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 2.1 THANH CHỌN LOẠI BĐS (CHO BÁN & CHO THUÊ)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const PropertyListScreen(
                                        pageTitle: 'Bất động sản Mua Bán',
                                        initialTypeId: 1,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF4EEE6),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: const Color(0xFFE8E3DC)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.house_outlined,
                                          color: Color(0xFF945331), size: 22),
                                      SizedBox(width: 8),
                                      Text(
                                        'Cho Bán',
                                        style: TextStyle(
                                          color: Color(0xFF1A1918),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          fontFamily: 'Plus Jakarta Sans',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const PropertyListScreen(
                                        pageTitle: 'Bất động sản Cho Thuê',
                                        initialTypeId: 2,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14, horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF4EEE6),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: const Color(0xFFE8E3DC)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.key_outlined,
                                          color: Color(0xFF945331), size: 22),
                                      SizedBox(width: 8),
                                      Text(
                                        'Cho Thuê',
                                        style: TextStyle(
                                          color: Color(0xFF1A1918),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          fontFamily: 'Plus Jakarta Sans',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 3. CATEGORIES ROW
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 46,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final cat = categories[index];
                            final isSelected = activeCategory == cat;
                            return Container(
                              margin: const EdgeInsets.only(right: 10),
                              child: ChoiceChip(
                                label: Text(cat),
                                selected: isSelected,
                                selectedColor: const Color(0xFF945331),
                                backgroundColor: const Color(0xFFF4EEE6),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF78736D),
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide.none,
                                ),
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      activeCategory = cat;
                                      if (cat == "Tất cả") {
                                        _filterRequest.title = null;
                                      } else {
                                        _filterRequest.title = cat;
                                      }
                                    });
                                    _loadData(isReset: true);
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),

                      // 4. HORIZONTAL FEATURED LIST
                      if (globalProperties.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 24,
                            right: 24,
                            top: 24,
                            bottom: 16,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Nổi bật',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1918),
                                  fontFamily: 'Georgia',
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const PropertyListScreen(
                                        pageTitle: 'Tất cả Bất động sản',
                                        initialTypeId: null,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Xem tất cả',
                                  style: TextStyle(
                                    color: Color(0xFF945331),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Plus Jakarta Sans',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (globalProperties.isNotEmpty)
                        SizedBox(
                          height: 385,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: globalProperties.length > 5
                                ? 5
                                : globalProperties.length,
                            itemBuilder: (context, index) {
                              final property = globalProperties[index];
                              return _buildHorizontalCard(property);
                            },
                          ),
                        ),

                      // 5. VERTICAL RECOMMENDATION LIST (LAZY LOADING)
                      Padding(
                        padding: const EdgeInsets.only(left: 24, top: 12, bottom: 16, right: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Đề xuất cho bạn',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1918),
                                fontFamily: 'Georgia',
                              ),
                            ),
                            if (_totalItems > 0)
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

                      if (globalProperties.isEmpty && !_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text(
                              'Không tìm thấy bất động sản phù hợp',
                              style: TextStyle(
                                color: Color(0xFF78736D),
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),

                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: globalProperties.length,
                        itemBuilder: (context, index) {
                          final property = globalProperties[index];
                          return _buildVerticalCard(property);
                        },
                      ),

                      if (_isLoadingMore)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF945331),
                            ),
                          ),
                        ),

                      if (!_hasMore && globalProperties.isNotEmpty)
                        const Padding(
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
                        ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHorizontalCard(PropertyDTO property) {
    return GestureDetector(
      onTap: () => openPropertyDetail(context, property),
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                (property.image != null && property.image!.isNotEmpty)
                    ? Image.network(
                        property.image!,
                        height: 195,
                        width: 280,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 195,
                          width: 280,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.image_not_supported),
                        ),
                      )
                    : Container(
                        height: 195,
                        width: 280,
                        color: Colors.grey.shade300,
                        child: const Icon(
                          Icons.home,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCFBFA).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      property.addressDetail ?? 'Bất động sản',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1918),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: GestureDetector(
                    onTap: () => _toggleSave(property),
                    child: CircleAvatar(
                      radius: 19,
                      backgroundColor: property.isSaved
                          ? const Color(0xFF945331)
                          : const Color(0xFF1A1918).withValues(alpha: 0.4),
                      child: Icon(
                        property.isSaved
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            property.title ?? "Chưa có tiêu đề",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1918),
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            formatPropertyPrice(property.price),
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Color(0xFF945331),
              fontFamily: 'Georgia',
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Color(0xFF78736D),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  property.address ?? property.city ?? 'Đang cập nhật địa chỉ',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF78736D),
                    fontSize: 13,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFE8E3DC), width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.bed_outlined, size: 18, color: Color(0xFF78736D)),
                const SizedBox(width: 5),
                Text(
                  '${property.bedroomCount ?? 0}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.bathtub_outlined,
                  size: 17,
                  color: Color(0xFF78736D),
                ),
                const SizedBox(width: 5),
                Text(
                  '${property.bathroomCount ?? 0}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.layers_outlined,
                  size: 16,
                  color: Color(0xFF78736D),
                ),
                const SizedBox(width: 5),
                Text(
                  '${property.floorCount ?? 1}T',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.crop_free, size: 15, color: Color(0xFF78736D)),
                const SizedBox(width: 6),
                Text(
                  property.area != null
                      ? '${property.area!.toStringAsFixed(0)}m²'
                      : 'N/A',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildVerticalCard(PropertyDTO property) {
    return GestureDetector(
      onTap: () => openPropertyDetail(context, property),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                (property.image != null && property.image!.isNotEmpty)
                    ? Image.network(
                        property.image!,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 120,
                          height: 120,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.image_not_supported),
                        ),
                      )
                    : Container(
                        width: 120,
                        height: 120,
                        color: Colors.grey.shade300,
                        child: const Icon(
                          Icons.home,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _toggleSave(property),
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: property.isSaved
                          ? const Color(0xFF945331)
                          : const Color(0xFF1A1918).withValues(alpha: 0.4),
                      child: Icon(
                        property.isSaved
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property.title ?? "Chưa có tiêu đề",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1918),
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  formatPropertyPrice(property.price),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: property.typeId == 2
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFF945331),
                    fontFamily: 'Georgia',
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 15,
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
                          fontSize: 13,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.bed_outlined,
                      size: 16,
                      color: Color(0xFF78736D),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${property.bedroomCount ?? 0} PN',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF78736D),
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.bathtub_outlined,
                      size: 15,
                      color: Color(0xFF78736D),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${property.bathroomCount ?? 0} PT',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF78736D),
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.layers_outlined,
                      size: 14,
                      color: Color(0xFF78736D),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${property.floorCount ?? 1} Tầng',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF78736D),
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.crop_free, size: 13, color: Color(0xFF78736D)),
                    const SizedBox(width: 4),
                    Text(
                      property.area != null
                          ? '${property.area!.toStringAsFixed(0)}m²'
                          : 'N/A',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF78736D),
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}
