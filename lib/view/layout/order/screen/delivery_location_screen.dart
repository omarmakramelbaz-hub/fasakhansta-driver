import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../../helpers/hive/hive_methods.dart';
import '../../../../helpers/locale/app_locale_key.dart';
import '../../../custom_widgets/custom_app_bar/custom_app_bar.dart';
import '../service/delegate_navigation_service.dart';

class DeliveryLocationArgs {
  final double lat;
  final double lng;
  final String? address;
  final int? orderId;
  final bool navigationMode;

  const DeliveryLocationArgs({
    required this.lat,
    required this.lng,
    this.address,
    this.orderId,
    this.navigationMode = false,
  });
}

class DeliveryLocationScreen extends StatefulWidget {
  static const String routeName = 'DeliveryLocationScreen';
  final DeliveryLocationArgs? args;

  const DeliveryLocationScreen({super.key, this.args});

  @override
  State<DeliveryLocationScreen> createState() =>
      _DeliveryLocationScreenState();
}

class _DeliveryLocationScreenState extends State<DeliveryLocationScreen> {
  static const _styleUrl = 'https://tiles.openfreemap.org/styles/liberty';
  static const _orange = Color(0xffFD7201);
  static const _navy = Color(0xff082A4D);
  static const _softText = Color(0xff7D8490);
  static const _bikeAsset = 'assets/images/go_motorcycle_marker.png';
  static const _bikeImageId = 'go-navigation-motorcycle';

  final DelegateNavigationService _navigationService =
      DelegateNavigationService();

  MapLibreMapController? _mapController;
  StreamSubscription<Position>? _positionSubscription;
  Circle? _destinationCircle;
  Circle? _bikePulse;
  Symbol? _bike;
  Line? _routeLine;
  DelegateNavigationRoute? _route;

  double? _currentLat;
  double? _currentLng;
  double _heading = 0;
  double _speedKmh = 0;
  bool _styleReady = false;
  bool _locationLoading = false;
  bool _routeLoading = false;
  bool _arrived = false;
  bool _followMode = true;
  String? _navigationError;
  int _stepIndex = 0;
  DateTime? _lastRouteAt;
  DateTime? _lastRouteAttemptAt;
  double? _lastRouteLat;
  double? _lastRouteLng;

  bool get _isArabic => context.locale.languageCode == 'ar';
  bool get _navigationMode => widget.args?.navigationMode == true;
  bool get _hasCurrentLocation => _currentLat != null && _currentLng != null;

