import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';

class DelegateNavigationRoute {
  final List<LatLng> geometry;
  final List<DelegateNavigationStep> steps;
  final double distanceMeters;
  final double durationSeconds;

  const DelegateNavigationRoute({
    required this.geometry,
    required this.steps,
    required this.distanceMeters,
    required this.durationSeconds,
  });
}

class DelegateNavigationStep {
  final LatLng location;
  final String type;
  final String modifier;
  final String roadName;
  final double distanceMeters;

  const DelegateNavigationStep({
    required this.location,
    required this.type,
    required this.modifier,
    required this.roadName,
    required this.distanceMeters,
  });

  String instruction({required bool isArabic}) {
    final road = roadName.trim();
    final suffix = road.isEmpty
        ? ''
        : (isArabic ? ' إلى $road' : ' onto $road');

    if (isArabic) {
      switch (type) {
        case 'depart':
          return 'ابدأ السير$suffix';
        case 'arrive':
          return 'وصلت إلى وجهتك';
        case 'roundabout':
        case 'rotary':
          return 'ادخل الميدان$suffix';
        case 'turn':
        case 'new name':
        case 'continue':
          if (modifier.contains('left')) return 'اتجه يسارًا$suffix';
          if (modifier.contains('right')) return 'اتجه يمينًا$suffix';
          if (modifier.contains('uturn')) return 'قم بالدوران للخلف$suffix';
          return 'استمر للأمام$suffix';
        case 'merge':
          return 'اندمج مع الطريق$suffix';
        case 'fork':
          if (modifier.contains('left')) return 'الزم اليسار$suffix';
          if (modifier.contains('right')) return 'الزم اليمين$suffix';
          return 'استمر عند التفرع$suffix';
        default:
          if (modifier.contains('left')) return 'اتجه يسارًا$suffix';
          if (modifier.contains('right')) return 'اتجه يمينًا$suffix';
          return 'استمر في الطريق$suffix';
      }
    }

    switch (type) {
      case 'depart':
        return 'Start driving$suffix';
      case 'arrive':
        return 'You have arrived';
      case 'roundabout':
      case 'rotary':
        return 'Enter the roundabout$suffix';
      case 'turn':
      case 'new name':
      case 'continue':
        if (modifier.contains('left')) return 'Turn left$suffix';
        if (modifier.contains('right')) return 'Turn right$suffix';
        if (modifier.contains('uturn')) return 'Make a U-turn$suffix';
        return 'Continue straight$suffix';
      case 'merge':
        return 'Merge$suffix';
      case 'fork':
        if (modifier.contains('left')) return 'Keep left$suffix';
        if (modifier.contains('right')) return 'Keep right$suffix';
        return 'Continue at the fork$suffix';
      default:
        if (modifier.contains('left')) return 'Turn left$suffix';
        if (modifier.contains('right')) return 'Turn right$suffix';
        return 'Continue$suffix';
    }
  }
}

class DelegateNavigationService {
  // The first endpoint is the same public OSRM family used by OpenStreetMap
  // directions. The project demo server remains a fallback only.
  static const List<String> _routingBases = [
    'https://routing.openstreetmap.de/routed-car',
    'https://router.project-osrm.org',
  ];

  Future<DelegateNavigationRoute> route({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    Object? lastError;

    for (final base in _routingBases) {
      try {
        return await _requestRoute(
          base: base,
          fromLat: fromLat,
          fromLng: fromLng,
          toLat: toLat,
          toLng: toLng,
        );
      } catch (e) {
        lastError = e;
      }
    }

    throw Exception('All routing providers failed: $lastError');
  }

  Future<DelegateNavigationRoute> _requestRoute({
    required String base,
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    final coordinates = '$fromLng,$fromLat;$toLng,$toLat';
    final uri = Uri.parse(
      '$base/route/v1/driving/$coordinates'
      '?overview=simplified&geometries=geojson&steps=true&alternatives=false',
    );

    // Do not set User-Agent here. Browsers treat it as a forbidden header and
    // it can make Flutter Web routing fail before a response is returned.
    final response = await http.get(
      uri,
      headers: const {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 9));

    if (response.statusCode != 200) {
      throw Exception('Routing request failed (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['code'] != 'Ok') {
      throw Exception('No route available');
    }

    final routes = decoded['routes'];
    if (routes is! List || routes.isEmpty || routes.first is! Map) {
      throw Exception('No route available');
    }

    final route = Map<String, dynamic>.from(routes.first as Map);
    final geometryJson = route['geometry'];
    final coordinatesJson = geometryJson is Map ? geometryJson['coordinates'] : null;

    final geometry = <LatLng>[];
    if (coordinatesJson is List) {
      for (final point in coordinatesJson) {
        if (point is List && point.length >= 2) {
          final lng = (point[0] as num?)?.toDouble();
          final lat = (point[1] as num?)?.toDouble();
          if (lat != null && lng != null) geometry.add(LatLng(lat, lng));
        }
      }
    }

    final steps = <DelegateNavigationStep>[];
    final legs = route['legs'];
    if (legs is List && legs.isNotEmpty && legs.first is Map) {
      final rawSteps = (legs.first as Map)['steps'];
      if (rawSteps is List) {
        for (final raw in rawSteps) {
          if (raw is! Map) continue;
          final step = Map<String, dynamic>.from(raw);
          final maneuver = step['maneuver'];
          if (maneuver is! Map) continue;
          final location = maneuver['location'];
          if (location is! List || location.length < 2) continue;
          final lng = (location[0] as num?)?.toDouble();
          final lat = (location[1] as num?)?.toDouble();
          if (lat == null || lng == null) continue;

          steps.add(
            DelegateNavigationStep(
              location: LatLng(lat, lng),
              type: '${maneuver['type'] ?? ''}',
              modifier: '${maneuver['modifier'] ?? ''}',
              roadName: '${step['name'] ?? ''}',
              distanceMeters: (step['distance'] as num?)?.toDouble() ?? 0,
            ),
          );
        }
      }
    }

    if (geometry.length < 2) {
      throw Exception('Route geometry is empty');
    }

    return DelegateNavigationRoute(
      geometry: geometry,
      steps: steps,
      distanceMeters: (route['distance'] as num?)?.toDouble() ?? 0,
      durationSeconds: (route['duration'] as num?)?.toDouble() ?? 0,
    );
  }
}
