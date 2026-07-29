// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'PropertyDTO.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PropertyDTO _$PropertyDTOFromJson(Map<String, dynamic> json) => PropertyDTO(
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

Map<String, dynamic> _$PropertyDTOToJson(PropertyDTO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'typeId': instance.typeId,
      'categoryId': instance.categoryId,
      'title': instance.title,
      'description': instance.description,
      'address': instance.address,
      'city': instance.city,
      'wardId': instance.wardId,
      'addressDetail': instance.addressDetail,
      'price': instance.price,
      'area': instance.area,
      'floorCount': instance.floorCount,
      'bedroomCount': instance.bedroomCount,
      'bathroomCount': instance.bathroomCount,
      'direction': instance.direction,
      'legal': instance.legal,
      'status': instance.status,
      'image': instance.image,
      'userPhone': instance.userPhone,
      'userFullname': instance.userFullname,
      'userEmail': instance.userEmail,
    };
