import 'package:servis_kontrol/features/owner/domain/owner_portal_models.dart';

abstract class OwnerPortalRepository {
  Future<OwnerDashboardSnapshot> loadDashboard();

  Future<List<OwnerCompanyItem>> loadCompanies();

  Future<OwnerCompanyDetail> loadCompanyDetail(String companyId);

  Future<OwnerCompanyDetail> createCompany(OwnerCompanyDraft draft);

  Future<OwnerCompanyDetail> updateCompanyProfile(
    OwnerCompanyProfileUpdate update,
  );

  Future<OwnerCompanyDetail> updateSubscription(OwnerSubscriptionUpdate update);

  Future<OwnerSupportSnapshot> loadSupport();

  Future<OwnerRequestsSnapshot> loadRequests();

  Future<void> registerSupportAccess(String companyId);
}
