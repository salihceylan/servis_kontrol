import 'package:servis_kontrol/core/network/api_client.dart';
import 'package:servis_kontrol/features/reports/data/report_repository.dart';
import 'package:servis_kontrol/features/reports/domain/report_snapshot.dart';

class ApiReportRepository implements ReportRepository {
  const ApiReportRepository(this._client);

  final ApiClient _client;

  @override
  Future<ReportSnapshot> load({
    String? team,
    String? user,
    ReportType? type,
  }) async {
    final payload = await _client.getMap(
      'reports',
      queryParameters: {
        if (team != null && team.isNotEmpty) 'team': team,
        if (user != null && user.isNotEmpty) 'user': user,
        if (type != null) 'type': type.apiValue,
      },
    );
    return ReportSnapshot.fromJson(payload);
  }

  @override
  Future<ReportRun> createReport({
    required String scope,
    required ReportType type,
    required ReportFormat format,
    String? team,
    String? user,
  }) async {
    final payload = await _client.postMap(
      'reports',
      body: {
        'scope': scope,
        'type': type.apiValue,
        'format': format.apiValue,
        if (team != null && team.isNotEmpty) 'team': team,
        if (user != null && user.isNotEmpty) 'user': user,
      },
    );
    return ReportRun.fromJson(payload['run'] as Map<String, dynamic>? ?? payload);
  }
}
