import 'package:flutter/material.dart';

import '../data/models/package_model.dart';
import '../data/models/user_model.dart';
import '../app/theme/app_colors.dart';

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 5,
        margin: const EdgeInsets.only(top: 10, bottom: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFE3E1D8),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

class RoundBackButton extends StatelessWidget {
  const RoundBackButton({super.key, this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: const Color(0x33000000),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap ?? () => Navigator.of(context).maybePop(),
        child: const SizedBox(
          width: 48,
          height: 48,
          child: Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.ink),
        ),
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  const Avatar(this.user,
      {super.key, this.radius = 22, this.background, this.foreground});
  final UserModel user;
  final double radius;
  final Color? background;
  final Color? foreground;

  static const _palette = [
    (Color(0xFFE7DBF5), Color(0xFF7B5BA6)), // lilac
    (Color(0xFFDCEBDC), Color(0xFF2F5D43)), // green
    (Color(0xFFFBE3CE), Color(0xFFB96A1F)), // orange
    (Color(0xFFD9E6F5), Color(0xFF3D6BA8)), // blue
  ];

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _palette[user.name.length % _palette.length];
    final photo = user.photoUrl;
    return CircleAvatar(
      radius: radius,
      backgroundColor: background ?? bg,
      backgroundImage: photo == null ? null : NetworkImage(photo),
      child: photo != null
          ? null
          : Text(
              user.initial,
              style: TextStyle(
                color: foreground ?? fg,
                fontWeight: FontWeight.w800,
                fontSize: radius * .82,
              ),
            ),
    );
  }
}

class StarRow extends StatelessWidget {
  const StarRow(this.stars, {super.key, this.size = 18});
  final int stars;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(i <= stars ? Icons.star_rounded : Icons.star_outline_rounded,
              color: AppColors.gold, size: size),
      ],
    );
  }
}

class VerifiedName extends StatelessWidget {
  const VerifiedName(this.user, {super.key, this.style});
  final UserModel user;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final s = style ??
        const TextStyle(fontSize: 17, fontWeight: FontWeight.w800);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: Text(user.name, style: s, overflow: TextOverflow.ellipsis)),
        if (user.verified) ...[
          const SizedBox(width: 5),
          Icon(Icons.verified, color: AppColors.primary, size: s.fontSize! * .95),
        ],
      ],
    );
  }
}

/// Rounded filter / trait chip.
class OtgChip extends StatelessWidget {
  const OtgChip(
    this.label, {
    super.key,
    this.selected = false,
    this.leading,
    this.onTap,
  });

  final String label;
  final bool selected;
  final IconData? leading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 1,
      shadowColor: const Color(0x1A000000),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                Icon(leading,
                    size: 15,
                    color: selected ? Colors.white : AppColors.ink),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Package hexagon-in-a-tile icon used in cards and lists.
class PackageTileIcon extends StatelessWidget {
  const PackageTileIcon({super.key, this.orange = false, this.size = 52});
  final bool orange;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: orange ? AppColors.accentSoft : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(size * .3),
      ),
      child: Icon(Icons.inventory_2_outlined,
          color: orange ? AppColors.accent : AppColors.primary, size: size * .5),
    );
  }
}

/// Four-step lifecycle indicator: Claimed · Picked up · In transit · Delivered.
class StatusStepper extends StatelessWidget {
  const StatusStepper({super.key, required this.status});
  final PackageStatus status;

  static const _steps = ['Claimed', 'Picked up', 'In transit', 'Delivered'];

  int get _activeIndex => switch (status) {
        PackageStatus.posted => -1,
        PackageStatus.claimed => 0,
        PackageStatus.pickedUp => 1,
        PackageStatus.inTransit => 2,
        PackageStatus.delivered || PackageStatus.confirmed => 3,
      };

  @override
  Widget build(BuildContext context) {
    final active = _activeIndex;
    final done = status == PackageStatus.delivered ||
        status == PackageStatus.confirmed;
    return Row(
      children: [
        for (var i = 0; i < _steps.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2.5,
                margin: const EdgeInsets.only(bottom: 22),
                color: i <= active
                    ? AppColors.primary.withValues(alpha: .5)
                    : const Color(0xFFE3E1D8),
              ),
            ),
          _StepDot(
            label: _steps[i],
            state: i < active
                ? _StepState.done
                : i == active
                    ? (done ? _StepState.done : _StepState.active)
                    : _StepState.pending,
          ),
        ],
      ],
    );
  }
}

enum _StepState { done, active, pending }

class _StepDot extends StatelessWidget {
  const _StepDot({required this.label, required this.state});
  final String label;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final (fill, child) = switch (state) {
      _StepState.done => (
          AppColors.primary,
          const Icon(Icons.check, color: Colors.white, size: 16)
        ),
      _StepState.active => (
          AppColors.accent,
          Container(
            margin: const EdgeInsets.all(7),
            decoration: const BoxDecoration(
                color: Color(0xFFF7CBA2), shape: BoxShape.circle),
          )
        ),
      _StepState.pending => (const Color(0xFFEDEBE2), const SizedBox()),
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
          child: child,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: switch (state) {
              _StepState.done => AppColors.inkSoft,
              _StepState.active => AppColors.accent,
              _StepState.pending => AppColors.muted,
            },
          ),
        ),
      ],
    );
  }
}

/// Pickup → dropoff vertical pair used in details and forms.
class RouteStops extends StatelessWidget {
  const RouteStops({
    super.key,
    required this.pickup,
    required this.dropoff,
    this.trailing,
  });

  final String pickup;
  final String dropoff;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    Widget stop(String label, String value, Widget marker) => Row(
          crossAxisAlignment: CrossAxisAlignment.center,
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
                      style: const TextStyle(
                          fontSize: 15.5, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                stop(
                  'PICKUP',
                  pickup,
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                        color: AppColors.primaryDark, shape: BoxShape.circle),
                  ),
                ),
                Row(children: [
                  const SizedBox(width: 10),
                  Container(width: 2, height: 18, color: AppColors.line),
                ]),
                stop('DROPOFF', dropoff,
                    const Icon(Icons.location_pin, color: AppColors.accent, size: 20)),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

void showOtgSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
