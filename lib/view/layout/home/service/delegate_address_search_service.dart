import 'dart:convert';

import 'package:http/http.dart' as http;

class DelegateAddressSearchResult {
  final String title;
  final String subtitle;
  final double lat;
  final double lng;

  const DelegateAddressSearchResult({
    required this.title,
    required this.subtitle,
    required this.lat,
    required this.lng,
  });

  String get fullAddress => subtitle.trim().isEmpty ? title : '$title، $subtitle';
}

class DelegateAddressSearchService {
  static const _endpoint = 'https://nominatim.openstreetmap.org/search';

  Future<List<DelegateAddressSearchResult>> search(
    String query, {
    required bool isArabic,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.length < 2) return const [];

    final uri = Uri.parse(_endpoint).replace(
      queryParameters: {
        'q': cleanQuery,
        'format': 'jsonv2',
        'addressdetails': '1',
        'limit': '6',
        'countrycodes': 'eg',
        'accept-language': isArabic ? 'ar' : 'en',
      },
    );

    final response = await http.get(
      uri,
      headers: const {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Address search failed (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];

    return decoded.map<DelegateAddressSearchResult?>((raw) {
      if (raw is! Map) return null;
      final item = Map<String, dynamic>.from(raw);
      final lat = double.tryParse('${item['lat'] ?? ''}');
      final lng = double.tryParse('${item['lon'] ?? ''}');
      if (lat == null || lng == null) return null;

      final address = item['address'] is Map
          ? Map<String, dynamic>.from(item['address'] as Map)
          : <String, dynamic>{};

      final title = _firstNonEmpty([
        address['road'],
        address['pedestrian'],
        address['neighbourhood'],
        address['suburb'],
        address['city'],
        item['name'],
      ]);

      final locality = _firstNonEmpty([
        address['suburb'],
        address['city_district'],
        address['city'],
        address['town'],
        address['village'],
        address['state'],
      ]);

      final displayName = '${item['display_name'] ?? ''}'.trim();
      final resolvedTitle = title.isEmpty
          ? (displayName.split(',').firstOrNull ?? displayName)
          : title;

      final subtitleParts = <String>{
        if (locality.isNotEmpty) locality,
        if ('${address['state'] ?? ''}'.trim().isNotEmpty)
          '${address['state']}'.trim(),
      }.toList();

      final subtitle = subtitleParts.isEmpty
          ? displayName
          : subtitleParts.join('، ');

      return DelegateAddressSearchResult(
        title: resolvedTitle.isEmpty ? displayName : resolvedTitle,
        subtitle: subtitle,
        lat: lat,
        lng: lng,
      );
    }).whereType<DelegateAddressSearchResult>().toList();
  }

  static String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = '${value ?? ''}'.trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }
}

extension _FirstOrNullExtension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
