# mytube_player

A Flutter-based mobile YouTube temporary player focused on Android first, with iOS compatibility work in progress.

## What it does

1. Download and play a specified YouTube video, with lock-screen/background playback support.
2. Keep only video Favorites and History records.

## Tabs

- **Default**: primary feed list
- **History**: watched videos in time order
- **Favorites**: starred videos in favorite order

## Current behavior notes

- Default list is memory-cached during app runtime
- After app restart, the default list can refresh
- History and Favorites are persisted locally on device

## Tech stack

- Flutter
- `youtube_explode_dart` (metadata / stream resolving)
- `flutter_downloader` (download task handling)
- `media_kit` + `audio_service` (playback and background audio)
- `path_provider` (local storage)

## Run (Android)

```bash
cd C:\works\yt_temp_player
flutter pub get
flutter run -d android
```

## Build APK

```bash
flutter build apk --debug
```

## iOS notes

iOS project settings were prepared for compatibility (including background audio mode and downloader plugin registration callback), but final iOS validation must be done on macOS with Xcode and a signed device profile.

## Disclaimer

This project is for personal testing/education. Only use content you are legally allowed to access and play.
