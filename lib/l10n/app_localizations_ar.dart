// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'قائمة فيديوهات YouTube';

  @override
  String get searchHint => 'ابحث عن فيديوهات (تمت تصفية Shorts)';

  @override
  String get search => 'بحث';

  @override
  String get loading => 'جارٍ التحميل...';

  @override
  String downloadingProgress(int progress) {
    return 'جارٍ التنزيل: $progress%';
  }

  @override
  String loadHomeFailed(String error) {
    return 'فشل تحميل فيديوهات الصفحة الرئيسية: $error';
  }

  @override
  String searchFailed(String error) {
    return 'فشل البحث: $error';
  }

  @override
  String downloadInitFailed(String error) {
    return 'فشل تهيئة التنزيل: $error';
  }

  @override
  String downloadFailed(String error) {
    return 'فشل التنزيل: $error';
  }

  @override
  String get downloadTaskFailed => 'فشل/أُلغي التنزيل، حاول مرة أخرى';

  @override
  String get video => 'فيديو';

  @override
  String duration(String value) {
    return 'المدة $value';
  }

  @override
  String get unknownChannel => 'قناة غير معروفة';
}
