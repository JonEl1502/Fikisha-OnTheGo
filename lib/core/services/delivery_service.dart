import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show Colors, EdgeInsets, Icon, Icons;
import 'package:get/get.dart';

import '../../app/theme/app_colors.dart';
import '../../data/models/package_model.dart';
import '../../data/models/user_model.dart';
import '../../widgets/otg_map.dart' show GeoPointLatLng, LatLngGeoPoint;
import '../utils/geo.dart';
import 'location_service.dart';
import 'route_service.dart';

/// Singleton Delivery Service — Firestore-backed package board.
///
/// All state flows one way: writes go to Firestore, and the snapshot
/// listener updates the reactive models in place, so both sides of a
/// delivery (sender + traveler) see the same live data.
class DeliveryService {
  static final DeliveryService _instance = DeliveryService._internal();
  factory DeliveryService() => _instance;
  DeliveryService._internal();

  /// Set false to disable the demo courier that claims your posted packages
  /// when no real traveler does (useful while testing with one device).
  static const bool demoCourierEnabled = true;

  /// Simulate the journey when *you* are the traveler: after pickup the
  /// courier drives the road route instead of streaming your real GPS.
  /// Set false for real two-phone field tests.
  static const bool demoTravelerJourney = true;

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('packages');

  late UserModel me;
  final RxBool signedIn = false.obs;

  final RxList<PackageModel> packages = <PackageModel>[].obs;
  final RxList<DeliveryRecord> history = <DeliveryRecord>[].obs;

  /// Package the user is currently carrying (traveler role).
  final Rxn<PackageModel> carrying = Rxn<PackageModel>();

  /// Package the user posted and is watching (sender role).
  final Rxn<PackageModel> sending = Rxn<PackageModel>();

  final Map<String, PackageModel> _byId = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  final Map<String, Timer> _timers = {};

  // ── Auth ────────────────────────────────────────────────────────────────

  /// Google sign-in — one account acts as sender or traveler; the uid keys
  /// all tracking data on both sides.
  void signInWithGoogle({
    required String uid,
    required String name,
    String contact = '',
    String? photoUrl,
  }) {
    me = UserModel(
      id: uid,
      name: name,
      phone: contact,
      rating: 5.0,
      ratingsCount: 0,
      verified: true,
      joined: 'Jul 2026',
      photoUrl: photoUrl,
    );
    signedIn.value = true;
    _bind();
  }

  // ── Firestore binding ───────────────────────────────────────────────────

  Future<void> _bind() async {
    await _seedIfEmpty();
    _sub?.cancel();
    _sub = _col.snapshots().listen(_onSnapshot, onError: (e) {
      _notify('Connection problem — retrying ($e)');
    });
  }

  void _onSnapshot(QuerySnapshot<Map<String, dynamic>> snap) {
    for (final change in snap.docChanges) {
      final id = change.doc.id;
      final data = change.doc.data();
      if (change.type == DocumentChangeType.removed || data == null) {
        _byId.remove(id);
        continue;
      }
      final existing = _byId[id];
      if (existing == null) {
        _byId[id] = PackageModel.fromDoc(id, data);
      } else {
        final before = existing.status.value;
        existing.updateFrom(data);
        if (before != existing.status.value) {
          _onStatusChanged(existing, before);
        }
      }
    }
    packages.assignAll(
        _byId.values.where((p) => p.status.value != PackageStatus.confirmed));
    _reconcileRoles();
  }

  void _reconcileRoles() {
    carrying.value = packages.firstWhereOrNull((p) =>
        p.traveler.value?.id == me.id &&
        p.status.value.index >= PackageStatus.claimed.index &&
        p.status.value.index < PackageStatus.delivered.index);
    sending.value = packages.firstWhereOrNull((p) =>
        p.sender.id == me.id && p.status.value != PackageStatus.confirmed);
  }

