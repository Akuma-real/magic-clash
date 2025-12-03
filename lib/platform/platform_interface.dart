import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

abstract class PlatformInterface {
  Future<String> getCorePath();
  Future<String> getConfigDirectory();
  Future<String> getLogDirectory();
  Future<void> setSystemProxy(String host, int port);
  Future<void> clearSystemProxy();

  static PlatformInterface get instance {
    if (Platform.isWindows) return WindowsPlatform();
    if (Platform.isLinux) return LinuxPlatform();
    if (Platform.isAndroid) return AndroidPlatform();
    throw UnsupportedError('Unsupported platform');
  }
}

class WindowsPlatform implements PlatformInterface {
  @override
  Future<String> getCorePath() async {
    final appDir = await getApplicationSupportDirectory();
    return p.join(appDir.path, 'mihomo', 'mihomo.exe');
  }

  @override
  Future<String> getConfigDirectory() async {
    final appDir = await getApplicationSupportDirectory();
    return p.join(appDir.path, 'configs');
  }

  @override
  Future<String> getLogDirectory() async {
    final appDir = await getApplicationSupportDirectory();
    return p.join(appDir.path, 'logs');
  }

  @override
  Future<void> setSystemProxy(String host, int port) async {
    await Process.run('reg', [
      'add',
      r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings',
      '/v', 'ProxyEnable', '/t', 'REG_DWORD', '/d', '1', '/f'
    ]);
    await Process.run('reg', [
      'add',
      r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings',
      '/v', 'ProxyServer', '/t', 'REG_SZ', '/d', '$host:$port', '/f'
    ]);
  }

  @override
  Future<void> clearSystemProxy() async {
    await Process.run('reg', [
      'add',
      r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings',
      '/v', 'ProxyEnable', '/t', 'REG_DWORD', '/d', '0', '/f'
    ]);
  }
}

class LinuxPlatform implements PlatformInterface {
  @override
  Future<String> getCorePath() async {
    final home = Platform.environment['HOME'] ?? '/tmp';
    return p.join(home, '.local', 'share', 'mihomo-valdi', 'mihomo');
  }

  @override
  Future<String> getConfigDirectory() async {
    final home = Platform.environment['HOME'] ?? '/tmp';
    return p.join(home, '.config', 'mihomo-valdi', 'configs');
  }

  @override
  Future<String> getLogDirectory() async {
    final home = Platform.environment['HOME'] ?? '/tmp';
    return p.join(home, '.local', 'share', 'mihomo-valdi', 'logs');
  }

  @override
  Future<void> setSystemProxy(String host, int port) async {
    // GNOME
    await Process.run('gsettings', [
      'set', 'org.gnome.system.proxy', 'mode', 'manual'
    ]);
    await Process.run('gsettings', [
      'set', 'org.gnome.system.proxy.http', 'host', host
    ]);
    await Process.run('gsettings', [
      'set', 'org.gnome.system.proxy.http', 'port', port.toString()
    ]);
    await Process.run('gsettings', [
      'set', 'org.gnome.system.proxy.https', 'host', host
    ]);
    await Process.run('gsettings', [
      'set', 'org.gnome.system.proxy.https', 'port', port.toString()
    ]);
    await Process.run('gsettings', [
      'set', 'org.gnome.system.proxy.socks', 'host', host
    ]);
    await Process.run('gsettings', [
      'set', 'org.gnome.system.proxy.socks', 'port', port.toString()
    ]);
  }

  @override
  Future<void> clearSystemProxy() async {
    await Process.run('gsettings', [
      'set', 'org.gnome.system.proxy', 'mode', 'none'
    ]);
  }
}

class AndroidPlatform implements PlatformInterface {
  static const _channel = MethodChannel('com.mihomo.mihomo_valdi/vpn');

  @override
  Future<String> getCorePath() async {
    final appDir = await getApplicationDocumentsDirectory();
    return p.join(appDir.path, 'mihomo');
  }

  @override
  Future<String> getConfigDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    return p.join(appDir.path, 'configs');
  }

  @override
  Future<String> getLogDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    return p.join(appDir.path, 'logs');
  }

  @override
  Future<void> setSystemProxy(String host, int port) async {
    await _channel.invokeMethod('startVpn', {
      'host': host,
      'port': port,
    });
  }

  @override
  Future<void> clearSystemProxy() async {
    await _channel.invokeMethod('stopVpn');
  }

  Future<bool> requestVpnPermission() async {
    return await _channel.invokeMethod('requestPermission') ?? false;
  }
}
