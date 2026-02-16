// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'YouTube वीडियो सूची';

  @override
  String get searchHint => 'वीडियो खोजें (Shorts फ़िल्टर किए गए)';

  @override
  String get search => 'खोजें';

  @override
  String get loading => 'लोड हो रहा है...';

  @override
  String downloadingProgress(int progress) {
    return 'डाउनलोड हो रहा है: $progress%';
  }

  @override
  String loadHomeFailed(String error) {
    return 'होम वीडियो लोड नहीं हुए: $error';
  }

  @override
  String searchFailed(String error) {
    return 'खोज विफल: $error';
  }

  @override
  String downloadInitFailed(String error) {
    return 'डाउनलोड शुरू करने में विफल: $error';
  }

  @override
  String downloadFailed(String error) {
    return 'डाउनलोड विफल: $error';
  }

  @override
  String get downloadTaskFailed => 'डाउनलोड विफल/रद्द, कृपया फिर से प्रयास करें';

  @override
  String get video => 'वीडियो';

  @override
  String duration(String value) {
    return 'अवधि $value';
  }

  @override
  String get unknownChannel => 'अज्ञात चैनल';
}
