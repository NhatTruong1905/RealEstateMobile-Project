import 'package:json_annotation/json_annotation.dart';

part 'PropertyDTO.g.dart';

//1. flutter pub add json_annotation
//2. flutter pub add dev:build_runner dev:json_serializable
@JsonSerializable()
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

  @JsonKey(includeFromJson: false, includeToJson: false)
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
    this.isSaved = false,
  });

  factory PropertyDTO.fromJson(Map<String, dynamic> json) =>
      _$PropertyDTOFromJson(json);

  Map<String, dynamic> toJson() => _$PropertyDTOToJson(this);
}

//3. flutter pub run build_runner build --delete-conflicting-outputs
