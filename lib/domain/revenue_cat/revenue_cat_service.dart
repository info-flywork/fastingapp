/// RevenueCat (purchases_flutter) üzerinden premium durumu yönetimi.
/// (Doküman 8)
///
/// İskelet: SDK konfigürasyonu ve satın alma akışı proje ihtiyacına göre
/// doldurulur.
class RevenueCatService {
  RevenueCatService();

  Future<void> init() async {
    // TODO(team): Purchases.configure(...) çağrısı.
  }

  Future<bool> isPremium() async {
    // TODO(team): CustomerInfo entitlements kontrolü.
    return false;
  }
}
