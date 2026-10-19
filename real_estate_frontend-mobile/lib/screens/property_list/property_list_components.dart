// ignore_for_file: invalid_use_of_protected_member

part of '../PropertyList.dart';

extension PropertyListComponents on _PropertyListScreenState {
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
            color: isSelected
                ? const Color(0xFF945331)
                : const Color(0xFFF4EEE6),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF945331).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
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
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
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
