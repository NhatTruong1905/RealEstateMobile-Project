class PropertyDTO {
  final int? id;
  final int? userId;
  final int? typeId;
  final int? categoryId;
  final String? title;
  final String? description;
  final String? address;
  final String? city;
  final int? wardId;
  final String? addressDetail;
  final double? price;
  final double? area;
  final int? floorCount;
  final int? bedroomCount;
  final int? bathroomCount;
  final String? direction;
  final String? legal;
  final String? status;
  final List<String>? images;
  final String? _image;
  final String? userPhone;
  final String? userFullname;
  final String? userEmail;

  bool isSaved;

  String? get image {
    if (images != null && images!.isNotEmpty) {
      return images!.first;
    }
    return _image;
  }

  PropertyDTO({
    this.id,
    this.userId,
    this.typeId,
    this.categoryId,
    this.title,
    this.description,
    this.address,
    this.city,
    this.wardId,
    this.addressDetail,
    this.price,
    this.area,
    this.floorCount,
    this.bedroomCount,
    this.bathroomCount,
    this.direction,
    this.legal,
    this.status,
    this.images,
    String? image,
    this.userPhone,
    this.userFullname,
    this.userEmail,
    this.isSaved = false,
  }) : _image = image;

  static String? cleanAddress(String? input) {
    if (input == null || input.trim().isEmpty) return input;
    String cleaned = input
        .replaceAll(
          RegExp(
            r'\(\s*Ward\s*ID:\s*\d+\s*,\s*District\s*ID:\s*\d+\s*\)',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(
          RegExp(
            r'\(\s*(?:Ward|District)\s*ID:\s*\d+\s*\)',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(
          RegExp(
            r'\b(?:Ward|District|wardId|districtId)\s*ID?\s*[:=]?\s*\d+\b',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'\(\s*\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s{2,}', caseSensitive: false), ' ')
        .replaceAll(RegExp(r',\s*,', caseSensitive: false), ',')
        .replaceAll(RegExp(r'^\s*,\s*|\s*,\s*$', caseSensitive: false), '')
        .trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  String? get displayAddress =>
      cleanAddress(addressDetail) ?? cleanAddress(address) ?? city;

  factory PropertyDTO.fromJson(Map<String, dynamic> json) {
    List<String>? parsedImages;
    if (json['images'] != null && json['images'] is List) {
      parsedImages = (json['images'] as List<dynamic>)
          .map((e) => e.toString())
          .toList();
    }

    return PropertyDTO(
      id: (json['id'] as num?)?.toInt(),
      userId: (json['userId'] as num?)?.toInt(),
      typeId: (json['typeId'] as num?)?.toInt(),
      categoryId: (json['categoryId'] as num?)?.toInt(),
      title: json['title'] as String?,
      description: json['description'] as String?,
      address: cleanAddress(json['address'] as String?),
      city: cleanAddress(json['city'] as String?),
      wardId: (json['wardId'] as num?)?.toInt(),
      addressDetail: cleanAddress(json['addressDetail'] as String?),
      price: (json['price'] as num?)?.toDouble(),
      area: (json['area'] as num?)?.toDouble(),
      floorCount: (json['floorCount'] as num?)?.toInt(),
      bedroomCount: (json['bedroomCount'] as num?)?.toInt(),
      bathroomCount: (json['bathroomCount'] as num?)?.toInt(),
      direction: json['direction'] as String?,
      legal: json['legal'] as String?,
      status: json['status'] as String?,
      images: parsedImages,
      image: json['image'] as String?,
      userPhone: json['userPhone'] as String?,
      userFullname: json['userFullname'] as String?,
      userEmail: json['userEmail'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'typeId': typeId,
      'categoryId': categoryId,
      'title': title,
      'description': description,
      'address': address,
      'city': city,
      'wardId': wardId,
      'addressDetail': addressDetail,
      'price': price,
      'area': area,
      'floorCount': floorCount,
      'bedroomCount': bedroomCount,
      'bathroomCount': bathroomCount,
      'direction': direction,
      'legal': legal,
      'status': status,
      'images': images,
      'image': image,
      'userPhone': userPhone,
      'userFullname': userFullname,
      'userEmail': userEmail,
    };
  }

  Map<String, String> toFields() {
    return {
      if (id != null) 'id': id.toString(),
      if (userId != null) 'userId': userId.toString(),
      if (typeId != null) 'typeId': typeId.toString(),
      if (categoryId != null) 'categoryId': categoryId.toString(),
      if (title != null && title!.trim().isNotEmpty) 'title': title!.trim(),
      if (description != null && description!.trim().isNotEmpty)
        'description': description!.trim(),
      if (address != null && address!.trim().isNotEmpty)
        'address': address!.trim(),
      if (city != null && city!.trim().isNotEmpty) 'city': city!.trim(),
      if (wardId != null) 'wardId': wardId.toString(),
      if (addressDetail != null && addressDetail!.trim().isNotEmpty)
        'addressDetail': addressDetail!.trim(),
      if (price != null) 'price': price.toString(),
      if (area != null) 'area': area.toString(),
      if (floorCount != null) 'floorCount': floorCount.toString(),
      if (bedroomCount != null) 'bedroomCount': bedroomCount.toString(),
      if (bathroomCount != null) 'bathroomCount': bathroomCount.toString(),
      if (direction != null && direction!.trim().isNotEmpty)
        'direction': direction!.trim(),
      if (legal != null && legal!.trim().isNotEmpty) 'legal': legal!.trim(),
      if (status != null && status!.trim().isNotEmpty) 'status': status!.trim(),
      if (images != null)
        for (var i = 0; i < images!.length; i++) 'images[$i]': images![i],
    };
  }

  Map<String, String> toFormData() => toFields();
}

