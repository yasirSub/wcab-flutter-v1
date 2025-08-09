class ApiConstants {
  // Base URLs
  static const String baseUrl = 'http://10.40.140.134:8000/api';
  static const String webBaseUrl = 'http://10.40.140.134:8000';

  // Authentication endpoints
  static const String register = '$baseUrl/register';
  static const String login = '$baseUrl/login';
  static const String logout = '$baseUrl/logout';
  static const String refresh = '$baseUrl/refresh';
  static const String me = '$baseUrl/me';
  static const String updateProfile = '$baseUrl/profile';
  static const String changePassword = '$baseUrl/change-password';

  // User endpoints
  static const String userProfile = '$baseUrl/user/profile';
  static const String userStatistics = '$baseUrl/user/statistics';
  static const String profileUpdate = '$baseUrl/profile/update';
  static const String profilePhoto = '$baseUrl/profile/upload-photo';
  static const String profileStatistics = '$baseUrl/profile/statistics';
  static const String emergencyContacts = '$baseUrl/profile/emergency-contacts';

  // Ride endpoints
  static const String requestRide = '$baseUrl/rides/request';
  static const String availableRides = '$baseUrl/rides/available';
  static const String acceptRide = '$baseUrl/rides/accept';
  static const String startRide = '$baseUrl/rides/start';
  static const String completeRide = '$baseUrl/rides/complete';
  static const String cancelRide = '$baseUrl/rides/cancel';
  static const String rideHistory = '$baseUrl/rides/history';
  static const String currentRide = '$baseUrl/rides/current';
  static const String rideDetails = '$baseUrl/rides'; // + /{id}

  // Driver endpoints
  static const String driverRegister = '$baseUrl/driver/register';
  static const String driverProfile = '$baseUrl/driver/profile';
  static const String updateDriverProfile = '$baseUrl/driver/profile';
  static const String updateDriverStatus = '$baseUrl/driver/status';
  static const String updateDriverLocation = '$baseUrl/driver/location';
  static const String driverEarnings = '$baseUrl/driver/earnings';
  static const String driverStatistics = '$baseUrl/driver/statistics';

  // Vehicle endpoints
  static const String vehicles = '$baseUrl/vehicles';
  static const String addVehicle = '$baseUrl/vehicles';
  static const String updateVehicle = '$baseUrl/vehicles'; // + /{id}
  static const String deleteVehicle = '$baseUrl/vehicles'; // + /{id}

  // Payment endpoints
  static const String payments = '$baseUrl/payments';
  static const String processPayment = '$baseUrl/payments/process';
  static const String paymentDetails = '$baseUrl/payments'; // + /{id}
  static const String refundPayment = '$baseUrl/payments'; // + /{id}/refund

  // Location endpoints
  static const String updateLocation = '$baseUrl/location/update';
  static const String nearbyDrivers = '$baseUrl/location/nearby-drivers';
  static const String estimateFare = '$baseUrl/location/estimate-fare';

  // Rating endpoints
  static const String rateRide = '$baseUrl/ratings';
  static const String receivedRatings = '$baseUrl/ratings/received';
  static const String givenRatings = '$baseUrl/ratings/given';

  // Settings endpoints
  static const String settings = '$baseUrl/settings';
  static const String notificationSettings = '$baseUrl/settings/notifications';
  static const String privacySettings = '$baseUrl/settings/privacy';
  static const String appPreferences = '$baseUrl/settings/preferences';

  // Admin endpoints
  static const String adminDashboard = '$baseUrl/admin/dashboard';
  static const String adminStatistics = '$baseUrl/admin/statistics';
  static const String adminUsers = '$baseUrl/admin/users';
  static const String adminRides = '$baseUrl/admin/rides';
  static const String adminDrivers = '$baseUrl/admin/drivers';
  static const String adminPayments = '$baseUrl/admin/payments';

  // HTTP Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Response status codes
  static const int success = 200;
  static const int created = 201;
  static const int badRequest = 400;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int validationError = 422;
  static const int serverError = 500;

  // Payment methods
  static const List<String> paymentMethods = ['cash', 'card', 'wallet'];

  // Ride statuses
  static const List<String> rideStatuses = [
    'pending',
    'searching',
    'accepted',
    'started',
    'completed',
    'cancelled',
  ];

  // User types
  static const String customerType = 'customer';
  static const String driverType = 'driver';
  static const String adminType = 'admin';

  // Default values
  static const double defaultBaseFare = 50.0;
  static const double defaultDistanceFare = 10.0; // per km
  static const int defaultSearchRadius = 5; // km
  static const Duration requestTimeout = Duration(seconds: 30);
}
