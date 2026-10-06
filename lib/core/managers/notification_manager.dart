/// Push bildirim servisi: init, izin, tag sync. (Doküman 8)
///
/// İskelet: bildirim SDK entegrasyonu (FCM/OneSignal vb.) proje ihtiyacına
/// göre doldurulur.
final class NotificationManager {
  NotificationManager();

  Future<void> init() async {
    // TODO(team): bildirim SDK init.
  }

  Future<void> syncTags(Map<String, String> tags) async {
    // TODO(team): kullanıcı tag'lerini senkronize et.
  }
}
