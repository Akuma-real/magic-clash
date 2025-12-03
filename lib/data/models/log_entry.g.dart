// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LogEntry _$LogEntryFromJson(Map<String, dynamic> json) =>
    LogEntry(type: json['type'] as String, payload: json['payload'] as String);

Map<String, dynamic> _$LogEntryToJson(LogEntry instance) => <String, dynamic>{
  'type': instance.type,
  'payload': instance.payload,
};
