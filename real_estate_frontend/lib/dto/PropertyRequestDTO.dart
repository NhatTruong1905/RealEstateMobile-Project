class PropertyRequestDTO {
  String? title;
  double? fromPrice;
  double? toPrice;
  double? area;
  String? address;
  int? districtId;
  int? wardId;
  int? floorCount;
  int? bedroomCount;
  int? bathroomCount;
  String? direction;
  String? legal;
  int? staffId;
  int? categoryId;
  int? typeId;
  String? statusProperty;

  int page;
  int limit;

  PropertyRequestDTO({
    this.title,
    this.fromPrice,
    this.toPrice,
    this.area,
    this.address,
    this.districtId,
    this.wardId,
    this.floorCount,
    this.bedroomCount,
    this.bathroomCount,
    this.direction,
    this.legal,
    this.staffId,
    this.categoryId,
    this.typeId,
    this.statusProperty,
    this.page = 1,
    this.limit = 6,
    String? keyword,
    String? city,
    double? minPrice,
    double? maxPrice,
    int? size,
  }) {
    if (keyword != null && keyword.trim().isNotEmpty && (title == null || title!.isEmpty)) {
      title = keyword;
    }
    if (city != null && city.trim().isNotEmpty && (address == null || address!.isEmpty)) {
      address = city;
    }
    if (minPrice != null && minPrice > 0 && fromPrice == null) {
      fromPrice = minPrice;
    }
    if (maxPrice != null && maxPrice > 0 && toPrice == null) {
      toPrice = maxPrice;
    }
    if (size != null && size > 0) {
      limit = size;
    }
  }

  String? get keyword => title;
  set keyword(String? val) => title = val;

  String? get city => address;
  set city(String? val) => address = val;

  double? get minPrice => fromPrice;
  set minPrice(double? val) => fromPrice = val;

  double? get maxPrice => toPrice;
  set maxPrice(double? val) => toPrice = val;

  int get size => limit;
  set size(int val) => limit = val;

  Map<String, String> toQueryParams() {
    final Map<String, String> params = {};

    if (title != null && title!.trim().isNotEmpty) {
      params['title'] = title!.trim();
    }
    if (fromPrice != null && fromPrice! > 0) {
      params['fromPrice'] = fromPrice.toString();
    }
    if (toPrice != null && toPrice! > 0) {
      params['toPrice'] = toPrice.toString();
    }
    if (area != null && area! > 0) {
      params['area'] = area.toString();
    }
    if (address != null && address!.trim().isNotEmpty) {
      params['address'] = address!.trim();
    }
    if (districtId != null && districtId! > 0) {
      params['districtId'] = districtId.toString();
    }
    if (wardId != null && wardId! > 0) {
      params['wardId'] = wardId.toString();
    }
    if (floorCount != null && floorCount! > 0) {
      params['floorCount'] = floorCount.toString();
    }
    if (bedroomCount != null && bedroomCount! > 0) {
      params['bedroomCount'] = bedroomCount.toString();
    }
    if (bathroomCount != null && bathroomCount! > 0) {
      params['bathroomCount'] = bathroomCount.toString();
    }
    if (direction != null && direction!.trim().isNotEmpty) {
      params['direction'] = direction!.trim();
    }
    if (legal != null && legal!.trim().isNotEmpty) {
      params['legal'] = legal!.trim();
    }
    if (staffId != null && staffId! > 0) {
      params['staffId'] = staffId.toString();
    }
    if (categoryId != null && categoryId! > 0) {
      params['categoryId'] = categoryId.toString();
    }
    if (typeId != null && typeId! > 0) {
      params['typeId'] = typeId.toString();
    }
    if (statusProperty != null && statusProperty!.trim().isNotEmpty) {
      params['statusProperty'] = statusProperty!.trim();
    }

    params['page'] = page.toString();
    params['limit'] = limit.toString();

    return params;
  }

  PropertyRequestDTO copyWith({
    String? title,
    double? fromPrice,
    double? toPrice,
    double? area,
    String? address,
    int? districtId,
    int? wardId,
    int? floorCount,
    int? bedroomCount,
    int? bathroomCount,
    String? direction,
    String? legal,
    int? staffId,
    int? categoryId,
    int? typeId,
    String? statusProperty,
    int? page,
    int? limit,
    String? keyword,
    String? city,
    double? minPrice,
    double? maxPrice,
    int? size,
  }) {
    return PropertyRequestDTO(
      title: title ?? this.title,
      fromPrice: fromPrice ?? this.fromPrice,
      toPrice: toPrice ?? this.toPrice,
      area: area ?? this.area,
      address: address ?? this.address,
      districtId: districtId ?? this.districtId,
      wardId: wardId ?? this.wardId,
      floorCount: floorCount ?? this.floorCount,
      bedroomCount: bedroomCount ?? this.bedroomCount,
      bathroomCount: bathroomCount ?? this.bathroomCount,
      direction: direction ?? this.direction,
      legal: legal ?? this.legal,
      staffId: staffId ?? this.staffId,
      categoryId: categoryId ?? this.categoryId,
      typeId: typeId ?? this.typeId,
      statusProperty: statusProperty ?? this.statusProperty,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      keyword: keyword,
      city: city,
      minPrice: minPrice,
      maxPrice: maxPrice,
      size: size,
    );
  }
}
