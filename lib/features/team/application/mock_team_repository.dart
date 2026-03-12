import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/auth/domain/user_role.dart';
import 'package:servis_kontrol/features/team/domain/team_member.dart';

class TeamSnapshot {
  const TeamSnapshot({
    required this.members,
    required this.corrections,
    required this.alerts,
  });

  final List<TeamMember> members;
  final List<TeamCorrection> corrections;
  final List<TeamAlert> alerts;
}

class MockTeamRepository {
  const MockTeamRepository();

  TeamSnapshot loadFor(AppUser user) {
    return switch (user.role) {
      UserRole.employee => TeamSnapshot(
        members: [
          TeamMember(
            id: 'emp-self',
            name: user.name,
            role: user.jobTitle,
            status: 'Sahada',
            activeTasks: 3,
            completedTasks: 9,
            performanceScore: 72,
            focusNote: 'Bugün iki teslim ve bir revizyon geri dönüşü var.',
            riskLevel: MemberRiskLevel.medium,
          ),
          const TeamMember(
            id: 'emp-lead',
            name: 'Seda Yılmaz',
            role: 'Ekip Lideri',
            status: 'Aktif',
            activeTasks: 5,
            completedTasks: 14,
            performanceScore: 78,
            focusNote: 'İnceleme kuyruğunu eritmeye odaklandı.',
            riskLevel: MemberRiskLevel.low,
          ),
          const TeamMember(
            id: 'emp-manager',
            name: 'Merve Aydın',
            role: 'Operasyon Yöneticisi',
            status: 'Aktif',
            activeTasks: 7,
            completedTasks: 19,
            performanceScore: 88,
            focusNote: 'Teslim risklerini günlük dashboard üzerinden takip ediyor.',
            riskLevel: MemberRiskLevel.low,
          ),
        ],
        corrections: const [
          TeamCorrection(
            id: 'emp-c1',
            title: 'Panel etiketi revizyonu',
            owner: 'Seda Yılmaz',
            summary: 'Yakın plan fotoğraf bekleniyor.',
            ageLabel: '23 dk',
          ),
        ],
        alerts: const [
          TeamAlert(
            id: 'emp-a1',
            title: 'Merkez Plaza teslim riski',
            detail: 'Gün içi tamamlanması gereken saha teslimi var.',
            project: 'Merkez Plaza',
            riskLevel: MemberRiskLevel.medium,
          ),
        ],
      ),
      UserRole.teamLead => const TeamSnapshot(
        members: [
          TeamMember(
            id: 'lead-self',
            name: 'Seda Yılmaz',
            role: 'Ekip Lideri',
            status: 'Aktif',
            activeTasks: 6,
            completedTasks: 13,
            performanceScore: 81,
            focusNote: 'Revizyon kuyruğu ve saha dağılımı bugün öncelik.',
            riskLevel: MemberRiskLevel.low,
          ),
          TeamMember(
            id: 'lead-1',
            name: 'Onur Kaya',
            role: 'Saha Teknisyeni',
            status: 'Sahada',
            activeTasks: 3,
            completedTasks: 9,
            performanceScore: 69,
            focusNote: 'UPS kapasite etiketi ikinci revizyon turunda.',
            riskLevel: MemberRiskLevel.high,
          ),
          TeamMember(
            id: 'lead-2',
            name: 'Burak Demir',
            role: 'Teknik Uzman',
            status: 'Aktif',
            activeTasks: 4,
            completedTasks: 10,
            performanceScore: 74,
            focusNote: 'Nova Residence rapor teslimi bugün kapanmalı.',
            riskLevel: MemberRiskLevel.medium,
          ),
          TeamMember(
            id: 'lead-3',
            name: 'Ece Akın',
            role: 'Saha Teknisyeni',
            status: 'İzinde',
            activeTasks: 2,
            completedTasks: 8,
            performanceScore: 79,
            focusNote: 'Asansör test formu dönüşünü bekliyor.',
            riskLevel: MemberRiskLevel.low,
          ),
        ],
        corrections: [
          TeamCorrection(
            id: 'lead-c1',
            title: 'UPS kapasite etiketi',
            owner: 'Onur Kaya',
            summary: 'Üçüncü çekim öncesi açıklama notu eklenmeli.',
            ageLabel: '12 dk',
          ),
          TeamCorrection(
            id: 'lead-c2',
            title: 'Asansör test formu',
            owner: 'Ece Akın',
            summary: 'İmza alanı için son kontrol bekleniyor.',
            ageLabel: '45 dk',
          ),
        ],
        alerts: [
          TeamAlert(
            id: 'lead-a1',
            title: 'Onur Kaya yüksek riskte',
            detail: '3 açık görev ve 2 bekleyen revizyon nedeniyle iş yükü yükseldi.',
            project: 'Kuzey Atölye',
            riskLevel: MemberRiskLevel.high,
          ),
          TeamAlert(
            id: 'lead-a2',
            title: 'Bugün 3 kritik teslim',
            detail: 'Nova Residence ve Merkez Plaza işleri yakın takip istiyor.',
            project: 'Çoklu proje',
            riskLevel: MemberRiskLevel.medium,
          ),
        ],
      ),
      UserRole.manager => const TeamSnapshot(
        members: [
          TeamMember(
            id: 'mgr-1',
            name: 'Merve Aydın',
            role: 'Operasyon Yöneticisi',
            status: 'Aktif',
            activeTasks: 6,
            completedTasks: 14,
            performanceScore: 84,
            focusNote: 'Genel operasyon ve yönetici onay kuyruğunu takip ediyor.',
            riskLevel: MemberRiskLevel.low,
          ),
          TeamMember(
            id: 'mgr-2',
            name: 'Seda Yılmaz',
            role: 'Saha Koordinatörü',
            status: 'Aktif',
            activeTasks: 4,
            completedTasks: 11,
            performanceScore: 76,
            focusNote: 'Lider tarafında bekleyen onaylar ve görev atamaları var.',
            riskLevel: MemberRiskLevel.medium,
          ),
          TeamMember(
            id: 'mgr-3',
            name: 'Onur Kaya',
            role: 'Teknisyen',
            status: 'Sahada',
            activeTasks: 3,
            completedTasks: 9,
            performanceScore: 69,
            focusNote: 'Revizyon sayacı eşik seviyesine ulaştı.',
            riskLevel: MemberRiskLevel.high,
          ),
          TeamMember(
            id: 'mgr-4',
            name: 'Burak Demir',
            role: 'Teknik Uzman',
            status: 'Aktif',
            activeTasks: 4,
            completedTasks: 10,
            performanceScore: 74,
            focusNote: 'Rapor teslimlerinde süre baskısı var.',
            riskLevel: MemberRiskLevel.medium,
          ),
        ],
        corrections: [
          TeamCorrection(
            id: 'mgr-c1',
            title: 'Kamera altyapısı',
            owner: 'Onur Kaya',
            summary: 'Revizyon sayısı 3 oldu, yönetici kararı gerekiyor.',
            ageLabel: '5 dk',
          ),
          TeamCorrection(
            id: 'mgr-c2',
            title: 'Yangın paneli raporu',
            owner: 'Seda Yılmaz',
            summary: 'Yönetici onayı bekliyor.',
            ageLabel: '18 dk',
          ),
          TeamCorrection(
            id: 'mgr-c3',
            title: 'Asansör test formu',
            owner: 'Ece Akın',
            summary: 'Nihai performans kaydı için kapanış onayı gerekli.',
            ageLabel: '1 sa',
          ),
        ],
        alerts: [
          TeamAlert(
            id: 'mgr-a1',
            title: 'Bayraklı görevler arttı',
            detail: '3 kritik görev kırmızı seviyede izleniyor.',
            project: 'Merkez Plaza',
            riskLevel: MemberRiskLevel.high,
          ),
          TeamAlert(
            id: 'mgr-a2',
            title: 'Revizyon eşiği aşıldı',
            detail: 'Kamera altyapısı görevi için erken uyarı tetiklendi.',
            project: 'Merkez Plaza',
            riskLevel: MemberRiskLevel.high,
          ),
          TeamAlert(
            id: 'mgr-a3',
            title: 'Teslim takvimi sıkıştı',
            detail: 'Bugün 4 teslim ve 2 gecikme var.',
            project: 'Çoklu proje',
            riskLevel: MemberRiskLevel.medium,
          ),
        ],
      ),
    };
  }
}
