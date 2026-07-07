import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../core/utils/geo.dart';
import 'user_model.dart';

enum PackageSize { small, medium, large }

extension PackageSizeLabel on PackageSize {
  String get label => switch (this) {
        PackageSize.small => 'Small',
        PackageSize.medium => 'Medium',
        PackageSize.large => 'Large',
      };
}

/// Lifecycle per PRD: Posted → Claimed → Picked Up → In Transit → Delivered
/// (+ confirmed once the sender acknowledges receipt).
enum PackageStatus { posted, claimed, pickedUp, inTransit, delivered, confirmed }

/// A package posted for delivery, backed by a Firestore document. Real
/// lat/lng lives in Firestore; the UI projects it onto the stylized canvas
/// with [Geo.project].
class PackageModel {
  PackageModel({
    required this.id,
    required this.description,
    required this.size,
    required this.fee,
    required this.negotiable,
    required this.pickupLabel,
    required this.dropoffLabel,
    required this.pickupGeo,
    required this.dropoffGeo,
    required this.sender,
    this.detourKm = 1.2,
  });

  final String id;
  final String description;
  final PackageSize size;
  final int fee; // KES
  final bool negotiable;
  final String pickupLabel;
  final String dropoffLabel;
  final GeoPoint pickupGeo;
  final GeoPoint dropoffGeo;
  final UserModel sender;
  final double detourKm;

  // Reactive lifecycle state — snapshot listeners update these in place so
  // screens holding a reference keep working.
  final Rx<PackageStatus> status = PackageStatus.posted.obs;
  final Rxn<UserModel> traveler = Rxn<UserModel>();

  /// Live courier position, streamed from the traveler's GPS via Firestore.
  final Rxn<GeoPoint> courier = Rxn<GeoPoint>();

  DateTime? postedAt;
  DateTime? claimedAt;
  DateTime? pickedUpAt;
  DateTime? deliveredAt;

  bool get isOpen => status.value == PackageStatus.posted;

  double get distanceKm => Geo.distanceKm(pickupGeo, dropoffGeo);

  /// Remaining distance for the courier (full route until pickup happens).
  double get remainingKm => Geo.distanceKm(courier.value ?? pickupGeo, dropoffGeo);

  int get etaMinutes => Geo.etaMinutes(remainingKm);

  /// Courier is within ~150 m of the dropoff point.
  bool get arrived {
    final c = courier.value;
    return c != null && Geo.distanceKm(c, dropoffGeo) < .15;
  }

  // ── Canvas projections ──────────────────────────────────────────────────

  Offset get pickupPos => Geo.project(pickupGeo);
  Offset get dropoffPos => Geo.project(dropoffGeo);

  /// Current marker position of the carried package.
  Offset get livePos => switch (status.value) {
        PackageStatus.delivered || PackageStatus.confirmed => dropoffPos,
        _ => courier.value != null ? Geo.project(courier.value!) : pickupPos,
      };

  Offset get routeControl {
    final mid = Offset.lerp(pickupPos, dropoffPos, .5)!;
    final d = dropoffPos - pickupPos;
    // Perpendicular bow so routes curve like streets rather than beelines.
    return mid + Offset(-d.dy, d.dx) * .18;
  }

  String get shortRoute {
    String head(String s) => s.split(' · ').first;
    return '${head(pickupLabel)} → ${head(dropoffLabel)}';
  }

  // ── Firestore mapping ───────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'description': description,
        'size': size.name,
        'fee': fee,
        'negotiable': negotiable,
        'pickupLabel': pickupLabel,
        'dropoffLabel': dropoffLabel,
        'pickup': pickupGeo,
        'dropoff': dropoffGeo,
        'detourKm': detourKm,
        'status': status.value.name,
        'sender': userMap(sender),
        'traveler':
            traveler.value == null ? null : userMap(traveler.value!),
        'courier': courier.value,
        'postedAt': postedAt,
        'claimedAt': claimedAt,
        'pickedUpAt': pickedUpAt,
        'deliveredAt': deliveredAt,
      };

  static PackageModel fromDoc(String id, Map<String, dynamic> d) {
    final p = PackageModel(
      id: id,
      description: d['description'] as String? ?? 'Package',
      size: PackageSize.values.asNameMap()[d['size']] ?? PackageSize.small,
      fee: (d['fee'] as num? ?? 0).toInt(),
      negotiable: d['negotiable'] as bool? ?? false,
      pickupLabel: d['pickupLabel'] as String? ?? '',
      dropoffLabel: d['dropoffLabel'] as String? ?? '',
      pickupGeo: d['pickup'] as GeoPoint? ?? const GeoPoint(-1.2842, 36.8235),
      dropoffGeo: d['dropoff'] as GeoPoint? ?? const GeoPoint(-1.2906, 36.6620),
      sender: _userFrom(d['sender']),
      detourKm: (d['detourKm'] as num? ?? 1.2).toDouble(),
    );
    p.updateFrom(d);
    return p;
  }

  /// Applies the mutable fields of a snapshot onto this instance.
  void updateFrom(Map<String, dynamic> d) {
    status.value =
        PackageStatus.values.asNameMap()[d['status']] ?? PackageStatus.posted;
    final t = d['traveler'];
    traveler.value = t == null ? null : _userFrom(t);
    courier.value = d['courier'] as GeoPoint?;
    postedAt = _date(d['postedAt']) ?? postedAt;
    claimedAt = _date(d['claimedAt']) ?? claimedAt;
    pickedUpAt = _date(d['pickedUpAt']) ?? pickedUpAt;
    deliveredAt = _date(d['deliveredAt']) ?? deliveredAt;
  }

  static Map<String, dynamic> userMap(UserModel u) => {
        'id': u.id,
        'name': u.name,
        'phone': u.phone,
        'rating': u.rating,
        'ratingsCount': u.ratingsCount,
        'verified': u.verified,
        'photoUrl': u.photoUrl,
      };

  static UserModel _userFrom(dynamic raw) {
    final m = (raw as Map?)?.cast<String, dynamic>() ?? const {};
    return UserModel(
      id: m['id'] as String? ?? '?',
      name: m['name'] as String? ?? 'User',
      phone: m['phone'] as String? ?? '',
      rating: (m['rating'] as num? ?? 5).toDouble(),
      ratingsCount: (m['ratingsCount'] as num? ?? 0).toInt(),
      verified: m['verified'] as bool? ?? false,
      photoUrl: m['photoUrl'] as String?,
    );
  }

  static DateTime? _date(dynamic v) => switch (v) {
        Timestamp t => t.toDate(),
        DateTime d => d,
        _ => null,
      };
}

/// A completed delivery shown in profile history.
class DeliveryRecord {
  const DeliveryRecord({
    required this.route,
    required this.date,
    required this.item,
    required this.fee,
    required this.stars,
    required this.asTraveler,
  });

  final String route;
  final String date;
  final String item;
  final int fee;
  final int stars;
  final bool asTraveler;
}
