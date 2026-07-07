import 'package:get/get.dart';

import '../../modules/auth/auth_binding.dart';
import '../../modules/auth/signin_screen.dart';
import '../../modules/delivery/active_delivery_binding.dart';
import '../../modules/delivery/active_delivery_screen.dart';
import '../../modules/home/home_binding.dart';
import '../../modules/home/home_screen.dart';
import '../../modules/package_details/package_details_binding.dart';
import '../../modules/package_details/package_details_screen.dart';
import '../../modules/post_package/post_package_binding.dart';
import '../../modules/post_package/post_package_screen.dart';
import '../../modules/profile/profile_binding.dart';
import '../../modules/profile/profile_screen.dart';
import '../../modules/tracking/live_tracking_binding.dart';
import '../../modules/tracking/live_tracking_screen.dart';
import 'app_routes.dart';

/// App Pages Configuration
class AppPages {
  AppPages._();

  static const initial = AppRoutes.signIn;

  static final routes = [
    GetPage(
      name: AppRoutes.signIn,
      page: () => const SignInScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.packageDetails,
      page: () => const PackageDetailsScreen(),
      binding: PackageDetailsBinding(),
    ),
    GetPage(
      name: AppRoutes.postPackage,
      page: () => const PostPackageScreen(),
      binding: PostPackageBinding(),
    ),
    GetPage(
      name: AppRoutes.activeDelivery,
      page: () => const ActiveDeliveryScreen(),
      binding: ActiveDeliveryBinding(),
    ),
    GetPage(
      name: AppRoutes.liveTracking,
      page: () => const LiveTrackingScreen(),
      binding: LiveTrackingBinding(),
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileScreen(),
      binding: ProfileBinding(),
    ),
  ];
}
