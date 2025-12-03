import 'package:json_annotation/json_annotation.dart';

part 'core_version.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class CoreVersion {
  final String tagName;
  final String name;
  final List<CoreAsset> assets;

  const CoreVersion({
    required this.tagName,
    required this.name,
    required this.assets,
  });

  factory CoreVersion.fromJson(Map<String, dynamic> json) =>
      _$CoreVersionFromJson(json);

  Map<String, dynamic> toJson() => _$CoreVersionToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class CoreAsset {
  final String name;
  final String browserDownloadUrl;
  final int size;

  const CoreAsset({
    required this.name,
    required this.browserDownloadUrl,
    required this.size,
  });

  factory CoreAsset.fromJson(Map<String, dynamic> json) =>
      _$CoreAssetFromJson(json);

  Map<String, dynamic> toJson() => _$CoreAssetToJson(this);
}
