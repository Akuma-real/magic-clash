/// 日志类型枚举
enum LogType {
  /// 标准输出
  stdout,

  /// 标准错误输出
  stderr,

  /// 系统消息（如启动、停止等）
  system,
}

/// 日志条目模型
class LogEntry {
  /// 日志时间戳
  final DateTime timestamp;

  /// 日志类型
  final LogType type;

  /// 日志内容
  final String message;

  const LogEntry({
    required this.timestamp,
    required this.type,
    required this.message,
  });

  /// 获取格式化的时间字符串
  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
