/// Endereço normalizado (Epic 12): texto + coordenadas opcionais (Places).
class ConchinhaAddress {
  const ConchinhaAddress({
    required this.label,
    this.lat,
    this.lng,
    this.placeId,
  });

  final String label;
  final double? lat;
  final double? lng;
  final String? placeId;

  Map<String, dynamic> toJson() => {
        'label': label,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (placeId != null) 'place_id': placeId,
      };

  static ConchinhaAddress fromJson(Map<String, dynamic> m) {
    final label = (m['label'] as String?)?.trim() ?? '';
    final lat = (m['lat'] as num?)?.toDouble();
    final lng = (m['lng'] as num?)?.toDouble();
    final placeId = m['place_id'] as String?;
    return ConchinhaAddress(
      label: label.isEmpty ? '(sem endereço)' : label,
      lat: lat,
      lng: lng,
      placeId: placeId,
    );
  }
}
