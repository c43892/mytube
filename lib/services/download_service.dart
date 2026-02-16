import 'dart:convert';
import 'dart:io';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import '../models/media_candidate.dart';

class DownloadResult {
  final String taskId;
  final String savedDir;
  final String fileName;
  const DownloadResult(this.taskId, this.savedDir, this.fileName);

  String get filePath => '$savedDir${Platform.pathSeparator}$fileName';
}

class DownloadService {
  static const int _maxRecent = 20;
  static const String _cacheIndexFile = 'recent_video_cache.json';

  String _buildFileName(MediaCandidate media) {
    final ext = media.fileExt.toLowerCase();
    final safeTitle = media.title.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    return '${safeTitle.isEmpty ? DateTime.now().millisecondsSinceEpoch : safeTitle}.$ext';
  }

  Future<File> _indexFile() async {
    final dir = await getTemporaryDirectory();
    return File('${dir.path}${Platform.pathSeparator}$_cacheIndexFile');
  }

  Future<List<Map<String, dynamic>>> _readIndex() async {
    final f = await _indexFile();
    if (!await f.exists()) return [];
    try {
      final raw = await f.readAsString();
      final data = jsonDecode(raw);
      if (data is List) {
        return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> _writeIndex(List<Map<String, dynamic>> items) async {
    final f = await _indexFile();
    await f.writeAsString(jsonEncode(items), flush: true);
  }

  Future<String?> getCachedVideoPath(String sourceUrl) async {
    final items = await _readIndex();
    for (final it in items) {
      if (it['sourceUrl'] == sourceUrl) {
        final path = it['filePath']?.toString();
        if (path != null && await File(path).exists()) {
          return path;
        }
      }
    }
    return null;
  }

  Future<void> markVideoPlayed({
    required String sourceUrl,
    required String filePath,
    required String title,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) return;

    final items = await _readIndex();
    items.removeWhere((e) => e['sourceUrl'] == sourceUrl);
    items.insert(0, {
      'sourceUrl': sourceUrl,
      'filePath': filePath,
      'title': title,
      'playedAt': DateTime.now().toIso8601String(),
    });

    if (items.length > _maxRecent) {
      final removed = items.sublist(_maxRecent);
      for (final r in removed) {
        final p = r['filePath']?.toString();
        if (p != null) {
          final f = File(p);
          if (await f.exists()) {
            try {
              await f.delete();
            } catch (_) {}
          }
        }
      }
      items.removeRange(_maxRecent, items.length);
    }

    await _writeIndex(items);
  }

  Future<DownloadResult> queueDownload(MediaCandidate media) async {
    final dir = await getTemporaryDirectory();
    final fileName = _buildFileName(media);

    final taskId = await FlutterDownloader.enqueue(
      url: media.streamUrl,
      savedDir: dir.path,
      fileName: fileName,
      headers: const {'User-Agent': 'Mozilla/5.0'},
      showNotification: true,
      openFileFromNotification: false,
      saveInPublicStorage: false,
    );

    if (taskId == null) {
      throw Exception('下载任务创建失败');
    }

    return DownloadResult(taskId, dir.path, fileName);
  }

  Future<DownloadTask?> getTask(String taskId) async {
    final tasks = await FlutterDownloader.loadTasksWithRawQuery(
      query: 'SELECT * FROM task WHERE task_id="$taskId"',
    );
    if (tasks == null || tasks.isEmpty) return null;
    return tasks.first;
  }

  Future<void> cancelTask(String taskId) async {
    await FlutterDownloader.cancel(taskId: taskId);
  }

  Future<void> removeTask(String taskId) async {
    await FlutterDownloader.remove(taskId: taskId, shouldDeleteContent: true);
  }
}
