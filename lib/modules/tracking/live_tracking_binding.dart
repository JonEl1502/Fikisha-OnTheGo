import 'package:get/get.dart';

import 'live_tracking_controller.dart';

class LiveTrackingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LiveTrackingController>(LiveTrackingController.new);
  }
}
