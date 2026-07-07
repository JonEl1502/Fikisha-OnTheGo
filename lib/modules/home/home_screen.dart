import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';

import '../../app/theme/app_colors.dart';
import '../../data/models/package_model.dart';
import '../../widgets/otg_map.dart';
import '../../widgets/stylized_map.dart' show MyLocationDot, PricePin;
import '../../widgets/ui.dart';
import 'home_controller.dart';

/// Screen 2 — Home Map · discover packages.
class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-bleed real map with open-package price pins.
          Positioned.fill(
            child: Obx(() {
              final open = controller.openPackages;
              final mine = controller.myPos.value;
              return OtgMap(
                controller: controller.mapCtrl,
                center: mine ?? OtgMap.nairobi,
                zoom: 12.5,
                markers: [
                  for (final p in open)
                    Marker(
                      point: p.pickupGeo.latLng,
                      width: 96,
                      height: 46,
                      alignment: Alignment.topCenter,
                      child: GestureDetector(
                        onTap: () => controller.openDetails(p),
                        child: Center(child: PricePin(fee: p.fee)),
                      ),
                    ),
                  if (mine != null)
                    Marker(
                      point: mine,
                      width: 52,
                      height: 52,
                      child: const MyLocationDot(),
                    ),
                ],
              );
            }),
          ),
          // Header: heading-to card + filter chips.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    elevation: 3,
                    shadowColor: const Color(0x22000000),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              color: AppColors.primary, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: controller.setDestination,
                              child: Obx(() {
                                final label = controller.destLabel.value;
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text('HEADING TO',
                                        style: TextStyle(
                                            fontSize: 11,
                                            letterSpacing: 1,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.muted)),
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            label.isEmpty
                                                ? 'Set your destination'
                                                : label,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w800,
                                                color: label.isEmpty
                                                    ? AppColors.muted
                                                    : AppColors.ink),
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        const Icon(Icons.edit_outlined,
                                            size: 15,
                                            color: AppColors.muted),
                                      ],
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                          GestureDetector(
                            onTap: controller.openProfile,
                            child: Obx(() => CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppColors.primary,
                                  child: Text(
                                    controller.service.signedIn.value
                                        ? controller.service.me.initial
                                        : '?',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 17),
                                  ),
                                )),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Scrolls horizontally so the chips never overflow on
                  // narrow screens.
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    child: Obx(() => Row(
                          children: [
                            OtgChip('Along my route',
                                selected: controller.alongRoute.value &&
                                    controller.destGeo.value != null,
                                leading: controller.alongRoute.value &&
                                        controller.destGeo.value != null
                                    ? Icons.check
                                    : null,
                                onTap: controller.toggleAlongRoute),
                            const SizedBox(width: 8),
                            OtgChip('Small',
                                selected: controller.smallOnly.value,
                                onTap: controller.smallOnly.toggle),
                            const SizedBox(width: 8),
                            OtgChip('< 2 km detour',
                                selected: controller.shortDetour.value,
                                onTap: controller.shortDetour.toggle),
                          ],
                        )),
                  ),
                  // Resume banners for active deliveries.
                  Obx(() {
                    final carrying = controller.service.carrying.value;
                    final sending = controller.service.sending.value;
                    return Column(children: [
                      if (carrying != null)
                        _ActiveBanner(
                          label:
                              'Carrying · ${carrying.description} → ${carrying.dropoffLabel}',
                          onTap: controller.openCarrying,
                        ),
                      if (sending != null)
                        _ActiveBanner(
                          label:
                              'Your package · ${_statusLabel(sending.status.value)}',
                          orange: true,
                          onTap: controller.openSending,
                        ),
                    ]);
                  }),
                ],
              ),
            ),
          ),
          // Bottom: Send-a-package CTA + nearby packages sheet.
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16, bottom: 12),
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 4,
                      shadowColor: const Color(0x33000000),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: controller.centerOnMe,
                        child: const SizedBox(
                          width: 50,
                          height: 50,
                          child: Icon(Icons.my_location,
                              color: AppColors.primary, size: 22),
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16, bottom: 14),
                    child: Material(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(30),
                      elevation: 5,
                      shadowColor: const Color(0x55EE8A38),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: controller.openPostPackage,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 22, vertical: 15),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, color: Colors.white, size: 22),
                              SizedBox(width: 8),
                              Text('Send a package',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _NearbySheet(controller: controller),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(PackageStatus s) => switch (s) {
        PackageStatus.posted => 'Posted — waiting for a traveler',
        PackageStatus.claimed => 'Claimed — traveler heading to pickup',
        PackageStatus.pickedUp => 'Picked up',
        PackageStatus.inTransit => 'In transit — tap to track live',
        PackageStatus.delivered => 'Delivered — confirm receipt',
        PackageStatus.confirmed => 'Completed',
      };
}

