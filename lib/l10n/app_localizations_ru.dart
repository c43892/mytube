// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Список видео YouTube';

  @override
  String get searchHint => 'Поиск видео (Shorts отфильтрованы)';

  @override
  String get search => 'Поиск';

  @override
  String get loading => 'Загрузка...';

  @override
  String downloadingProgress(int progress) {
    return 'Скачивание: $progress%';
  }

  @override
  String loadHomeFailed(String error) {
    return 'Не удалось загрузить главные видео: $error';
  }

  @override
  String searchFailed(String error) {
    return 'Ошибка поиска: $error';
  }

  @override
  String downloadInitFailed(String error) {
    return 'Ошибка инициализации загрузки: $error';
  }

  @override
  String downloadFailed(String error) {
    return 'Ошибка загрузки: $error';
  }

  @override
  String get downloadTaskFailed => 'Загрузка не удалась/отменена, повторите попытку';

  @override
  String get video => 'Видео';

  @override
  String duration(String value) {
    return 'Длительность $value';
  }

  @override
  String get unknownChannel => 'Неизвестный канал';

  @override
  String get tabDefault => 'Default';

  @override
  String get tabHistory => 'History';

  @override
  String get tabFavorites => 'Favorites';
}
