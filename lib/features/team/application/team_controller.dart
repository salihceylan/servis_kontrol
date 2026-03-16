import 'package:flutter/foundation.dart';
import 'package:servis_kontrol/core/network/api_client.dart';
import 'package:servis_kontrol/core/network/api_exception.dart';
import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/auth/domain/user_role.dart';
import 'package:servis_kontrol/features/team/data/api_team_repository.dart';
import 'package:servis_kontrol/features/team/data/team_repository.dart';
import 'package:servis_kontrol/features/team/domain/team_management.dart';
import 'package:servis_kontrol/features/team/domain/team_member.dart';

class TeamMetric {
  const TeamMetric({
    required this.label,
    required this.value,
    required this.caption,
  });

  final String label;
  final String value;
  final String caption;
}

class TeamController extends ChangeNotifier {
  TeamController({
    required AppUser user,
    required ApiClient apiClient,
    TeamRepository? repository,
  }) : _user = user,
       _repository = repository ?? ApiTeamRepository(apiClient),
       _managerMode = user.role == UserRole.manager {
    load();
  }

  final AppUser _user;
  final TeamRepository _repository;

  List<TeamMember> _members = const [];
  List<TeamCorrection> _corrections = const [];
  List<TeamAlert> _alerts = const [];
  List<ManagedTeam> _teams = const [];
  List<TeamPermissionOption> _permissionOptions = const [];
  List<TeamRoleOption> _roleOptions = const [];
  bool _managerMode;
  String _query = '';
  bool _flaggedOnly = false;
  String? _selectedMemberId;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  bool get managerMode => _managerMode;
  bool get canToggleManagerMode => _user.role == UserRole.manager;
  bool get canManageWorkspace => _user.role == UserRole.manager;
  bool get flaggedOnly => _flaggedOnly;
  String get query => _query;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  bool get hasData => _members.isNotEmpty || _teams.isNotEmpty;
  List<TeamPermissionOption> get permissionOptions => _permissionOptions;
  List<TeamRoleOption> get roleOptions => _roleOptions;
  List<ManagedTeam> get teams =>
      [..._teams]..sort((a, b) => a.name.compareTo(b.name));

  List<TeamMember> get members {
    final normalized = _query.trim().toLowerCase();
    final items =
        _members.where((member) {
            final queryMatches =
                normalized.isEmpty ||
                member.name.toLowerCase().contains(normalized) ||
                member.role.toLowerCase().contains(normalized) ||
                member.status.toLowerCase().contains(normalized) ||
                member.loginName.toLowerCase().contains(normalized) ||
                member.department.toLowerCase().contains(normalized) ||
                (member.teamName ?? '').toLowerCase().contains(normalized);
            final flaggedMatches =
                !_flaggedOnly || member.riskLevel == MemberRiskLevel.high;
            return queryMatches && flaggedMatches;
          }).toList()
          ..sort((a, b) => b.performanceScore.compareTo(a.performanceScore));
    return items;
  }

  TeamMember? get selectedMember {
    final visibleMembers = members;
    if (visibleMembers.isEmpty) {
      return null;
    }
    final selected = visibleMembers.cast<TeamMember?>().firstWhere(
      (member) => member?.id == _selectedMemberId,
      orElse: () => null,
    );
    return selected ?? visibleMembers.first;
  }

  List<TeamCorrection> get corrections =>
      _managerMode ? _corrections : _corrections.take(2).toList();

  List<TeamAlert> get alerts =>
      _managerMode ? _alerts : _alerts.take(2).toList();

