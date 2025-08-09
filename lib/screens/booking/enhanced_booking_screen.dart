import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../../services/location_service.dart';
import '../../services/api_service.dart';
import '../../services/routing_service.dart';

class EnhancedBookingScreen extends StatefulWidget {
  const EnhancedBookingScreen({super.key});

  @override
  State<EnhancedBookingScreen> createState() => _EnhancedBookingScreenState();
}

class _EnhancedBookingScreenState extends State<EnhancedBookingScreen> {
  MapController? mapController;
  Position? currentPosition;
  LatLng? pickupLocation;
  LatLng? dropoffLocation;
  String pickupAddress = 'Getting location...';
  String dropoffAddress = 'Select destination';
  bool isSelectingPickup = false;
  bool isSelectingDropoff = false;
  bool isLoading = false;
  bool isBookingRide = false;
  String selectedPaymentMethod = 'cash';

  // Fare estimation data
  Map<String, dynamic>? fareEstimate;

  // Route display
  List<LatLng> routePoints = [];
  bool showRoute = false;
  List<dynamic> nearbyDrivers = [];

  // UI Controllers
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();

  // Search functionality
  Timer? _searchTimer;
  bool isSearchingAddress = false;

  final List<Map<String, dynamic>> paymentMethods = [
    {'id': 'cash', 'name': 'Cash', 'icon': Icons.money},
    {'id': 'card', 'name': 'Card', 'icon': Icons.credit_card},
    {'id': 'wallet', 'name': 'Wallet', 'icon': Icons.account_balance_wallet},
  ];

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _notesController.dispose();
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => isLoading = true);
    try {
      currentPosition = await LocationService.getCurrentLocation();
      if (currentPosition != null) {
        pickupLocation = LatLng(
          currentPosition!.latitude,
          currentPosition!.longitude,
        );
        pickupAddress = await LocationService.getAddressFromCoordinates(
          currentPosition!.latitude,
          currentPosition!.longitude,
        );
        _pickupController.text = pickupAddress;

        // Get nearby drivers
        await _getNearbyDrivers();
      }
    } catch (e) {
      _showErrorSnackBar('Error getting location: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _getNearbyDrivers() async {
    if (pickupLocation == null) return;

    try {
      final response = await ApiService.getNearbyDrivers(
        latitude: pickupLocation!.latitude,
        longitude: pickupLocation!.longitude,
      );

      if (response['success']) {
        setState(() {
          nearbyDrivers = response['data']['drivers'] ?? [];
        });
      }
    } catch (e) {
      print('Error getting nearby drivers: $e');
    }
  }

  void _onMapTap(LatLng point) async {
    if (isSelectingPickup) {
      setState(() {
        pickupLocation = point;
        isSelectingPickup = false;
        isLoading = true;
      });

      pickupAddress = await LocationService.getAddressFromCoordinates(
        point.latitude,
        point.longitude,
      );
      _pickupController.text = pickupAddress;

      setState(() => isLoading = false);

      // Create route if dropoff is already set
      if (dropoffLocation != null) {
        await _createRoute();
      }
      await _getNearbyDrivers();
      await _estimateFare();
    } else if (isSelectingDropoff) {
      setState(() {
        dropoffLocation = point;
        isSelectingDropoff = false;
        isLoading = true;
      });

      dropoffAddress = await LocationService.getAddressFromCoordinates(
        point.latitude,
        point.longitude,
      );
      _dropoffController.text = dropoffAddress;

      setState(() => isLoading = false);

      // Create route when both locations are set
      if (pickupLocation != null) {
        await _createRoute();
      }

      await _estimateFare();
    }
  }

  Future<void> _estimateFare() async {
    if (pickupLocation == null || dropoffLocation == null) return;

    setState(() => isLoading = true);

    try {
      final response = await ApiService.estimateFare(
        pickupLatitude: pickupLocation!.latitude,
        pickupLongitude: pickupLocation!.longitude,
        dropoffLatitude: dropoffLocation!.latitude,
        dropoffLongitude: dropoffLocation!.longitude,
      );

      if (response['success']) {
        setState(() {
          fareEstimate = response['data'];
        });
      } else {
        _showErrorSnackBar('Failed to estimate fare: ${response['message']}');
      }
    } catch (e) {
      _showErrorSnackBar('Error estimating fare: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    // Show loading indicator
    setState(() => isLoading = true);

    try {
      // Refresh nearby drivers
      await _getNearbyDrivers();

      // Refresh fare estimate if both locations are set
      if (pickupLocation != null && dropoffLocation != null) {
        await _estimateFare();
      }

      _showSuccessSnackBar('Data refreshed successfully!');
    } catch (e) {
      _showErrorSnackBar('Failed to refresh data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _bookRide() async {
    // Validate locations
    if (pickupLocation == null || dropoffLocation == null) {
      _showErrorSnackBar('Please select both pickup and drop-off locations');
      return;
    }

    // Validate addresses are properly loaded
    if (pickupAddress.isEmpty ||
        pickupAddress == 'Getting location...' ||
        dropoffAddress.isEmpty ||
        dropoffAddress == 'Select destination') {
      _showErrorSnackBar('Please wait for addresses to load properly');
      return;
    }

    setState(() => isBookingRide = true);

    try {
      // Debug logging
      print('Booking ride with:');
      print('Pickup Address: $pickupAddress');
      print('Dropoff Address: $dropoffAddress');
      print(
        'Pickup Location: ${pickupLocation!.latitude}, ${pickupLocation!.longitude}',
      );
      print(
        'Dropoff Location: ${dropoffLocation!.latitude}, ${dropoffLocation!.longitude}',
      );

      final response = await ApiService.requestRide(
        pickupAddress: pickupAddress.trim(),
        pickupLatitude: pickupLocation!.latitude,
        pickupLongitude: pickupLocation!.longitude,
        dropoffAddress: dropoffAddress.trim(),
        dropoffLatitude: dropoffLocation!.latitude,
        dropoffLongitude: dropoffLocation!.longitude,
        notes: _notesController.text.isEmpty
            ? null
            : _notesController.text.trim(),
        paymentMethod: selectedPaymentMethod,
      );

      if (response['success']) {
        _showSuccessDialog(response['data']);
      } else {
        _showErrorSnackBar('Failed to book ride: ${response['message']}');
      }
    } catch (e) {
      _showErrorSnackBar('Error booking ride: $e');
    } finally {
      setState(() => isBookingRide = false);
    }
  }

  void _showSuccessDialog(Map<String, dynamic> rideData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Ride Booked Successfully!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ride ID: #${rideData['ride']['id']}'),
            SizedBox(height: 8),
            Text('Estimated Fare: ₨${rideData['estimated_fare']}'),
            SizedBox(height: 8),
            Text('Nearby Drivers: ${rideData['nearby_drivers']}'),
            SizedBox(height: 8),
            Text('Estimated Wait: ${rideData['estimated_wait_time']}'),
            SizedBox(height: 16),
            Text(
              'A driver will be assigned shortly. You will be notified once a driver accepts your ride.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to main screen
            },
            child: Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _goToRideTracking(rideData['ride']['id']);
            },
            child: Text('Track Ride'),
          ),
        ],
      ),
    );
  }

  void _goToRideTracking(int rideId) {
    // Navigate to ride tracking screen
    Navigator.pushNamed(context, '/ride-tracking', arguments: rideId);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _createRoute() async {
    if (pickupLocation != null && dropoffLocation != null) {
      setState(() {
        isLoading = true;
      });

      try {
        print(
          'Creating route from ${pickupLocation!.latitude},${pickupLocation!.longitude} to ${dropoffLocation!.latitude},${dropoffLocation!.longitude}',
        );

        // Get actual road route using routing service
        final routeCoordinates = await RoutingService.getRoute(
          startLat: pickupLocation!.latitude,
          startLng: pickupLocation!.longitude,
          endLat: dropoffLocation!.latitude,
          endLng: dropoffLocation!.longitude,
        );

        setState(() {
          routePoints = routeCoordinates;
          showRoute = true;
          isLoading = false;
        });

        print('Route created with ${routePoints.length} points');

        // Fit camera to show the entire route with padding
        _fitCameraToRoute();
      } catch (e) {
        print('Error creating route: $e');

        // Fallback to straight line
        setState(() {
          routePoints = [pickupLocation!, dropoffLocation!];
          showRoute = true;
          isLoading = false;
        });

        _fitCameraToRoute();
      }
    }
  }

  void _fitCameraToRoute() {
    if (pickupLocation != null &&
        dropoffLocation != null &&
        mapController != null) {
      // Calculate bounds
      double minLat = pickupLocation!.latitude < dropoffLocation!.latitude
          ? pickupLocation!.latitude
          : dropoffLocation!.latitude;
      double maxLat = pickupLocation!.latitude > dropoffLocation!.latitude
          ? pickupLocation!.latitude
          : dropoffLocation!.latitude;
      double minLng = pickupLocation!.longitude < dropoffLocation!.longitude
          ? pickupLocation!.longitude
          : dropoffLocation!.longitude;
      double maxLng = pickupLocation!.longitude > dropoffLocation!.longitude
          ? pickupLocation!.longitude
          : dropoffLocation!.longitude;

      // Add padding
      double latPadding = (maxLat - minLat) * 0.2;
      double lngPadding = (maxLng - minLng) * 0.2;

      // Ensure minimum padding
      if (latPadding < 0.01) latPadding = 0.01;
      if (lngPadding < 0.01) lngPadding = 0.01;

      LatLngBounds bounds = LatLngBounds(
        LatLng(minLat - latPadding, minLng - lngPadding),
        LatLng(maxLat + latPadding, maxLng + lngPadding),
      );

      mapController!.fitCamera(CameraFit.bounds(bounds: bounds));
    }
  }

  // Search address and update map
  Future<void> _searchAddress(String address, bool isPickup) async {
    if (address.trim().isEmpty ||
        address == 'Getting location...' ||
        address == 'Select destination') {
      return;
    }

    setState(() => isSearchingAddress = true);

    try {
      final position = await LocationService.getCoordinatesFromAddress(
        address.trim(),
      );

      if (position != null) {
        final location = LatLng(position.latitude, position.longitude);

        setState(() {
          if (isPickup) {
            pickupLocation = location;
            pickupAddress = address;
          } else {
            dropoffLocation = location;
            dropoffAddress = address;
          }
        });

        // Move camera to the new location
        if (mapController != null) {
          mapController!.move(location, 15.0);
        }

        // Create route if both locations are set
        if (pickupLocation != null && dropoffLocation != null) {
          await _createRoute();
          await _estimateFare();
        }

        // Get nearby drivers if pickup location is set
        if (isPickup) {
          await _getNearbyDrivers();
        }
      } else {
        _showErrorSnackBar(
          'Address not found. Please try a different address.',
        );
      }
    } catch (e) {
      _showErrorSnackBar('Error searching address: $e');
    } finally {
      setState(() => isSearchingAddress = false);
    }
  }

  // Debounced search - waits for user to stop typing
  void _onAddressChanged(String value, bool isPickup) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 1500), () {
      if (value.trim().length > 3) {
        _searchAddress(value, isPickup);
      }
    });
  }

  List<Marker> _buildMarkers() {
    List<Marker> markers = [];

    // Pickup marker
    if (pickupLocation != null) {
      markers.add(
        Marker(
          width: 80,
          height: 80,
          point: pickupLocation!,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.my_location,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Pickup',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Dropoff marker
    if (dropoffLocation != null) {
      markers.add(
        Marker(
          width: 80,
          height: 80,
          point: dropoffLocation!,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Drop-off',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Nearby drivers markers
    for (var driver in nearbyDrivers) {
      if (driver['vehicle'] != null) {
        markers.add(
          Marker(
            width: 60,
            height: 60,
            point: LatLng(
              driver['vehicle']['current_latitude'] ?? 0.0,
              driver['vehicle']['current_longitude'] ?? 0.0,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.directions_car,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        );
      }
    }

    return markers;
  }

  Widget _buildLocationInput({
    required String title,
    required String address,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
    required TextEditingController controller,
  }) {
    bool isPickup = title.contains('Pickup');

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.05),
      ),
      child: Row(
        children: [
          // Location icon and map tap button
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Icon(icon, color: color, size: 24),
            ),
          ),
          // Address text field
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: isPickup
                        ? 'Enter pickup location'
                        : 'Enter destination',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.only(bottom: 8),
                    suffixIcon: isSearchingAddress
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  onChanged: (value) => _onAddressChanged(value, isPickup),
                  textInputAction: TextInputAction.search,
                ),
              ],
            ),
          ),
          // Map selection button
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Icon(Icons.map, color: color, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: paymentMethods.map((method) {
            final isSelected = selectedPaymentMethod == method['id'];
            return Expanded(
              child: GestureDetector(
                onTap: () =>
                    setState(() => selectedPaymentMethod = method['id']),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        method['icon'],
                        color: isSelected ? Colors.white : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        method['name'],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFareEstimate() {
    if (fareEstimate == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estimated Fare',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Text(
                    '₨${fareEstimate!['total_fare']?.toStringAsFixed(0) ?? '0'}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Distance',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Text(
                    '${fareEstimate!['distance']?.toStringAsFixed(1) ?? '0'} km',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Duration',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Text(
                    '${fareEstimate!['estimated_duration'] ?? '0'} min',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (nearbyDrivers.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${nearbyDrivers.length} drivers nearby',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Ride'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Map Section
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                // Interactive Map
                FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: pickupLocation ?? LatLng(28.6139, 77.2090),
                    initialZoom: 14.0,
                    onTap: (tapPosition, point) => _onMapTap(point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.wcab',
                    ),
                    // Route polyline
                    if (showRoute && routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          // Background (border) line
                          Polyline(
                            points: routePoints,
                            strokeWidth: 8.0,
                            color: Colors.black.withOpacity(0.3),
                          ),
                          // Main route line
                          Polyline(
                            points: routePoints,
                            strokeWidth: 5.0,
                            color: const Color(0xFF1976D2),
                            gradientColors: [
                              const Color(0xFF2196F3),
                              const Color(0xFF1976D2),
                              const Color(0xFF0D47A1),
                            ],
                          ),
                        ],
                      ),
                    MarkerLayer(markers: _buildMarkers()),
                  ],
                ),

                // Route loading indicator
                if (isLoading &&
                    pickupLocation != null &&
                    dropoffLocation != null)
                  Positioned(
                    top: 20,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Finding best route...',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Map instructions overlay
                if (isSelectingPickup || isSelectingDropoff)
                  Positioned(
                    top: 20,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        isSelectingPickup
                            ? 'Tap on the map to select pickup location'
                            : 'Tap on the map to select drop-off location',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                // Loading overlay
                if (isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),

          // Booking Details Section
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: RefreshIndicator(
                onRefresh: _refreshData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location inputs
                      _buildLocationInput(
                        title: 'Pickup Location',
                        address: pickupAddress,
                        color: Colors.green,
                        icon: Icons.my_location,
                        onTap: () => setState(() => isSelectingPickup = true),
                        controller: _pickupController,
                      ),
                      const SizedBox(height: 12),
                      _buildLocationInput(
                        title: 'Drop-off Location',
                        address: dropoffAddress,
                        color: Colors.red,
                        icon: Icons.location_on,
                        onTap: () => setState(() => isSelectingDropoff = true),
                        controller: _dropoffController,
                      ),

                      const SizedBox(height: 16),

                      // Fare estimate
                      _buildFareEstimate(),

                      const SizedBox(height: 16),

                      // Payment method
                      _buildPaymentMethodSelector(),

                      const SizedBox(height: 16),

                      // Notes
                      TextField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          labelText: 'Special Instructions (Optional)',
                          hintText: 'Any special requests or instructions...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.note),
                        ),
                        maxLines: 2,
                      ),

                      const SizedBox(height: 20),

                      // Book ride button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed:
                              (pickupLocation == null ||
                                  dropoffLocation == null ||
                                  isBookingRide)
                              ? null
                              : _bookRide,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            elevation: 8,
                          ),
                          child: isBookingRide
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Booking Ride...'),
                                  ],
                                )
                              : Text(
                                  fareEstimate != null
                                      ? 'Book Ride - ₨${fareEstimate!['total_fare']?.toStringAsFixed(0) ?? '0'}'
                                      : 'Book Ride',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
