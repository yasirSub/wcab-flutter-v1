import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../../providers/auth_provider.dart';
import '../../services/location_service.dart';
import '../../services/api_service.dart';
import '../../widgets/free_map_widget.dart';

class DriverModeScreen extends StatefulWidget {
  const DriverModeScreen({super.key});

  @override
  State<DriverModeScreen> createState() => _DriverModeScreenState();
}

class _DriverModeScreenState extends State<DriverModeScreen> {
  Position? currentPosition;
  bool isOnline = false;
  bool isLoading = false;
  String currentAddress = 'Getting location...';
  List<dynamic> availableRides = [];
  Timer? _locationTimer;
  Timer? _ridesTimer;

  // Driver stats
  int todayRides = 0;
  double todayEarnings = 0.0;
  double rating = 4.8;
  int totalRides = 156;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _ridesTimer?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    print('DriverMode: Starting location request...');
    setState(() {
      isLoading = true;
    });

    try {
      print('DriverMode: Calling LocationService.getCurrentLocation()...');
      currentPosition = await LocationService.getCurrentLocation();
      if (currentPosition != null) {
        print(
          'DriverMode: Location obtained: ${currentPosition!.latitude}, ${currentPosition!.longitude}',
        );
        currentAddress = await LocationService.getAddressFromCoordinates(
          currentPosition!.latitude,
          currentPosition!.longitude,
        );
        print('DriverMode: Address obtained: $currentAddress');
      } else {
        print('DriverMode: Failed to get location - currentPosition is null');
        print('DriverMode: Using fallback location (Delhi, India)');
        // Use a fallback location to test if the map works
        currentPosition = Position(
          latitude: 28.6139,
          longitude: 77.2090,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
        currentAddress = 'Delhi, India (Fallback Location)';
        _showSnackBar(
          'Using fallback location. Please check permissions and GPS.',
          Colors.orange,
        );
      }
    } catch (e) {
      print('DriverMode: Error getting location: $e');
      _showSnackBar('Location error: $e', Colors.red);
    } finally {
      print('DriverMode: Location request completed');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _toggleOnlineStatus() async {
    if (!isOnline) {
      // Going online
      if (currentPosition != null) {
        await _updateLocationOnServer();
        _startLocationTracking();
        _startRidePolling();
      }
    } else {
      // Going offline
      _stopLocationTracking();
      _stopRidePolling();
    }

    setState(() {
      isOnline = !isOnline;
    });

    _showSnackBar(
      isOnline ? 'You are now online!' : 'You are now offline',
      isOnline ? Colors.green : Colors.grey,
    );
  }

  Future<void> _updateLocationOnServer() async {
    if (currentPosition == null) return;

    try {
      await ApiService.updateLocation(
        latitude: currentPosition!.latitude,
        longitude: currentPosition!.longitude,
      );
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  void _startLocationTracking() {
    _locationTimer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) => _updateLocationOnServer(),
    );
  }

  void _stopLocationTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  void _startRidePolling() {
    _loadAvailableRides();
    _ridesTimer = Timer.periodic(
      const Duration(seconds: 15),
      (timer) => _loadAvailableRides(),
    );
  }

  void _stopRidePolling() {
    _ridesTimer?.cancel();
    _ridesTimer = null;
    setState(() {
      availableRides = [];
    });
  }

  Future<void> _loadAvailableRides() async {
    if (!isOnline) return;

    try {
      final response = await ApiService.getAvailableRides();
      if (response['success']) {
        setState(() {
          availableRides = response['data'] ?? [];
        });
      }
    } catch (e) {
      print('Error loading available rides: $e');
    }
  }

  Future<void> _refreshDriverData() async {
    try {
      // Update location
      await _updateLocationOnServer();

      // Refresh available rides
      await _loadAvailableRides();

      _showSnackBar('Data refreshed successfully!', Colors.green);
    } catch (e) {
      _showSnackBar('Failed to refresh data: $e', Colors.red);
    }
  }

  Future<void> _acceptRide(int rideId) async {
    try {
      final response = await ApiService.acceptRide(rideId: rideId);
      if (response['success']) {
        _showSnackBar('Ride accepted successfully!', Colors.green);
        await _loadAvailableRides(); // Refresh the list

        // Navigate to ride details or tracking
        Navigator.pushNamed(context, '/ride-tracking', arguments: rideId);
      } else {
        _showSnackBar(
          'Failed to accept ride: ${response['message']}',
          Colors.red,
        );
      }
    } catch (e) {
      _showSnackBar('Error accepting ride: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildStatsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              title,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideRequestCard(Map<String, dynamic> ride) {
    final customer = ride['customer'];
    final pickupAddress = ride['pickup_address'] ?? 'Unknown pickup';
    final dropoffAddress = ride['dropoff_address'] ?? 'Unknown destination';
    final fare = ride['total_fare'] ?? 0;
    final distance = ride['distance'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  customer?['name']?.substring(0, 1)?.toUpperCase() ?? 'C',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer?['name'] ?? 'Customer',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Rating: ${customer?['rating']?.toString() ?? 'N/A'} ⭐',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '₨${fare.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.my_location, color: Colors.green, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pickupAddress,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.red, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dropoffAddress,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${distance.toStringAsFixed(1)} km',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => _acceptRide(ride['id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Accept'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      body: Column(
        children: [
          // Header with status
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              color: isOnline ? const Color(0xFF4CAF50) : Colors.grey[600],
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Text(
                        user?.name.substring(0, 1).toUpperCase() ?? 'D',
                        style: TextStyle(
                          color: isOnline
                              ? const Color(0xFF4CAF50)
                              : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Driver',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            isOnline
                                ? 'Online - ${availableRides.length} rides available'
                                : 'Offline',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isOnline,
                      onChanged: (_) => _toggleOnlineStatus(),
                      activeColor: Colors.white,
                      activeTrackColor: Colors.white.withOpacity(0.3),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Online/Offline button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _toggleOnlineStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: isOnline
                          ? const Color(0xFF4CAF50)
                          : Colors.grey[600],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isOnline ? 'GO OFFLINE' : 'GO ONLINE',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Available rides or map
          Expanded(
            flex: 3,
            child: isOnline && availableRides.isNotEmpty
                ? Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available Rides (${availableRides.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _refreshDriverData,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: availableRides.length,
                              itemBuilder: (context, index) {
                                return _buildRideRequestCard(
                                  availableRides[index],
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      currentPosition == null
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 16),
                                  Text('Loading map...'),
                                  SizedBox(height: 8),
                                  Text(
                                    'Getting your location...',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : FreeMapWidget(
                              currentPosition: currentPosition,
                              showCurrentLocation: true,
                            ),
                      if (isLoading)
                        Container(
                          color: Colors.black.withOpacity(0.3),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      if (isOnline && availableRides.isEmpty)
                        Positioned(
                          top: 20,
                          left: 20,
                          right: 20,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: const Text(
                              'You\'re online! Waiting for ride requests...',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),

          // Stats and actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Today\'s Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 16),

                // Stats grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.9,
                  children: [
                    _buildStatsCard(
                      'Rides',
                      '$todayRides',
                      Icons.local_taxi,
                      const Color(0xFF4CAF50),
                    ),
                    _buildStatsCard(
                      'Earnings',
                      '₨${todayEarnings.toStringAsFixed(0)}',
                      Icons.account_balance_wallet,
                      const Color(0xFFFF9800),
                    ),
                    _buildStatsCard(
                      'Rating',
                      rating.toString(),
                      Icons.star,
                      const Color(0xFFFFC107),
                    ),
                    _buildStatsCard(
                      'Total',
                      '$totalRides',
                      Icons.trending_up,
                      const Color(0xFF2196F3),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Quick actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/ride-history');
                        },
                        icon: const Icon(Icons.analytics),
                        label: const Text('Earnings'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/ride-history');
                        },
                        icon: const Icon(Icons.history),
                        label: const Text('History'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
