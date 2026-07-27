import 'dart:async';
import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/hive/hive_methods.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../../helpers/utils/navigator_methods.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../../custom_widgets/custom_app_bar/custom_app_bar.dart';
import '../../../custom_widgets/custom_image/custom_image.dart';
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
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        CommonMethods.showError(message: 'Location services are disabled.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
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

      Position position = await Geolocator.getCurrentPosition();
      _updateLocation(HiveMethods.getLat() ?? position.latitude, HiveMethods.getLan() ?? position.longitude);
    } catch (e) {
      CommonMethods.showError(message: 'Failed to get location: $e');
    }
  }

  void _updateLocation(double lat, double lng) async {
    setState(() {
      currentLat = lat;
      currentLng = lng;
      markers.clear();
      markers.add(Marker(markerId: const MarkerId('currentLocation'), position: LatLng(lat, lng)));
    });

    if (gmc != null) {
      gmc!.animateCamera(CameraUpdate.newLatLng(LatLng(lat, lng)));
    }

    placemarks = await placemarkFromCoordinates(lat, lng);
    setState(() {});
  }

  void _onMapTap(LatLng latLng) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _updateLocation(latLng.latitude, latLng.longitude);
    });
  }

  void _onConfirmLocation(BuildContext context) {
    final authController = Provider.of<AuthController>(context, listen: false);
    if (currentLat != null && currentLng != null && placemarks != null) {
      authController.updateDelegateLocation(
        lat: currentLat!,
        lng: currentLng!,
        onSuccess: () {
          HiveMethods.updateLan(currentLng!);
          HiveMethods.updateLat(currentLat!);
          Provider.of<AuthController>(context, listen: false).getProfile();
          HiveMethods.delegateAddress(
            placemarks![0].locality ?? placemarks![0].subLocality ?? placemarks![0].administrativeArea ?? '',
          );
          log(
            'Location confirmed: ${placemarks![0].country},${placemarks![0].administrativeArea},${placemarks![0].locality}, ${placemarks![0].street}',
          );
          NavigatorMethods.pushNamedAndRemoveUntil(context, DelegateBottomNavBarScreen.routeName);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: CustomAppBar(
        context,
        height: 80,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColor.blackColor(context)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(AppLocaleKey.location.tr(), style: AppTextStyle.text18BS(context)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: GoogleMap(
                    onTap: _onMapTap,
                    markers: markers,
                    mapType: MapType.normal,
                    onMapCreated: (GoogleMapController controller) {
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
              ),
            ),
            const SizedBox(height: 20),
            if (placemarks != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.11,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: AppColor.whiteColor(context),
                    boxShadow: [
                      BoxShadow(
                        color: AppColor.greyColor(context).withOpacity(0.2),
                        offset: const Offset(0, -3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CustomImage(path: AppImages.currentLocation, type: ImageType.svg),
                          const SizedBox(width: 10),
                          Text(AppLocaleKey.area.tr(), style: AppTextStyle.text14MG(context)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${placemarks![0].locality}, ${placemarks![0].street}',
                        style: AppTextStyle.text14MG(context).copyWith(overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: CustomButton(
          text: AppLocaleKey.confirm.tr(),
          onPressed: () {
            _onConfirmLocation(context);
          },
        ),
      ),
    );
  }
}
