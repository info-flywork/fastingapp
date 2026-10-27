import 'package:url_launcher/url_launcher.dart';

/// Harici bağlantılar: yasal metinler tarayıcıda, destek e-postası posta
/// uygulamasında. Açılamazsa false.
final class UrlLauncherManager {
  UrlLauncherManager();

  Future<bool> openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      return false;
    }
  }

  Future<bool> openEmail(String address, {String? subject}) async {
    // Uri(scheme, path) '@' işaretini kodlar; iOS bu mailto'yu açmaz ve
    // çağıran adres kopyalamaya düşer. Ayrıca varsayılan kip uygulama içi
    // görünüm ister, mailto orada açılmaz.
    final query = subject == null
        ? ''
        : '?subject=${Uri.encodeComponent(subject)}';
    final uri = Uri.parse('mailto:$address$query');
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      return false;
    }
  }
}
