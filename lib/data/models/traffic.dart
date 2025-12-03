import 'package:json_annotation/json_annotation.dart';

part 'traffic.g.dart';

@JsonSerializable()
class Traffic {
  final int up;
  final int down;

  const Traffic({required this.up, required this.down});

  factory Traffic.fromJson(Map<String, dynamic> json) =>
      _$TrafficFromJson(json);

  Map<String, dynamic> toJson() => _$TrafficToJson(this);
}
