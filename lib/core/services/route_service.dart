import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Singleton Route Service — real road geometry from the public OSRM demo
/// server, cached per od-pair. Falls back to a straight line offline.
/// Swappable for the Google Directions API later.
class RouteService {
  static final RouteService _instance = RouteService._internal();
  factory RouteService() => _instance;
  RouteService._internal();

  final Map<String, List<LatLng>> _cache = {};

  Future<List<LatLng>> roadRoute(LatLng from, LatLng to) async {
    final key = '${from.latitude},${from.longitude}'
        '|${to.latitude},${to.longitude}';
    final hit = _cache[key];
    if (hit != null) return hit;

    try {
      final uri = Uri.https(
        'router.project-osrm.org',
        '/route/v1/driving/${from.longitude},${from.latitude};'
            '${to.longitude},${to.latitude}',
        {'overview': 'full', 'geometries': 'geojson'},
      );
      final res = await http
          .get(uri)
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final coords = (((body['routes'] as List).first
                as Map<String, dynamic>)['geometry']
            as Map<String, dynamic>)['coordinates'] as List;
        final points = [
          for (final c in coords.cast<List>())
            LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
        ];
        if (points.length >= 2) {
          _cache[key] = points;
          return points;
        }
      }
    } catch (_) {
      // fall through to straight line
    }
    return [from, to];
  }

  /// Point at [fraction] (0..1) of the way along a polyline, by distance.
  static LatLng pointAlong(List<LatLng> path, double fraction) {
    if (path.isEmpty) return LatLng(0, 0);
    if (path.length == 1 || fraction <= 0) return path.first;
    if (fraction >= 1) return path.last;
    const d = Distance();
    final segments = <double>[];
    var total = 0.0;
    for (var i = 1; i < path.length; i++) {
      final len = d.as(LengthUnit.Meter, path[i - 1], path[i]);
      segments.add(len);
      total += len;
    }
    if (total == 0) return path.last;
    var remaining = fraction * total;
    for (var i = 0; i < segments.length; i++) {
      if (remaining <= segments[i]) {
        final f = segments[i] == 0 ? 0.0 : remaining / segments[i];
        final a = path[i], b = path[i + 1];
        return LatLng(
          a.latitude + (b.latitude - a.latitude) * f,
          a.longitude + (b.longitude - a.longitude) * f,
        );
      }
      remaining -= segments[i];
    }
    return path.last;
  }
}
