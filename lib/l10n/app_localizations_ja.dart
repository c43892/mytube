// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'YouTube動画リスト';

  @override
  String get searchHint => '動画を検索（Shortsは除外）';

  @override
  String get search => '検索';

  @override
  String get loading => '読み込み中...';

  @override
  String downloadingProgress(int progress) {
    return 'ダウンロード中: $progress%';
  }

  @override
  String loadHomeFailed(String error) {
    return 'ホーム動画の読み込みに失敗: $error';
  }

  @override
  String searchFailed(String error) {
    return '検索に失敗: $error';
  }

  @override
  String downloadInitFailed(String error) {
    return 'ダウンロード初期化に失敗: $error';
  }

  @override
  String downloadFailed(String error) {
    return 'ダウンロード失敗: $error';
  }

  @override
  String get downloadTaskFailed => 'ダウンロード失敗/キャンセル。再試行してください';

  @override
  String get video => '動画';

  @override
  String duration(String value) {
    return '長さ $value';
  }

  @override
  String get unknownChannel => '不明なチャンネル';

  @override
  String get tabDefault => 'Default';

  @override
  String get tabHistory => 'History';

  @override
  String get tabFavorites => 'Favorites';
}