  /// Push-notification stand-in for lifecycle transitions I care about.
  void _onStatusChanged(PackageModel p, PackageStatus before) {
    final mine = p.sender.id == me.id;
    final carryingIt = p.traveler.value?.id == me.id;
    if (!mine && !carryingIt) return;
    final who = p.traveler.value?.name ?? 'A traveler';
    final message = switch (p.status.value) {
      PackageStatus.claimed when mine => '$who claimed your package',
      PackageStatus.pickedUp when mine =>
        'Your package was picked up at ${p.pickupLabel}',
      PackageStatus.inTransit when mine =>
        'Package in transit to ${p.dropoffLabel}',
      PackageStatus.delivered when mine =>
        'Delivered at ${p.dropoffLabel} — confirm receipt',
      PackageStatus.confirmed when carryingIt =>
        '${p.sender.name} confirmed receipt — KES ${p.fee} settled',
      _ => null,
    };
    if (message != null) _notify(message);
  }

  // ── Traveler flow ───────────────────────────────────────────────────────

  void claim(PackageModel p) {
    p.status.value = PackageStatus.claimed;
    p.traveler.value = me;
    p.claimedAt = DateTime.now();
    carrying.value = p;
    _col.doc(p.id).update({
      'status': PackageStatus.claimed.name,
      'traveler': PackageModel.userMap(me),
      'claimedAt': FieldValue.serverTimestamp(),
    });
    _notify('${p.sender.name} has been notified — head to ${p.pickupLabel}');
  }

  void markPickedUp(PackageModel p) {
    p.status.value = PackageStatus.pickedUp;
    p.pickedUpAt = DateTime.now();
    _col.doc(p.id).update({
      'status': PackageStatus.pickedUp.name,
      'pickedUpAt': FieldValue.serverTimestamp(),
      'courier': p.pickupGeo,
    });
    _notify('${p.sender.name} notified: package picked up');
    if (!demoTravelerJourney) {
      // Real GPS sharing starts now and runs until delivery.
      LocationService().start(p.id);
    }
    _after(p.id, const Duration(seconds: 4), () {
      if (p.status.value != PackageStatus.pickedUp) return;
      p.status.value = PackageStatus.inTransit;
      _col.doc(p.id).update({'status': PackageStatus.inTransit.name});
      if (demoTravelerJourney) {
        // Drive the route; the traveler taps "Mark as delivered" on arrival.
        _driveCourier(p, autoDeliver: false);
      }
    });
  }

  void markDelivered(PackageModel p) {
    p.status.value = PackageStatus.delivered;
    p.deliveredAt = DateTime.now();
    LocationService().stop();
    _col.doc(p.id).update({
      'status': PackageStatus.delivered.name,
      'deliveredAt': FieldValue.serverTimestamp(),
    });
    if (p.traveler.value?.id == me.id) {
      me.deliveredCount++;
      me.kesEarned += p.fee;
      _addHistory(p, asTraveler: true);
      carrying.value = null;
      _notify('${p.sender.name} notified — awaiting receipt confirmation');
    }
  }

  // ── Sender flow ─────────────────────────────────────────────────────────

  PackageModel postPackage({
    required String description,
    required PackageSize size,
    required int fee,
    required bool negotiable,
    required String pickupLabel,
    required String dropoffLabel,
    required GeoPoint pickupGeo,
    required GeoPoint dropoffGeo,
  }) {
    final p = PackageModel(
      id: _col.doc().id,
      description: description,
      size: size,
      fee: fee,
      negotiable: negotiable,
      pickupLabel: pickupLabel,
      dropoffLabel: dropoffLabel,
      pickupGeo: pickupGeo,
      dropoffGeo: dropoffGeo,
      sender: me,
    )..postedAt = DateTime.now();
    _byId[p.id] = p;
    packages.add(p);
    sending.value = p;
    me.sentCount++;
    _col.doc(p.id).set(p.toMap());
    if (demoCourierEnabled) _scheduleDemoCourier(p);
    return p;
  }

  void confirmReceipt(PackageModel p) {
    p.status.value = PackageStatus.confirmed;
    _col.doc(p.id).update({'status': PackageStatus.confirmed.name});
    if (p.sender.id == me.id) {
      sending.value = null;
      _addHistory(p, asTraveler: false);
    }
    packages.remove(p);
  }

  void submitRating(PackageModel p, int stars) {
    final other =
        p.sender.id == me.id ? p.traveler.value?.name : p.sender.name;
    _notify('Rated $other $stars★ — asante!');
    if (p.sender.id != me.id && p.sender.id.startsWith('demo-')) {
      // Demo senders can't tap "confirm receipt" — close it out for them.
      confirmReceipt(p);
    }
  }

