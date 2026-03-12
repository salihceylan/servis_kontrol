import 'package:servis_kontrol/features/settings/domain/general_settings.dart';

abstract class SettingsRepository {
  Future<GeneralSettings> load();

  Future<GeneralSettings> save(GeneralSettings settings);
}
