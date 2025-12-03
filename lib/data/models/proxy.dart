import 'package:json_annotation/json_annotation.dart';

part 'proxy.g.dart';

@JsonSerializable()
class Proxy {
  final String name;
  final String type;
  final bool udp;
  final int? delay;
  final List<String>? all;
  final String? now;

  const Proxy({
    required this.name,
    required this.type,
    this.udp = false,
    this.delay,
    this.all,
    this.now,
  });

  factory Proxy.fromJson(Map<String, dynamic> json) => _$ProxyFromJson(json);

  Map<String, dynamic> toJson() => _$ProxyToJson(this);

  bool get isGroup => all != null && all!.isNotEmpty;
}