  void skipRating(PackageModel p) {
    if (p.sender.id != me.id && p.sender.id.startsWith('demo-')) {
      confirmReceipt(p);
    }
  }

  // ── Demo courier ────────────────────────────────────────────────────────
  //
  // Lets a solo tester watch the sender flow end to end: if nobody claims
  // the posted package within 12 s, "Kevin (demo)" claims it and drives the
  // route, writing courier GeoPoints to Firestore — the exact same data path
  // a real traveler's GPS uses.

  void _scheduleDemoCourier(PackageModel p) {
    _after('demo-${p.id}', const Duration(seconds: 12), () async {
      if (p.status.value != PackageStatus.posted) return;
      await _col.doc(p.id).update({
        'status': PackageStatus.claimed.name,
        'claimedAt': FieldValue.serverTimestamp(),
        'traveler': {
          'id': 'demo-kevin',
          'name': 'Kevin Mwangi (demo)',
          'phone': '+254 722 118 340',
          'rating': 4.7,
          'ratingsCount': 63,
          'verified': true,
        },
      });
      _after('demo-pu-${p.id}', const Duration(seconds: 6), () async {
        await _col.doc(p.id).update({
          'status': PackageStatus.pickedUp.name,
          'pickedUpAt': FieldValue.serverTimestamp(),
          'courier': p.pickupGeo,
        });
        _after('demo-tr-${p.id}', const Duration(seconds: 3), () {
          _col.doc(p.id).update({'status': PackageStatus.inTransit.name});
          _driveCourier(p, autoDeliver: true);
        });
      });
    });
  }

  /// Animate the courier along the real road geometry, writing GeoPoints to
  /// Firestore — the same data path a real traveler's GPS uses. With
  /// [autoDeliver] the run ends in `delivered`; without it, the courier
  /// parks at the dropoff and the traveler confirms by hand.
  Future<void> _driveCourier(PackageModel p,
      {required bool autoDeliver}) async {
    final path = await RouteService()
        .roadRoute(p.pickupGeo.latLng, p.dropoffGeo.latLng);
    var t = 0.0;
    _timers['drive-${p.id}']?.cancel();
    _timers['drive-${p.id}'] = Timer.periodic(
      const Duration(seconds: 2),
      (timer) {
        if (p.status.value != PackageStatus.inTransit) {
          timer.cancel();
          return;
        }
        t += .04;
        if (t >= 1) {
          timer.cancel();
          if (autoDeliver) {
            _col.doc(p.id).update({
              'courier': p.dropoffGeo,
              'status': PackageStatus.delivered.name,
              'deliveredAt': FieldValue.serverTimestamp(),
            });
          } else {
            _col.doc(p.id).update({'courier': p.dropoffGeo});
            _notify('You have arrived — hand over and mark as delivered');
          }
          return;
        }
        _col.doc(p.id).update(
            {'courier': RouteService.pointAlong(path, t).geoPoint});
      },
    );
  }

  // ── Seeding ─────────────────────────────────────────────────────────────

  /// Keeps the demo board stocked: curated 5 + generated packages around
  /// Nairobi and on Kenya intercity routes, up to [seedTarget] open ones.
  static const int seedTarget = 42;

  Future<void> _seedIfEmpty() async {
    try {
      final snap = await _col.get();
      final demoCount =
          snap.docs.where((d) => d.id.startsWith('demo-')).length;
      if (demoCount >= seedTarget) return;
      final batch = _db.batch();
      var needed = seedTarget - demoCount;
      if (demoCount == 0) {
        for (final p in _demoPackages()) {
          batch.set(_col.doc(p.id), p.toMap());
        }
        needed -= 5;
      }
      for (final p in _generatedPackages(needed)) {
        batch.set(_col.doc(p.id), p.toMap());
      }
      await batch.commit();
    } catch (e) {
      _notify('Could not reach Firestore: $e');
    }
  }

