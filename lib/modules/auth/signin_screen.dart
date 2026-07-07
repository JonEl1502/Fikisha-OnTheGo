import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/app_colors.dart';
import '../../widgets/stylized_map.dart';
import 'auth_controller.dart';

/// Screen 1 — Onboarding · Google sign-in.
class SignInScreen extends GetView<AuthController> {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.vertical,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 64),
                // Brand mark
                Center(
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x332F5D43),
                            blurRadius: 18,
                            offset: Offset(0, 8)),
                      ],
                    ),
                    child: const Icon(Icons.near_me,
                        color: Colors.white, size: 40),
                  ),
                ),
                const SizedBox(height: 22),
                const Text('On the Go',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                const Text(
                  'Send it with someone already\nheading that way.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16.5, color: AppColors.inkSoft),
                ),
                const SizedBox(height: 32),
                // Mini map illustration with a dotted route
                Container(
                  height: 200,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: const [
                      BoxShadow(color: Color(0x14000000), blurRadius: 16),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: const StylizedMap(
                      route: (
                        Offset(.14, .78),
                        Offset(.5, .48),
                        Offset(.86, .30)
                      ),
                      routeDashed: true,
                      children: [
                        MapPin(
                            at: Offset(.14, .78),
                            size: Size(18, 18),
                            child: DotPin()),
                        MapPin(
                            at: Offset(.86, .30),
                            size: Size(40, 40),
                            anchor: Offset(.5, .9),
                            child: DropoffPin()),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                Obx(() => ElevatedButton(
                      onPressed: controller.googleBusy.value
                          ? null
                          : controller.signInWithGoogle,
                      child: controller.googleBusy.value
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _GoogleMark(),
                                SizedBox(width: 10),
                                Text('Continue with Google'),
                              ],
                            ),
                    )),
                const SizedBox(height: 16),
                const Text(
                  'By continuing you agree to our Terms\n& Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.muted),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// White "G" badge on the green button — no image asset needed.
class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration:
          const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: const Center(
        child: Text('G',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF4285F4))),
      ),
    );
  }
}
