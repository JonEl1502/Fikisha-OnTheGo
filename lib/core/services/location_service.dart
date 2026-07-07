import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

/// Singleton Location Service — streams the traveler's GPS to the active
/// package's Firestore doc. Foreground only, and only while a delivery is
/// active: started at pickup, stopped at delivery (PRD privacy rule).
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _sub;
  String? _packageId;

  bool get isSharing => _sub != null;

  Future<void> start(String packageId) async {
    stop();
    if (!await Geolocator.isLocationServiceEnabled()) {
      Get.snackbar('On the Go', 'Turn on location to share your position',
          snackPosition: SnackPosition.TOP);
      return;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      Get.snackbar('On the Go',
          'Location permission needed so the sender can track the package',
          snackPosition: SnackPosition.TOP);
      return;
    }
    _packageId = packageId;
    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20, // meters between updates — keeps writes cheap
      ),
    ).listen(_publish);
    // Push one fix immediately so the sender sees the courier right away.
    try {
      _publish(await Geolocator.getCurrentPosition());
    } catch (_) {}
  }

  void _publish(Position pos) {
    final id = _packageId;
    if (id == null) return;
    FirebaseFirestore.instance.collection('packages').doc(id).update({
      'courier': GeoPoint(pos.latitude, pos.longitude),
      'courierUpdatedAt': FieldValue.serverTimestamp(),
    }).catchError((_) {});
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _packageId = null;
  }
}
