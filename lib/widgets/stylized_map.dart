import 'package:flutter/material.dart';

import '../app/theme/app_colors.dart';

/// A lightweight, key-free map canvas that matches the screen board's pale
/// street style. Children are placed with [MapPin] using normalized (0..1)
/// coordinates. Swappable for google_maps_flutter without touching screens:
/// keep the same normalized-position contract at the call sites.
class StylizedMap extends StatelessWidget {
  const StylizedMap({
    super.key,
    this.route,
    this.routeDashed = false,
    this.children = const [],
  });

  /// Normalized route (start, control, end) drawn as a green polyline.
  final (Offset, Offset, Offset)? route;
  final bool routeDashed;
  final List<MapPin> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final size = Size(c.maxWidth, c.maxHeight);
      return ClipRect(
        child: Stack(
          children: [
            CustomPaint(size: size, painter: _MapPainter()),
            if (route != null)
              CustomPaint(
                size: size,
                painter: _RoutePainter(route!, dashed: routeDashed),
              ),
            for (final pin in children)
              Positioned(
                left: pin.at.dx * size.width - pin.size.width * pin.anchor.dx,
                top: pin.at.dy * size.height - pin.size.height * pin.anchor.dy,
                child: SizedBox.fromSize(size: pin.size, child: pin.child),
              ),
          ],
        ),
      );
    });
  }
}

class MapPin {
  const MapPin({
    required this.at,
    required this.size,
    required this.child,
    this.anchor = const Offset(.5, .5),
  });

  final Offset at; // normalized 0..1
  final Size size;
  final Offset anchor; // which point of the child sits on [at]
  final Widget child;
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.mapBase);

    // Park + water patches.
    final park = Paint()..color = AppColors.mapPark;
    canvas.drawPath(
      Path()
        ..moveTo(0, h * .82)
        ..quadraticBezierTo(w * .3, h * .68, w * .62, h * .84)
        ..quadraticBezierTo(w * .82, h * .94, w, h * .88)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      park,
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * .12, h * .18), width: w * .3, height: h * .18),
      park,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * .86, 0)
        ..quadraticBezierTo(w * .78, h * .10, w * .9, h * .18)
        ..quadraticBezierTo(w * 1.02, h * .24, w, h * .3)
        ..lineTo(w, 0)
        ..close(),
      Paint()..color = AppColors.mapWater,
    );

    void road(Path p, double width) {
      canvas.drawPath(
        p,
        Paint()
          ..color = const Color(0xFFDFE1D8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = width + 3
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawPath(
        p,
        Paint()
          ..color = AppColors.mapRoad
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
    }

    // Arterials.
    road(
      Path()
        ..moveTo(-w * .05, h * .38)
        ..quadraticBezierTo(w * .45, h * .26, w * 1.05, h * .42),
      w * .05,
    );
    road(
      Path()
        ..moveTo(w * .22, -h * .05)
        ..quadraticBezierTo(w * .30, h * .5, w * .18, h * 1.05),
      w * .045,
    );
    road(
      Path()
        ..moveTo(w * .62, -h * .05)
        ..quadraticBezierTo(w * .55, h * .55, w * .72, h * 1.05),
      w * .045,
    );
    // Secondary streets.
    road(
      Path()
        ..moveTo(-w * .05, h * .66)
        ..quadraticBezierTo(w * .5, h * .60, w * 1.05, h * .72),
      w * .028,
    );
    road(
      Path()
        ..moveTo(w * .88, -h * .05)
        ..quadraticBezierTo(w * .82, h * .4, w * .95, h * .8),
      w * .026,
    );
    road(
      Path()
        ..moveTo(w * .42, h * .05)
        ..quadraticBezierTo(w * .48, h * .3, w * .40, h * .55),
      w * .02,
    );
    road(
      Path()
        ..moveTo(-w * .02, h * .14)
        ..quadraticBezierTo(w * .3, h * .1, w * .5, h * .16),
      w * .02,
    );
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) => false;
}

class _RoutePainter extends CustomPainter {
  _RoutePainter(this.route, {required this.dashed});

  final (Offset, Offset, Offset) route;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    Offset s(Offset o) => Offset(o.dx * size.width, o.dy * size.height);
    final path = Path()
      ..moveTo(s(route.$1).dx, s(route.$1).dy)
      ..quadraticBezierTo(
          s(route.$2).dx, s(route.$2).dy, s(route.$3).dx, s(route.$3).dy);

    final halo = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    final line = Paint()
      ..color = AppColors.primaryDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    if (!dashed) {
      canvas.drawPath(path, halo);
      canvas.drawPath(path, line);
      return;
    }
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final p = metric.getTangentForOffset(d)!.position;
        canvas.drawCircle(p, 3.4, Paint()..color = AppColors.primaryDark);
        d += 14;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RoutePainter old) =>
      old.route != route || old.dashed != dashed;
}

// ── Ready-made pins ───────────────────────────────────────────────────────

/// White pill with a green KES price, as on the discovery map.
class PricePin extends StatelessWidget {
  const PricePin({super.key, required this.fee});
  final int fee;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.primary, width: 1.4),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 3))
            ],
          ),
          child: Text(
            'KES $fee',
            style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 13),
          ),
        ),
        Container(
          width: 2.5,
          height: 7,
          decoration: BoxDecoration(
              color: AppColors.primary, borderRadius: BorderRadius.circular(2)),
        ),
      ],
    );
  }
}

/// Dark-green dot with a white ring — pickup points.
class DotPin extends StatelessWidget {
  const DotPin({super.key, this.color = AppColors.primaryDark});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6)],
      ),
    );
  }
}

/// Orange teardrop — dropoff points.
class DropoffPin extends StatelessWidget {
  const DropoffPin({super.key});

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.location_pin,
        color: AppColors.accent,
        size: 40,
        shadows: [Shadow(color: Color(0x44000000), blurRadius: 6)]);
  }
}

/// Circular badge holding the package (hexagon) icon — the live marker.
class PackageMarker extends StatelessWidget {
  const PackageMarker({super.key, this.ringColor});
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ringColor == null ? AppColors.primaryDark : AppColors.blue,
        shape: BoxShape.circle,
        border: Border.all(color: ringColor ?? Colors.white, width: 3.5),
        boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 8)],
      ),
      child: const Icon(Icons.hexagon_outlined, color: Colors.white, size: 20),
    );
  }
}

/// Blue "you are here" dot with a soft halo.
class MyLocationDot extends StatelessWidget {
  const MyLocationDot({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
          color: Color(0x334A7BD0), shape: BoxShape.circle),
      child: Center(
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
        ),
      ),
    );
  }
}
