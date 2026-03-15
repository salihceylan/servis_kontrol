import 'package:servis_kontrol/core/network/api_client.dart';
import 'package:servis_kontrol/features/owner/data/owner_portal_repository.dart';
import 'package:servis_kontrol/features/owner/domain/owner_portal_models.dart';

class ApiOwnerPortalRepository implements OwnerPortalRepository {
  const ApiOwnerPortalRepository(this._client);

  final ApiClient _client;

  @override
  Future<OwnerDashboardSnapshot> loadDashboard() async {
    final payload = await _client.getMap('owner/dashboard');
    return OwnerDashboardSnapshot.fromJson(payload);
  }

  @override
  Future<List<OwnerCompanyItem>> loadCompanies() async {
    final payload = await _client.getList('owner/companies');
    return payload
        .map((item) => OwnerCompanyItem.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<OwnerCompanyDetail> loadCompanyDetail(String companyId) async {
    final payload = await _client.getMap('owner/companies/$companyId');
    return OwnerCompanyDetail.fromJson(payload);
  }

  @override
  Future<OwnerCompanyDetail> createCompany(OwnerCompanyDraft draft) async {
    final payload = await _client.postMap(
      'owner/companies',
      body: draft.toJson(),
    );
    return OwnerCompanyDetail.fromJson(payload);
  }

  @override
  Future<OwnerCompanyDetail> updateCompanyProfile(
    OwnerCompanyProfileUpdate update,
  ) async {
    final payload = await _client.putMap(
      'owner/companies/${update.companyId}',
      body: update.toJson(),
    );
    return OwnerCompanyDetail.fromJson(payload);
  }

  @override
  Future<OwnerCompanyDetail> updateSubscription(
    OwnerSubscriptionUpdate update,
  ) async {
    final payload = await _client.putMap(
      'owner/companies/${update.companyId}/subscription',
      body: update.toJson(),
    );
    return OwnerCompanyDetail.fromJson(payload);
  }

  @override
  Future<OwnerSupportSnapshot> loadSupport() async {
    final payload = await _client.getMap('owner/support');
    return OwnerSupportSnapshot.fromJson(payload);
  }

  @override
  Future<OwnerRequestsSnapshot> loadRequests() async {
    final payload = await _client.getMap('owner/requests');
    return OwnerRequestsSnapshot.fromJson(payload);
  }

  @override
  Future<void> registerSupportAccess(String companyId) {
    return _client.postVoid('owner/companies/$companyId/support-access');
  }
}
