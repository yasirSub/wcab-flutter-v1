import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RoutingService {
  // Using OpenRouteService (free alternative to Google Directions)
  // You can get a free API key from https://openrouteservice.org/
  static const String _baseUrl =
      'https://api.openrouteservice.org/v2/directions';

  // For demo purposes, using a public demo key (limited usage)
  // In production, get your own free API key from openrouteservice.org
  static const String _apiKey =
      '5b3ce3597851110001cf6248d5a1d8e1b4c1450bb5b0b3d4f9b7b8f4';

  /// Get driving route between two points
  static Future<List<LatLng>> getRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/driving-car?api_key=$_apiKey&start=$startLng,$startLat&end=$endLng,$endLat&format=json',
      );

      print('Fetching route from: $url');

      final response = await http
          .get(
            url,
            headers: {
              'Accept':
                  'application/json, application/geo+json, application/gpx+xml, img/png; charset=utf-8',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];

          if (geometry != null) {
            // Decode the route coordinates
            final coordinates = geometry['coordinates'] as List;

            return coordinates.map<LatLng>((coord) {
              return LatLng(coord[1].toDouble(), coord[0].toDouble());
            }).toList();
          }
        }
      } else {
        print('Route API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching route: $e');
    }

    // Fallback to straight line if route service fails
    return [LatLng(startLat, startLng), LatLng(endLat, endLng)];
  }

  /// Get route using Google Directions API (requires API key)
  static Future<List<LatLng>> getRouteGoogle({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    String? googleApiKey,
  }) async {
    if (googleApiKey == null || googleApiKey.isEmpty) {
      print('Google API key not provided, using fallback route');
      return [LatLng(startLat, startLng), LatLng(endLat, endLng)];
    }

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?origin=$startLat,$startLng&destination=$endLat,$endLng&key=$googleApiKey',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final legs = route['legs'] as List;

          List<LatLng> routePoints = [];

          for (var leg in legs) {
            final steps = leg['steps'] as List;
            for (var step in steps) {
              final polyline = step['polyline']['points'];
              final decodedPoints = _decodePolyline(polyline);
              routePoints.addAll(decodedPoints);
            }
          }

          return routePoints;
        }
      } else {
        print(
          'Google Directions API Error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error fetching Google route: $e');
    }

    // Fallback to straight line if route service fails
    return [LatLng(startLat, startLng), LatLng(endLat, endLng)];
  }

  /// Decode Google polyline string to LatLng points
  static List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  /// Get estimated distance and duration for route
  static Future<Map<String, dynamic>> getRouteInfo({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/driving-car?api_key=$_apiKey&start=$startLng,$startLat&end=$endLng,$endLat&format=json',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final summary = route['summary'];

          return {
            'distance': (summary['distance'] / 1000)
                .toDouble(), // Convert to km
            'duration': (summary['duration'] / 60)
                .toDouble(), // Convert to minutes
            'success': true,
          };
        }
      }
    } catch (e) {
      print('Error fetching route info: $e');
    }

    // Fallback calculation
    const double avgSpeed = 30.0; // km/h average city speed
    final distance = _calculateDistance(startLat, startLng, endLat, endLng);
    final duration = (distance / avgSpeed) * 60; // minutes

    return {'distance': distance, 'duration': duration, 'success': false};
  }

  /// Calculate straight-line distance between two points (Haversine formula)
  static double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadius = 6371; // Earth radius in kilometers

    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  static double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}
