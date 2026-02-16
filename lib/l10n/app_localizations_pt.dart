// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Lista de vídeos do YouTube';

  @override
  String get searchHint => 'Pesquisar vídeos (Shorts filtrados)';

  @override
  String get search => 'Pesquisar';

  @override
  String get loading => 'Carregando...';

  @override
  String downloadingProgress(int progress) {
    return 'Baixando: $progress%';
  }

  @override
  String loadHomeFailed(String error) {
    return 'Falha ao carregar vídeos iniciais: $error';
  }

  @override
  String searchFailed(String error) {
    return 'Falha na pesquisa: $error';
  }

  @override
  String downloadInitFailed(String error) {
    return 'Falha ao iniciar download: $error';
  }

  @override
  String downloadFailed(String error) {
    return 'Falha no download: $error';
  }

  @override
  String get downloadTaskFailed => 'Download falhou/cancelado, tente novamente';

  @override
  String get video => 'Vídeo';

  @override
  String duration(String value) {
    return 'Duração $value';
  }

  @override
  String get unknownChannel => 'Canal desconhecido';
}
