import 'package:get/get.dart';

import 'post_package_controller.dart';

class PostPackageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PostPackageController>(PostPackageController.new);
  }
}
