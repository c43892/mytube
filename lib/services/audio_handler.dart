import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

class AppAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  AudioSession? _session;
  StreamSubscription<PlaybackEvent>? _eventSub;

  AppAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    _session = await AudioSession.instance;
    await _session!.configure(const AudioSessionConfiguration.music());

    _eventSub = _player.playbackEventStream.listen((_) {
      playbackState.add(_transformState(_player));
    });

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) stop();
    });
  }

  Future<void> load(String filePath, String title) async {
    final item = MediaItem(
      id: filePath,
      title: title,
      artist: 'YT Temp Player',
      playable: true,
    );

    mediaItem.add(item);
    queue.add([item]);
    await _player.setFilePath(filePath);
  }

  @override
  Future<void> play() async {
    await _session?.setActive(true);
    await _player.play();
    playbackState.add(_transformState(_player));
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    playbackState.add(_transformState(_player));
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await _session?.setActive(false);
    playbackState.add(_transformState(_player));
    return super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  PlaybackState _transformState(AudioPlayer player) {
    return PlaybackState(
      controls: [
        player.playing ? MediaControl.pause : MediaControl.play,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1],
      processingState: {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[player.processingState]!,
      playing: player.playing,
      updatePosition: player.position,
      bufferedPosition: player.bufferedPosition,
      speed: player.speed,
      queueIndex: player.currentIndex,
    );
  }

  AudioPlayer get rawPlayer => _player;

  @override
  Future<void> onTaskRemoved() => stop();

  Future<void> closeHandler() async {
    await _eventSub?.cancel();
    await _player.dispose();
  }
}
