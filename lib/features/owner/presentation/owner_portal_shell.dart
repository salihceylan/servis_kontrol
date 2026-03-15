import 'package:flutter/material.dart';
import 'package:servis_kontrol/core/network/api_client.dart';
import 'package:servis_kontrol/core/theme/app_palette.dart';
import 'package:servis_kontrol/features/auth/domain/app_user.dart';
import 'package:servis_kontrol/features/owner/data/api_owner_portal_repository.dart';
import 'package:servis_kontrol/features/owner/data/owner_portal_repository.dart';
import 'package:servis_kontrol/features/owner/presentation/owner_companies_page.dart';
import 'package:servis_kontrol/features/owner/presentation/owner_company_detail_page.dart';
import 'package:servis_kontrol/features/owner/presentation/owner_dashboard_page.dart';
import 'package:servis_kontrol/features/owner/presentation/owner_requests_page.dart';
import 'package:servis_kontrol/features/owner/presentation/owner_subscriptions_page.dart';
import 'package:servis_kontrol/features/owner/presentation/owner_support_page.dart';

enum OwnerSection {
  dashboard,
  companies,
  companyDetail,
  subscriptions,
  support,
  requests,
}

class OwnerPortalShell extends StatefulWidget {
  const OwnerPortalShell({
    super.key,
    required this.user,
    required this.apiClient,
    required this.onLogout,
  });

  final AppUser user;
  final ApiClient apiClient;
  final Future<void> Function() onLogout;

  @override
  State<OwnerPortalShell> createState() => _OwnerPortalShellState();
}

class _OwnerPortalShellState extends State<OwnerPortalShell> {
  late final OwnerPortalRepository _repository;
  OwnerSection _section = OwnerSection.dashboard;
  String? _selectedCompanyId;

  @override
  void initState() {
    super.initState();
    _repository = ApiOwnerPortalRepository(widget.apiClient);
  }

  void _openCompany(String companyId) {
    setState(() {
      _selectedCompanyId = companyId;
      _section = OwnerSection.companyDetail;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1120;
        return Scaffold(
          drawer: wide
              ? null
              : Drawer(
                  backgroundColor: const Color(0xFF111F36),
                  child: SafeArea(
                    child: _Sidebar(
                      user: widget.user,
                      onSelect: _setSection,
                      current: _section,
                    ),
                  ),
                ),
          body: SafeArea(
            child: Row(
              children: [
                if (wide)
                  SizedBox(
                    width: 260,
                    child: _Sidebar(
                      user: widget.user,
                      current: _section,
                      onSelect: _setSection,
                    ),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      _TopBar(
                        title: _titleForSection(),
                        wide: wide,
                        onLogout: widget.onLogout,
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: _buildContent(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _setSection(OwnerSection section) {
    setState(() {
      _section = section;
    });
  }

  String _titleForSection() => switch (_section) {
    OwnerSection.dashboard => 'Owner Dashboard',
    OwnerSection.companies => 'Sirketler',
    OwnerSection.companyDetail => 'Sirket Detayi',
    OwnerSection.subscriptions => 'Abonelik / Paket',
    OwnerSection.support => 'Destek / Erisim',
    OwnerSection.requests => 'Kaydol Talepleri',
  };

  Widget _buildContent() {
    switch (_section) {
      case OwnerSection.dashboard:
        return OwnerDashboardPage(
          repository: _repository,
          onOpenCompany: _openCompany,
        );
      case OwnerSection.companies:
        return OwnerCompaniesPage(
          repository: _repository,
          onOpenCompany: _openCompany,
        );
      case OwnerSection.companyDetail:
        final companyId = _selectedCompanyId;
        if (companyId == null || companyId.isEmpty) {
          return OwnerCompaniesPage(
            repository: _repository,
            onOpenCompany: _openCompany,
          );
        }
        return OwnerCompanyDetailPage(
          companyId: companyId,
          repository: _repository,
          onBack: () => setState(() => _section = OwnerSection.companies),
        );
      case OwnerSection.subscriptions:
        return OwnerSubscriptionsPage(
          repository: _repository,
          onOpenCompany: _openCompany,
        );
      case OwnerSection.support:
        return OwnerSupportPage(
          repository: _repository,
          onOpenCompany: _openCompany,
        );
      case OwnerSection.requests:
        return OwnerRequestsPage(repository: _repository);
    }
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.user,
    required this.current,
    required this.onSelect,
  });

  final AppUser user;
  final OwnerSection current;
  final ValueChanged<OwnerSection> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF111F36),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2D4A),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Color(0xFFE8B259),
                  child: Icon(
                    Icons.control_camera_rounded,
                    color: Color(0xFF111F36),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Workflow Owner',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Control Tower',
                        style: TextStyle(
                          color: Color(0x99FFFFFF),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _NavTile(
                  label: 'Dashboard',
                  icon: Icons.grid_view_rounded,
                  selected: current == OwnerSection.dashboard,
                  onTap: () => onSelect(OwnerSection.dashboard),
                ),
                _NavTile(
                  label: 'Sirketler',
                  icon: Icons.apartment_rounded,
                  selected:
                      current == OwnerSection.companies ||
                      current == OwnerSection.companyDetail,
                  onTap: () => onSelect(OwnerSection.companies),
                ),
                _NavTile(
                  label: 'Abonelik',
                  icon: Icons.workspace_premium_rounded,
                  selected: current == OwnerSection.subscriptions,
                  onTap: () => onSelect(OwnerSection.subscriptions),
                ),
                _NavTile(
                  label: 'Destek',
                  icon: Icons.support_agent_rounded,
                  selected: current == OwnerSection.support,
                  onTap: () => onSelect(OwnerSection.support),
                ),
                _NavTile(
                  label: 'Talepler',
                  icon: Icons.assignment_late_outlined,
                  selected: current == OwnerSection.requests,
                  onTap: () => onSelect(OwnerSection.requests),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppPalette.primarySoft,
                  child: Text(
                    user.initials,
                    style: const TextStyle(
                      color: AppPalette.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xAAFFFFFF),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: selected ? AppPalette.primary : Colors.transparent,
        leading: Icon(icon, color: Colors.white),
        title: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.wide,
    required this.onLogout,
  });

  final String title;
  final bool wide;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppPalette.border)),
      ),
      child: Row(
        children: [
          if (!wide)
            Builder(
              builder: (context) => IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu_rounded),
              ),
            ),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppPalette.text,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Cikis'),
          ),
        ],
      ),
    );
  }
}
