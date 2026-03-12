import 'package:servis_kontrol/core/network/api_client.dart';
import 'package:servis_kontrol/features/settings/data/settings_repository.dart';
import 'package:servis_kontrol/features/settings/domain/general_settings.dart';

class ApiSettingsRepository implements SettingsRepository {
  const ApiSettingsRepository(this._client);

  final ApiClient _client;

  @override
  Future<GeneralSettings> load() async {
    final payload = await _client.getMap('settings/general');
    return GeneralSettings.fromJson(payload);
  }

  @override
  Future<GeneralSettings> save(GeneralSettings settings) async {
    final payload = await _client.putMap(
      'settings/general',
      body: settings.toJson(),
    );
    return GeneralSettings.fromJson(payload['settings'] as Map<String, dynamic>? ?? payload);
  }
}
