import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app/routes/app_routes.dart';
import '../../core/services/delivery_service.dart';
import '../../core/utils/geo.dart';
import '../../data/models/package_model.dart';
import '../../widgets/otg_map.dart' show GeoPointLatLng, LatLngGeoPoint;
import '../post_package/location_picker_screen.dart';

/// Home Controller — live package map + discovery filters.
class HomeController extends GetxController {
  final DeliveryService service = DeliveryService();

  // Filters from the screen board: along-route ✓ · Small · < 2 km detour.
  final RxBool alongRoute = true.obs;
  final RxBool smallOnly = false.obs;
  final RxBool shortDetour = false.obs;

  /// Bottom sheet mode: horizontal cards over the map, or a full list.
  final RxBool listMode = false.obs;

  /// Where the traveler is heading — set on the map, drives "Along my route".
  final Rxn<GeoPoint> destGeo = Rxn<GeoPoint>();
  final RxString destLabel = ''.obs;

  Future<void> setDestination() async {
    final result = await Get.to<PickedLocation>(
      () => LocationPickerScreen(
        title: 'Where are you heading?',
        isPickup: false,
        initial: destGeo.value,
        initialLabel: destLabel.value.isEmpty ? null : destLabel.value,
      ),
      fullscreenDialog: true,
    );
    if (result == null) return;
    destGeo.value = result.geo;
    destLabel.value = result.label;
  }

  /// Chip tap: needs a destination to mean anything — prompt for one first.
  Future<void> toggleAlongRoute() async {
    if (!alongRoute.value && destGeo.value == null) {
      await setDestination();
      if (destGeo.value == null) return;
    }
    alongRoute.toggle();
  }

  /// The user's own position ("you are here" dot).
  final Rxn<LatLng> myPos = Rxn<LatLng>();

  final MapController mapCtrl = MapController();

  @override
  void onInit() {
    super.onInit();
    _locate();
  }

  Future<void> _locate() async {
    final at = await _acquirePosition(prompt: false);
    if (at != null) _jumpTo(at, 14.5);
  }

  /// My-location button: prompts to enable location if it's off.
  Future<void> centerOnMe() async {
    final at = await _acquirePosition(prompt: true);
    if (at != null) _jumpTo(at, 15.5);
  }

  Future<LatLng?> _acquirePosition({required bool prompt}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (prompt) {
          Get.snackbar('On the Go', 'Turn on location to find you on the map',
              snackPosition: SnackPosition.TOP);
          // Opens the system location settings panel.
          await Geolocator.openLocationSettings();
          if (!await Geolocator.isLocationServiceEnabled()) return null;
        } else {
          return null;
        }
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        if (prompt) {
          Get.snackbar('On the Go',
              'Location permission is blocked — enable it in app settings',
              snackPosition: SnackPosition.TOP);
          await Geolocator.openAppSettings();
        }
        return null;
      }
      if (perm == LocationPermission.denied) return null;
      final pos = await Geolocator.getCurrentPosition();
      final at = LatLng(pos.latitude, pos.longitude);
      myPos.value = at;
      return at;
    } catch (_) {
      // Map falls back to the Nairobi default center.
      return null;
    }
  }

  void _jumpTo(LatLng at, double zoom) {
    // initialCenter is only read once, so jump the camera explicitly.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      try {
        mapCtrl.move(at, zoom);
      } catch (_) {}
    });
  }

  List<PackageModel> get openPackages {
    var open = service.packages
        .where((p) =>
            p.isOpen &&
            p.sender.id != service.me.id &&
            (!smallOnly.value || p.size == PackageSize.small) &&
            (!shortDetour.value || p.detourKm < 2))
        .toList();
    // "Along my route": keep packages whose pickup AND dropoff sit inside
    // the corridor between my position and my destination.
    final dest = destGeo.value;
    final mine = myPos.value;
    if (alongRoute.value && dest != null && mine != null) {
      final start = mine.geoPoint;
      final routeKm = Geo.distanceKm(start, dest);
      final corridorKm = max(3.0, routeKm * .2);
      open = open
          .where((p) =>
              Geo.distanceToSegmentKm(p.pickupGeo, start, dest) < corridorKm &&
              Geo.distanceToSegmentKm(p.dropoffGeo, start, dest) < corridorKm)
          .toList();
    }
    // Nearest pickup first when we know where the user is.
    if (mine != null) {
      const d = Distance();
      open.sort((a, b) => d
          .as(LengthUnit.Meter, mine, a.pickupGeo.latLng)
          .compareTo(d.as(LengthUnit.Meter, mine, b.pickupGeo.latLng)));
    }
    return open;
  }

  /// Km from the user to a package's pickup, when location is known.
  double? kmToPickup(PackageModel p) {
    final mine = myPos.value;
    if (mine == null) return null;
    return const Distance().as(LengthUnit.Kilometer, mine, p.pickupGeo.latLng);
  }

  void openDetails(PackageModel p) =>
      Get.toNamed(AppRoutes.packageDetails, arguments: p);

  void openPostPackage() => Get.toNamed(AppRoutes.postPackage);

  void openProfile() => Get.toNamed(AppRoutes.profile);

  /// Resume banner targets: active carry (traveler) or active send (sender).
  void openCarrying() => Get.toNamed(AppRoutes.activeDelivery);

  void openSending() => Get.toNamed(AppRoutes.liveTracking);
}
