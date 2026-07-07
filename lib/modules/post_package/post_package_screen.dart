import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';

import '../../app/theme/app_colors.dart';
import '../../data/models/package_model.dart';
import '../../widgets/otg_map.dart';
import '../../widgets/stylized_map.dart' show DotPin, DropoffPin;
import '../../widgets/ui.dart';
import 'post_package_controller.dart';

/// Screen 6 — Post Package · sender.
class PostPackageScreen extends GetView<PostPackageController> {
  const PostPackageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  const RoundBackButton(),
                  const SizedBox(width: 14),
                  const Text('Send a package',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                children: [
                  // Route preview — follows the pins picked on the map.
                  Obx(() {
                    final a = controller.pickupGeo.value;
                    final b = controller.dropoffGeo.value;
                    final both = a != null && b != null;
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: SizedBox(
                        height: 150,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: IgnorePointer(
                                child: OtgMap(
                                  interactive: false,
                                  center: (a ?? b)?.latLng,
                                  zoom: 13,
                                  fitPoints: both
                                      ? [a.latLng, b.latLng]
                                      : null,
                                  fitPadding: const EdgeInsets.all(36),
                                  route: both
                                      ? [a.latLng, b.latLng]
                                      : null,
                                  markers: [
                                    if (a != null)
                                      Marker(
                                          point: a.latLng,
                                          width: 16,
                                          height: 16,
                                          child: const DotPin()),
                                    if (b != null)
                                      Marker(
                                          point: b.latLng,
                                          width: 38,
                                          height: 38,
                                          alignment: Alignment.topCenter,
                                          child: const DropoffPin()),
                                  ],
                                ),
                              ),
                            ),
                            if (both)
                              Positioned(
                                right: 10,
                                bottom: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                      '${controller.routeKm.toStringAsFixed(1)} km',
                                      style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 14),
                  Obx(() => _LocationField(
                        label: 'PICKUP',
                        value: controller.pickupLabel.value.isEmpty
                            ? 'Pick on the map'
                            : controller.pickupLabel.value,
                        isSet: controller.pickupGeo.value != null,
                        marker: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                              color: AppColors.primaryDark,
                              shape: BoxShape.circle),
                        ),
                        onTap: () => controller.pickLocation(isPickup: true),
                      )),
                  const SizedBox(height: 10),
                  Obx(() => _LocationField(
                        label: 'DROPOFF',
                        value: controller.dropoffLabel.value.isEmpty
                            ? 'Pick on the map'
                            : controller.dropoffLabel.value,
                        isSet: controller.dropoffGeo.value != null,
                        marker: const Icon(Icons.location_pin,
                            color: AppColors.accent, size: 20),
                        onTap: () => controller.pickLocation(isPickup: false),
                      )),
                  const SizedBox(height: 22),
                  const Text('PACKAGE DETAILS',
                      style: TextStyle(
                          fontSize: 12.5,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: controller.descriptionCtrl,
                    decoration: const InputDecoration(
                        hintText: 'What are you sending?'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Obx(() => Row(
                        children: [
                          for (final s in PackageSize.values) ...[
                            Expanded(
                              child: _SizeButton(
                                label: s.label,
                                selected: controller.size.value == s,
                                onTap: () => controller.size.value = s,
                              ),
                            ),
                            if (s != PackageSize.large) const SizedBox(width: 10),
                          ],
                        ],
                      )),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const PackageTileIcon(size: 74),
                      const SizedBox(width: 12),
                      Obx(() => GestureDetector(
                            onTap: controller.hasPhoto.toggle,
                            child: Container(
                              width: 74,
                              height: 74,
                              decoration: BoxDecoration(
                                color: controller.hasPhoto.value
                                    ? AppColors.primarySoft
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: controller.hasPhoto.value
                                        ? AppColors.primary
                                        : AppColors.muted,
                                    width: 1.4,
                                    style: BorderStyle.solid),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                      controller.hasPhoto.value
                                          ? Icons.check_circle
                                          : Icons.add,
                                      color: controller.hasPhoto.value
                                          ? AppColors.primary
                                          : AppColors.muted,
                                      size: 22),
                                  const SizedBox(height: 4),
                                  Text(
                                      controller.hasPhoto.value
                                          ? 'Photo added'
                                          : 'Add photo',
                                      style: const TextStyle(
                                          fontSize: 11.5,
                                          color: AppColors.inkSoft)),
                                ],
                              ),
                            ),
                          )),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Text('DELIVERY FEE',
                      style: TextStyle(
                          fontSize: 12.5,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      children: [
                        const Text('KES',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.muted)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: controller.feeCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(5),
                            ],
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.w800),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              hintText: '0',
                            ),
                          ),
                        ),
                        const Text('Negotiable',
                            style: TextStyle(
                                fontSize: 14.5, fontWeight: FontWeight.w600)),
                        Obx(() => Switch(
                              value: controller.negotiable.value,
                              activeThumbColor: Colors.white,
                              activeTrackColor: AppColors.primary,
                              onChanged: (v) =>
                                  controller.negotiable.value = v,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
              child: ElevatedButton(
                onPressed: controller.post,
                child: const Text('Post package'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationField extends StatelessWidget {
  const _LocationField({
    required this.label,
    required this.value,
    required this.marker,
    required this.onTap,
    this.isSet = false,
  });

  final String label;
  final String value;
  final Widget marker;
  final VoidCallback onTap;
  final bool isSet;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              SizedBox(width: 22, child: Center(child: marker)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 11.5,
                            letterSpacing: .8,
                            fontWeight: FontWeight.w700,
                            color: AppColors.muted)),
                    const SizedBox(height: 2),
                    Text(value,
                        style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color:
                                isSet ? AppColors.ink : AppColors.muted)),
                  ],
                ),
              ),
              Icon(isSet ? Icons.edit_location_alt_outlined : Icons.map_outlined,
                  size: 19, color: isSet ? AppColors.muted : AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _SizeButton extends StatelessWidget {
  const _SizeButton(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: selected ? AppColors.primary : AppColors.line),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.ink)),
        ),
      ),
    );
  }
}
