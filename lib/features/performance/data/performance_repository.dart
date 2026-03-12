import 'package:servis_kontrol/features/performance/domain/performance_snapshot.dart';

abstract class PerformanceRepository {
  Future<PerformanceSnapshot> load(PerformanceRange range);
}
