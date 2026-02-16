import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

Future<void> main() async {
  const url = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
  final yt = YoutubeExplode();

  try {
    final video = await yt.videos.get(url);
    final manifest = await yt.videos.streamsClient.getManifest(video.id);
    final audio = manifest.audioOnly.withHighestBitrate();

    final outFile = File('smoke_audio_sample.tmp');
    final out = outFile.openWrite();

    var bytes = 0;
    await for (final data in yt.videos.streamsClient.get(audio)) {
      bytes += data.length;
      out.add(data);
      if (bytes > 700 * 1024) break;
    }
    await out.flush();
    await out.close();

    print('OK: resolved "${video.title}", wrote $bytes bytes to ${outFile.path}');
  } finally {
    yt.close();
  }
}
