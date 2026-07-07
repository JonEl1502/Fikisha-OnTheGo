import 'package:get/get.dart';

import 'package_details_controller.dart';

class PackageDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PackageDetailsController>(PackageDetailsController.new);
  }
}
