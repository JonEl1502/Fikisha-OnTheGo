import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../app/routes/app_routes.dart';
import '../../core/services/delivery_service.dart';

/// Auth Controller — Google sign-in via Firebase Auth. The Firebase uid keys
/// all tracking data, whether the account acts as sender or traveler.
class AuthController extends GetxController {
  final DeliveryService _service = DeliveryService();

  final RxBool googleBusy = false.obs;

  Future<void> signInWithGoogle() async {
    if (googleBusy.value) return;
    googleBusy.value = true;
    try {
      final google = GoogleSignIn.instance;
      await google.initialize();
      final account = await google.authenticate();
      final credential = GoogleAuthProvider.credential(
        idToken: account.authentication.idToken,
      );
      final user = (await FirebaseAuth.instance
              .signInWithCredential(credential))
          .user!;
      _service.signInWithGoogle(
        uid: user.uid,
        name: user.displayName ?? account.displayName ?? 'On the Go user',
        contact: user.phoneNumber ?? user.email ?? '',
        photoUrl: user.photoURL,
      );
      Get.offAllNamed(AppRoutes.home);
    } on GoogleSignInException catch (e) {
      if (e.code != GoogleSignInExceptionCode.canceled) {
        _authError('Google sign-in failed (${e.code.name})');
      }
    } catch (e) {
      _authError('Google sign-in failed — check your connection');
    } finally {
      googleBusy.value = false;
    }
  }

  void _authError(String message) {
    Get.snackbar('On the Go', message,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4));
  }
}
