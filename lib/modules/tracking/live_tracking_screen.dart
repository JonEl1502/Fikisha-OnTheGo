import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';

import '../../app/theme/app_colors.dart';
import '../../data/models/package_model.dart';
import '../../widgets/otg_map.dart';
import '../../widgets/stylized_map.dart'
    show DotPin, DropoffPin, PackageMarker;
import '../../widgets/ui.dart';
import 'live_tracking_controller.dart';

/// Screen 5 — Live Tracking · sender. The traveler's GPS position is shared
/// only while this delivery is active and stops at delivery (PRD §6).
class LiveTrackingScreen extends GetView<LiveTrackingController> {
  const LiveTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = controller.package;
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Obx(() {
                    final courier = p.courier.value;
                    final hasTraveler = p.traveler.value != null;
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
                        if (hasTraveler)
                          Marker(
                              point: delivered
                                  ? p.dropoffGeo.latLng
                                  : (courier ?? p.pickupGeo).latLng,
                              width: 46,
                              height: 46,
                              child: GestureDetector(
                                  onTap: controller.focusCourier,
                                  child: const PackageMarker(
                                      ringColor: Color(0xFFBBD0F2)))),
                      ],
                    );
                  }),
                ),
                // Traveler header card.
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const RoundBackButton(),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Obx(() {
                          final t = p.traveler.value;
                          return Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            elevation: 3,
                            shadowColor: const Color(0x22000000),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: t == null
                                  ? const Row(
                                      children: [
                                        SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: AppColors.primary),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Posted — waiting for a traveler heading your way…',
                                            style: TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        Avatar(t,
                                            radius: 22,
                                            background: AppColors.primary,
                                            foreground: Colors.white),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              VerifiedName(t,
                                                  style: const TextStyle(
                                                      fontSize: 16.5,
                                                      fontWeight:
                                                          FontWeight.w800)),
                                              Row(
                                                children: [
                                                  const Icon(
                                                      Icons.star_rounded,
                                                      color: AppColors.gold,
                                                      size: 15),
                                                  Text(
                                                    ' ${t.rating.toStringAsFixed(1)} · carrying your package',
                                                    style: const TextStyle(
                                                        fontSize: 13,
                                                        color: AppColors
                                                            .inkSoft),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (p.status.value ==
                                            PackageStatus.inTransit)
                                          Column(
                                            children: [
                                              Text('${p.etaMinutes}',
                                                  style: const TextStyle(
                                                      fontSize: 24,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color:
                                                          AppColors.primary)),
                                              const Text('MIN',
                                                  style: TextStyle(
                                                      fontSize: 10.5,
                                                      letterSpacing: 1,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color:
                                                          AppColors.muted)),
                                            ],
                                          ),
                                      ],
                                    ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Timeline + actions sheet.
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
                    const SizedBox(height: 8),
                    Obx(() => Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Your package to ${p.dropoffLabel.split(' · ').first}',
                                style: const TextStyle(
                                    fontSize: 19, fontWeight: FontWeight.w800),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.accentSoft,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                _statusChip(p.status.value),
                                style: const TextStyle(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13),
                              ),
                            ),
                          ],
                        )),
                    const SizedBox(height: 14),
                    Obx(() {
                      p.status.value;
                      return Column(children: [
                        _TimelineRow(
                          done: p.claimedAt != null || p.postedAt != null,
                          title: 'Posted & claimed',
                          subtitle: p.claimedAt == null
                              ? 'Posted ${controller.time(p.postedAt)} · waiting'
                              : '${controller.time(p.postedAt)} · ${controller.time(p.claimedAt)}',
                        ),
                        _TimelineRow(
                          done: p.pickedUpAt != null,
                          title: 'Picked up',
                          subtitle: p.pickedUpAt == null
                              ? 'Pending'
                              : '${controller.time(p.pickedUpAt)} · ${p.pickupLabel.split(' · ').last}',
                        ),
                        _TimelineRow(
                          done: p.deliveredAt != null,
                          active: p.status.value == PackageStatus.inTransit,
                          title: 'In transit → Delivered',
                          subtitle: p.deliveredAt != null
                              ? 'Delivered ${controller.time(p.deliveredAt)}'
                              : p.status.value == PackageStatus.inTransit
                                  ? 'Arriving ~${p.etaMinutes} min'
                                  : 'Pending',
                          last: true,
                        ),
                      ]);
                    }),
                    const SizedBox(height: 10),
                    Obx(() {
                      final hasTraveler = p.traveler.value != null;
                      return Row(
                        children: [
                          Expanded(
                            child: _ContactBar(
                                icon: Icons.call,
                                label: 'Call',
                                enabled: hasTraveler,
                                onTap: () => controller.contact('Phone')),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ContactBar(
                                icon: Icons.chat,
                                label: 'WhatsApp',
                                enabled: hasTraveler,
                                whatsapp: true,
                                onTap: () => controller.contact('WhatsApp')),
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 12),
                    Obx(() {
                      final delivered =
                          p.status.value == PackageStatus.delivered;
                      return ElevatedButton(
                        onPressed:
                            delivered ? controller.confirmReceipt : null,
                        child: Text(delivered
                            ? 'Confirm receipt'
                            : 'Confirm receipt · after delivery'),
                      );
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

  String _statusChip(PackageStatus s) => switch (s) {
        PackageStatus.posted => 'Posted',
        PackageStatus.claimed => 'Claimed',
        PackageStatus.pickedUp => 'Picked up',
        PackageStatus.inTransit => 'In transit',
        PackageStatus.delivered => 'Delivered',
        PackageStatus.confirmed => 'Completed',
      };
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.done,
    required this.title,
    required this.subtitle,
    this.active = false,
    this.last = false,
  });

  final bool done;
  final bool active;
  final String title;
  final String subtitle;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? AppColors.accent
        : done
            ? AppColors.primary
            : AppColors.muted;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active || !done ? Colors.transparent : color,
                  border: Border.all(color: color, width: 2.2),
                ),
              ),
              if (!last)
                Expanded(
                    child: Container(width: 2, color: const Color(0xFFE3E1D8))),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: active ? AppColors.accent : AppColors.ink)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.muted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactBar extends StatelessWidget {
  const _ContactBar({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.whatsapp = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final bool whatsapp;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled ? onTap : null,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 19,
                  color: !enabled
                      ? AppColors.muted
                      : whatsapp
                          ? const Color(0xFF4CC763)
                          : AppColors.ink),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: enabled ? AppColors.ink : AppColors.muted)),
            ],
          ),
        ),
      ),
    );
  }
}
