import 'package:servis_kontrol/core/network/api_client.dart';
import 'package:servis_kontrol/features/help/data/help_repository.dart';
import 'package:servis_kontrol/features/help/domain/help_center_snapshot.dart';

class ApiHelpRepository implements HelpRepository {
  const ApiHelpRepository(this._client);

  final ApiClient _client;

  @override
  Future<HelpCenterSnapshot> load({String? query}) async {
    final payload = await _client.getMap(
      'help-center',
      queryParameters: {
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      },
    );
    return HelpCenterSnapshot.fromJson(payload);
  }
}