  /// Procedural demo packages: ~2/3 Nairobi metro, ~1/3 city-to-city.
  List<PackageModel> _generatedPackages(int n) {
    if (n <= 0) return const [];
    final rng = Random(DateTime.now().millisecondsSinceEpoch);

    const cities = <(String, GeoPoint)>[
      ('Nairobi CBD', GeoPoint(-1.2860, 36.8220)),
      ('Thika', GeoPoint(-1.0333, 37.0693)),
      ('Nakuru', GeoPoint(-0.3031, 36.0800)),
      ('Naivasha', GeoPoint(-0.7172, 36.4310)),
      ('Eldoret', GeoPoint(0.5143, 35.2698)),
      ('Kisumu', GeoPoint(-0.0917, 34.7680)),
      ('Mombasa', GeoPoint(-4.0435, 39.6682)),
      ('Machakos', GeoPoint(-1.5177, 37.2634)),
      ('Nyeri', GeoPoint(-0.4197, 36.9510)),
      ('Meru', GeoPoint(0.0463, 37.6559)),
      ('Kericho', GeoPoint(-0.3689, 35.2863)),
      ('Narok', GeoPoint(-1.0921, 35.8711)),
      ('Embu', GeoPoint(-0.5310, 37.4575)),
    ];

    const items = <(String, PackageSize)>[
      ('Documents envelope', PackageSize.small),
      ('Phone + charger', PackageSize.small),
      ('House keys', PackageSize.small),
      ('Medicine pack', PackageSize.small),
      ('Laptop sleeve', PackageSize.small),
      ('Spare part (sealed)', PackageSize.small),
      ('Birthday cake box', PackageSize.medium),
      ('Shoe box', PackageSize.medium),
      ('Clothes bag', PackageSize.medium),
      ('Gift hamper', PackageSize.medium),
      ('Textbooks bundle', PackageSize.medium),
      ('Baby supplies bag', PackageSize.medium),
      ('Small suitcase', PackageSize.large),
      ('Electronics box', PackageSize.large),
      ('Farm produce crate', PackageSize.large),
    ];

    const senders = <(String, double, int, bool)>[
      ('Grace Wanjiru', 4.8, 23, true),
      ('Peter Kamau', 4.9, 40, true),
      ('Aisha Noor', 4.6, 11, true),
      ('Mercy Chebet', 4.5, 8, false),
      ('John Baraka', 4.7, 17, true),
      ('Faith Atieno', 4.4, 6, false),
      ('Samuel Mutua', 4.9, 52, true),
      ('Lucy Njeri', 4.7, 19, true),
      ('Hassan Omar', 4.6, 14, true),
      ('Beatrice Wambui', 4.8, 31, true),
      ('Dennis Kiprop', 4.3, 5, false),
      ('Ann Moraa', 4.7, 22, true),
    ];

    GeoPoint jitter(GeoPoint at, double spread) => GeoPoint(
          at.latitude + (rng.nextDouble() - .5) * spread,
          at.longitude + (rng.nextDouble() - .5) * spread,
        );

    final out = <PackageModel>[];
    for (var i = 0; i < n; i++) {
      final intercity = i % 3 == 2; // every third package goes city-to-city
      String fromName, toName;
      GeoPoint from, to;
      if (intercity) {
        final a = cities[rng.nextInt(cities.length)];
        var b = cities[rng.nextInt(cities.length)];
        while (b.$1 == a.$1) {
          b = cities[rng.nextInt(cities.length)];
        }
        (fromName, from) = a;
        (toName, to) = b;
        from = jitter(from, .01);
        to = jitter(to, .01);
      } else {
        final a = Geo.landmarks[rng.nextInt(Geo.landmarks.length)];
        var b = Geo.landmarks[rng.nextInt(Geo.landmarks.length)];
        while (b.$1 == a.$1) {
          b = Geo.landmarks[rng.nextInt(Geo.landmarks.length)];
        }
        (fromName, from) = a;
        (toName, to) = b;
        from = jitter(from, .012);
        to = jitter(to, .012);
      }

      final (desc, size) = items[rng.nextInt(items.length)];
      final (sName, sRating, sCount, sVerified) =
          senders[rng.nextInt(senders.length)];
      final km = Geo.distanceKm(from, to);
      // Rough market pricing: short hops flat-ish, intercity by distance.
      final raw = intercity ? 250 + km * 2.2 : 80 + km * 45;
      final fee = ((raw + size.index * 40) / 10).round() * 10;

      out.add(PackageModel(
        id: 'demo-g${DateTime.now().microsecondsSinceEpoch}$i',
        description: desc,
        size: size,
        fee: fee.clamp(80, 1800),
        negotiable: rng.nextBool(),
        pickupLabel: fromName,
        dropoffLabel: toName,
        pickupGeo: from,
        dropoffGeo: to,
        sender: UserModel(
          id: 'demo-s${sName.hashCode}',
          name: sName,
          phone: '+254 7${10000000 + rng.nextInt(89999999)}',
          rating: sRating,
          ratingsCount: sCount,
          verified: sVerified,
        ),
        detourKm: (rng.nextDouble() * 2.4 + .3),
      )..postedAt =
          DateTime.now().subtract(Duration(minutes: rng.nextInt(180))));
    }
    return out;
  }

