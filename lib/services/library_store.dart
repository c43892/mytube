import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/media_candidate.dart';
import '../models/video_record.dart';

class LibraryStore {
  static const _historyFile = 'history_videos.json';
  static const _favoriteFile = 'favorite_videos.json';

  Future<File> _fileOf(String name) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}${Platform.pathSeparator}$name');
  }

  Future<List<VideoRecord>> _readList(String name) async {
    final file = await _fileOf(name);
    if (!await file.exists()) return [];
    try {
      final raw = await file.readAsString();
      final data = jsonDecode(raw);
      if (data is! List) return [];
      return data.whereType<Map>().map((e) => VideoRecord.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeList(String name, List<VideoRecord> list) async {
    final file = await _fileOf(name);
    await file.writeAsString(jsonEncode(list.map((e) => e.toJson()).toList()), flush: true);
  }

  Future<List<VideoRecord>> loadHistory() => _readList(_historyFile);
  Future<List<VideoRecord>> loadFavorites() => _readList(_favoriteFile);

  Future<void> addHistory(MediaCandidate media) async {
    final list = await _readList(_historyFile);
    list.removeWhere((e) => e.media.sourceUrl == media.sourceUrl);
    list.insert(0, VideoRecord(media: media, updatedAt: DateTime.now()));
    await _writeList(_historyFile, list);
  }

  Future<bool> toggleFavorite(MediaCandidate media) async {
    final list = await _readList(_favoriteFile);
    final i = list.indexWhere((e) => e.media.sourceUrl == media.sourceUrl);
    if (i >= 0) {
      list.removeAt(i);
      await _writeList(_favoriteFile, list);
      return false;
    }
    list.insert(0, VideoRecord(media: media, updatedAt: DateTime.now()));
    await _writeList(_favoriteFile, list);
    return true;
  }
}
