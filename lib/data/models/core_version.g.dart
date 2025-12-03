// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'core_version.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CoreVersion _$CoreVersionFromJson(Map<String, dynamic> json) => CoreVersion(
  tagName: json['tag_name'] as String,
  name: json['name'] as String,
  assets: (json['assets'] as List<dynamic>)
      .map((e) => CoreAsset.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$CoreVersionToJson(CoreVersion instance) =>
    <String, dynamic>{
      'tag_name': instance.tagName,
      'name': instance.name,
      'assets': instance.assets,
    };

CoreAsset _$CoreAssetFromJson(Map<String, dynamic> json) => CoreAsset(
  name: json['name'] as String,
  browserDownloadUrl: json['browser_download_url'] as String,
  size: (json['size'] as num).toInt(),
);

Map<String, dynamic> _$CoreAssetToJson(CoreAsset instance) => <String, dynamic>{
  'name': instance.name,
  'browser_download_url': instance.browserDownloadUrl,
  'size': instance.size,
};
