import 'package:flutter/material.dart';
import 'package:real_estate_frontend/dto/PropertyPageResponseDTO.dart';
import 'package:real_estate_frontend/mixin/api/APIPropertyMixin.dart';
import 'package:real_estate_frontend/screens/PropertyDetail.dart';
import 'package:real_estate_frontend/screens/PropertyList.dart';
import 'package:real_estate_frontend/utils/PriceFormatter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:real_estate_frontend/screens/Auth.dart';
import 'package:real_estate_frontend/services/ChatService.dart';
import 'package:real_estate_frontend/widgets/RagChatModal.dart';
import '../../dto/PropertyDTO.dart';
import '../../dto/PropertyRequestDTO.dart';

part 'home/home_filter_sheet.dart';
part 'home/home_view.dart';
part 'home/home_property_cards.dart';

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

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _isLoggedIn = false;
  bool _showScrollToTop = false;
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
        globalProperties = fetched;
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
        globalProperties.addAll(fetched);
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

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
