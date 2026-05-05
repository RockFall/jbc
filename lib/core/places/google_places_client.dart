import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../data/models/conchinha_address.dart';

/// Predição da API Places (legado JSON) para autocomplete.
class PlacePrediction {
  const PlacePrediction({
    required this.placeId,
    required this.description,
  });

  final String placeId;
  final String description;
}

/// Cliente mínimo para autocomplete + detalhes. Chave: `--dart-define=GOOGLE_MAPS_API_KEY=...`.
abstract final class GooglePlacesClient {
  static const _apiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');

  static bool get isConfigured => _apiKey.isNotEmpty;

  static Future<List<PlacePrediction>> autocomplete(String input) async {
    final q = input.trim();
    if (!isConfigured || q.length < 2) return [];
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      {
        'input': q,
        'key': _apiKey,
        'language': 'pt-BR',
      },
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) return [];
    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) return [];
    final preds = decoded['predictions'];
    if (preds is! List) return [];
    final out = <PlacePrediction>[];
    for (final p in preds) {
      if (p is! Map) continue;
      final m = Map<String, dynamic>.from(p);
      final pid = m['place_id'] as String?;
      final desc = m['description'] as String?;
      if (pid == null || desc == null) continue;
      out.add(PlacePrediction(placeId: pid, description: desc));
    }
    return out;
  }

  static Future<ConchinhaAddress?> placeDetails(String placeId) async {
    if (!isConfigured) return null;
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/details/json',
      {
        'place_id': placeId,
        'fields': 'formatted_address,geometry/location',
        'key': _apiKey,
        'language': 'pt-BR',
      },
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;
    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) return null;
    final result = decoded['result'];
    if (result is! Map) return null;
    final r = Map<String, dynamic>.from(result);
    final label = (r['formatted_address'] as String?)?.trim() ?? '';
    final geom = r['geometry'];
    double? lat;
    double? lng;
    if (geom is Map) {
      final loc = geom['location'];
      if (loc is Map) {
        lat = (loc['lat'] as num?)?.toDouble();
        lng = (loc['lng'] as num?)?.toDouble();
      }
    }
    if (label.isEmpty) return null;
    return ConchinhaAddress(label: label, lat: lat, lng: lng, placeId: placeId);
  }

  /// URL do mapa estático (opcional); retorna null se não houver chave ou coordenadas.
  static String? staticMapUrl({required double lat, required double lng, int width = 600, int height = 280}) {
    if (!isConfigured) return null;
    final center = '$lat,$lng';
    return 'https://maps.googleapis.com/maps/api/staticmap?'
        'center=$center&zoom=16&size=${width}x$height'
        '&markers=color:red%7C$center&key=$_apiKey';
  }
}
