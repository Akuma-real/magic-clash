import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux) {
    await windowManager.ensureInitialized();
    await windowManager.setMinimumSize(const Size(400, 600));
    await windowManager.setSize(const Size(900, 700));
    await windowManager.setTitle('Magic Clash');
  }

  runApp(const App());
}
