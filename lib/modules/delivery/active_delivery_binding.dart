import 'package:get/get.dart';

import 'active_delivery_controller.dart';

class ActiveDeliveryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ActiveDeliveryController>(ActiveDeliveryController.new);
  }
}
