import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../../helpers/locale/app_locale_key.dart';
import '../../../custom_widgets/custom_app_bar/custom_app_bar.dart';

class DeliveryLocationArgs {
  final double lat;
  final double lng;
  const DeliveryLocationArgs({required this.lat, required this.lng});
}

class DeliveryLocationScreen extends StatefulWidget {
  static const String routeName = 'DeliveryLocationScreen';
  final DeliveryLocationArgs? args;
  const DeliveryLocationScreen({super.key, this.args});

  @override
  State<DeliveryLocationScreen> createState() => _DeliveryLocationScreenState();
}

class _DeliveryLocationScreenState extends State<DeliveryLocationScreen> {
  static const _styleUrl = 'https://tiles.openfreemap.org/styles/liberty';

  List<Placemark>? placemarks;
  MapLibreMapController? _mapController;
  Circle? _destinationCircle;
  bool _addressLoading = true;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    final args = widget.args;
    if (args == null) return;

    if (kIsWeb) {
      if (mounted) setState(() => _addressLoading = false);
      return;
    }

    try {
      final result = await placemarkFromCoordinates(args.lat, args.lng);
      if (!mounted) return;
      setState(() {
        placemarks = result;
        _addressLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _addressLoading = false);
    }
  }

  Future<void> _onMapCreated(MapLibreMapController controller) async {
    _mapController = controller;
  }

  Future<void> _onStyleLoaded() async {
    final args = widget.args;
    final controller = _mapController;
    if (args == null || controller == null) return;

    final target = LatLng(args.lat, args.lng);
    try {
      _destinationCircle = await controller.addCircle(
        CircleOptions(
          geometry: target,
          circleRadius: 13,
          circleColor: '#FD7201',
          circleOpacity: .96,
          circleStrokeColor: '#FFFFFF',
          circleStrokeWidth: 4,
          circleStrokeOpacity: 1,
        ),
      );
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 16.8, tilt: 38),
        ),
        duration: const Duration(milliseconds: 550),
      );
    } catch (_) {}
  }

  String _addressText(BuildContext context, DeliveryLocationArgs args) {
    if (_addressLoading) {
      return context.locale.languageCode == 'ar'
          ? 'جارٍ تحميل العنوان...'
          : 'Loading address...';
    }

    if (placemarks != null && placemarks!.isNotEmpty) {
      final p = placemarks!.first;
      final parts = <String>[
        p.street ?? '',
        p.subLocality ?? '',
        p.locality ?? '',
      ].where((e) => e.trim().isNotEmpty).toList();
      if (parts.isNotEmpty) return parts.join('، ');
    }

    return '${args.lat.toStringAsFixed(6)}, ${args.lng.toStringAsFixed(6)}';
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xff082A4D);
    const softText = Color(0xff7D8490);
    const orange = Color(0xffFD7201);
    final args = widget.args;

    return Scaffold(
      backgroundColor: const Color(0xffF8F9FB),
      appBar: CustomAppBar(
        context,
        height: 86,
        title: Text(
          AppLocaleKey.location.tr(),
          style: const TextStyle(
            color: navy,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: args == null
          ? const Center(
              child: Icon(
                Icons.location_off_rounded,
                color: softText,
                size: 50,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.locale.languageCode == 'ar'
                        ? 'موقع التسليم'
                        : 'Delivery destination',
                    style: const TextStyle(
                      color: navy,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    context.locale.languageCode == 'ar'
                        ? 'خريطة حديثة مفتوحة المصدر لمراجعة الموقع بدقة'
                        : 'Modern open map for precise destination review',
                    style: const TextStyle(
                      color: softText,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: MediaQuery.of(context).size.height * .60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xffECEEF1)),
                      boxShadow: [
                        BoxShadow(
                          color: navy.withOpacity(.09),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: MapLibreMap(
                            styleString: _styleUrl,
                            initialCameraPosition: CameraPosition(
                              target: LatLng(args.lat, args.lng),
                              zoom: 16.5,
                              tilt: 34,
                            ),
                            onMapCreated: _onMapCreated,
                            onStyleLoadedCallback: _onStyleLoaded,
                            compassEnabled: false,
                            myLocationEnabled: false,
                            trackCameraPosition: true,
                          ),
                        ),
                        PositionedDirectional(
                          top: 14,
                          start: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(.94),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: navy.withOpacity(.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  color: orange,
                                  size: 17,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  context.locale.languageCode == 'ar'
                                      ? 'نقطة التسليم'
                                      : 'Delivery point',
                                  style: const TextStyle(
                                    color: navy,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xffECEEF1)),
                      boxShadow: [
                        BoxShadow(
                          color: navy.withOpacity(.055),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xffFFF0E3),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: orange,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocaleKey.area.tr(),
                                style: const TextStyle(
                                  color: navy,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _addressText(context, args),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: softText,
                                  fontSize: 12.5,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
