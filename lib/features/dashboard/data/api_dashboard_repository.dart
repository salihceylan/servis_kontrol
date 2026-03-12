import 'package:servis_kontrol/core/network/api_client.dart';
import 'package:servis_kontrol/features/dashboard/data/dashboard_repository.dart';
import 'package:servis_kontrol/features/dashboard/domain/dashboard_snapshot.dart';

class ApiDashboardRepository implements DashboardRepository {
  const ApiDashboardRepository(this._client);

  final ApiClient _client;

  @override
  Future<DashboardSnapshot> load() async {
    final payload = await _client.getMap('dashboard');
    return DashboardSnapshot.fromJson(payload);
  }
}
