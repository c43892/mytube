// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'YouTube 视频列表';

  @override
  String get searchHint => '搜索视频（已过滤 Shorts）';

  @override
  String get search => '搜索';

  @override
  String get loading => '加载中...';

  @override
  String downloadingProgress(int progress) {
    return '下载中：$progress%';
  }

  @override
  String loadHomeFailed(String error) {
    return '加载首页视频失败：$error';
  }

  @override
  String searchFailed(String error) {
    return '搜索失败：$error';
  }

  @override
  String downloadInitFailed(String error) {
    return '下载初始化失败：$error';
  }

  @override
  String downloadFailed(String error) {
    return '下载失败：$error';
  }

  @override
  String get downloadTaskFailed => '下载失败/已取消，请重试';

  @override
  String get video => '视频';

  @override
  String duration(String value) {
    return '时长 $value';
  }

  @override
  String get unknownChannel => '未知频道';

  @override
  String get tabDefault => '默认';

  @override
  String get tabHistory => '历史';

  @override
  String get tabFavorites => '收藏';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant(): super('zh_Hant');

  @override
  String get appTitle => 'YouTube 影片列表';

  @override
  String get searchHint => '搜尋影片（已過濾 Shorts）';

  @override
  String get search => '搜尋';

  @override
  String get loading => '載入中...';

  @override
  String downloadingProgress(int progress) {
    return '下載中：$progress%';
  }

  @override
  String loadHomeFailed(String error) {
    return '載入首頁影片失敗：$error';
  }

  @override
  String searchFailed(String error) {
    return '搜尋失敗：$error';
  }

  @override
  String downloadInitFailed(String error) {
    return '下載初始化失敗：$error';
  }

  @override
  String downloadFailed(String error) {
    return '下載失敗：$error';
  }

  @override
  String get downloadTaskFailed => '下載失敗/已取消，請重試';

  @override
  String get video => '影片';

  @override
  String duration(String value) {
    return '時長 $value';
  }

  @override
  String get unknownChannel => '未知頻道';

  @override
  String get tabDefault => '預設';

  @override
  String get tabHistory => '歷史';

  @override
  String get tabFavorites => '收藏';
}
