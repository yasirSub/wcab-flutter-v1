import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://10.40.140.134:8000/api';

  // Get stored token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Store token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Remove token
  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Get headers with auth token
  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Register user
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String userType,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: await getHeaders(),
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'user_type': userType,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Registration successful',
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed',
          'errors': data['errors'],
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Login user
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: await getHeaders(),
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Save token
        if (data['data']?['access_token'] != null) {
          await saveToken(data['data']['access_token']);
        }

        return {
          'success': true,
          'message': data['message'] ?? 'Login successful',
          'data': data['data'],
        };
      } else {
        return {'success': false, 'message': data['message'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get user profile
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: await getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get profile',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Logout
  static Future<Map<String, dynamic>> logout() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: await getHeaders(),
      );

      // Remove token regardless of response
      await removeToken();

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Logged out successfully'};
      } else {
        return {'success': true, 'message': 'Logged out locally'};
      }
    } catch (e) {
      // Remove token even if network fails
      await removeToken();
      return {'success': true, 'message': 'Logged out locally'};
    }
  }

  // Update user profile
  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/profile/update'),
        headers: await getHeaders(),
        body: jsonEncode({'name': name, 'email': email, 'phone': phone}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Profile updated successfully',
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update profile',
          'errors': data['errors'],
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Upload profile photo
  static Future<Map<String, dynamic>> uploadProfilePhoto({
    required String imagePath,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/profile/upload-photo'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.files.add(await http.MultipartFile.fromPath('photo', imagePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Profile photo updated successfully',
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to upload photo',
          'errors': data['errors'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to upload photo: ${e.toString()}',
      };
    }
  }

  // Delete profile photo
  static Future<Map<String, dynamic>> deleteProfilePhoto() async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/profile/delete-photo'),
        headers: await getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Profile photo deleted successfully',
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete photo',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get user statistics
  static Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile/statistics'),
        headers: await getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get statistics',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get notification settings
  static Future<Map<String, dynamic>> getNotificationSettings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/settings/notifications'),
        headers: await getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get notification settings',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Update notification settings
  static Future<Map<String, dynamic>> updateNotificationSettings({
    required Map<String, dynamic> settings,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/settings/notifications'),
        headers: await getHeaders(),
        body: jsonEncode(settings),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Notification settings updated',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update settings',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get app settings
  static Future<Map<String, dynamic>> getAppSettings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/settings'),
        headers: await getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get settings',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Update app settings
  static Future<Map<String, dynamic>> updateAppSettings({
    required Map<String, dynamic> settings,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/settings'),
        headers: await getHeaders(),
        body: jsonEncode(settings),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Settings updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update settings',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Update emergency contacts
  static Future<Map<String, dynamic>> updateEmergencyContacts({
    required List<Map<String, String>> contacts,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/profile/emergency-contacts'),
        headers: await getHeaders(),
        body: jsonEncode({'contacts': contacts}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Emergency contacts updated',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update contacts',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // =========================
  // RIDE/BOOKING API METHODS
  // =========================

  // Request a new ride
  static Future<Map<String, dynamic>> requestRide({
    required String pickupAddress,
    required double pickupLatitude,
    required double pickupLongitude,
    required String dropoffAddress,
    required double dropoffLatitude,
    required double dropoffLongitude,
    String? notes,
    required String paymentMethod,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rides/request'),
        headers: await getHeaders(),
        body: jsonEncode({
          'pickup_address': pickupAddress,
          'pickup_latitude': pickupLatitude,
          'pickup_longitude': pickupLongitude,
          'dropoff_address': dropoffAddress,
          'dropoff_latitude': dropoffLatitude,
          'dropoff_longitude': dropoffLongitude,
          'notes': notes,
          'payment_method': paymentMethod,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Ride requested successfully',
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to request ride',
          'errors': data['errors'],
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get current active ride
  static Future<Map<String, dynamic>> getCurrentRide() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rides/current'),
        headers: await getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'No active ride found',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get ride history
  static Future<Map<String, dynamic>> getRideHistory({int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rides/history?page=$page'),
        headers: await getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get ride history',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Cancel a ride
  static Future<Map<String, dynamic>> cancelRide({required int rideId}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rides/cancel'),
        headers: await getHeaders(),
        body: jsonEncode({'ride_id': rideId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Ride cancelled successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to cancel ride',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get nearby drivers
  static Future<Map<String, dynamic>> getNearbyDrivers({
    required double latitude,
    required double longitude,
    double radius = 5.0,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/location/nearby-drivers?latitude=$latitude&longitude=$longitude&radius=$radius',
        ),
        headers: await getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get nearby drivers',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Estimate fare
  static Future<Map<String, dynamic>> estimateFare({
    required double pickupLatitude,
    required double pickupLongitude,
    required double dropoffLatitude,
    required double dropoffLongitude,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/location/estimate-fare?pickup_latitude=$pickupLatitude&pickup_longitude=$pickupLongitude&dropoff_latitude=$dropoffLatitude&dropoff_longitude=$dropoffLongitude',
        ),
        headers: await getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to estimate fare',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Update user location (for drivers)
  static Future<Map<String, dynamic>> updateLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/location/update'),
        headers: await getHeaders(),
        body: jsonEncode({'latitude': latitude, 'longitude': longitude}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Location updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update location',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Track ride
  static Future<Map<String, dynamic>> trackRide({required int rideId}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/location/track-ride/$rideId'),
        headers: await getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to track ride',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // =========================
  // DRIVER API METHODS
  // =========================

  // Accept a ride (for drivers)
  static Future<Map<String, dynamic>> acceptRide({required int rideId}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rides/accept'),
        headers: await getHeaders(),
        body: jsonEncode({'ride_id': rideId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Ride accepted successfully',
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to accept ride',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Start a ride (for drivers)
  static Future<Map<String, dynamic>> startRide({required int rideId}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rides/start'),
        headers: await getHeaders(),
        body: jsonEncode({'ride_id': rideId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Ride started successfully',
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to start ride',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Complete a ride (for drivers)
  static Future<Map<String, dynamic>> completeRide({
    required int rideId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rides/complete'),
        headers: await getHeaders(),
        body: jsonEncode({'ride_id': rideId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Ride completed successfully',
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to complete ride',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get available rides (for drivers)
  static Future<Map<String, dynamic>> getAvailableRides() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rides/available'),
        headers: await getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get available rides',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // =========================
  // THEME SETTINGS API METHODS
  // =========================

  // Get user theme preference from backend
  static Future<Map<String, dynamic>> getUserThemePreference() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/settings/preferences'),
        headers: await getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'theme_mode': data['data']['theme_mode'] ?? 'system',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get theme preference',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Save user theme preference to backend
  static Future<Map<String, dynamic>> saveUserThemePreference({
    required String themeMode,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/settings/preferences'),
        headers: await getHeaders(),
        body: jsonEncode({'theme_mode': themeMode}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Theme preference saved successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to save theme preference',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
}
