import 'PropertyDTO.dart';

class PropertyPageResponseDTO {
  final List<PropertyDTO> content;
  final int currentPage;
  final int totalItems;
  final int totalPages;

  PropertyPageResponseDTO({
    required this.content,
    required this.currentPage,
    required this.totalItems,
    required this.totalPages,
  });

  factory PropertyPageResponseDTO.fromJson(Map<String, dynamic> json) {
    List<dynamic> list = [];
    if (json['content'] is List) {
      list = json['content'];
    }

    return PropertyPageResponseDTO(
      content: list
          .map((item) => PropertyDTO.fromJson(item as Map<String, dynamic>))
          .toList(),
      currentPage: json['currentPage'] as int? ?? 1,
      totalItems: json['totalItems'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
    );
  }
}
