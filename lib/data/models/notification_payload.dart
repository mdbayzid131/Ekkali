import 'dart:convert';
import 'package:moeb_26/config/constants/api_constants.dart';

/// Shared recognition for REST notifications and string-valued FCM data.
class NotificationPayload {
  static Iterable<Map> _layers(Map? data, [int depth = 0]) sync* {
    if (data == null || depth > 4) return;
    yield data;
    for (final key in const ['metadata', 'data', 'payload', 'notification']) {
      dynamic nested = data[key];
      if (nested is String) {
        try {
          nested = jsonDecode(nested);
        } catch (_) {
          continue;
        }
      }
      if (nested is Map) yield* _layers(nested, depth + 1);
    }
  }

  static bool isBroadcast(Map? data, {String? type}) {
    bool broadcastType(dynamic value) => const [
      'BROADCAST',
      'ADMIN_BROADCAST',
    ].contains(value?.toString().trim().toUpperCase());
    if (broadcastType(type)) return true;
    return _layers(data).any(
      (layer) =>
          layer['isBroadcast'] == true ||
          layer['isBroadcast'] == 'true' ||
          layer['broadcast'] == true ||
          layer['broadcast'] == 'true' ||
          (layer['broadcastId']?.toString().trim().isNotEmpty ?? false) ||
          broadcastType(layer['type']) ||
          broadcastType(layer['notificationType']),
    );
  }

  static String? text(Map? data, List<String> fields) {
    for (final layer in _layers(data)) {
      for (final field in fields) {
        final value = layer[field];
        if (value is String && value.trim().isNotEmpty) return value.trim();
      }
    }
    return null;
  }

  static String? imageUrl(Map? data) =>
      _mediaUrl(data, const ['image', 'imageUrl', 'image_url']);

  static String? videoUrl(Map? data) =>
      _mediaUrl(data, const ['video', 'videoUrl', 'video_url']);

  static String? _mediaUrl(Map? data, List<String> fields) {
    for (final layer in _layers(data)) {
      for (final key in fields) {
        final value = layer[key];
        final url = value is Map ? value['url'] : value;
        if (url is! String || url.trim().isEmpty) continue;
        final uri = Uri.tryParse(url.trim());
        if (uri == null) continue;
        final apiUri = Uri.parse(ApiConstants.baseUrl);
        var resolved = apiUri.resolveUri(
          uri.hasScheme || uri.hasAuthority
              ? uri
              : Uri(
                  path: '/${uri.path.replaceFirst(RegExp(r'^/'), '')}',
                  query: uri.hasQuery ? uri.query : null,
                ),
        );
        if ((resolved.scheme == 'http' || resolved.scheme == 'https') &&
            resolved.host.isNotEmpty) {
          // Backend uploads can contain its own loopback origin, which is
          // unreachable from the phone. Keep the media path and query intact.
          final host = resolved.host.toLowerCase();
          final octets = host.split('.').map(int.tryParse).toList();
          final privateIp =
              octets.length == 4 &&
              octets.every(
                (part) => part != null && part >= 0 && part <= 255,
              ) &&
              (octets[0] == 10 ||
                  (octets[0] == 172 && octets[1]! >= 16 && octets[1]! <= 31) ||
                  (octets[0] == 192 && octets[1] == 168));
          if (host == 'localhost' ||
              host == '127.0.0.1' ||
              host == '::1' ||
              host == '[::1]' ||
              host == '0.0.0.0' ||
              privateIp) {
            resolved = apiUri.resolveUri(
              Uri(
                path: resolved.path,
                query: resolved.hasQuery ? resolved.query : null,
                fragment: resolved.hasFragment ? resolved.fragment : null,
              ),
            );
          }
          return resolved.toString();
        }
      }
    }
    return null;
  }
}
