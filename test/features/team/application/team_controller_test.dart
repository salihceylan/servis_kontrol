import 'package:flutter_test/flutter_test.dart';
import 'package:servis_kontrol/features/team/application/team_controller.dart';
import 'package:servis_kontrol/features/team/data/team_repository.dart';
import 'package:servis_kontrol/features/team/domain/team_member.dart';
import 'package:servis_kontrol/features/team/domain/team_snapshot.dart';
import '../../../support/test_support.dart';

void main() {
  test('ekip filtreleri ve yonetici yorumu calisir', () async {
    final controller = TeamController(
      user: managerUser,
      apiClient: createTestApiClient(),
      repository: _FakeTeamRepository(),
    );

    await controller.load();
    expect(controller.managerMode, isTrue);
    expect(controller.members, isNotEmpty);

    controller.toggleFlaggedOnly(true);
    expect(
      controller.members.every(
        (member) => member.riskLevel == MemberRiskLevel.high,
      ),
      isTrue,
    );

    controller.toggleFlaggedOnly(false);
    controller.updateQuery('Seda');
    expect(controller.members, hasLength(1));
    expect(controller.selectedMember?.name, 'Seda Yilmaz');

    await controller.addManagerNote('Bugun teslim oncesi revizyon kuyrugunu kapat.');
    expect(
      controller.selectedMember?.lastManagerNote,
      'Bugun teslim oncesi revizyon kuyrugunu kapat.',
    );

    controller.toggleManagerMode(false);
    expect(controller.managerMode, isFalse);
    expect(controller.alerts.length, lessThanOrEqualTo(2));
  });
}

class _FakeTeamRepository implements TeamRepository {
  TeamSnapshot _snapshot = TeamSnapshot(
    members: const [
      TeamMember(
        id: '1',
        name: 'Seda Yilmaz',
        role: 'Ekip Lideri',
        status: 'Aktif',
        activeTasks: 4,
        completedTasks: 10,
        performanceScore: 82,
        focusNote: 'Revizyonlari takip ediyor',
        riskLevel: MemberRiskLevel.medium,
        capacityPercent: 72,
        trackedHoursLabel: '5.2 saat',
        workloadStatusLabel: 'Dengeli kapasite',
      ),
      TeamMember(
        id: '2',
        name: 'Onur Kaya',
        role: 'Teknisyen',
        status: 'Sahada',
        activeTasks: 5,
        completedTasks: 8,
        performanceScore: 68,
        focusNote: 'Kritik teslimi var',
        riskLevel: MemberRiskLevel.high,
        capacityPercent: 108,
        trackedHoursLabel: '7.8 saat',
        workloadStatusLabel: 'Aşırı yükte',
      ),
    ],
    corrections: const [
      TeamCorrection(
        id: 'c1',
        title: 'Panel etiketi',
        owner: 'Onur Kaya',
        summary: 'Revizyon bekliyor',
        ageLabel: '10 dk',
      ),
    ],
    alerts: const [
      TeamAlert(
        id: 'a1',
        title: 'Onur riskte',
        detail: 'Yuksek yuk',
        project: 'Merkez Plaza',
        riskLevel: MemberRiskLevel.high,
      ),
      TeamAlert(
        id: 'a2',
        title: 'Teslimler yogun',
        detail: 'Bugun 3 teslim var',
        project: 'Coklu proje',
        riskLevel: MemberRiskLevel.medium,
      ),
      TeamAlert(
        id: 'a3',
        title: 'Geciken is',
        detail: 'Takip gerekiyor',
        project: 'Nova',
        riskLevel: MemberRiskLevel.high,
      ),
    ],
  );

  @override
  Future<TeamSnapshot> load({
    String? query,
    bool flaggedOnly = false,
  }) async {
    return _snapshot;
  }

  @override
  Future<void> addManagerNote({
    required String memberId,
    required String note,
  }) async {
    _snapshot = TeamSnapshot(
      members: [
        for (final member in _snapshot.members)
          if (member.id == memberId)
            member.copyWith(lastManagerNote: note)
          else
            member,
      ],
      corrections: _snapshot.corrections,
      alerts: _snapshot.alerts,
    );
  }
}
