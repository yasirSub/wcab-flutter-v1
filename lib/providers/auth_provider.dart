import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error message
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  // Register user
  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String userType,
  }) async {
    _setLoading(true);
    clearError();

    try {
      final result = await ApiService.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        userType: userType,
      );

      if (result['success']) {
        _setLoading(false);
        return true;
      } else {
        _setError(result['message'] ?? 'Registration failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Registration failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Login user
  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    clearError();

    try {
      final result = await ApiService.login(email: email, password: password);

      if (result['success']) {
        // Get user profile after successful login
        await _loadUserProfile();
        _setLoading(false);
        return true;
      } else {
        _setError(result['message'] ?? 'Login failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Login failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Load user profile
  Future<void> _loadUserProfile() async {
    try {
      final result = await ApiService.getProfile();
      if (result['success']) {
        _user = User.fromJson(result['data']);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load user profile: $e');
    }
  }

  // Check if user is already logged in
  Future<void> checkAuthStatus() async {
    final token = await ApiService.getToken();
    if (token != null) {
      await _loadUserProfile();
    }
  }

  // Refresh user profile data
  Future<void> refreshUser() async {
    _setLoading(true);
    clearError();

    try {
      await _loadUserProfile();
      _setLoading(false);
    } catch (e) {
      _setError('Failed to refresh user data: ${e.toString()}');
      _setLoading(false);
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    _setLoading(true);
    clearError();

    try {
      final result = await ApiService.updateProfile(
        name: name,
        email: email,
        phone: phone,
      );

      if (result['success']) {
        // Refresh user data after successful update
        await _loadUserProfile();
        _setLoading(false);
        return true;
      } else {
        _setError(result['message'] ?? 'Profile update failed');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Profile update failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Logout user
  Future<void> logout() async {
    _setLoading(true);

    try {
      await ApiService.logout();
      _user = null;
      clearError();
      _setLoading(false);
    } catch (e) {
      _user = null;
      _setLoading(false);
    }
  }
}
