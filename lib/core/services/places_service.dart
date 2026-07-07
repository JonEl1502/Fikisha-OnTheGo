import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Singleton Places Service — free OSM Nominatim geocoding. Results are
/// biased to the Nairobi metro and sorted by distance from where the user
/// is looking, so suggestions stay close and sensible. Swappable for the
/// Google Places API once a Maps key lands.
class PlacesService {
  static final PlacesService _instance = PlacesService._internal();
  factory PlacesService() => _instance;
  PlacesService._internal();

  static const _headers = {
    'User-Agent': 'OnTheGo-MVP/1.0 (kabiujm@gmail.com)',
  };

  // Nairobi metro viewbox: lng1,lat1,lng2,lat2
  static const _metroViewbox = '36.55,-1.10,37.10,-1.50';

  /// [near] biases ranking — pass the map camera center.
  Future<List<PlaceHit>> search(String query, {LatLng? near}) async {
    final anchor = near ?? LatLng(-1.2860, 36.8220);
    // Photon: fuzzy, typo-tolerant OSM search built for autocomplete —
    // handles colloquial "name + area" queries Nominatim can't.
    var hits = await _photon(query, anchor);
    // Fallback: strict Nominatim geocoding for full addresses.
    if (hits.isEmpty) hits = await _query(query, bounded: false);
    // Last resort for "name + area" where the name isn't mapped in OSM:
    // search the trailing area word so the user can still jump close and
    // drop the pin by hand ("ankara rongai" → "rongai").
    if (hits.isEmpty) {
      final words = query.trim().split(RegExp(r'\s+'));
      if (words.length > 1) {
        hits = await _photon(words.last, anchor);
      }
    }

    const d = Distance();
    for (final h in hits) {
      h.distanceKm = d.as(LengthUnit.Kilometer, anchor, h.at);
    }
    // Keep relevance order (bias already favors nearby); dedupe
    // near-identical entries (same name within ~300 m).
    final seen = <String>{};
    return [
      for (final h in hits)
        if (seen.add('${h.name}|${(h.at.latitude * 200).round()}'
            '|${(h.at.longitude * 200).round()}'))
          h,
    ];
  }

  Future<List<PlaceHit>> _photon(String query, LatLng near) async {
    final uri = Uri.https('photon.komoot.io', '/api/', {
      'q': query,
      'limit': '10',
      'lang': 'en',
      'lat': '${near.latitude}',
      'lon': '${near.longitude}',
      'location_bias_scale': '0.4',
    });
    try {
      final res = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return [];
      final features =
          ((jsonDecode(res.body) as Map)['features'] as List? ?? const [])
              .cast<Map<String, dynamic>>();
      final hits = <PlaceHit>[];
      for (final f in features) {
        final props = (f['properties'] as Map).cast<String, dynamic>();
        if ((props['countrycode'] as String?)?.toUpperCase() != 'KE') {
          continue;
        }
        final coords =
            ((f['geometry'] as Map)['coordinates'] as List).cast<num>();
        final name = props['name'] as String? ??
            props['street'] as String? ??
            'Pinned location';
        final area = <String>[
          for (final key in ['district', 'suburb', 'city', 'county', 'state'])
            if (props[key] is String &&
                (props[key] as String).isNotEmpty &&
                props[key] != name)
              props[key] as String,
        ];
        hits.add(PlaceHit(
          name: name,
          detail: area.take(2).toSet().join(' · '),
          at: LatLng(coords[1].toDouble(), coords[0].toDouble()),
        ));
      }
      return hits;
    } catch (_) {
      return [];
    }
  }

  Future<List<PlaceHit>> _query(String query, {required bool bounded}) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'jsonv2',
      'limit': '10',
      'countrycodes': 'ke',
      'viewbox': _metroViewbox,
      'bounded': bounded ? '1' : '0',
      'addressdetails': '1',
    });
    try {
      final res = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return [];
      final list = jsonDecode(res.body) as List;
      return [
        for (final raw in list.cast<Map<String, dynamic>>())
          PlaceHit(
            name: _name(raw),
            detail: _area(raw),
            at: LatLng(
              double.parse(raw['lat'] as String),
              double.parse(raw['lon'] as String),
            ),
          ),
      ];
    } catch (_) {
      return [];
    }
  }

  /// Short human label for a dropped pin ("Kimathi Street · Nairobi").
  Future<String?> reverseLabel(LatLng at) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'lat': '${at.latitude}',
      'lon': '${at.longitude}',
      'format': 'jsonv2',
      'zoom': '16',
      'addressdetails': '1',
    });
    try {
      final res = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final raw = jsonDecode(res.body) as Map<String, dynamic>;
      final name = _name(raw);
      final area = _area(raw);
      return area.isEmpty ? name : '$name · ${area.split(' · ').first}';
    } catch (_) {
      return null;
    }
  }

  /// The place's own name (falls back to the first display-name part).
  static String _name(Map<String, dynamic> raw) {
    final name = raw['name'] as String?;
    if (name != null && name.isNotEmpty) return name;
    final display = raw['display_name'] as String? ?? '';
    return display.split(', ').first.trim().isEmpty
        ? 'Pinned location'
        : display.split(', ').first.trim();
  }

  /// Compact area context ("Westlands · Nairobi"), not the full address.
  static String _area(Map<String, dynamic> raw) {
    final a = (raw['address'] as Map?)?.cast<String, dynamic>() ?? const {};
    final parts = <String>[
      for (final key in ['suburb', 'neighbourhood', 'town', 'city', 'county'])
        if (a[key] is String && (a[key] as String).isNotEmpty) a[key] as String,
    ];
    final unique = <String>[];
    for (final p in parts) {
      if (!unique.contains(p) && p != _name(raw)) unique.add(p);
      if (unique.length == 2) break;
    }
    return unique.join(' · ');
  }
}

class PlaceHit {
  PlaceHit({required this.name, required this.detail, required this.at});
  final String name;
  final String detail;
  final LatLng at;
  double? distanceKm;
}
