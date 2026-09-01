import 'dart:async';
import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/hive/hive_methods.dart';
import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../../helpers/utils/navigator_methods.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../../custom_widgets/custom_app_bar/custom_app_bar.dart';
import '../../auth/controller/auth_controller.dart';
import '../../delegate_bottom_nav_bar.dart/screen/delegate_bottom_nav_bar_screen.dart';

class DelegateLocationScreen extends StatefulWidget {
  static const String routeName = 'DelegateLocationScreen';
  const DelegateLocationScreen({super.key});

  @override
  State<DelegateLocationScreen> createState() => _DelegateLocationScreenState();
}

class _DelegateLocationScreenState extends State<DelegateLocationScreen> {
  List<Placemark>? placemarks;
  double? currentLat;
  double? currentLng;
  GoogleMapController? gmc;
  Set<Marker> markers = {};
  Timer? _debounce;

  String? _resolvedAddress;
  String? _locationError;
  bool _isLocating = true;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    if (mounted) {
      setState(() {
        _isLocating = true;
        _locationError = null;
      });
    }

    try {
      if (!kIsWeb) {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          throw Exception('Location services are disabled');
        }
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is denied');
      }

      final position = await Geolocator.getCurrentPosition().timeout(const Duration(seconds: 15));
      await _updateLocation(position.latitude, position.longitude);
    } catch (e) {
      log('Failed to get current location: $e');

      final savedLat = HiveMethods.getLat();
      final savedLng = HiveMethods.getLan();

      if (savedLat != null && savedLng != null) {
        await _updateLocation(savedLat, savedLng);
        if (mounted) {
          setState(() {
            _locationError = context.locale.languageCode == 'ar'
                ? 'تعذر الوصول لموقع الجهاز، تم عرض آخر موقع محفوظ ويمكنك تغييره من الخريطة.'
                : 'Could not access device location. The last saved location is shown and can be changed on the map.';
          });
        }
      } else if (mounted) {
        setState(() {
          _isLocating = false;
          _locationError = context.locale.languageCode == 'ar'
              ? 'تعذر تحديد موقعك تلقائياً. اضغط على الخريطة لاختيار موقعك.'
              : 'Could not detect your location automatically. Tap the map to choose it.';
        });
      }
    }
  }

  Future<void> _updateLocation(double lat, double lng) async {
    if (!mounted) return;

    setState(() {
      currentLat = lat;
      currentLng = lng;
      _isLocating = true;
      _locationError = null;
      markers = {
        Marker(
          markerId: const MarkerId('selectedLocation'),
          position: LatLng(lat, lng),
        ),
      };
    });

    try {
      await gmc?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(lat, lng), zoom: 16),
        ),
      );
    } catch (e) {
      log('Map camera animation failed: $e');
    }

    await _resolveAddress(lat, lng);
  }

  Future<void> _resolveAddress(double lat, double lng) async {
    final coordinateText = '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';

    // The geocoding plugin is not dependable on Flutter Web. The selected
    // coordinates are enough to save the delegate location, so never block
    // the map or confirmation waiting for reverse geocoding on web.
    if (kIsWeb) {
      if (!mounted) return;
      setState(() {
        placemarks = null;
        _resolvedAddress = context.locale.languageCode == 'ar'
            ? 'الموقع المحدد: $coordinateText'
            : 'Selected location: $coordinateText';
        _isLocating = false;
      });
      return;
    }

    try {
      final result = await placemarkFromCoordinates(lat, lng);
      if (!mounted) return;

      final first = result.isNotEmpty ? result.first : null;
      final parts = <String>[
        first?.locality ?? '',
        first?.subLocality ?? '',
        first?.street ?? '',
      ].where((part) => part.trim().isNotEmpty).toList();

      setState(() {
        placemarks = result;
        _resolvedAddress = parts.isEmpty ? coordinateText : parts.join(', ');
        _isLocating = false;
      });
    } catch (e) {
      log('Reverse geocoding failed: $e');
      if (!mounted) return;
      setState(() {
        placemarks = null;
        _resolvedAddress = coordinateText;
        _isLocating = false;
      });
    }
  }

  void _onMapTap(LatLng latLng) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 220),
      () => _updateLocation(latLng.latitude, latLng.longitude),
    );
  }

  void _onConfirmLocation(BuildContext context) {
    if (currentLat == null || currentLng == null) {
      CommonMethods.showError(
        message: context.locale.languageCode == 'ar'
            ? 'حدد موقعك على الخريطة أولاً'
            : 'Choose your location on the map first',
      );
      return;
    }

    final authController = context.read<AuthController>();
    authController.updateDelegateLocation(
      lat: currentLat!,
      lng: currentLng!,
      onSuccess: () {
        HiveMethods.updateLan(currentLng!);
        HiveMethods.updateLat(currentLat!);
        context.read<AuthController>().getProfile();

        final placemark = placemarks != null && placemarks!.isNotEmpty ? placemarks!.first : null;
        final resolvedArea = placemark?.locality ??
            placemark?.subLocality ??
            placemark?.administrativeArea ??
            _resolvedAddress ??
            '${currentLat!.toStringAsFixed(6)}, ${currentLng!.toStringAsFixed(6)}';

        HiveMethods.delegateAddress(resolvedArea);
        log('Location confirmed: $resolvedArea ($currentLat, $currentLng)');
        NavigatorMethods.pushNamedAndRemoveUntil(context, DelegateBottomNavBarScreen.routeName);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xff082A4D);
    const softText = Color(0xff7D8490);
    const orange = Color(0xffFD7201);

    final locationText = _locationError ??
        (_isLocating
            ? (context.locale.languageCode == 'ar' ? 'جارٍ تحديد الموقع...' : 'Detecting location...')
            : (_resolvedAddress ??
                (context.locale.languageCode == 'ar' ? 'اضغط على الخريطة لتحديد الموقع' : 'Tap the map to choose a location')));

    return Scaffold(
      backgroundColor: const Color(0xffF8F9FB),
      appBar: CustomAppBar(
        context,
        height: 86,
        title: Text(
          AppLocaleKey.location.tr(),
          style: const TextStyle(color: navy, fontSize: 21, fontWeight: FontWeight.w900),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.locale.languageCode == 'ar' ? 'حدد موقعك الحالي' : 'Choose your current location',
              style: const TextStyle(color: navy, fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            Text(
              context.locale.languageCode == 'ar'
                  ? 'اضغط على الخريطة لتحديد النقطة بدقة'
                  : 'Tap the map to set your location precisely',
              style: const TextStyle(color: softText, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Container(
              height: MediaQuery.of(context).size.height * .54,
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
                    child: GoogleMap(
                      onTap: _onMapTap,
                      markers: markers,
                      mapType: MapType.normal,
                      myLocationButtonEnabled: false,
                      myLocationEnabled: !kIsWeb,
                      mapToolbarEnabled: false,
                      zoomControlsEnabled: false,
                      onMapCreated: (controller) {
                        gmc = controller;
                        if (currentLat != null && currentLng != null) {
                          gmc!.animateCamera(
                            CameraUpdate.newCameraPosition(
                              CameraPosition(
                                target: LatLng(currentLat!, currentLng!),
                                zoom: 16,
                              ),
                            ),
                          );
                        }
                      },
                      initialCameraPosition: CameraPosition(
                        target: LatLng(currentLat ?? 31.043867, currentLng ?? 31.388388),
                        zoom: 14,
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    end: 14,
                    bottom: 14,
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      elevation: 5,
                      child: InkWell(
                        onTap: _isLocating ? null : _determinePosition,
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: _isLocating
                              ? const Padding(
                                  padding: EdgeInsets.all(15),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: orange,
                                  ),
                                )
                              : const Icon(Icons.my_location_rounded, color: orange, size: 25),
                        ),
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
                    child: const Icon(Icons.my_location_rounded, color: orange, size: 23),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocaleKey.area.tr(),
                          style: const TextStyle(color: navy, fontSize: 14, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          locationText,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _locationError == null ? softText : const Color(0xffB46714),
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
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 8, 18, 12),
        child: CustomButton(
          prefixIcon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 22),
          text: AppLocaleKey.confirm.tr(),
          onPressed: currentLat == null || currentLng == null ? null : () => _onConfirmLocation(context),
        ),
      ),
    );
  }
}
