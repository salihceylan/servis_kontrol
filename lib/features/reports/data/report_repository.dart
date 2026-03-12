import 'package:servis_kontrol/features/reports/domain/report_snapshot.dart';

abstract class ReportRepository {
  Future<ReportSnapshot> load({
    String? team,
    String? user,
    ReportType? type,
  });

  Future<ReportRun> createReport({
    required String scope,
    required ReportType type,
    required ReportFormat format,
    String? team,
    String? user,
  });
}
