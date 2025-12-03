import 'package:json_annotation/json_annotation.dart';

part 'config_profile.g.dart';

@JsonSerializable()
class ConfigProfile {
  final String id;
  final String name;
  final String fileName;
  final String? sourceUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ConfigProfile({
    required this.id,
    required this.name,
    required this.fileName,
    this.sourceUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConfigProfile.fromJson(Map<String, dynamic> json) =>
      _$ConfigProfileFromJson(json);
  Map<String, dynamic> toJson() => _$ConfigProfileToJson(this);

  ConfigProfile copyWith({DateTime? updatedAt}) => ConfigProfile(
        id: id,
        name: name,
        fileName: fileName,
        sourceUrl: sourceUrl,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  bool get isSubscription => sourceUrl != null;
}
