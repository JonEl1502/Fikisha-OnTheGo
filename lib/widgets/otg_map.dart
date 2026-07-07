import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../app/theme/app_colors.dart';

/// Real map (OpenStreetMap tiles via flutter_map) with the app's pin set.
/// Swappable for google_maps_flutter later without touching screens — the
/// contract is LatLng markers + an optional route polyline.
class OtgMap extends StatelessWidget {
  const OtgMap({
    super.key,
    this.center,
    this.zoom = 13,
    this.fitPoints,
    this.fitPadding = const EdgeInsets.fromLTRB(48, 110, 48, 60),
    this.markers = const [],
    this.route,
    this.onTap,
    this.controller,
    this.interactive = true,
  });

  static final nairobi = LatLng(-1.2860, 36.8220);

  final LatLng? center;
  final double zoom;

  /// When set, the initial camera fits these points instead of center/zoom.
  final List<LatLng>? fitPoints;
  final EdgeInsets fitPadding;

  final List<Marker> markers;
  final List<LatLng>? route;
  final void Function(LatLng)? onTap;
  final MapController? controller;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final fit = fitPoints != null && fitPoints!.length >= 2
        ? CameraFit.coordinates(coordinates: fitPoints!, padding: fitPadding)
        : null;
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: center ?? nairobi,
        initialZoom: zoom,
        initialCameraFit: fit,
        minZoom: 7,
        maxZoom: 18,
        backgroundColor: AppColors.mapBase,
        onTap: onTap == null ? null : (_, latLng) => onTap!(latLng),
        interactionOptions: InteractionOptions(
          flags: interactive ? InteractiveFlag.all : InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'ke.onthego.on_the_go',
        ),
        if (route != null && route!.length >= 2)
          PolylineLayer(polylines: [
            Polyline(
              points: route!,
              strokeWidth: 5,
              color: AppColors.primaryDark,
              borderColor: Colors.white,
              borderStrokeWidth: 2,
            ),
          ]),
        MarkerLayer(markers: markers),
        const SimpleAttributionWidget(
          source: Text('OpenStreetMap', style: TextStyle(fontSize: 10)),
          backgroundColor: Color(0xAAFFFFFF),
        ),
      ],
    );
  }
}

/// GeoPoint (Firestore) ↔ LatLng (map) bridges.
extension GeoPointLatLng on GeoPoint {
  LatLng get latLng => LatLng(latitude, longitude);
}

extension LatLngGeoPoint on LatLng {
  GeoPoint get geoPoint => GeoPoint(latitude, longitude);
}
