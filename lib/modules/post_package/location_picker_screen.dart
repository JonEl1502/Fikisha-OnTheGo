import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme/app_colors.dart';
import '../../core/services/places_service.dart';
import '../../widgets/otg_map.dart';
import '../../widgets/stylized_map.dart' show DotPin, DropoffPin;
import '../../widgets/ui.dart';

/// Result returned by [LocationPickerScreen] via Get.back().
class PickedLocation {
  const PickedLocation(this.geo, this.label);
  final GeoPoint geo;
  final String label;
}

/// Full-screen real-map picker — search a place or tap to drop the pin
/// (PRD: pickup and dropoff are set on the map).
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({
    super.key,
    required this.title,
    required this.isPickup,
    this.initial,
    this.initialLabel,
  });

  final String title;
  final bool isPickup;
  final GeoPoint? initial;
  final String? initialLabel;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _map = MapController();
  final _search = TextEditingController();
  final _label = TextEditingController();

  LatLng? _pin;
  bool _labelEdited = false;
  bool _searching = false;
  List<PlaceHit> _hits = const [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _pin = widget.initial?.latLng;
    _label.text = widget.initialLabel ?? '';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _label.dispose();
    super.dispose();
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    if (q.trim().length < 3) {
      setState(() => _hits = const []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _searching = true);
      LatLng? near = _pin;
      try {
        near ??= _map.camera.center;
      } catch (_) {}
      final hits = await PlacesService().search(q.trim(), near: near);
      if (!mounted) return;
      setState(() {
        _hits = hits;
        _searching = false;
      });
    });
  }

  void _select(PlaceHit hit) {
    FocusScope.of(context).unfocus();
    setState(() {
      _hits = const [];
      _search.text = hit.name;
      _pin = hit.at;
      if (!_labelEdited) _label.text = hit.name;
    });
    _moveMap(hit.at, 16);
  }

  /// Move after the frame settles — the keyboard dismiss triggers a resize
  /// that can otherwise swallow the camera move.
  void _moveMap(LatLng at, double zoom) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _map.move(at, zoom);
      } catch (_) {}
    });
  }

  Future<void> _drop(LatLng at) async {
    setState(() {
      _pin = at;
      _hits = const [];
      if (!_labelEdited) _label.text = 'Locating…';
    });
    if (_labelEdited) return;
    final name = await PlacesService().reverseLabel(at);
    if (!mounted || _labelEdited) return;
    setState(() => _label.text = name ?? 'Pinned location');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: OtgMap(
                    controller: _map,
                    center: _pin ?? OtgMap.nairobi,
                    zoom: _pin == null ? 12 : 15,
                    onTap: _drop,
                    markers: [
                      if (_pin != null)
                        Marker(
                          point: _pin!,
                          width: 40,
                          height: 40,
                          alignment: widget.isPickup
                              ? Alignment.center
                              : Alignment.topCenter,
                          child: widget.isPickup
                              ? const Center(
                                  child: SizedBox(
                                      width: 20, height: 20, child: DotPin()))
                              : const DropoffPin(),
                        ),
                    ],
                  ),
                ),
                // Search bar + results.
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const RoundBackButton(),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                elevation: 3,
                                shadowColor: const Color(0x33000000),
                                child: TextField(
                                  controller: _search,
                                  onChanged: _onSearchChanged,
                                  textInputAction: TextInputAction.search,
                                  decoration: InputDecoration(
                                    hintText: widget.isPickup
                                        ? 'Search pickup place'
                                        : 'Search dropoff place',
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: false,
                                    prefixIcon: const Icon(Icons.search,
                                        color: AppColors.muted),
                                    suffixIcon: _searching
                                        ? const Padding(
                                            padding: EdgeInsets.all(13),
                                            child: SizedBox(
                                              width: 16,
                                              height: 16,
                                              child:
                                                  CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color:
                                                          AppColors.primary),
                                            ),
                                          )
                                        : null,
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            vertical: 14),
                                  ),
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_hits.isNotEmpty)
                          Flexible(
                            child: Container(
                            margin: const EdgeInsets.only(top: 8),
                            constraints: const BoxConstraints(maxHeight: 260),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: const [
                                BoxShadow(
                                    color: Color(0x33000000), blurRadius: 12)
                              ],
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 6),
                              itemCount: _hits.length,
                              separatorBuilder: (_, i) => const Divider(
                                  height: 1, color: AppColors.line),
                              itemBuilder: (_, i) {
                                final hit = _hits[i];
                                final km = hit.distanceKm;
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.place_outlined,
                                      color: AppColors.primary, size: 20),
                                  title: Text(hit.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700)),
                                  subtitle: hit.detail.isEmpty
                                      ? null
                                      : Text(hit.detail,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.muted)),
                                  trailing: km == null
                                      ? null
                                      : Text(
                                          km < 1
                                              ? '${(km * 1000).round()} m'
                                              : '${km.toStringAsFixed(1)} km',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary)),
                                  onTap: () => _select(hit),
                                );
                              },
                            ),
                          ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (_pin == null && _hits.isEmpty)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: IgnorePointer(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 18),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.ink.withValues(alpha: .85),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Text(
                            'Search a place or tap the map to drop the pin',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Confirm sheet.
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
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SheetHandle(),
                    const SizedBox(height: 6),
                    Text(widget.isPickup ? 'PICKUP POINT' : 'DROPOFF POINT',
                        style: const TextStyle(
                            fontSize: 12,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w700,
                            color: AppColors.muted)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _label,
                      onChanged: (_) => _labelEdited = true,
                      decoration: InputDecoration(
                        hintText: 'Name this place',
                        prefixIcon: Icon(
                          widget.isPickup
                              ? Icons.trip_origin
                              : Icons.location_pin,
                          size: 20,
                          color: widget.isPickup
                              ? AppColors.primaryDark
                              : AppColors.accent,
                        ),
                      ),
                      style: const TextStyle(
                          fontSize: 15.5, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _pin == null
                          ? null
                          : () => Get.back(
                                result: PickedLocation(
                                  _pin!.geoPoint,
                                  _label.text.trim().isEmpty ||
                                          _label.text == 'Locating…'
                                      ? 'Pinned location'
                                      : _label.text.trim(),
                                ),
                              ),
                      child: const Text('Confirm location'),
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
