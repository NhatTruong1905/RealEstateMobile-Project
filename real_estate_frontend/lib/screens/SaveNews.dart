import 'package:flutter/material.dart';
import 'package:real_estate_frontend/layout/Footer.dart';
import 'package:real_estate_frontend/screens/Home.dart';

class SavedNewsScreen extends StatefulWidget {
  const SavedNewsScreen({super.key});

  @override
  State<SavedNewsScreen> createState() => _SavedNewsScreenState();
}

class _SavedNewsScreenState extends State<SavedNewsScreen> {
  @override
  Widget build(BuildContext context) {
    final savedItems = globalProperties.where((p) => p.isSaved).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFCFBFA),
      body: SafeArea(
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
              child: savedItems.isNotEmpty
                  ? ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: savedItems.length,
                      itemBuilder: (context, index) {
                        final property = savedItems[index];
                        return _buildVerticalCard(property);
                      },
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: const Color(0xFFF4EEE6),
                            child: Icon(
                              Icons.favorite_border,
                              size: 32,
                              color: const Color(0xFF78736D),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Chưa có mục nào',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1918),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 60),
                            child: Text(
                              'Bạn chưa lưu bất động sản nào. Hãy khám phá và thả tim nhé!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF78736D),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const Footer(currentIndex: 1),
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
                    onTap: () =>
                        setState(() => property.isSaved = !property.isSaved),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFF945331),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 16,
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF945331),
                    fontFamily: 'Georgia',
                  ),
                ),
                Text(
                  property.title,
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
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
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
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.bed_outlined,
                      size: 14,
                      color: Color(0xFF78736D),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${property.beds}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF78736D),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.bathtub_outlined,
                      size: 14,
                      color: Color(0xFF78736D),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${property.baths}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF78736D),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.fullscreen,
                      size: 14,
                      color: Color(0xFF78736D),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${property.area}m²',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF78736D),
                      ),
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
