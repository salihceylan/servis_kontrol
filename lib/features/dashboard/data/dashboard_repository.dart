import 'package:servis_kontrol/features/dashboard/domain/dashboard_snapshot.dart';

abstract class DashboardRepository {
  Future<DashboardSnapshot> load();
}