  @override
  void initState() {
    super.initState();

    // The delegate location screen already keeps the latest GPS position in
    // Hive. Seed navigation with it immediately so opening navigation never
    // waits on a second GPS fix before it can calculate the route.
    final savedLat = HiveMethods.getLat();
    final savedLng = HiveMethods.getLan();
    if (savedLat != null && savedLng != null) {
      _currentLat = savedLat;
      _currentLng = savedLng;
    }

    if (_navigationMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_startNavigationLocation());
      });
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _onMapCreated(MapLibreMapController controller) async {
    _mapController = controller;
  }

  Future<void> _onStyleLoaded() async {
    final args = widget.args;
    final controller = _mapController;
    if (args == null || controller == null) return;

    try {
      _destinationCircle = await controller.addCircle(
        CircleOptions(
          geometry: LatLng(args.lat, args.lng),
          circleRadius: 13,
          circleColor: '#FD7201',
          circleOpacity: .98,
          circleStrokeColor: '#FFFFFF',
          circleStrokeWidth: 4,
          circleStrokeOpacity: 1,
        ),
      );

      if (_navigationMode) {
        final data = await rootBundle.load(_bikeAsset);
        final bytes = Uint8List.sublistView(data);
        await controller.addImage(_bikeImageId, bytes);
      }

      _styleReady = true;

      if (_navigationMode) {
        if (_hasCurrentLocation) {
          await _syncBike();
          await _loadRoute(force: true);
          await _followDriver(initial: true);
        } else {
          await _focusDestination();
        }
      } else {
        await _focusDestination();
      }
    } catch (e) {
      log('Navigation map setup failed: $e');
      if (!mounted) return;
      setState(() {
        _navigationError = _isArabic
            ? 'تعذر تجهيز الخريطة للملاحة.'
            : 'Could not prepare the navigation map.';
      });
    }
  }

  Future<void> _focusDestination() async {
    final controller = _mapController;
    final args = widget.args;
    if (controller == null || args == null) return;

    try {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(args.lat, args.lng),
            zoom: 16.2,
            tilt: 35,
          ),
        ),
        duration: const Duration(milliseconds: 500),
      );
    } catch (e) {
      log('Destination camera failed: $e');
    }
  }

  Future<void> _startNavigationLocation() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    if (mounted) {
      setState(() {
        _locationLoading = !_hasCurrentLocation;
        _navigationError = null;
      });
    }

    try {
      if (!kIsWeb && !await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Location services are disabled');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }

      // A fresh fix improves accuracy, but navigation no longer depends on it
      // because the latest saved location is already available immediately.
      try {
        final first = await Geolocator.getCurrentPosition().timeout(
          const Duration(seconds: 8),
        );
        await _handlePosition(first, initial: true);
      } catch (e) {
        log('Fresh navigation GPS fix unavailable, using saved fix: $e');
        if (!_hasCurrentLocation) rethrow;
      }

      _startGpsStream();
    } catch (e) {
      log('Navigation location failed: $e');
      if (!mounted) return;
      setState(() {
        _locationLoading = false;
        _navigationError = _hasCurrentLocation
            ? (_isArabic
                ? 'يتم استخدام آخر موقع معروف لحين عودة تحديث GPS.'
                : 'Using the last known location until GPS updates resume.')
            : (_isArabic
                ? 'تعذر تحديد موقع المندوب. تأكد من تشغيل GPS والسماح بالموقع.'
                : 'Could not detect driver location. Enable GPS and location permission.');
      });

      if (_hasCurrentLocation && _styleReady && _route == null) {
        unawaited(_loadRoute(force: true));
      }
    }
  }

  void _startGpsStream() {
    final settings = LocationSettings(
      accuracy:
          kIsWeb ? LocationAccuracy.high : LocationAccuracy.bestForNavigation,
      distanceFilter: 5,
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(
      (position) => unawaited(_handlePosition(position)),
      onError: (Object error) {
        log('Navigation GPS stream failed: $error');
        if (!mounted) return;
        setState(() {
          _navigationError = _isArabic
              ? 'توقف تحديث GPS مؤقتًا. اضغط زر تحديد الموقع للمحاولة مرة أخرى.'
              : 'GPS updates paused. Tap the locate button to retry.';
        });
      },
    );
  }

  Future<void> _handlePosition(
    Position position, {
    bool initial = false,
  }) async {
    if (!mounted) return;

    final heading = position.heading.isFinite && position.heading >= 0
        ? position.heading
        : _heading;
    final speed = position.speed.isFinite && position.speed > 0
        ? position.speed * 3.6
        : 0.0;

    setState(() {
      _currentLat = position.latitude;
      _currentLng = position.longitude;
      _heading = heading;
      _speedKmh = speed;
      _locationLoading = false;
      if (_route != null) _navigationError = null;
    });

    HiveMethods.updateLat(position.latitude);
    HiveMethods.updateLan(position.longitude);

    if (_styleReady) {
      await _syncBike();
      _updateArrivalAndStep();

      if (_followMode) {
        await _followDriver(initial: initial);
      }

      if (!_arrived && _shouldRefreshRoute()) {
        // Never force here. A failed router must not be hammered on every GPS
        // update; _loadRoute has a retry throttle.
        unawaited(_loadRoute());
      }
    }
  }

  bool _shouldRefreshRoute() {
    if (!_hasCurrentLocation) return false;
    if (_route == null) return true;

    final now = DateTime.now();
    final elapsed = _lastRouteAt == null
        ? const Duration(days: 1)
        : now.difference(_lastRouteAt!);

    final movedFromRouteStart =
        _lastRouteLat == null || _lastRouteLng == null
            ? double.infinity
            : Geolocator.distanceBetween(
                _lastRouteLat!,
                _lastRouteLng!,
                _currentLat!,
                _currentLng!,
              );

    double nearestRouteDistance = double.infinity;
    final geometry = _route?.geometry ?? const <LatLng>[];
    for (var i = 0; i < geometry.length; i += 3) {
      final point = geometry[i];
      final distance = Geolocator.distanceBetween(
        _currentLat!,
        _currentLng!,
        point.latitude,
        point.longitude,
      );
      if (distance < nearestRouteDistance) nearestRouteDistance = distance;
    }

    final offRoute = nearestRouteDistance > 70;
    final progressed = movedFromRouteStart > 120 && elapsed.inSeconds >= 25;
    return offRoute || progressed;
  }

  Future<void> _loadRoute({bool force = false}) async {
    final args = widget.args;
    if (args == null || !_hasCurrentLocation || _routeLoading || _arrived) {
      return;
    }

    final now = DateTime.now();
    if (!force &&
        _lastRouteAttemptAt != null &&
        now.difference(_lastRouteAttemptAt!).inSeconds < 12) {
      return;
    }

    _lastRouteAttemptAt = now;
    if (mounted) {
      setState(() {
        _routeLoading = true;
        if (_route == null) _navigationError = null;
      });
    }

    try {
      final result = await _navigationService.route(
        fromLat: _currentLat!,
        fromLng: _currentLng!,
        toLat: args.lat,
        toLng: args.lng,
      );

      _lastRouteAt = DateTime.now();
      _lastRouteLat = _currentLat;
      _lastRouteLng = _currentLng;
      _stepIndex = 0;
      _route = result;

      if (mounted) {
        setState(() {
          _routeLoading = false;
          _navigationError = null;
        });
      }

      await _drawRoute(result.geometry);
      _updateArrivalAndStep();
    } catch (e) {
      log('Route calculation failed: $e');
      if (!mounted) return;
      setState(() {
        _routeLoading = false;
        _navigationError = _isArabic
            ? 'تعذر تحميل الطريق الآن. اضغط هنا لإعادة المحاولة.'
            : 'Could not load the route. Tap here to retry.';
      });
    }
  }

  Future<void> _drawRoute(List<LatLng> points) async {
    final controller = _mapController;
    if (!_styleReady || controller == null || points.length < 2) return;

    try {
      if (_routeLine != null) {
        await controller.removeLine(_routeLine!);
        _routeLine = null;
      }

      _routeLine = await controller.addLine(
        LineOptions(
          geometry: points,
          lineColor: '#FD7201',
          lineWidth: 6.5,
          lineOpacity: .96,
        ),
      );
    } catch (e) {
      log('Route drawing failed: $e');
      if (mounted) {
        setState(() {
          _navigationError = _isArabic
              ? 'تم حساب الطريق لكن تعذر رسمه. اضغط هنا لإعادة المحاولة.'
              : 'Route calculated but could not be drawn. Tap to retry.';
        });
      }
    }
  }

  Future<void> _syncBike() async {
    final controller = _mapController;
    if (!_styleReady || controller == null || !_hasCurrentLocation) return;

    final point = LatLng(_currentLat!, _currentLng!);
    try {
      if (_bikePulse == null) {
        _bikePulse = await controller.addCircle(
          CircleOptions(
            geometry: point,
            circleRadius: 23,
            circleColor: '#FD7201',
            circleOpacity: .12,
            circleStrokeColor: '#FF9B46',
            circleStrokeWidth: 2,
            circleStrokeOpacity: .30,
          ),
        );
      } else {
        await controller.updateCircle(
          _bikePulse!,
          CircleOptions(geometry: point),
        );
      }

      if (_bike == null) {
        _bike = await controller.addSymbol(
          SymbolOptions(
            geometry: point,
            iconImage: _bikeImageId,
            iconSize: .56,
            iconRotate: _heading,
            iconAnchor: 'center',
            zIndex: 20,
          ),
          {'type': 'delegate-navigation'},
        );
      } else {
        await controller.updateSymbol(
          _bike!,
          SymbolOptions(
            geometry: point,
            iconRotate: _heading,
          ),
        );
      }
    } catch (e) {
      log('Driver marker update failed: $e');
    }
  }

  Future<void> _followDriver({bool initial = false}) async {
    final controller = _mapController;
    if (!_styleReady || controller == null || !_hasCurrentLocation) return;

    try {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_currentLat!, _currentLng!),
            zoom: initial ? 16.4 : 17.05,
            tilt: 50,
            bearing: _heading,
          ),
        ),
        duration: const Duration(milliseconds: 550),
      );
    } catch (e) {
      log('Navigation camera follow failed: $e');
    }
  }

  void _updateArrivalAndStep() {
    final args = widget.args;
    if (args == null || !_hasCurrentLocation) return;

    final destinationDistance = Geolocator.distanceBetween(
      _currentLat!,
      _currentLng!,
      args.lat,
      args.lng,
    );

    if (destinationDistance <= 35 && !_arrived) {
      if (mounted) {
        setState(() {
          _arrived = true;
          final count = _route?.steps.length ?? 0;
          _stepIndex = count > 0 ? count - 1 : 0;
        });
      }
      return;
    }

    final steps = _route?.steps ?? const <DelegateNavigationStep>[];
    if (steps.isEmpty || _stepIndex >= steps.length) return;

    var nextIndex = _stepIndex;
    while (nextIndex < steps.length - 1) {
      final step = steps[nextIndex];
      final distance = Geolocator.distanceBetween(
        _currentLat!,
        _currentLng!,
        step.location.latitude,
        step.location.longitude,
      );
      if (distance > 38) break;
      nextIndex++;
    }

    if (nextIndex != _stepIndex && mounted) {
      setState(() => _stepIndex = nextIndex);
    }
  }

  String get _instruction {
    if (_arrived) {
      return _isArabic ? 'وصلت إلى موقع العميل' : 'You reached the customer';
    }
    if (_routeLoading && _route == null) {
      return _isArabic ? 'جارٍ تحديد أفضل طريق...' : 'Finding the best route...';
    }
    final steps = _route?.steps ?? const <DelegateNavigationStep>[];
    if (steps.isEmpty) {
      return _isArabic ? 'جارٍ تجهيز الاتجاهات...' : 'Preparing directions...';
    }
    final index = _stepIndex.clamp(0, steps.length - 1);
    return steps[index].instruction(isArabic: _isArabic);
  }

  String get _nextStepDistance {
    final steps = _route?.steps ?? const <DelegateNavigationStep>[];
    if (!_hasCurrentLocation || steps.isEmpty) return '';
    final index = _stepIndex.clamp(0, steps.length - 1);
    final point = steps[index].location;
    final distance = Geolocator.distanceBetween(
      _currentLat!,
      _currentLng!,
      point.latitude,
      point.longitude,
    );
    if (distance >= 1000) return '${(distance / 1000).toStringAsFixed(1)} كم';
    return '${distance.round()} م';
  }

  String get _distanceText {
    final distance = _route?.distanceMeters;
    if (distance == null) return '--';
    if (distance >= 1000) return '${(distance / 1000).toStringAsFixed(1)} كم';
    return '${distance.round()} م';
  }

  String get _durationText {
    final seconds = _route?.durationSeconds;
    if (seconds == null) return '--';
    final minutes = (seconds / 60).ceil();
    if (minutes < 60) return _isArabic ? '$minutes دقيقة' : '$minutes min';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return _isArabic ? '$hours س $rest د' : '${hours}h ${rest}m';
  }

  String _destinationText(DeliveryLocationArgs args) {
    final address = args.address?.trim();
    if (address != null && address.isNotEmpty) return address;
    return '${args.lat.toStringAsFixed(6)}, ${args.lng.toStringAsFixed(6)}';
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    if (args == null) {
      return const Scaffold(
        body: Center(
          child: Icon(Icons.location_off_rounded, color: _softText, size: 50),
        ),
      );
    }

    final initialTarget = _hasCurrentLocation
        ? LatLng(_currentLat!, _currentLng!)
        : LatLng(args.lat, args.lng);

    return Scaffold(
      backgroundColor: const Color(0xffF7F8FA),
      appBar: CustomAppBar(
        context,
        height: 86,
        title: Text(
          _navigationMode
              ? (_isArabic ? 'الملاحة إلى الوجهة' : 'Navigate to destination')
              : AppLocaleKey.location.tr(),
          style: const TextStyle(
            color: _navy,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: MapLibreMap(
              styleString: _styleUrl,
              initialCameraPosition: CameraPosition(
                target: initialTarget,
                zoom: _navigationMode ? 16.4 : 16.2,
                tilt: _navigationMode ? 48 : 35,
              ),
              onMapCreated: _onMapCreated,
              onStyleLoadedCallback: _onStyleLoaded,
              compassEnabled: false,
              myLocationEnabled: false,
              trackCameraPosition: true,
            ),
          ),
          if (_navigationMode) ...[
            PositionedDirectional(
              top: 14,
              start: 14,
              end: 14,
              child: _navigationInstructionCard(),
            ),
            PositionedDirectional(
              end: 16,
              bottom: 150,
              child: FloatingActionButton.small(
                heroTag: 'navigationRecenter',
                backgroundColor: Colors.white,
                foregroundColor: _orange,
                elevation: 5,
                onPressed: () {
                  setState(() => _followMode = true);
                  if (_hasCurrentLocation) {
                    unawaited(_followDriver(initial: true));
                  } else {
                    unawaited(_startNavigationLocation());
                  }
                },
                child: const Icon(Icons.my_location_rounded),
              ),
            ),
          ] else
            PositionedDirectional(
              top: 14,
              start: 14,
              child: _destinationBadge(),
            ),
          if (_navigationError != null)
            PositionedDirectional(
              start: 14,
              end: 14,
              bottom: _navigationMode ? 152 : 22,
              child: GestureDetector(
                onTap: _navigationMode && _hasCurrentLocation
                    ? () => unawaited(_loadRoute(force: true))
                    : null,
                child: _errorCard(),
              ),
            ),
          if (_navigationMode)
            PositionedDirectional(
              start: 0,
              end: 0,
              bottom: 0,
              child: _navigationBottomCard(args),
            )
          else
            PositionedDirectional(
              start: 14,
              end: 14,
              bottom: 20,
              child: _destinationInfoCard(args),
            ),
        ],
      ),
    );
  }

  Widget _navigationInstructionCard() {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.97),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _orange.withOpacity(.25)),
          boxShadow: [
            BoxShadow(
              color: _navy.withOpacity(.12),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _orange.withOpacity(.11),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _arrived ? Icons.flag_rounded : Icons.navigation_rounded,
                color: _orange,
                size: 29,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _instruction,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 16,
                      height: 1.25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (_nextStepDistance.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _nextStepDistance,
                      style: const TextStyle(
                        color: _orange,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_routeLoading || _locationLoading)
              const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  strokeWidth: 2.3,
                  color: _orange,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _navigationBottomCard(DeliveryLocationArgs args) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 13, 18, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.98),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(.12),
            blurRadius: 28,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _stat(Icons.route_rounded, _distanceText),
                const SizedBox(width: 8),
                _stat(Icons.schedule_rounded, _durationText),
                const SizedBox(width: 8),
                _stat(Icons.speed_rounded, '${_speedKmh.round()} كم/س'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xffFFF0E3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: _orange,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _destinationText(args),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (args.orderId != null)
                  Container(
                    margin: const EdgeInsetsDirectional.only(start: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _orange.withOpacity(.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '#${args.orderId}',
                      style: const TextStyle(
                        color: _orange,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(IconData icon, String value) {
    return Expanded(
      child: Container(
        height: 43,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xffF8F9FB),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0xffECEEF1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _orange, size: 16),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _destinationBadge() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.95),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _navy.withOpacity(.08),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on_rounded, color: _orange, size: 18),
            const SizedBox(width: 5),
            Text(
              _isArabic ? 'نقطة التسليم' : 'Delivery point',
              style: const TextStyle(
                color: _navy,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _destinationInfoCard(DeliveryLocationArgs args) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.97),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffECEEF1)),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(.09),
            blurRadius: 20,
            offset: const Offset(0, 7),
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
            child: const Icon(Icons.location_on_rounded, color: _orange),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocaleKey.area.tr(),
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _destinationText(args),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _softText,
                    fontSize: 12,
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

  Widget _errorCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xF9FFF4EA),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _orange.withOpacity(.32)),
      ),
      child: Row(
        children: [
          const Icon(Icons.refresh_rounded, color: _orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _navigationError!,
              style: const TextStyle(
                color: _navy,
                fontSize: 11.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
