/// Cihaz kimliği üretimi (guest login için). (Doküman 8)
///
/// İskelet: gerçek cihaz ID kaynağı (device_info_plus vb.) proje ihtiyacına
/// göre eklenir.
class DeviceManager {
  DeviceManager();

  Future<String> getDeviceId() async {
    // TODO(team): kalıcı cihaz ID üret/oku.
    return 'unknown-device-id';
  }
}
