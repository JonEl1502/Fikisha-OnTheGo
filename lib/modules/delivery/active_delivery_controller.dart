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

/// Active Delivery Controller — traveler side of the lifecycle.
class ActiveDeliveryController extends GetxController {
  final DeliveryService service = DeliveryService();

  /// Grabbed at open so the screen keeps working through the rating step
  /// (the service clears `carrying` on delivery).
  late final PackageModel package = service.carrying.value!;

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

  void markPickedUp() => service.markPickedUp(package);

  Future<void> markDelivered() async {
    service.markDelivered(package);
    await showRatingDialog(
      package: package,
      rateUser: package.sender,
      rateLabel: 'RATE YOUR SENDER',
    );
    Get.offAllNamed(AppRoutes.home);
  }

  /// Contact actions hand off to phone/SMS/WhatsApp outside the app (PRD §4).
  void contact(String channel) {
    Get.snackbar('On the Go',
        'Opening $channel to ${package.sender.name} · ${package.sender.phone}',
        snackPosition: SnackPosition.TOP);
  }
}
