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
  final String? image;
  final String? userPhone;
  final String? userFullname;
  final String? userEmail;

  bool isSaved;

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
    this.image,
    this.userPhone,
    this.userFullname,
    this.userEmail,
    this.isSaved = false,
  });

  factory PropertyDTO.fromJson(Map<String, dynamic> json) {
    return PropertyDTO(
      id: (json['id'] as num?)?.toInt(),
      userId: (json['userId'] as num?)?.toInt(),
      typeId: (json['typeId'] as num?)?.toInt(),
      categoryId: (json['categoryId'] as num?)?.toInt(),
      title: json['title'] as String?,
      description: json['description'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      wardId: (json['wardId'] as num?)?.toInt(),
      addressDetail: json['addressDetail'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      area: (json['area'] as num?)?.toDouble(),
      floorCount: (json['floorCount'] as num?)?.toInt(),
      bedroomCount: (json['bedroomCount'] as num?)?.toInt(),
      bathroomCount: (json['bathroomCount'] as num?)?.toInt(),
      direction: json['direction'] as String?,
      legal: json['legal'] as String?,
      status: json['status'] as String?,
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
      'image': image,
      'userPhone': userPhone,
      'userFullname': userFullname,
      'userEmail': userEmail,
    };
  }
}
