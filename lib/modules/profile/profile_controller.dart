import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../app/routes/app_routes.dart';
import '../../core/services/delivery_service.dart';
import '../../data/models/package_model.dart';

/// Profile Controller — stats + delivery history tabs.
class ProfileController extends GetxController {
  final DeliveryService service = DeliveryService();

  final RxBool asTraveler = true.obs;

  List<DeliveryRecord> get records => service.history
      .where((r) => r.asTraveler == asTraveler.value)
      .toList();

  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await FirebaseAuth.instance.signOut();
    Get.offAllNamed(AppRoutes.signIn);
  }
}
