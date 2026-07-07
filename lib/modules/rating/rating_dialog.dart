import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/app_colors.dart';
import '../../core/services/delivery_service.dart';
import '../../data/models/package_model.dart';
import '../../data/models/user_model.dart';
import '../../widgets/ui.dart';

/// Screen 8 — Rating · post-delivery. Shown as a dialog over the map.
Future<void> showRatingDialog({
  required PackageModel package,
  required UserModel rateUser,
  required String rateLabel, // 'RATE YOUR SENDER' / 'RATE YOUR TRAVELER'
}) {
  return Get.dialog(
    _RatingDialog(package: package, rateUser: rateUser, rateLabel: rateLabel),
    barrierDismissible: false,
    barrierColor: Colors.black38,
  );
}

class _RatingDialog extends StatefulWidget {
  const _RatingDialog(
      {required this.package, required this.rateUser, required this.rateLabel});

  final PackageModel package;
  final UserModel rateUser;
  final String rateLabel;

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  int _stars = 4;
  final Set<String> _traits = {'On time', 'Friendly'};

  static const _allTraits = ['On time', 'Friendly', 'Careful', 'Good comms'];

  void _submit() {
    // Pop the dialog route directly — Get.back() would dismiss the rating
    // snackbar instead of the dialog and leave it stuck open.
    Navigator.of(context).pop();
    DeliveryService().submitRating(widget.package, _stars);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.package;
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.white, size: 38),
            ),
            const SizedBox(height: 18),
            const Text('Delivered!',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('KES ${p.fee} settled · ${p.shortRoute}',
                style:
                    const TextStyle(fontSize: 15, color: AppColors.inkSoft)),
            const SizedBox(height: 20),
            // Who you're rating.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Avatar(widget.rateUser),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.rateLabel,
                          style: const TextStyle(
                              fontSize: 11,
                              letterSpacing: .8,
                              fontWeight: FontWeight.w700,
                              color: AppColors.muted)),
                      const SizedBox(height: 2),
                      Text(widget.rateUser.name,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  GestureDetector(
                    onTap: () => setState(() => _stars = i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Icon(
                        i <= _stars
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: AppColors.gold,
                        size: 44,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final t in _allTraits)
                  GestureDetector(
                    onTap: () => setState(
                        () => _traits.contains(t)
                            ? _traits.remove(t)
                            : _traits.add(t)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: _traits.contains(t)
                            ? AppColors.primarySoft
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(t,
                          style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: _traits.contains(t)
                                  ? AppColors.primary
                                  : AppColors.inkSoft)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: _submit, child: const Text('Submit rating')),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                DeliveryService().skipRating(widget.package);
              },
              child: const Text('Skip',
                  style: TextStyle(color: AppColors.muted)),
            ),
          ],
        ),
      ),
    );
  }
}
