// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'YouTube Video List';

  @override
  String get searchHint => 'Search videos (Shorts filtered)';

  @override
  String get search => 'Search';

  @override
  String get loading => 'Loading...';

  @override
  String downloadingProgress(int progress) {
    return 'Downloading: $progress%';
  }

  @override
  String loadHomeFailed(String error) {
    return 'Failed to load home videos: $error';
  }

  @override
  String searchFailed(String error) {
    return 'Search failed: $error';
  }

  @override
  String downloadInitFailed(String error) {
    return 'Download init failed: $error';
  }

  @override
  String downloadFailed(String error) {
    return 'Download failed: $error';
  }

  @override
  String get downloadTaskFailed => 'Download failed/cancelled, please retry';

  @override
  String get video => 'Video';

  @override
  String duration(String value) {
    return 'Duration $value';
  }

  @override
  String get unknownChannel => 'Unknown Channel';

  @override
  String get tabDefault => 'Default';

  @override
  String get tabHistory => 'History';

  @override
  String get tabFavorites => 'Favorites';
}
