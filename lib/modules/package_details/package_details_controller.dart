import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../app/routes/app_routes.dart';
import '../../core/services/delivery_service.dart';
import '../../core/services/route_service.dart';
import '../../data/models/package_model.dart';
import '../../widgets/otg_map.dart';

/// Package Details Controller — claim flow.
class PackageDetailsController extends GetxController {
  final DeliveryService service = DeliveryService();

  late final PackageModel package = Get.arguments as PackageModel;

  /// Real road geometry pickup → dropoff (straight line while loading).
  final RxList<LatLng> route = <LatLng>[].obs;

  @override
  void onInit() {
    super.onInit();
    route.assignAll([package.pickupGeo.latLng, package.dropoffGeo.latLng]);
    RouteService()
        .roadRoute(package.pickupGeo.latLng, package.dropoffGeo.latLng)
        .then(route.assignAll);
  }

  void claim() {
    service.claim(package);
    Get.offNamed(AppRoutes.activeDelivery);
  }
}
