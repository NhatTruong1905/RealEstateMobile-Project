import 'package:flutter/material.dart';
import 'package:real_estate_frontend/layout/Footer.dart';

// --- DATA MODEL ---
class Property {
  final int id;
  final String title;
  final String price;
  final String location;
  final int beds;
  final int baths;
  final int area;
  final String image;
  bool isSaved;
  final String tag;

  Property({
    required this.id,
    required this.title,
    required this.price,
    required this.location,
    required this.beds,
    required this.baths,
    required this.area,
    required this.image,
    required this.isSaved,
    required this.tag,
  });
}

// --- GLOBAL STATE MOCK ---
List<Property> globalProperties = [
  Property(
    id: 1,
    title: "Biệt thự Thảo Điền",
    price: "45 Tỷ",
    location: "Quận 2, TP. Hồ Chí Minh",
    beds: 5,
    baths: 6,
    area: 450,
    image: "https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800",
    isSaved: true,
    tag: "Cao cấp",
  ),
  Property(
    id: 2,
    title: "Căn hộ Vinhomes Central Park",
    price: "6.5 Tỷ",
    location: "Bình Thạnh, TP. Hồ Chí Minh",
    beds: 2,
    baths: 2,
    area: 85,
    image: "https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800",
    isSaved: false,
    tag: "Bán chạy",
  ),
  Property(
    id: 3,
    title: "Nhà phố Lakeview City",
    price: "18 Tỷ",
    location: "Quận 2, TP. Hồ Chí Minh",
    beds: 4,
    baths: 4,
    area: 120,
    image: "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800",
    isSaved: true,
    tag: "Mới",
  ),
  Property(
    id: 4,
    title: "Penthouse Đảo Kim Cương",
    price: "32 Tỷ",
    location: "Quận 2, TP. Hồ Chí Minh",
    beds: 3,
    baths: 4,
    area: 320,
    image: "https://images.unsplash.com/photo-1600607687920-4e2a09cf159d?w=800",
    isSaved: false,
    tag: "Độc quyền",
  ),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String activeCategory = "Tất cả";
  final List<String> categories = [
    "Tất cả",
    "Biệt thự",
    "Căn hộ",
    "Nhà phố",
    "Đất nền",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFBFA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HEADER (Đã đổi mainAxisAlignment sangspaceBetween để đẩy đều hai bên)
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 16),
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

              // 2. SEARCH BOX
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4EEE6),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.search,
                              color: Color(0xFF78736D),
                              size: 22,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 15),
                                decoration: InputDecoration(
                                  hintText: 'Tìm kiếm bất động sản...',
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(
                                    color: Color(0xFF78736D),
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
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
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: InkWell(
                        onTap: () => setState(() => activeCategory = cat),
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF1A1918)
                                : const Color(0xFFF4EEE6),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Center(
                            child: Text(
                              cat,
                              style: TextStyle(
                                color: isSelected
                                    ? const Color(0xFFFCFBFA)
                                    : const Color(0xFF1A1918),
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 4. HORIZONTAL FEATURED PROPERTIES
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24, top: 32, bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // Đẩy sang 2 đầu rìa màn hình
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Nổi bật',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1918),
                        fontFamily: 'Georgia',
                      ),
                    ),
                    InkWell(
                      onTap: () {},
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

              // Đã nâng chiều cao từ 340 lên 365 để giải quyết triệt để lỗi Overflow phần Bottom
              SizedBox(
                height: 385,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: globalProperties.length,
                  itemBuilder: (context, index) {
                    final property = globalProperties[index];
                    return _buildHorizontalCard(property);
                  },
                ),
              ),

              // 5. VERTICAL RECOMMENDATION LIST
              const Padding(
                padding: EdgeInsets.only(left: 24, top: 12, bottom: 16),
                child: Text(
                  'Đề xuất cho bạn',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1918),
                    fontFamily: 'Georgia',
                  ),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: globalProperties.length,
                itemBuilder: (context, index) {
                  final property = globalProperties[globalProperties.length - 1 - index];
                  return _buildVerticalCard(property);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const Footer(currentIndex: 0),
    );
  }

  Widget _buildHorizontalCard(Property property) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Image.network(
                  property.image,
                  height: 195,
                  width: 280,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCFBFA).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      property.tag,
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
                    onTap: () => setState(() => property.isSaved = !property.isSaved),
                    child: CircleAvatar(
                      radius: 19,
                      backgroundColor: property.isSaved
                          ? const Color(0xFF945331)
                          : const Color(0xFF1A1918).withOpacity(0.4),
                      child: Icon(
                        property.isSaved ? Icons.favorite : Icons.favorite_border,
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
            property.title,
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
            property.price,
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
                  property.location,
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
              border: Border(top: BorderSide(color: Color(0xFFE8E3DC), width: 1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.bed_outlined, size: 18, color: Color(0xFF78736D)),
                const SizedBox(width: 5),
                Text(
                  '${property.beds}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Plus Jakarta Sans', fontSize: 13),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.bathtub_outlined, size: 17, color: Color(0xFF78736D)),
                const SizedBox(width: 5),
                Text(
                  '${property.baths}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Plus Jakarta Sans', fontSize: 13),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.crop_free, size: 15, color: Color(0xFF78736D)),
                const SizedBox(width: 6),
                Text(
                  '${property.area}m²',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Plus Jakarta Sans', fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalCard(Property property) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Image.network(
                  property.image,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => setState(() => property.isSaved = !property.isSaved),
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: property.isSaved
                          ? const Color(0xFF945331)
                          : const Color(0xFF1A1918).withOpacity(0.4),
                      child: Icon(
                        property.isSaved ? Icons.favorite : Icons.favorite_border,
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
                  property.price,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF945331),
                    fontFamily: 'Georgia',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  property.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1918),
                    fontFamily: 'Plus Jakarta Sans',
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
                        property.location,
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
                    const Icon(Icons.bed_outlined, size: 16, color: Color(0xFF78736D)),
                    const SizedBox(width: 4),
                    Text(
                      '${property.beds}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF78736D), fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 14),
                    const Icon(Icons.bathtub_outlined, size: 15, color: Color(0xFF78736D)),
                    const SizedBox(width: 4),
                    Text(
                      '${property.baths}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF78736D), fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 14),
                    const Icon(Icons.crop_free, size: 13, color: Color(0xFF78736D)),
                    const SizedBox(width: 4),
                    Text(
                      '${property.area}m²',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF78736D), fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w600),
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