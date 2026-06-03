import 'package:flutter/foundation.dart' show kIsWeb;
import '../config/app_config.dart';

/// Converts a DigitalOcean Spaces CDN URL to a backend-proxied URL when
/// running on Flutter Web.
///
/// Problem: browsers enforce CORS, so requests to
/// `tafs-assets.sgp1.cdn.digitaloceanspaces.com` from `localhost:*` are
/// blocked unless the CDN sends `Access-Control-Allow-Origin` headers.
///
/// Solution: route through the backend `/api/v1/media/proxy?url=<cdn_url>`
/// endpoint which fetches the asset server-side and sends it back with the
/// correct CORS headers. The backend only allows TAFS CDN URLs.
///
/// On native (Android / iOS / desktop) this function returns the original URL
/// unchanged because those platforms don't enforce CORS.
class CdnUtils {
  CdnUtils._();

  static String _apiBase() =>
      AppConfig.apiBaseUrl
          .trimRight()
          .replaceAll(RegExp(r'/+$'), '');

  /// Returns the effective URL to use for loading a CDN asset.
  /// On web, wraps it in the backend proxy. On native, returns [url] as-is.
  static String resolve(String? url) {
    if (url == null || url.isEmpty) return '';
    if (!kIsWeb) return url;
    // Already a proxy or local URL — don't double-wrap.
    if (!url.contains('digitaloceanspaces.com') &&
        !url.contains('cdn.digitaloceanspaces.com')) {
      return url;
    }
    final encoded = Uri.encodeComponent(url);
    return '${_apiBase()}/media/proxy?url=$encoded';
  }
}
