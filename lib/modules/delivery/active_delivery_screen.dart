import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';

import '../../app/theme/app_colors.dart';
import '../../data/models/package_model.dart';
import '../../widgets/otg_map.dart';
import '../../widgets/stylized_map.dart'
    show DotPin, DropoffPin, PackageMarker;
import '../../widgets/ui.dart';
import 'active_delivery_controller.dart';

/// Screen 4 — Active Delivery · traveler.
class ActiveDeliveryScreen extends GetView<ActiveDeliveryController> {
  const ActiveDeliveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = controller.package;
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Live map — courier marker follows the traveler's real GPS.
                Positioned.fill(
                  child: Obx(() {
                    final courier = p.courier.value;
                    final delivered =
                        p.status.value.index >= PackageStatus.delivered.index;
                    return OtgMap(
                      controller: controller.mapCtrl,
                      fitPoints: [
                        p.pickupGeo.latLng,
                        p.dropoffGeo.latLng,
                        if (courier != null) courier.latLng,
                      ],
                      route: controller.route.toList(),
                      markers: [
                        Marker(
                            point: p.pickupGeo.latLng,
                            width: 16,
                            height: 16,
                            child: const DotPin()),
                        Marker(
                            point: p.dropoffGeo.latLng,
                            width: 40,
                            height: 40,
                            alignment: Alignment.topCenter,
                            child: const DropoffPin()),
                        Marker(
                            point: delivered
                                ? p.dropoffGeo.latLng
                                : (courier ?? p.pickupGeo).latLng,
                            width: 42,
                            height: 42,
                            child: GestureDetector(
                                onTap: controller.focusCourier,
                                child: const PackageMarker())),
                      ],
                    );
                  }),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        const RoundBackButton(),
                        const Spacer(),
                        Obx(() {
                          final s = p.status.value;
                          p.courier.value; // ETA follows live position
                          final label = switch (s) {
                            PackageStatus.claimed => 'Head to pickup',
                            PackageStatus.pickedUp => 'Starting trip…',
                            PackageStatus.inTransit =>
                              'Dropoff · ${p.etaMinutes} min',
                            _ => 'Arrived',
                          };
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.ink,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Text(label,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800)),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Status + actions sheet.
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
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SheetHandle(),
                    const SizedBox(height: 10),
                    Obx(() => StatusStepper(status: p.status.value)),
                    const SizedBox(height: 16),
                    // Destination card.
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Obx(() {
                            final toPickup =
                                p.status.value == PackageStatus.claimed;
                            return Icon(
                                toPickup
                                    ? Icons.storefront_outlined
                                    : Icons.location_pin,
                                color: AppColors.accent,
                                size: 24);
                          }),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Obx(() {
                              final toPickup =
                                  p.status.value == PackageStatus.claimed;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      toPickup
                                          ? 'HEAD TO PICKUP'
                                          : 'HEAD TO DROPOFF',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          letterSpacing: .8,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.muted)),
                                  const SizedBox(height: 2),
                                  Text(
                                      toPickup
                                          ? p.pickupLabel
                                          : p.dropoffLabel,
                                      style: const TextStyle(
                                          fontSize: 16.5,
                                          fontWeight: FontWeight.w800)),
                                ],
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Sender contact row — numbers revealed after claim.
                    Row(
                      children: [
                        Avatar(p.sender, radius: 21),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.sender.name,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800)),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded,
                                      color: AppColors.gold, size: 15),
                                  Text(
                                      ' ${p.sender.rating.toStringAsFixed(1)} · Sender',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.inkSoft)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        _ContactButton(
                            icon: Icons.call,
                            onTap: () => controller.contact('Phone')),
                        const SizedBox(width: 8),
                        _ContactButton(
                            icon: Icons.sms_outlined,
                            onTap: () => controller.contact('SMS')),
                        const SizedBox(width: 8),
                        _ContactButton(
                            icon: Icons.chat,
                            green: true,
                            onTap: () => controller.contact('WhatsApp')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Settlement note — platform doesn't touch money in MVP.
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule,
                              size: 18, color: AppColors.inkSoft),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              'Collect KES ${p.fee} on delivery · cash or M-Pesa',
                              style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.inkSoft),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Obx(() {
                      final s = p.status.value;
                      // Delivery unlocks only once the courier reaches the
                      // dropoff (within ~150 m).
                      final canDeliver =
                          s == PackageStatus.inTransit && p.arrived ||
                              s.index >= PackageStatus.delivered.index;
                      return switch (s) {
                        PackageStatus.claimed => ElevatedButton(
                            onPressed: controller.markPickedUp,
                            child: const Text('Mark as picked up'),
                          ),
                        PackageStatus.pickedUp => const ElevatedButton(
                            onPressed: null,
                            child: Text('Picked up — starting trip…'),
                          ),
                        PackageStatus.inTransit when !canDeliver =>
                          ElevatedButton(
                            onPressed: null,
                            child: Text(
                                'In transit · ${p.etaMinutes} min to dropoff'),
                          ),
                        _ => ElevatedButton(
                            onPressed: controller.markDelivered,
                            child: const Text('Mark as delivered'),
                          ),
                      };
                    }),
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

class _ContactButton extends StatelessWidget {
  const _ContactButton(
      {required this.icon, required this.onTap, this.green = false});
  final IconData icon;
  final VoidCallback onTap;
  final bool green;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: green ? const Color(0xFF4CC763) : AppColors.background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon,
              size: 20, color: green ? Colors.white : AppColors.primary),
        ),
      ),
    );
  }
}
