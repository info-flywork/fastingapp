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
    final uri = Uri(
      scheme: 'mailto',
      path: address,
      query: subject == null ? null : 'subject=${Uri.encodeComponent(subject)}',
    );
    try {
      return await launchUrl(uri);
    } on Object {
      return false;
    }
  }
}
