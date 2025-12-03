class CoreNotRunningException implements Exception {
  final String message;
  const CoreNotRunningException([this.message = '请先启动核心']);
  @override
  String toString() => message;
}

class ConfigNotFoundException implements Exception {
  final String message;
  const ConfigNotFoundException([this.message = '配置文件未找到']);
  @override
  String toString() => message;
}

class SubscriptionParseException implements Exception {
  final String message;
  const SubscriptionParseException([this.message = '订阅解析失败']);
  @override
  String toString() => message;
}
