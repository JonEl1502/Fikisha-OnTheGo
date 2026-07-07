import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../app/routes/app_routes.dart';
import '../../core/services/delivery_service.dart';
import '../../core/services/route_service.dart';
import '../../data/models/package_model.dart';
import '../../widgets/otg_map.dart';
import '../rating/rating_dialog.dart';

/// Live Tracking Controller — sender side of the lifecycle.
class LiveTrackingController extends GetxController {
  final DeliveryService service = DeliveryService();

  /// Grabbed at open so the screen keeps working through the rating step
  /// (the service clears `sending` on confirmation).
  late final PackageModel package = service.sending.value!;

  /// Real road geometry pickup → dropoff (straight line while loading).
  final RxList<LatLng> route = <LatLng>[].obs;

  final MapController mapCtrl = MapController();

  @override
  void onInit() {
    super.onInit();
    route.assignAll([package.pickupGeo.latLng, package.dropoffGeo.latLng]);
    RouteService()
        .roadRoute(package.pickupGeo.latLng, package.dropoffGeo.latLng)
        .then(route.assignAll);
  }

  /// Tap the courier marker → zoom in and center on it.
  void focusCourier() {
    final at = (package.courier.value ?? package.pickupGeo).latLng;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      try {
        mapCtrl.move(at, 16);
      } catch (_) {}
    });
  }

  Future<void> confirmReceipt() async {
    service.confirmReceipt(package);
    final traveler = package.traveler.value;
    if (traveler != null) {
      await showRatingDialog(
        package: package,
        rateUser: traveler,
        rateLabel: 'RATE YOUR TRAVELER',
      );
    }
    Get.offAllNamed(AppRoutes.home);
  }

  void contact(String channel) {
    final t = package.traveler.value;
    if (t == null) return;
    Get.snackbar('On the Go', 'Opening $channel to ${t.name} · ${t.phone}',
        snackPosition: SnackPosition.TOP);
  }

  String time(DateTime? d) => d == null
      ? '—'
      : '${d.hour}:${d.minute.toString().padLeft(2, '0')}';
}
