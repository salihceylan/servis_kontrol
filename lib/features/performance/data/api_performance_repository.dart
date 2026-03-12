import 'package:servis_kontrol/core/network/api_client.dart';
import 'package:servis_kontrol/features/performance/data/performance_repository.dart';
import 'package:servis_kontrol/features/performance/domain/performance_snapshot.dart';

class ApiPerformanceRepository implements PerformanceRepository {
  const ApiPerformanceRepository(this._client);

  final ApiClient _client;

  @override
  Future<PerformanceSnapshot> load(PerformanceRange range) async {
    final payload = await _client.getMap(
      'performance',
      queryParameters: {'range': range.apiValue},
    );
    return PerformanceSnapshot.fromJson(payload);
  }
}
