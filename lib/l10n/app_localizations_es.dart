// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Lista de videos de YouTube';

  @override
  String get searchHint => 'Buscar videos (Shorts filtrados)';

  @override
  String get search => 'Buscar';

  @override
  String get loading => 'Cargando...';

  @override
  String downloadingProgress(int progress) {
    return 'Descargando: $progress%';
  }

  @override
  String loadHomeFailed(String error) {
    return 'Error al cargar videos de inicio: $error';
  }

  @override
  String searchFailed(String error) {
    return 'Error de búsqueda: $error';
  }

  @override
  String downloadInitFailed(String error) {
    return 'Error al iniciar descarga: $error';
  }

  @override
  String downloadFailed(String error) {
    return 'Descarga fallida: $error';
  }

  @override
  String get downloadTaskFailed => 'Descarga fallida/cancelada, inténtalo de nuevo';

  @override
  String get video => 'Video';

  @override
  String duration(String value) {
    return 'Duración $value';
  }

  @override
  String get unknownChannel => 'Canal desconocido';
}
