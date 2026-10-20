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

  static String? imageUrl(Map? data) {
    for (final layer in _layers(data)) {
      for (final key in const ['image', 'imageUrl', 'image_url']) {
        final value = layer[key];
        final url = value is Map ? value['url'] : value;
        if (url is! String || url.trim().isEmpty) continue;
        final uri = Uri.tryParse(url.trim());
        if (uri == null) continue;
        final resolved = Uri.parse(ApiConstants.baseUrl).resolveUri(
          uri.hasScheme || uri.hasAuthority
              ? uri
              : Uri(
                  path: '/${uri.path.replaceFirst(RegExp(r'^/'), '')}',
                  query: uri.hasQuery ? uri.query : null,
                ),
        );
        if ((resolved.scheme == 'http' || resolved.scheme == 'https') &&
            resolved.host.isNotEmpty) {
          return resolved.toString();
        }
      }
    }
    return null;
  }
}
