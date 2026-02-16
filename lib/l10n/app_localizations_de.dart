// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'YouTube-Videoliste';

  @override
  String get searchHint => 'Videos suchen (Shorts gefiltert)';

  @override
  String get search => 'Suchen';

  @override
  String get loading => 'Lädt...';

  @override
  String downloadingProgress(int progress) {
    return 'Herunterladen: $progress%';
  }

  @override
  String loadHomeFailed(String error) {
    return 'Startvideos konnten nicht geladen werden: $error';
  }

  @override
  String searchFailed(String error) {
    return 'Suche fehlgeschlagen: $error';
  }

  @override
  String downloadInitFailed(String error) {
    return 'Download-Initialisierung fehlgeschlagen: $error';
  }

  @override
  String downloadFailed(String error) {
    return 'Download fehlgeschlagen: $error';
  }

  @override
  String get downloadTaskFailed => 'Download fehlgeschlagen/abgebrochen, bitte erneut versuchen';

  @override
  String get video => 'Video';

  @override
  String duration(String value) {
    return 'Dauer $value';
  }

  @override
  String get unknownChannel => 'Unbekannter Kanal';
}
