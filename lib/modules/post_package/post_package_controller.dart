import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../core/services/delivery_service.dart';
import '../../core/utils/geo.dart';
import '../../data/models/package_model.dart';
import 'location_picker_screen.dart';

/// Post Package Controller — sender form state. Pickup/dropoff are chosen on
/// the map (PRD §3.1) and stored as real coordinates.
class PostPackageController extends GetxController {
  final DeliveryService service = DeliveryService();

  final descriptionCtrl = TextEditingController();
  final feeCtrl = TextEditingController(text: '250');

  final Rx<PackageSize> size = PackageSize.small.obs;
  final RxBool negotiable = true.obs;
  final RxBool hasPhoto = false.obs;

  final Rxn<GeoPoint> pickupGeo = Rxn<GeoPoint>();
  final Rxn<GeoPoint> dropoffGeo = Rxn<GeoPoint>();
  final RxString pickupLabel = ''.obs;
  final RxString dropoffLabel = ''.obs;

  bool get locationsSet => pickupGeo.value != null && dropoffGeo.value != null;

  Future<void> pickLocation({required bool isPickup}) async {
    final result = await Get.to<PickedLocation>(
      () => LocationPickerScreen(
        title: isPickup ? 'Set pickup on the map' : 'Set dropoff on the map',
        isPickup: isPickup,
        initial: isPickup ? pickupGeo.value : dropoffGeo.value,
        initialLabel: isPickup
            ? (pickupLabel.value.isEmpty ? null : pickupLabel.value)
            : (dropoffLabel.value.isEmpty ? null : dropoffLabel.value),
      ),
      fullscreenDialog: true,
    );
    if (result == null) return;
    if (isPickup) {
      pickupGeo.value = result.geo;
      pickupLabel.value = result.label;
    } else {
      dropoffGeo.value = result.geo;
      dropoffLabel.value = result.label;
    }
  }

  double get routeKm => locationsSet
      ? Geo.distanceKm(pickupGeo.value!, dropoffGeo.value!)
      : 0;

  void post() {
    final fee = int.tryParse(feeCtrl.text.trim());
    final desc = descriptionCtrl.text.trim();
    if (!locationsSet) {
      Get.snackbar('On the Go', 'Set pickup and dropoff on the map first',
          snackPosition: SnackPosition.TOP);
      return;
    }
    if (desc.isEmpty || fee == null || fee <= 0) {
      Get.snackbar('On the Go', 'Add a description and a valid KES fee',
          snackPosition: SnackPosition.TOP);
      return;
    }
    service.postPackage(
      description: desc,
      size: size.value,
      fee: fee,
      negotiable: negotiable.value,
      pickupLabel: pickupLabel.value,
      dropoffLabel: dropoffLabel.value,
      pickupGeo: pickupGeo.value!,
      dropoffGeo: dropoffGeo.value!,
    );
    // Straight to the sender's tracking view — it shows the Posted state
    // until a traveler claims (PRD: visible on the map in under 60 s).
    Get.offNamed(AppRoutes.liveTracking);
  }

  @override
  void onClose() {
    descriptionCtrl.dispose();
    feeCtrl.dispose();
    super.onClose();
  }
}
