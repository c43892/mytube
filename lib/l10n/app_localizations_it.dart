// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Elenco video YouTube';

  @override
  String get searchHint => 'Cerca video (Shorts filtrati)';

  @override
  String get search => 'Cerca';

  @override
  String get loading => 'Caricamento...';

  @override
  String downloadingProgress(int progress) {
    return 'Download: $progress%';
  }

  @override
  String loadHomeFailed(String error) {
    return 'Caricamento video home non riuscito: $error';
  }

  @override
  String searchFailed(String error) {
    return 'Ricerca non riuscita: $error';
  }

  @override
  String downloadInitFailed(String error) {
    return 'Inizializzazione download non riuscita: $error';
  }

  @override
  String downloadFailed(String error) {
    return 'Download non riuscito: $error';
  }

  @override
  String get downloadTaskFailed => 'Download fallito/annullato, riprova';

  @override
  String get video => 'Video';

  @override
  String duration(String value) {
    return 'Durata $value';
  }

  @override
  String get unknownChannel => 'Canale sconosciuto';

  @override
  String get tabDefault => 'Default';

  @override
  String get tabHistory => 'History';

  @override
  String get tabFavorites => 'Favorites';
}
