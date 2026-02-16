import 'dart:isolate';
import 'dart:ui';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'screens/home_screen.dart';
import 'services/audio_handler.dart';

AppAudioHandler? _audioHandler;
Future<AppAudioHandler>? _audioHandlerFuture;

Future<AppAudioHandler> ensureAudioHandler() {
  if (_audioHandler != null) return Future.value(_audioHandler!);
  return _audioHandlerFuture ??= AudioService.init(
    builder: () => AppAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.yt_temp_player.audio',
      androidNotificationChannelName: 'Media Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  ).then((h) {
    _audioHandler = h;
    debugPrint('[startup] audio_service initialized');
    return h;
  });
}

@pragma('vm:entry-point')
void downloadCallback(String id, int status, int progress) {
  final SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
  send?.send([id, status, progress]);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  try {
    await FlutterDownloader.initialize(debug: true, ignoreSsl: true)
        .timeout(const Duration(seconds: 8));
    FlutterDownloader.registerCallback(downloadCallback);
    debugPrint('[startup] flutter_downloader initialized');
  } catch (e, st) {
    debugPrint('[startup] flutter_downloader init failed: $e\n$st');
  }

  // 音频后台服务改为懒初始化：首次进入音频播放页再初始化，避免启动卡 logo。
  runApp(const ProviderScope(child: YtTempPlayerApp()));
}

class YtTempPlayerApp extends StatelessWidget {
  const YtTempPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YT Temp Player',
      theme: ThemeData(colorSchemeSeed: Colors.red, useMaterial3: true),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
