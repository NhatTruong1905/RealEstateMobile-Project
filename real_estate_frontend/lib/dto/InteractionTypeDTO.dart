class InteractionTypeDTO {
  final int? id;
  final String? name;

  InteractionTypeDTO({this.id, this.name});

  factory InteractionTypeDTO.fromJson(Map<String, dynamic> json) {
    return InteractionTypeDTO(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
    );
  }
}
