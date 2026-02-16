// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'YouTube 동영상 목록';

  @override
  String get searchHint => '동영상 검색 (Shorts 필터링)';

  @override
  String get search => '검색';

  @override
  String get loading => '로딩 중...';

  @override
  String downloadingProgress(int progress) {
    return '다운로드 중: $progress%';
  }

  @override
  String loadHomeFailed(String error) {
    return '홈 영상 로드 실패: $error';
  }

  @override
  String searchFailed(String error) {
    return '검색 실패: $error';
  }

  @override
  String downloadInitFailed(String error) {
    return '다운로드 초기화 실패: $error';
  }

  @override
  String downloadFailed(String error) {
    return '다운로드 실패: $error';
  }

  @override
  String get downloadTaskFailed => '다운로드 실패/취소됨, 다시 시도하세요';

  @override
  String get video => '동영상';

  @override
  String duration(String value) {
    return '길이 $value';
  }

  @override
  String get unknownChannel => '알 수 없는 채널';

  @override
  String get tabDefault => 'Default';

  @override
  String get tabHistory => 'History';

  @override
  String get tabFavorites => 'Favorites';
}
