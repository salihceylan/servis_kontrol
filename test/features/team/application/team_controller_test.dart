import 'package:flutter_test/flutter_test.dart';
import 'package:servis_kontrol/features/team/application/team_controller.dart';
import 'package:servis_kontrol/features/team/data/team_repository.dart';
import 'package:servis_kontrol/features/team/domain/team_management.dart';
import 'package:servis_kontrol/features/team/domain/team_member.dart';
import 'package:servis_kontrol/features/team/domain/team_snapshot.dart';

import '../../../support/test_support.dart';

void main() {
  test('ekip filtreleri, not ve yönetici görünumu çalışir', () async {
    final controller = TeamController(
      user: managerUser,
      apiClient: createTestApiClient(),
      repository: _FakeTeamRepository(),
    );

    await controller.load();
    expect(controller.managerMode, isTrue);
    expect(controller.members, hasLength(2));
    expect(controller.teams, hasLength(1));

    controller.toggleFlaggedOnly(true);
    expect(
      controller.members.every(
        (member) => member.riskLevel == MemberRiskLevel.high,
      ),
      isTrue,
    );

    controller.toggleFlaggedOnly(false);
    controller.updateQuery('seda01');
    expect(controller.members, hasLength(1));
    expect(controller.selectedMember?.loginName, 'seda01');

    await controller.addManagerNote(
      'Bugun teslim oncesi revizyon kuyrugunu kapat.',
    );
    expect(
      controller.selectedMember?.lastManagerNote,
      'Bugun teslim oncesi revizyon kuyrugunu kapat.',
    );

    controller.toggleManagerMode(false);
    expect(controller.managerMode, isFalse);
    expect(controller.alerts.length, lessThanOrEqualTo(2));
  });

  test('manager çalışan ve takım oluşturup düzenleyebilir', () async {
    final repository = _FakeTeamRepository();
    final controller = TeamController(
      user: managerUser,
      apiClient: createTestApiClient(),
      repository: repository,
    );

    await controller.load();

    final createdTeam = await controller.createTeam(
      const TeamGroupDraft(name: 'Saha Operasyon', managerUserId: '1'),
    );
    expect(createdTeam, isTrue);
    expect(
      controller.teams.any((team) => team.name == 'Saha Operasyon'),
      isTrue,
    );

    final createdMember = await controller.createMember(
      const TeamMemberDraft(
        name: 'Pelin Demir',
        loginName: 'pelin02',
        password: 'Pelin123.',
        roleCode: 'employee',
        statusCode: 'active',
        teamId: '2',
        department: 'Saha',
        jobTitle: 'Teknisyen',
        workPreference: 'Saha',
        permissionCodes: {'tasks.view', 'tasks.update'},
      ),
    );
    expect(createdMember, isTrue);
    expect(controller.selectedMember?.loginName, 'pelin02');

    final updated = await controller.updateMember(
      memberId: controller.selectedMember!.id,
      draft: const TeamMemberDraft(
        name: 'Pelin Demir',
        loginName: 'pelin02',
        roleCode: 'team_lead',
        statusCode: 'passive',
        teamId: '2',
        department: 'Saha',
        jobTitle: 'Takım Lideri',
        workPreference: 'Karma',
        permissionCodes: {'tasks.assign', 'team.manage'},
      ),
    );
    expect(updated, isTrue);
    expect(controller.selectedMember?.roleCode, 'team_lead');
    expect(controller.selectedMember?.statusCode, 'passive');
    expect(controller.selectedMember?.permissions, contains('team.manage'));

    final updatedTeam = await controller.updateTeam(
      teamId: '2',
      draft: const TeamGroupDraft(
        name: 'Saha Operasyon Kuzey',
        managerUserId: '3',
      ),
    );
    expect(updatedTeam, isTrue);
    expect(
      controller.teams.any((team) => team.name == 'Saha Operasyon Kuzey'),
      isTrue,
    );
  });
}

