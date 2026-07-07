import 'dart:math';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Geo helpers — real WGS84 coordinates in Firestore, projected onto the
/// stylized map canvas via a fixed Nairobi-metro bounding box. When the
/// Google Maps key lands, screens switch to raw lat/lng and this projection
/// goes away.
class Geo {
  Geo._();

  // Nairobi metro: covers CBD, Westlands, Kikuyu, Rongai, Kasarani.
  static const double minLat = -1.42;
  static const double maxLat = -1.16;
  static const double minLng = 36.60;
  static const double maxLng = 37.00;

  /// Project lat/lng into normalized (0..1) canvas coordinates.
  static Offset project(GeoPoint p) => Offset(
        ((p.longitude - minLng) / (maxLng - minLng)).clamp(0.0, 1.0),
        (1 - (p.latitude - minLat) / (maxLat - minLat)).clamp(0.0, 1.0),
      );

  /// Inverse of [project]: canvas tap position back to lat/lng.
  static GeoPoint unproject(Offset o) => GeoPoint(
        minLat + (1 - o.dy) * (maxLat - minLat),
        minLng + o.dx * (maxLng - minLng),
      );

  static GeoPoint lerp(GeoPoint a, GeoPoint b, double t) => GeoPoint(
        a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t,
      );

  /// Haversine distance in km.
  static double distanceKm(GeoPoint a, GeoPoint b) {
    const r = 6371.0;
    final dLat = _rad(b.latitude - a.latitude);
    final dLng = _rad(b.longitude - a.longitude);
    final h = pow(sin(dLat / 2), 2) +
        cos(_rad(a.latitude)) * cos(_rad(b.latitude)) * pow(sin(dLng / 2), 2);
    return 2 * r * asin(sqrt(h.toDouble()));
  }

  /// ETA: ~22 km/h matatu/boda pace in town, ~65 km/h on intercity hauls.
  static int etaMinutes(double km) =>
      max(1, (km / (km > 30 ? 65 : 22) * 60).round());

  /// Distance (km) from point [p] to the segment [a]→[b], on a local flat
  /// projection — used for "along my route" corridor checks.
  static double distanceToSegmentKm(GeoPoint p, GeoPoint a, GeoPoint b) {
    final lat0 = _rad((a.latitude + b.latitude) / 2);
    double x(GeoPoint g) => g.longitude * 111.32 * cos(lat0);
    double y(GeoPoint g) => g.latitude * 110.57;
    final px = x(p), py = y(p);
    final ax = x(a), ay = y(a), bx = x(b), by = y(b);
    final dx = bx - ax, dy = by - ay;
    final len2 = dx * dx + dy * dy;
    final t = len2 == 0
        ? 0.0
        : (((px - ax) * dx + (py - ay) * dy) / len2).clamp(0.0, 1.0);
    final cx = ax + t * dx, cy = ay + t * dy;
    return sqrt(pow(px - cx, 2) + pow(py - cy, 2)).toDouble();
  }

  static double _rad(double deg) => deg * pi / 180;

  // Known Nairobi-metro areas — offline stand-in for reverse geocoding
  // (Places API replaces this once the Google Maps key lands).
  static const landmarks = <(String, GeoPoint)>[
    ('Nairobi CBD', GeoPoint(-1.2860, 36.8220)),
    ('Westlands', GeoPoint(-1.2635, 36.8020)),
    ('Upper Hill', GeoPoint(-1.2990, 36.8145)),
    ('Kilimani', GeoPoint(-1.2880, 36.7870)),
    ('Kangemi', GeoPoint(-1.2670, 36.7460)),
    ('Kawangware', GeoPoint(-1.2856, 36.7472)),
    ('Kikuyu', GeoPoint(-1.2462, 36.6635)),
    ('Kikuyu · Gikambura', GeoPoint(-1.2910, 36.6620)),
    ('Kikuyu · Thogoto', GeoPoint(-1.3160, 36.6710)),
    ('Karen', GeoPoint(-1.3190, 36.7060)),
    ("Lang'ata", GeoPoint(-1.3330, 36.7440)),
    ('Rongai', GeoPoint(-1.3961, 36.7440)),
    ('Ngong Rd', GeoPoint(-1.2990, 36.7660)),
    ('South B', GeoPoint(-1.3080, 36.8330)),
    ('Kasarani', GeoPoint(-1.2210, 36.8980)),
    ('Embakasi', GeoPoint(-1.3230, 36.8940)),
  ];

  /// Human label for a dropped pin: nearest known area, or a raw pin note.
  static String nearestLabel(GeoPoint p) {
    String best = '';
    var bestKm = double.infinity;
    for (final (name, at) in landmarks) {
      final d = distanceKm(p, at);
      if (d < bestKm) {
        bestKm = d;
        best = name;
      }
    }
    if (bestKm > 4) return 'Pinned location';
    return bestKm < .8 ? best : 'Near $best';
  }
}
