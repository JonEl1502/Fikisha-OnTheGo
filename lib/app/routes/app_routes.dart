/// App Route Names
class AppRoutes {
  AppRoutes._();

  // Auth
  static const String signIn = '/sign-in';

  // Main
  static const String home = '/home';
  static const String packageDetails = '/package-details';
  static const String postPackage = '/post-package';

  // Delivery lifecycle
  static const String activeDelivery = '/active-delivery'; // traveler side
  static const String liveTracking = '/live-tracking'; // sender side

  // User
  static const String profile = '/profile';
}
