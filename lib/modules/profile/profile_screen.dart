import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/app_colors.dart';
import '../../data/models/package_model.dart';
import '../../widgets/ui.dart';
import 'profile_controller.dart';

/// Screen 7 — Profile & history.
class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final me = controller.service.me;
    return Scaffold(
      body: Column(
        children: [
          // Green header.
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 54),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Material(
                          color: Colors.white24,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: Get.back,
                            child: const SizedBox(
                              width: 42,
                              height: 42,
                              child: Icon(Icons.arrow_back_ios_new,
                                  size: 17, color: Colors.white),
                            ),
                          ),
                        ),
                        const Spacer(),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.menu,
                              color: Colors.white, size: 26),
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          onSelected: (v) {
                            if (v == 'signout') controller.signOut();
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'signout',
                              child: Row(
                                children: [
                                  Icon(Icons.logout,
                                      size: 18, color: AppColors.ink),
                                  SizedBox(width: 10),
                                  Text('Sign out'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          width: 82,
                          height: 82,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: .4),
                                width: 3),
                          ),
                          child: Center(
                            child: Text(me.initial,
                                style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(me.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white)),
                                  ),
                                  const SizedBox(width: 6),
                                  if (me.verified)
                                    const Icon(Icons.verified,
                                        color: Colors.white, size: 20),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '★ ${me.rating.toStringAsFixed(1)} · ${me.ratingsCount} ratings · Joined ${me.joined}',
                                style: const TextStyle(
                                    fontSize: 13.5, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Stat cards overlapping the header.
          Transform.translate(
            offset: const Offset(0, -36),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _StatCard(value: '${me.deliveredCount}', label: 'Delivered'),
                  const SizedBox(width: 12),
                  _StatCard(value: '${me.sentCount}', label: 'Sent'),
                  const SizedBox(width: 12),
                  _StatCard(
                      value: _kes(me.kesEarned),
                      label: 'KES earned',
                      green: true),
                ],
              ),
            ),
          ),
          // Role tabs.
          Transform.translate(
            offset: const Offset(0, -18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Obx(() => Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9E7DE),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Row(
                      children: [
                        _Tab(
                            label: 'As Traveler',
                            selected: controller.asTraveler.value,
                            onTap: () => controller.asTraveler.value = true),
                        _Tab(
                            label: 'As Sender',
                            selected: !controller.asTraveler.value,
                            onTap: () => controller.asTraveler.value = false),
                      ],
                    ),
                  )),
            ),
          ),
          // History list.
          Expanded(
            child: Obx(() {
              final records = controller.records;
              if (records.isEmpty) {
                return const Center(
                  child: Text('No deliveries yet',
                      style:
                          TextStyle(fontSize: 15, color: AppColors.muted)),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: records.length,
                separatorBuilder: (_, i) =>
                    const Divider(height: 1, color: AppColors.line),
                itemBuilder: (_, i) => _HistoryTile(r: records[i]),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _kes(int v) {
    final s = '$v';
    if (s.length <= 3) return s;
    return '${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.value, required this.label, this.green = false});
  final String value;
  final String label;
  final bool green;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: Color(0x14000000), blurRadius: 12),
          ],
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: green ? AppColors.primary : AppColors.ink)),
            const SizedBox(height: 3),
            Text(label,
                style:
                    const TextStyle(fontSize: 12.5, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            boxShadow: selected
                ? const [BoxShadow(color: Color(0x14000000), blurRadius: 8)]
                : null,
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: selected ? AppColors.ink : AppColors.muted)),
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.r});
  final DeliveryRecord r;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          PackageTileIcon(orange: !r.asTraveler, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.route,
                    style: const TextStyle(
                        fontSize: 15.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text('${r.date} · ${r.item}',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.muted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('KES ${r.fee}',
                  style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary)),
              const SizedBox(height: 3),
              StarRow(r.stars, size: 14),
            ],
          ),
        ],
      ),
    );
  }
}