  List<PackageModel> _demoPackages() {
    UserModel u(String id, String name, double rating, int n,
            {bool v = true}) =>
        UserModel(
            id: 'demo-$id',
            name: name,
            phone: '+254 7$id',
            rating: rating,
            ratingsCount: n,
            verified: v);

    PackageModel pkg(String id, String desc, PackageSize size, int fee,
            bool neg, String from, String to, GeoPoint a, GeoPoint b,
            UserModel sender, {double detour = 1.2}) =>
        PackageModel(
            id: 'demo-$id',
            description: desc,
            size: size,
            fee: fee,
            negotiable: neg,
            pickupLabel: from,
            dropoffLabel: to,
            pickupGeo: a,
            dropoffGeo: b,
            sender: sender,
            detourKm: detour)
          ..postedAt = DateTime.now();

    return [
      pkg('a1', 'Documents envelope', PackageSize.small, 250, true,
          'Nairobi CBD · Kimathi St', 'Kikuyu · Gikambura',
          const GeoPoint(-1.2842, 36.8235), const GeoPoint(-1.2906, 36.6620),
          u('11 222 001', 'Grace Wanjiru', 4.8, 23)),
      pkg('a2', 'Shoe box', PackageSize.medium, 400, false,
          'Nairobi CBD · Moi Ave', 'Rongai · Maasai Lodge',
          const GeoPoint(-1.2860, 36.8230), const GeoPoint(-1.3961, 36.7440),
          u('33 810 552', 'Peter Kamau', 4.9, 40), detour: 2.0),
      pkg('a3', 'Phone charger', PackageSize.small, 180, true,
          'Westlands · Sarit', 'Kangemi · Mountain View',
          const GeoPoint(-1.2609, 36.8028), const GeoPoint(-1.2669, 36.7460),
          u('20 555 314', 'Aisha Noor', 4.6, 11), detour: .8),
      pkg('a4', 'Spare part (sealed)', PackageSize.small, 120, false,
          'CBD · Tom Mboya St', 'Kawangware · 46',
          const GeoPoint(-1.2833, 36.8280), const GeoPoint(-1.2856, 36.7472),
          u('44 902 217', 'Mercy Chebet', 4.5, 8, v: false), detour: .6),
      pkg('a5', 'Gift bag', PackageSize.medium, 300, true,
          'Upper Hill · Britam', 'Kikuyu · Thogoto',
          const GeoPoint(-1.2999, 36.8140), const GeoPoint(-1.3160, 36.6710),
          u('55 610 984', 'John Baraka', 4.7, 17), detour: 1.5),
    ];
  }

  // ── Internals ───────────────────────────────────────────────────────────

  void _addHistory(PackageModel p, {required bool asTraveler}) {
    history.insert(
      0,
      DeliveryRecord(
        route: p.shortRoute,
        date: _shortDate(DateTime.now()),
        item: p.description.split(' ').first,
        fee: p.fee,
        stars: 5,
        asTraveler: asTraveler,
      ),
    );
  }

  void _after(String key, Duration d, void Function() fn) {
    _timers[key]?.cancel();
    _timers[key] = Timer(d, fn);
  }

  /// Stand-in for FCM push notifications on status transitions (PRD §4).
  void _notify(String message) {
    Get.snackbar(
      'On the Go',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.ink,
      colorText: Colors.white,
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      borderRadius: 16,
      duration: const Duration(milliseconds: 2600),
      icon: const Icon(Icons.notifications_active_outlined,
          color: Colors.white, size: 20),
    );
  }

  String _shortDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}';
  }
}