  List<TeamMetric> get metrics {
    final totalMembers = _members.length;
    final activeTasks = _members.fold<int>(
      0,
      (sum, member) => sum + member.activeTasks,
    );
    final highRisk = _members
        .where((member) => member.riskLevel == MemberRiskLevel.high)
        .length;
    final averageScore = _members.isEmpty
        ? 0
        : _members
                  .map((member) => member.performanceScore)
                  .reduce((a, b) => a + b) ~/
              _members.length;

    return [
      TeamMetric(
        label: 'Toplam Çalışan',
        value: '$totalMembers',
        caption: 'Aktif ekip görünumu',
      ),
      TeamMetric(
        label: 'Takım Sayisi',
        value: '${_teams.length}',
        caption: 'Operasyon gruplari',
      ),
      TeamMetric(
        label: 'Aktif Görevler',
        value: '$activeTasks',
        caption: 'Dağıtilmis iş yükü',
      ),
      TeamMetric(
        label: 'Ekip Performansi',
        value: '%$averageScore',
        caption: highRisk > 0
            ? '$highRisk kisi risk takibinde'
            : 'Risk seviyesi dengeli',
      ),
    ];
  }

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final snapshot = await _repository.load(
        query: _query,
        flaggedOnly: _flaggedOnly,
      );
      _members = snapshot.members;
      _corrections = snapshot.corrections;
      _alerts = snapshot.alerts;
      _teams = snapshot.teams;
      _permissionOptions = snapshot.permissionOptions;
      _roleOptions = snapshot.roleOptions;
      _ensureSelection();
    } on ApiException catch (error) {
      _members = const [];
      _corrections = const [];
      _alerts = const [];
      _teams = const [];
      _permissionOptions = const [];
      _roleOptions = const [];
      _selectedMemberId = null;
      _errorMessage = error.message;
    } catch (_) {
      _members = const [];
      _corrections = const [];
      _alerts = const [];
      _teams = const [];
      _permissionOptions = const [];
      _roleOptions = const [];
      _selectedMemberId = null;
      _errorMessage = 'Ekip verileri alınamadı.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleManagerMode(bool value) {
    if (!canToggleManagerMode) {
      return;
    }
    _managerMode = value;
    notifyListeners();
  }

  void updateQuery(String value) {
    _query = value;
    _ensureSelection();
    notifyListeners();
  }

  void toggleFlaggedOnly(bool value) {
    _flaggedOnly = value;
    _ensureSelection();
    notifyListeners();
  }

  void selectMember(String id) {
    _selectedMemberId = id;
    notifyListeners();
  }

  Future<bool> addManagerNote(String note) async {
    final member = selectedMember;
    final normalized = note.trim();
    if (member == null || normalized.isEmpty) {
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.addManagerNote(memberId: member.id, note: normalized);
      _members = [
        for (final current in _members)
          if (current.id == member.id)
            current.copyWith(lastManagerNote: normalized)
          else
            current,
      ];
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Yönetici notu kaydedilemedi.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> createMember(TeamMemberDraft draft) {
    return _runMutation(() async {
      final created = await _repository.createMember(draft);
      _selectedMemberId = created.id;
      await load();
    }, fallbackMessage: 'Çalışan kaydı oluşturulamadı.');
  }

  Future<bool> updateMember({
    required String memberId,
    required TeamMemberDraft draft,
  }) {
    return _runMutation(() async {
      final updated = await _repository.updateMember(
        memberId: memberId,
        draft: draft,
      );
      _selectedMemberId = updated.id;
      await load();
    }, fallbackMessage: 'Çalışan kaydı güncellenemedi.');
  }

  Future<bool> createTeam(TeamGroupDraft draft) {
    return _runMutation(() async {
      await _repository.createTeam(draft);
      await load();
    }, fallbackMessage: 'Takım oluşturulamadı.');
  }

  Future<bool> updateTeam({
    required String teamId,
    required TeamGroupDraft draft,
  }) {
    return _runMutation(() async {
      await _repository.updateTeam(teamId: teamId, draft: draft);
      await load();
    }, fallbackMessage: 'Takım güncellenemedi.');
  }

  Future<bool> _runMutation(
    Future<void> Function() action, {
    required String fallbackMessage,
  }) async {
    if (!canManageWorkspace) {
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = fallbackMessage;
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void _ensureSelection() {
    final visibleMembers = members;
    if (visibleMembers.isEmpty) {
      _selectedMemberId = null;
      return;
    }
    final exists = visibleMembers.any(
      (member) => member.id == _selectedMemberId,
    );
    if (!exists) {
      _selectedMemberId = visibleMembers.first.id;
    }
  }
}