class _ActiveBanner extends StatelessWidget {
  const _ActiveBanner(
      {required this.label, required this.onTap, this.orange = false});
  final String label;
  final VoidCallback onTap;
  final bool orange;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Material(
        color: orange ? AppColors.accent : AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        elevation: 3,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.local_shipping_outlined,
                    color: Colors.white, size: 19),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5)),
                ),
                const Icon(Icons.chevron_right, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NearbySheet extends StatelessWidget {
  const _NearbySheet({required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Color(0x22000000), blurRadius: 20)],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
              child: Obx(() => Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${controller.openPackages.length} packages on your way',
                          style: const TextStyle(
                              fontSize: 19, fontWeight: FontWeight.w800),
                        ),
                      ),
                      _ModeToggle(controller: controller),
                    ],
                  )),
            ),
            Obx(() {
              final open = controller.openPackages;
              if (!controller.listMode.value) {
                return SizedBox(
                  height: 132,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                    scrollDirection: Axis.horizontal,
                    itemCount: open.length,
                    separatorBuilder: (_, i) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => _PackageCard(
                        p: open[i],
                        onTap: () => controller.openDetails(open[i])),
                  ),
                );
              }
              return SizedBox(
                height: MediaQuery.of(context).size.height * .48,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                  itemCount: open.length,
                  separatorBuilder: (_, i) =>
                      const Divider(height: 1, color: AppColors.line),
                  itemBuilder: (_, i) => _PackageListTile(
                      p: open[i],
                      km: controller.kmToPickup(open[i]),
                      onTap: () => controller.openDetails(open[i])),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.controller});
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    Widget seg(String label, bool active, VoidCallback onTap) =>
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: active ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : AppColors.muted)),
          ),
        );

    return Obx(() => Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFFEFEDE4),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              seg('Map', !controller.listMode.value,
                  () => controller.listMode.value = false),
              seg('List', controller.listMode.value,
                  () => controller.listMode.value = true),
            ],
          ),
        ));
  }
}

class _PackageListTile extends StatelessWidget {
  const _PackageListTile({required this.p, required this.onTap, this.km});
  final PackageModel p;
  final VoidCallback onTap;
  final double? km;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            PackageTileIcon(orange: p.size != PackageSize.small, size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15.5, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(p.shortRoute,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.inkSoft)),
                  const SizedBox(height: 2),
                  Text(
                    '${p.size.label}'
                    '${km == null ? '' : ' · pickup ${km! < 1 ? '${(km! * 1000).round()} m' : '${km!.toStringAsFixed(km! > 20 ? 0 : 1)} km'} away'}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('KES ${p.fee}',
                    style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary)),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        color: AppColors.gold, size: 15),
                    Text(p.sender.rating.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({required this.p, required this.onTap});
  final PackageModel p;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: 250,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PackageTileIcon(
                      orange: p.size != PackageSize.small, size: 46),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 3),
                        Text(
                            '${p.size.label} · +${p.detourKm.toStringAsFixed(1)} km detour',
                            style: const TextStyle(
                                fontSize: 12.5, color: AppColors.muted)),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Text('KES ${p.fee}',
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary)),
                  const Spacer(),
                  const Icon(Icons.star_rounded,
                      color: AppColors.gold, size: 17),
                  Text(p.sender.rating.toStringAsFixed(1),
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
