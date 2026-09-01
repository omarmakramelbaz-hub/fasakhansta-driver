import 'dart:async';
import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
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
  StreamSubscription<Position>? positionStream;
  List<Placemark>? placemarks;
  double? currentLat;
  double? currentLng;
  GoogleMapController? gmc;
  Set<Marker> markers = {};
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    positionStream?.cancel();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        CommonMethods.showError(message: 'Location services are disabled.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          CommonMethods.showError(message: 'Location permissions are denied');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        CommonMethods.showError(message: 'Location permissions are permanently denied, we cannot request permissions.');
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      _updateLocation(HiveMethods.getLat() ?? position.latitude, HiveMethods.getLan() ?? position.longitude);
    } catch (e) {
      CommonMethods.showError(message: 'Failed to get location: $e');
    }
  }

  Future<void> _updateLocation(double lat, double lng) async {
    setState(() {
      currentLat = lat;
      currentLng = lng;
      markers = {Marker(markerId: const MarkerId('currentLocation'), position: LatLng(lat, lng))};
    });
    await gmc?.animateCamera(CameraUpdate.newLatLng(LatLng(lat, lng)));
    placemarks = await placemarkFromCoordinates(lat, lng);
    if (mounted) setState(() {});
  }

  void _onMapTap(LatLng latLng) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => _updateLocation(latLng.latitude, latLng.longitude),
    );
  }

  void _onConfirmLocation(BuildContext context) {
    final authController = context.read<AuthController>();
    if (currentLat == null || currentLng == null || placemarks == null) return;
    authController.updateDelegateLocation(
      lat: currentLat!,
      lng: currentLng!,
      onSuccess: () {
        HiveMethods.updateLan(currentLng!);
        HiveMethods.updateLat(currentLat!);
        context.read<AuthController>().getProfile();
        HiveMethods.delegateAddress(
          placemarks![0].locality ?? placemarks![0].subLocality ?? placemarks![0].administrativeArea ?? '',
        );
        log('Location confirmed: ${placemarks![0].locality}, ${placemarks![0].street}');
        NavigatorMethods.pushNamedAndRemoveUntil(context, DelegateBottomNavBarScreen.routeName);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xff082A4D);
    const softText = Color(0xff7D8490);
    const orange = Color(0xffFD7201);

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
              child: GoogleMap(
                onTap: _onMapTap,
                markers: markers,
                mapType: MapType.normal,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: false,
                onMapCreated: (controller) {
                  gmc = controller;
                  if (currentLat != null && currentLng != null) {
                    gmc!.animateCamera(CameraUpdate.newLatLng(LatLng(currentLat!, currentLng!)));
                  }
                },
                initialCameraPosition: CameraPosition(
                  target: LatLng(currentLat ?? 31.043867, currentLng ?? 31.388388),
                  zoom: 14,
                ),
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
                          placemarks == null
                              ? (context.locale.languageCode == 'ar' ? 'جارٍ تحديد الموقع...' : 'Detecting location...')
                              : '${placemarks![0].locality ?? ''}, ${placemarks![0].street ?? ''}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: softText, fontSize: 12.5, height: 1.4, fontWeight: FontWeight.w500),
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
