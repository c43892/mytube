// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Liste de vidéos YouTube';

  @override
  String get searchHint => 'Rechercher des vidéos (Shorts filtrés)';

  @override
  String get search => 'Rechercher';

  @override
  String get loading => 'Chargement...';

  @override
  String downloadingProgress(int progress) {
    return 'Téléchargement : $progress%';
  }

  @override
  String loadHomeFailed(String error) {
    return 'Échec du chargement des vidéos d’accueil : $error';
  }

  @override
  String searchFailed(String error) {
    return 'Échec de la recherche : $error';
  }

  @override
  String downloadInitFailed(String error) {
    return 'Échec d\'initialisation du téléchargement : $error';
  }

  @override
  String downloadFailed(String error) {
    return 'Échec du téléchargement : $error';
  }

  @override
  String get downloadTaskFailed => 'Téléchargement échoué/annulé, veuillez réessayer';

  @override
  String get video => 'Vidéo';

  @override
  String duration(String value) {
    return 'Durée $value';
  }

  @override
  String get unknownChannel => 'Chaîne inconnue';
}
