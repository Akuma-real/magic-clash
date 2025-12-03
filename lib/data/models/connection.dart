import 'package:json_annotation/json_annotation.dart';

part 'connection.g.dart';

@JsonSerializable()
class Connection {
  final String id;
  final ConnectionMetadata metadata;
  final int upload;
  final int download;
  final String start;
  final List<String> chains;
  final String rule;
  final String rulePayload;

  const Connection({
    required this.id,
    required this.metadata,
    required this.upload,
    required this.download,
    required this.start,
    required this.chains,
    required this.rule,
    required this.rulePayload,
  });

  factory Connection.fromJson(Map<String, dynamic> json) =>
      _$ConnectionFromJson(json);

  Map<String, dynamic> toJson() => _$ConnectionToJson(this);
}

@JsonSerializable()
class ConnectionMetadata {
  final String network;
  final String type;
  final String sourceIP;
  final String destinationIP;
  final String sourcePort;
  final String destinationPort;
  final String host;
  final String? process;

  const ConnectionMetadata({
    required this.network,
    required this.type,
    required this.sourceIP,
    required this.destinationIP,
    required this.sourcePort,
    required this.destinationPort,
    required this.host,
    this.process,
  });

  factory ConnectionMetadata.fromJson(Map<String, dynamic> json) =>
      _$ConnectionMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$ConnectionMetadataToJson(this);
}
