import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class GeocodingService {
  // Using Nominatim (OpenStreetMap's geocoding service) - completely free
  static const String _nominatimBaseUrl = 'https://nominatim.openstreetmap.org';

  /// Search for addresses with suggestions
  static Future<List<AddressSuggestion>> searchAddresses(String query) async {
    if (query.length < 3) return [];

    try {
      final url = Uri.parse(
        '$_nominatimBaseUrl/search?format=json&limit=5&q=${Uri.encodeComponent(query)}&addressdetails=1&countrycodes=in',
      );

      print('🔍 Searching addresses: $url');

      final response = await http
          .get(url, headers: {'User-Agent': 'WCAB-Flutter-App/1.0'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        return data.map<AddressSuggestion>((item) {
          return AddressSuggestion(
            displayName: item['display_name'] ?? '',
            address: _formatAddress(item),
            latitude: double.parse(item['lat'] ?? '0.0'),
            longitude: double.parse(item['lon'] ?? '0.0'),
            placeId: item['place_id']?.toString() ?? '',
            type: item['type'] ?? 'unknown',
          );
        }).toList();
      } else {
        print('Geocoding API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error searching addresses: $e');
    }

    return [];
  }

  /// Format address for better display
  static String _formatAddress(Map<String, dynamic> item) {
    final address = item['address'] as Map<String, dynamic>?;
    if (address == null) return item['display_name'] ?? '';

    List<String> parts = [];

    // Add house number and road
    if (address['house_number'] != null && address['road'] != null) {
      parts.add('${address['house_number']} ${address['road']}');
    } else if (address['road'] != null) {
      parts.add(address['road']);
    }

    // Add neighbourhood or suburb
    if (address['neighbourhood'] != null) {
      parts.add(address['neighbourhood']);
    } else if (address['suburb'] != null) {
      parts.add(address['suburb']);
    }

    // Add city
    if (address['city'] != null) {
      parts.add(address['city']);
    } else if (address['town'] != null) {
      parts.add(address['town']);
    } else if (address['village'] != null) {
      parts.add(address['village']);
    }

    // Add state
    if (address['state'] != null) {
      parts.add(address['state']);
    }

    return parts.isNotEmpty ? parts.join(', ') : item['display_name'] ?? '';
  }

  /// Get coordinates from address
  static Future<LatLng?> getCoordinatesFromAddress(String address) async {
    if (address.length < 3) return null;

    try {
      final url = Uri.parse(
        '$_nominatimBaseUrl/search?format=json&limit=1&q=${Uri.encodeComponent(address)}&countrycodes=in',
      );

      final response = await http
          .get(url, headers: {'User-Agent': 'WCAB-Flutter-App/1.0'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        if (data.isNotEmpty) {
          final item = data[0];
          return LatLng(
            double.parse(item['lat'] ?? '0.0'),
            double.parse(item['lon'] ?? '0.0'),
          );
        }
      }
    } catch (e) {
      print('Error getting coordinates: $e');
    }

    return null;
  }

  /// Get address from coordinates (reverse geocoding)
  static Future<String> getAddressFromCoordinates(
    double lat,
    double lng,
  ) async {
    try {
      final url = Uri.parse(
        '$_nominatimBaseUrl/reverse?format=json&lat=$lat&lon=$lng&addressdetails=1',
      );

      final response = await http
          .get(url, headers: {'User-Agent': 'WCAB-Flutter-App/1.0'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return _formatAddress(data);
      }
    } catch (e) {
      print('Error getting address from coordinates: $e');
    }

    return 'Unknown location';
  }
}

class AddressSuggestion {
  final String displayName;
  final String address;
  final double latitude;
  final double longitude;
  final String placeId;
  final String type;

  AddressSuggestion({
    required this.displayName,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.placeId,
    required this.type,
  });

  LatLng get location => LatLng(latitude, longitude);

  @override
  String toString() => address;
}
