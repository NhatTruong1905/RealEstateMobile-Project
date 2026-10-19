part of '../Home.dart';

extension HomePropertyCards on _HomeScreenState {
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
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
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
            Container(
              padding: const EdgeInsets.only(top: 10),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFE8E3DC), width: 1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.bed_outlined,
                    size: 18,
                    color: Color(0xFF78736D),
                  ),
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
                  const Icon(
                    Icons.crop_free,
                    size: 15,
                    color: Color(0xFF78736D),
                  ),
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
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
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
                      const Icon(
                        Icons.crop_free,
                        size: 13,
                        color: Color(0xFF78736D),
                      ),
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
