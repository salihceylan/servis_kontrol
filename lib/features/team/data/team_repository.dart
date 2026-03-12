import 'package:servis_kontrol/features/team/domain/team_snapshot.dart';

abstract class TeamRepository {
  Future<TeamSnapshot> load({
    String? query,
    bool flaggedOnly = false,
  });

  Future<void> addManagerNote({
    required String memberId,
    required String note,
  });
}
