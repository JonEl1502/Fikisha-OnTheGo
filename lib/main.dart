import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'app/bindings/initial_binding.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/theme/app_theme.dart';
import 'core/services/delivery_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  // Firebase caches the Google session — restore it and skip sign-in.
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    DeliveryService().signInWithGoogle(
      uid: user.uid,
      name: user.displayName ?? 'On the Go user',
      contact: user.phoneNumber ?? user.email ?? '',
      photoUrl: user.photoURL,
    );
  }

  runApp(OnTheGoApp(
    initialRoute: user == null ? AppRoutes.signIn : AppRoutes.home,
  ));
}

class OnTheGoApp extends StatelessWidget {
  const OnTheGoApp({super.key, this.initialRoute = AppRoutes.signIn});

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'On the Go',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: initialRoute,
      getPages: AppPages.routes,
      initialBinding: InitialBinding(),
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
