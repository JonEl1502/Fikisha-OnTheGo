import 'package:get/get.dart';

import '../../core/services/delivery_service.dart';

/// Registers app-wide singletons with GetX so controllers can Get.find them.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<DeliveryService>(DeliveryService(), permanent: true);
  }
}
