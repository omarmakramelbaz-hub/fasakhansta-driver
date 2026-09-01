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
import '../../auth/controller/auth_controller.dart';
import '../../delegate_bottom_nav_bar.dart/screen/delegate_bottom_nav_bar_screen.dart';

class DelegateLocationScreen extends StatefulWidget {
  static const String routeName = 'DelegateLocationScreen';

  const DelegateLocationScreen({super.key});

  @override
  State<DelegateLocationScreen> createState() => _DelegateLocationScreenState();
}

class _DelegateLocationScreenState extends State<DelegateLocationScreen> {
  static const _navy = Color(0xff082A4D);
  static const _orange = Color(0xffFD7201);
  static const _softText = Color(0xff7D8490);

  List<Placemark>? placemarks;
  double? currentLat;
  double? currentLng;
  GoogleMapController? gmc;
  Set<Marker> markers = {};
  Timer? _debounce;

  String? _resolvedAddress;
  String? _locationError;
  bool _isLocating = true;

  bool get _isArabic => context.locale.languageCode == 'ar';
  bool get _hasLocation => currentLat != null && currentLng != null;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    gmc?.dispose();
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

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is denied');
      }

      final position = await Geolocator.getCurrentPosition().timeout(
        const Duration(seconds: 15),
      );
      await _updateLocation(position.latitude, position.longitude);
    } catch (e) {
      log('Failed to get current location: $e');

      final savedLat = HiveMethods.getLat();
      final savedLng = HiveMethods.getLan();

      if (savedLat != null && savedLng != null) {
        await _updateLocation(savedLat, savedLng);
        if (mounted) {
          setState(() {
            _locationError = _isArabic
                ? 'تعذر الوصول لموقع الجهاز. تم عرض آخر موقع محفوظ ويمكنك تغييره من الخريطة.'
                : 'Could not access device location. Your last saved location is shown and can be changed.';
          });
        }
      } else if (mounted) {
        setState(() {
          _isLocating = false;
          _locationError = _isArabic
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
          draggable: true,
          onDragEnd: (position) {
            _updateLocation(position.latitude, position.longitude);
          },
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

    if (kIsWeb) {
      if (!mounted) return;
      setState(() {
        placemarks = null;
        _resolvedAddress = _isArabic
            ? 'الموقع المحدد على الخريطة'
            : 'Selected map location';
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
        _resolvedAddress = _isArabic
            ? 'الموقع المحدد على الخريطة'
            : 'Selected map location';
        _isLocating = false;
      });
    }
  }

  void _onMapTap(LatLng latLng) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 180),
      () => _updateLocation(latLng.latitude, latLng.longitude),
    );
  }

  void _onConfirmLocation(BuildContext context) {
    if (!_hasLocation) {
      CommonMethods.showError(
        message: _isArabic
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

        final placemark =
            placemarks != null && placemarks!.isNotEmpty ? placemarks!.first : null;
        final resolvedArea = placemark?.locality ??
            placemark?.subLocality ??
            placemark?.administrativeArea ??
            _resolvedAddress ??
            '${currentLat!.toStringAsFixed(6)}, ${currentLng!.toStringAsFixed(6)}';

        HiveMethods.delegateAddress(resolvedArea);
        log('Location confirmed: $resolvedArea ($currentLat, $currentLng)');
        NavigatorMethods.pushNamedAndRemoveUntil(
          context,
          DelegateBottomNavBarScreen.routeName,
        );
      },
    );
  }

  String get _coordinatesText {
    if (!_hasLocation) return '--';
    return '${currentLat!.toStringAsFixed(6)}, ${currentLng!.toStringAsFixed(6)}';
  }

  String get _locationTitle {
    if (_isLocating) {
      return _isArabic ? 'جارٍ تحديد موقعك...' : 'Detecting your location...';
    }
    if (_resolvedAddress != null) return _resolvedAddress!;
    return _isArabic ? 'حدد نقطة على الخريطة' : 'Choose a point on the map';
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final mapHeight = (screenHeight * .46).clamp(330.0, 500.0).toDouble();

    return Scaffold(
      backgroundColor: const Color(0xffF7F8FA),
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _LocationBackgroundPainter()),
            ),
          ),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 130),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 20),
                      _buildIntroCard(),
                      const SizedBox(height: 16),
                      _buildMapCard(mapHeight),
                      const SizedBox(height: 16),
                      _buildSelectedLocationCard(),
                      if (_locationError != null) ...[
                        const SizedBox(height: 12),
                        _buildWarningCard(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.98),
          boxShadow: [
            BoxShadow(
              color: _navy.withOpacity(.08),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          minimum: const EdgeInsets.fromLTRB(18, 10, 18, 12),
          child: CustomButton(
            height: 60,
            radius: 20,
            hasShadow: true,
            text: AppLocaleKey.confirm.tr(),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xffFF8A08), Color(0xffFF6500)],
            ),
            prefixIcon: const Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 23,
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
            boxShadow: [
              BoxShadow(
                color: _orange.withOpacity(.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
            onPressed: _hasLocation ? () => _onConfirmLocation(context) : null,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 18, 13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [Color(0xffFFF5EB), Colors.white],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xffF2ECE7)),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(.06),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () => Navigator.maybePop(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xffECEEF1)),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: _orange,
                  size: 26,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocaleKey.location.tr(),
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 24,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isArabic
                      ? 'حدّث موقعك بدقة لتسهيل استلام الطلبات'
                      : 'Set your location precisely for smoother deliveries',
                  style: const TextStyle(
                    color: _softText,
                    fontSize: 12.5,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffECEEF1)),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(.055),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xffFF9A17), Color(0xffFF6500)],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: _orange.withOpacity(.22),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: Colors.white,
              size: 29,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isArabic ? 'حدد موقعك الحالي' : 'Choose your current location',
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _isArabic
                      ? 'اضغط على الخريطة أو اسحب العلامة لتحديد النقطة بدقة.'
                      : 'Tap the map or drag the marker to set the exact point.',
                  style: const TextStyle(
                    color: _softText,
                    fontSize: 12.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: _hasLocation ? const Color(0xffECF8F1) : const Color(0xffFFF4E8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _hasLocation ? Icons.check_circle_rounded : Icons.gps_not_fixed_rounded,
                  size: 15,
                  color: _hasLocation ? const Color(0xff319B63) : _orange,
                ),
                const SizedBox(width: 5),
                Text(
                  _hasLocation
                      ? (_isArabic ? 'تم التحديد' : 'Selected')
                      : (_isArabic ? 'غير محدد' : 'Not set'),
                  style: TextStyle(
                    color: _hasLocation ? const Color(0xff267C51) : _orange,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard(double mapHeight) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xffE9EBEF)),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(.10),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: mapHeight,
        child: Stack(
          children: [
            Positioned.fill(
              child: GoogleMap(
                onTap: _onMapTap,
                onLongPress: _onMapTap,
                markers: markers,
                mapType: MapType.normal,
                myLocationButtonEnabled: false,
                myLocationEnabled: !kIsWeb,
                mapToolbarEnabled: false,
                zoomControlsEnabled: false,
                compassEnabled: false,
                onMapCreated: (controller) {
                  gmc = controller;
                  if (_hasLocation) {
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
              start: 14,
              top: 14,
              end: 14,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.94),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: const Color(0xffECEEF1)),
                      boxShadow: [
                        BoxShadow(
                          color: _navy.withOpacity(.08),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.touch_app_rounded,
                          color: _orange,
                          size: 17,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _isArabic
                                ? 'اضغط على أي نقطة لتحديدها'
                                : 'Tap anywhere to select a point',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _navy,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              end: 14,
              bottom: 14,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                elevation: 5,
                child: InkWell(
                  onTap: _isLocating ? null : _determinePosition,
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    width: 54,
                    height: 54,
                    child: _isLocating
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.3,
                              color: _orange,
                            ),
                          )
                        : const Icon(
                            Icons.my_location_rounded,
                            color: _orange,
                            size: 26,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedLocationCard() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffECEEF1)),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(.055),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xffFFF0E3),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.near_me_rounded,
              color: _orange,
              size: 25,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppLocaleKey.area.tr(),
                        style: const TextStyle(
                          color: _navy,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (_hasLocation)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xffECF8F1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _isArabic ? 'جاهز للحفظ' : 'Ready to save',
                          style: const TextStyle(
                            color: Color(0xff267C51),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _locationTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _isLocating ? _softText : _navy,
                    fontSize: 13.5,
                    height: 1.45,
                    fontWeight: _isLocating ? FontWeight.w500 : FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 9),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xffF7F8FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.pin_drop_outlined,
                        color: Color(0xff9AA0AA),
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _coordinatesText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xff747B86),
                            fontSize: 11.5,
                            letterSpacing: .2,
                            fontWeight: FontWeight.w600,
                          ),
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
    );
  }

  Widget _buildWarningCard() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xffFFF8EC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffFFE3B7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xffC77A18),
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              _locationError!,
              style: const TextStyle(
                color: Color(0xff9A661F),
                fontSize: 11.5,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationBackgroundPainter extends CustomPainter {
  const _LocationBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const orange = Color(0xffFD7201);

    canvas.drawCircle(
      Offset(size.width * .05, 0),
      size.width * .34,
      Paint()..color = orange.withOpacity(.055),
    );
    canvas.drawCircle(
      Offset(size.width * .34, -28),
      size.width * .24,
      Paint()..color = orange.withOpacity(.022),
    );
    canvas.drawCircle(
      Offset(size.width * 1.04, size.height * .73),
      size.width * .30,
      Paint()..color = orange.withOpacity(.022),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
