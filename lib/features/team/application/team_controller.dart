import 'package:flutter/foundation.dart';
import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/auth/domain/user_role.dart';
import 'package:servis_kontrol/features/team/application/mock_team_repository.dart';
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
    MockTeamRepository? repository,
  })  : _user = user,
        _repository = repository ?? const MockTeamRepository() {
    final snapshot = _repository.loadFor(user);
    _members = snapshot.members;
    _corrections = snapshot.corrections;
    _alerts = snapshot.alerts;
    _managerMode = user.role == UserRole.manager;
    if (_members.isNotEmpty) {
      _selectedMemberId = _members.first.id;
    }
  }

  final AppUser _user;
  final MockTeamRepository _repository;

  late List<TeamMember> _members;
  late List<TeamCorrection> _corrections;
  late List<TeamAlert> _alerts;
  bool _managerMode = false;
  String _query = '';
  bool _flaggedOnly = false;
  String? _selectedMemberId;

  bool get managerMode => _managerMode;
  bool get canToggleManagerMode => _user.role == UserRole.manager;
  bool get flaggedOnly => _flaggedOnly;
  String get query => _query;

  List<TeamMember> get members {
    final normalized = _query.trim().toLowerCase();
    final items = _members.where((member) {
      final queryMatches =
          normalized.isEmpty ||
          member.name.toLowerCase().contains(normalized) ||
          member.role.toLowerCase().contains(normalized) ||
          member.status.toLowerCase().contains(normalized);
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
        caption: 'Aktif ekip görünümü',
      ),
      TeamMetric(
        label: 'Aktif Görevler',
        value: '$activeTasks',
        caption: 'Dağıtılmış iş yükü',
      ),
      TeamMetric(
        label: 'Bekleyen Düzeltmeler',
        value: '${_corrections.length}',
        caption: 'Aksiyon bekleyen kayıt',
      ),
      TeamMetric(
        label: 'Ekip Performansı',
        value: '%$averageScore',
        caption: highRisk > 0
            ? '$highRisk kişi risk takibinde'
            : 'Risk seviyesi dengeli',
      ),
    ];
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

  void addManagerNote(String note) {
    final member = selectedMember;
    final normalized = note.trim();
    if (member == null || normalized.isEmpty) {
      return;
    }

    _members = [
      for (final current in _members)
        if (current.id == member.id)
          current.copyWith(lastManagerNote: normalized)
        else
          current,
    ];
    notifyListeners();
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
