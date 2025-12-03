// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'traffic.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Traffic _$TrafficFromJson(Map<String, dynamic> json) => Traffic(
  up: (json['up'] as num).toInt(),
  down: (json['down'] as num).toInt(),
);

Map<String, dynamic> _$TrafficToJson(Traffic instance) => <String, dynamic>{
  'up': instance.up,
  'down': instance.down,
};
