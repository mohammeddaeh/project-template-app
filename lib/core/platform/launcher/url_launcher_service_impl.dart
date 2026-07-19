import 'package:injectable/injectable.dart';
import 'package:url_launcher/url_launcher.dart';

import 'url_launcher_service.dart';

@LazySingleton(as: UrlLauncherService)
class UrlLauncherServiceImpl implements UrlLauncherService {
  @override
  Future<bool> launch(String url) => _tryLaunch(url);

  @override
  Future<bool> phone(String phoneNumber) =>
      _tryLaunch('tel:$phoneNumber');

  @override
  Future<bool> email(String emailAddress) =>
      _tryLaunch('mailto:$emailAddress');

  @override
  Future<bool> whatsapp(String phoneNumber) =>
      _tryLaunch('https://wa.me/$phoneNumber');

  @override
  Future<bool> telegram(String usernameOrId) =>
      _tryLaunch('https://t.me/$usernameOrId');

  // ── Internal ───────────────────────────────────────────────────────────────

  Future<bool> _tryLaunch(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return false;

    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
