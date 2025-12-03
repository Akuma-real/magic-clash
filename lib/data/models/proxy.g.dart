// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proxy.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Proxy _$ProxyFromJson(Map<String, dynamic> json) => Proxy(
  name: json['name'] as String,
  type: json['type'] as String,
  udp: json['udp'] as bool? ?? false,
  delay: (json['delay'] as num?)?.toInt(),
  all: (json['all'] as List<dynamic>?)?.map((e) => e as String).toList(),
  now: json['now'] as String?,
);

Map<String, dynamic> _$ProxyToJson(Proxy instance) => <String, dynamic>{
  'name': instance.name,
  'type': instance.type,
  'udp': instance.udp,
  'delay': instance.delay,
  'all': instance.all,
  'now': instance.now,
};
