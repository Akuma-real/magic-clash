// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConfigProfile _$ConfigProfileFromJson(Map<String, dynamic> json) =>
    ConfigProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      fileName: json['fileName'] as String,
      sourceUrl: json['sourceUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$ConfigProfileToJson(ConfigProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'fileName': instance.fileName,
      'sourceUrl': instance.sourceUrl,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