class _FakeTeamRepository implements TeamRepository {
  TeamSnapshot _snapshot = TeamSnapshot(
    members: const [
      TeamMember(
        id: '1',
        userCode: '1000000001',
        loginName: 'seda01',
        name: 'Seda Yilmaz',
        role: 'Ekip Lideri',
        roleCode: 'team_lead',
        status: 'Aktif',
        statusCode: 'active',
        email: 'seda@example.com',
        department: 'Operasyon',
        jobTitle: 'Ekip Lideri',
        workPreference: 'Hibrit',
        teamId: '1',
        teamName: 'Merkez Ekip',
        activeTasks: 4,
        completedTasks: 10,
        performanceScore: 82,
        focusNote: 'Revizyonlari takip ediyor',
        riskLevel: MemberRiskLevel.medium,
        capacityPercent: 72,
        trackedHoursLabel: '5.2 saat',
        workloadStatusLabel: 'Dengeli kapasite',
        permissions: {'tasks.assign'},
        canEdit: true,
      ),
      TeamMember(
        id: '2',
        userCode: '1000000002',
        loginName: 'onur01',
        name: 'Onur Kaya',
        role: 'Çalışan',
        roleCode: 'employee',
        status: 'Aktif',
        statusCode: 'active',
        email: 'onur@example.com',
        department: 'Saha',
        jobTitle: 'Teknisyen',
        workPreference: 'Saha',
        teamId: '1',
        teamName: 'Merkez Ekip',
        activeTasks: 5,
        completedTasks: 8,
        performanceScore: 68,
        focusNote: 'Kritik teslimi var',
        riskLevel: MemberRiskLevel.high,
        capacityPercent: 108,
        trackedHoursLabel: '7.8 saat',
        workloadStatusLabel: 'Aşıri yükte',
        permissions: {'tasks.view'},
        canEdit: true,
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
        detail: 'Yüksek yük',
        project: 'Merkez Plaza',
        riskLevel: MemberRiskLevel.high,
      ),
      TeamAlert(
        id: 'a2',
        title: 'Teslimler yogun',
        detail: 'Bugun 3 teslim var',
        project: 'Çoklu proje',
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
    teams: const [
      ManagedTeam(
        id: '1',
        name: 'Merkez Ekip',
        code: 'T1001',
        managerUserId: '1',
        managerName: 'Seda Yilmaz',
        memberCount: 2,
        activeTaskCount: 9,
      ),
    ],
    permissionOptions: const [
      TeamPermissionOption(
        code: 'tasks.view',
        module: 'tasks',
        label: 'Görevleri Gör',
        description: 'Görev listesi görüntüleme',
      ),
      TeamPermissionOption(
        code: 'tasks.assign',
        module: 'tasks',
        label: 'Görev Ata',
        description: 'Görev oluşturma ve dağıtma',
      ),
      TeamPermissionOption(
        code: 'team.manage',
        module: 'team',
        label: 'Ekip Yönet',
        description: 'Çalışan ve takım güncelleme',
      ),
    ],
    roleOptions: const [
      TeamRoleOption(code: 'team_lead', label: 'Ekip Lideri'),
      TeamRoleOption(code: 'employee', label: 'Çalışan'),
    ],
  );

  int _memberSequence = 3;
  int _teamSequence = 2;

  @override
  Future<TeamSnapshot> load({String? query, bool flaggedOnly = false}) async {
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
      teams: _snapshot.teams,
      permissionOptions: _snapshot.permissionOptions,
      roleOptions: _snapshot.roleOptions,
    );
  }

  @override
  Future<TeamMember> createMember(TeamMemberDraft draft) async {
    final created = _memberFromDraft(
      id: '${_memberSequence++}',
      draft: draft,
      teamName: _teamNameById(draft.teamId),
    );
    _snapshot = TeamSnapshot(
      members: [..._snapshot.members, created],
      corrections: _snapshot.corrections,
      alerts: _snapshot.alerts,
      teams: _recalculateTeams(extraMember: created),
      permissionOptions: _snapshot.permissionOptions,
      roleOptions: _snapshot.roleOptions,
    );
    return created;
  }

  @override
  Future<TeamMember> updateMember({
    required String memberId,
    required TeamMemberDraft draft,
  }) async {
    final updated = _memberFromDraft(
      id: memberId,
      draft: draft,
      teamName: _teamNameById(draft.teamId),
    );
    _snapshot = TeamSnapshot(
      members: [
        for (final member in _snapshot.members)
          if (member.id == memberId) updated else member,
      ],
      corrections: _snapshot.corrections,
      alerts: _snapshot.alerts,
      teams: _recalculateTeams(updatedMember: updated),
      permissionOptions: _snapshot.permissionOptions,
      roleOptions: _snapshot.roleOptions,
    );
    return updated;
  }

  @override
  Future<ManagedTeam> createTeam(TeamGroupDraft draft) async {
    final created = ManagedTeam(
      id: '${_teamSequence++}',
      name: draft.name,
      code: 'T100$_teamSequence',
      managerUserId: draft.managerUserId,
      managerName: _memberNameById(draft.managerUserId),
      memberCount: 0,
      activeTaskCount: 0,
    );
    _snapshot = TeamSnapshot(
      members: _snapshot.members,
      corrections: _snapshot.corrections,
      alerts: _snapshot.alerts,
      teams: [..._snapshot.teams, created],
      permissionOptions: _snapshot.permissionOptions,
      roleOptions: _snapshot.roleOptions,
    );
    return created;
  }

  @override
  Future<ManagedTeam> updateTeam({
    required String teamId,
    required TeamGroupDraft draft,
  }) async {
    final updated = ManagedTeam(
      id: teamId,
      name: draft.name,
      code: _snapshot.teams.firstWhere((team) => team.id == teamId).code,
      managerUserId: draft.managerUserId,
      managerName: _memberNameById(draft.managerUserId),
      memberCount: _snapshot.members
          .where((member) => member.teamId == teamId)
          .length,
      activeTaskCount: _snapshot.members
          .where((member) => member.teamId == teamId)
          .fold<int>(0, (sum, member) => sum + member.activeTasks),
    );
    _snapshot = TeamSnapshot(
      members: [
        for (final member in _snapshot.members)
          if (member.teamId == teamId)
            member.copyWith(teamName: draft.name)
          else
            member,
      ],
      corrections: _snapshot.corrections,
      alerts: _snapshot.alerts,
      teams: [
        for (final team in _snapshot.teams)
          if (team.id == teamId) updated else team,
      ],
      permissionOptions: _snapshot.permissionOptions,
      roleOptions: _snapshot.roleOptions,
    );
    return updated;
  }

  TeamMember _memberFromDraft({
    required String id,
    required TeamMemberDraft draft,
    required String? teamName,
  }) {
    final roleLabel = draft.roleCode == 'team_lead' ? 'Ekip Lideri' : 'Çalışan';
    final statusLabel = draft.statusCode == 'passive' ? 'Pasif' : 'Aktif';
    return TeamMember(
      id: id,
      userCode: '100000000$id',
      loginName: draft.loginName,
      name: draft.name,
      role: roleLabel,
      roleCode: draft.roleCode,
      status: statusLabel,
      statusCode: draft.statusCode,
      email: draft.email ?? '',
      department: draft.department ?? '',
      jobTitle: draft.jobTitle ?? '',
      workPreference: draft.workPreference ?? '',
      teamId: draft.teamId,
      teamName: teamName,
      activeTasks: 0,
      completedTasks: 0,
      performanceScore: 0,
      focusNote: 'Yeni ekip üyesi',
      riskLevel: MemberRiskLevel.low,
      capacityPercent: 0,
      trackedHoursLabel: '0 saat',
      workloadStatusLabel: 'Planlanmadı',
      permissions: draft.permissionCodes,
      canEdit: true,
    );
  }

  String? _teamNameById(String? teamId) {
    if (teamId == null) {
      return null;
    }
    final team = _snapshot.teams.where((current) => current.id == teamId);
    return team.isEmpty ? null : team.first.name;
  }

  String? _memberNameById(String? memberId) {
    if (memberId == null) {
      return null;
    }
    final member = _snapshot.members.where((current) => current.id == memberId);
    return member.isEmpty ? null : member.first.name;
  }

  List<ManagedTeam> _recalculateTeams({
    TeamMember? extraMember,
    TeamMember? updatedMember,
  }) {
    final members = [
      ..._snapshot.members.where(
        (member) => updatedMember == null || member.id != updatedMember.id,
      ),
      ...(updatedMember == null ? const <TeamMember>[] : [updatedMember]),
      ...(extraMember == null ? const <TeamMember>[] : [extraMember]),
    ];
    return [
      for (final team in _snapshot.teams)
        ManagedTeam(
          id: team.id,
          name: team.name,
          code: team.code,
          managerUserId: team.managerUserId,
          managerName: team.managerName,
          memberCount: members
              .where((member) => member.teamId == team.id)
              .length,
          activeTaskCount: members
              .where((member) => member.teamId == team.id)
              .fold<int>(0, (sum, member) => sum + member.activeTasks),
        ),
    ];
  }
}
