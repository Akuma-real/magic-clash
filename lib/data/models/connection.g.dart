// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Connection _$ConnectionFromJson(Map<String, dynamic> json) => Connection(
  id: json['id'] as String,
  metadata: ConnectionMetadata.fromJson(
    json['metadata'] as Map<String, dynamic>,
  ),
  upload: (json['upload'] as num).toInt(),
  download: (json['download'] as num).toInt(),
  start: json['start'] as String,
  chains: (json['chains'] as List<dynamic>).map((e) => e as String).toList(),
  rule: json['rule'] as String,
  rulePayload: json['rulePayload'] as String,
);

Map<String, dynamic> _$ConnectionToJson(Connection instance) =>
    <String, dynamic>{
      'id': instance.id,
      'metadata': instance.metadata,
      'upload': instance.upload,
      'download': instance.download,
      'start': instance.start,
      'chains': instance.chains,
      'rule': instance.rule,
      'rulePayload': instance.rulePayload,
    };

ConnectionMetadata _$ConnectionMetadataFromJson(Map<String, dynamic> json) =>
    ConnectionMetadata(
      network: json['network'] as String,
      type: json['type'] as String,
      sourceIP: json['sourceIP'] as String,
      destinationIP: json['destinationIP'] as String,
      sourcePort: json['sourcePort'] as String,
      destinationPort: json['destinationPort'] as String,
      host: json['host'] as String,
      process: json['process'] as String?,
    );

Map<String, dynamic> _$ConnectionMetadataToJson(ConnectionMetadata instance) =>
    <String, dynamic>{
      'network': instance.network,
      'type': instance.type,
      'sourceIP': instance.sourceIP,
      'destinationIP': instance.destinationIP,
      'sourcePort': instance.sourcePort,
      'destinationPort': instance.destinationPort,
      'host': instance.host,
      'process': instance.process,
    };
