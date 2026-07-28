import 'package:flutter/material.dart';
import 'package:real_estate_frontend/dto/PropertyDTO.dart';
import 'package:real_estate_frontend/mixin/api/APIPropertyMixin.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:real_estate_frontend/screens/Home.dart';
import 'package:real_estate_frontend/screens/Auth.dart';

class SavedNewsScreen extends StatefulWidget {
  const SavedNewsScreen({super.key});

  @override
  State<SavedNewsScreen> createState() => _SavedNewsScreenState();
}

class _SavedNewsScreenState extends State<SavedNewsScreen> with ApiPropertyMixin {
  bool _isLoggedIn = false;
  bool _isLoading = true;
  List<PropertyDTO> _savedProperties = [];

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    _isLoggedIn = token != null && token.isNotEmpty;

    if (_isLoggedIn) {
      // Gọi API lấy TẤT CẢ bất động sản đã thả tim từ Backend
      List<PropertyDTO> favData = await fetchFavoriteProperties();
      for (var p in favData) {
        p.isSaved = true;
      }
      _savedProperties = favData;

      // Đồng bộ lại trạng thái isSaved cho các phần tử đang có trong globalProperties (nếu có)
      for (var p in globalProperties) {
        if (p.id != null) {
          p.isSaved = userFavoriteIds.contains(p.id);
        }
      }
    } else {
      _savedProperties = [];
      userFavoriteIds.clear();
      for (var p in globalProperties) {
        p.isSaved = false;
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _checkLoginStatus();
  }

  @override
  Widget build(BuildContext context) {
    final savedItems = _savedProperties;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFBFA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF945331)))
          : SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF945331),
          onRefresh: _refreshData,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Đã lưu',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1918),
                        fontFamily: 'Georgia',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${savedItems.length} bất động sản yêu thích',
                      style: const TextStyle(
                        color: Color(0xFF78736D),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: !_isLoggedIn
                // TRẠNG THÁI CHƯA ĐĂNG NHẬP
                    ? Center(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircleAvatar(
                          radius: 40,
                          backgroundColor: Color(0xFFF4EEE6),
                          child: Icon(Icons.lock_outline, size: 32, color: Color(0xFF78736D)),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Bạn chưa đăng nhập',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1918)),
                        ),
                        const SizedBox(height: 8),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 60),
                          child: Text('Hãy đăng nhập để quản lý các bất động sản yêu thích của bạn!', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF78736D), fontSize: 14)),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const AuthScreen()))
                                .then((_) => _checkLoginStatus());
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF945331),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                          ),
                          child: const Text("Đăng nhập ngay", style: TextStyle(color: Colors.white)),
                        )
                      ],
                    ),
                  ),
                )
                    : savedItems.isNotEmpty
                // DANH SÁCH ĐÃ LƯU TẤT CẢ
                    ? ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: savedItems.length,
                  itemBuilder: (context, index) {
                    final property = savedItems[index];
                    return _buildVerticalCard(property);
                  },
                )
                // TRẠNG THÁI TRỐNG
                    : Center(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircleAvatar(
                          radius: 40,
                          backgroundColor: Color(0xFFF4EEE6),
                          child: Icon(Icons.favorite_border, size: 32, color: Color(0xFF78736D)),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Chưa có mục nào',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1918)),
                        ),
                        const SizedBox(height: 8),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 60),
                          child: Text(
                            'Bạn chưa lưu bất động sản nào. Hãy khám phá và thả tim nhé!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF78736D), fontSize: 14),
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
      ),
    );
  }

  Widget _buildVerticalCard(PropertyDTO property) {
    return Padding(
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
                    width: 120, height: 120, color: Colors.grey.shade300, child: const Icon(Icons.image_not_supported),
                  ),
                )
                    : Container(width: 120, height: 120, color: Colors.grey.shade300, child: const Icon(Icons.image)),

                // NÚT BỎ LƯU
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () async {
                      if (property.id == null) return;

                      // Cập nhật UI danh sách đã lưu lập tức
                      setState(() {
                        userFavoriteIds.remove(property.id!);
                        _savedProperties.removeWhere((p) => p.id == property.id);
                      });

                      // Cập nhật lại thuộc tính isSaved ở globalProperties nếu có
                      for (var p in globalProperties) {
                        if (p.id == property.id) {
                          p.isSaved = false;
                        }
                      }

                      await syncFavoriteProperties(userFavoriteIds.toList());
                    },
                    child: const CircleAvatar(
                      radius: 16,
                      backgroundColor: Color(0xFF945331),
                      child: Icon(Icons.favorite, color: Colors.white, size: 16),
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
                  "${property.price ?? 'Thỏa thuận'} VNĐ",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF945331),
                    fontFamily: 'Georgia',
                  ),
                ),
                Text(
                  property.title ?? "Chưa có tiêu đề",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1918),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF78736D)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        property.address ?? property.city ?? 'Chưa cập nhật',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF78736D), fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.bed_outlined, size: 14, color: Color(0xFF78736D)),
                    const SizedBox(width: 4),
                    Text('${property.bedroomCount ?? 0}', style: const TextStyle(fontSize: 12, color: Color(0xFF78736D))),
                    const SizedBox(width: 12),
                    const Icon(Icons.bathtub_outlined, size: 14, color: Color(0xFF78736D)),
                    const SizedBox(width: 4),
                    Text('${property.bathroomCount ?? 0}', style: const TextStyle(fontSize: 12, color: Color(0xFF78736D))),
                    const SizedBox(width: 12),
                    const Icon(Icons.fullscreen, size: 14, color: Color(0xFF78736D)),
                    const SizedBox(width: 4),
                    Text(
                      property.area != null ? '${property.area!.toStringAsFixed(0)}m²' : 'N/A',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF78736D)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}