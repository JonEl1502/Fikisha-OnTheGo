import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';

import '../../app/theme/app_colors.dart';
import '../../data/models/package_model.dart';
import '../../widgets/otg_map.dart';
import '../../widgets/stylized_map.dart' show DotPin, DropoffPin;
import '../../widgets/ui.dart';
import 'package_details_controller.dart';

/// Screen 3 — Package Details · claim.
class PackageDetailsScreen extends GetView<PackageDetailsController> {
  const PackageDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = controller.package;
    return Scaffold(
      body: Column(
        children: [
          // Route preview map.
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Obx(() => OtgMap(
                        fitPoints: [
                          p.pickupGeo.latLng,
                          p.dropoffGeo.latLng,
                        ],
                        route: controller.route.toList(),
                        markers: [
                          Marker(
                              point: p.pickupGeo.latLng,
                              width: 18,
                              height: 18,
                              child: const DotPin()),
                          Marker(
                              point: p.dropoffGeo.latLng,
                              width: 40,
                              height: 40,
                              alignment: Alignment.topCenter,
                              child: const DropoffPin()),
                        ],
                      )),
                ),
                const SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Align(
                        alignment: Alignment.topLeft,
                        child: RoundBackButton()),
                  ),
                ),
              ],
            ),
          ),
          // Details sheet.
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [BoxShadow(color: Color(0x22000000), blurRadius: 20)],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SheetHandle(),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        PackageTileIcon(orange: p.size != PackageSize.small),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.description,
                                  style: const TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(p.size.label.toUpperCase(),
                                    style: const TextStyle(
                                        fontSize: 11.5,
                                        letterSpacing: .8,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.inkSoft)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    RouteStops(
                      pickup: p.pickupLabel,
                      dropoff: p.dropoffLabel,
                      trailing: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${p.distanceKm.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text('+${p.detourKm.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text('KES ${p.fee}',
                            style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary)),
                        const SizedBox(width: 10),
                        if (p.negotiable)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.accentSoft,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('Negotiable',
                                style: TextStyle(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5)),
                          ),
                      ],
                    ),
                    const Divider(height: 28, color: AppColors.line),
                    Row(
                      children: [
                        Avatar(p.sender),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              VerifiedName(p.sender),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded,
                                      color: AppColors.gold, size: 16),
                                  Text(
                                    ' ${p.sender.rating.toStringAsFixed(1)} · '
                                    '${p.sender.ratingsCount} deliveries'
                                    '${p.sender.verified ? ' · Verified' : ''}',
                                    style: const TextStyle(
                                        fontSize: 13.5,
                                        color: AppColors.inkSoft),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: controller.claim,
                      child: const Text('Claim delivery'),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        "${p.sender.name.split(' ').first}'s phone number is shared once you claim.",
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.muted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
