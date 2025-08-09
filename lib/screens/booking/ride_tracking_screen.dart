import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import '../../services/api_service.dart';

class RideTrackingScreen extends StatefulWidget {
  final int rideId;

  const RideTrackingScreen({super.key, required this.rideId});

  @override
  State<RideTrackingScreen> createState() => _RideTrackingScreenState();
}

class _RideTrackingScreenState extends State<RideTrackingScreen> {
  MapController? mapController;
  Timer? _trackingTimer;
  Map<String, dynamic>? rideData;
  bool isLoading = true;
  String rideStatus = 'pending';

  // Location data
  LatLng? pickupLocation;
  LatLng? dropoffLocation;
  LatLng? driverLocation;

  final Map<String, String> statusMessages = {
    'pending': 'Looking for a driver...',
    'accepted': 'Driver assigned! On the way to pickup',
    'started': 'Ride in progress',
    'completed': 'Ride completed',
    'cancelled': 'Ride cancelled',
  };

  final Map<String, Color> statusColors = {
    'pending': Colors.orange,
    'accepted': Colors.blue,
    'started': Colors.green,
    'completed': Colors.purple,
    'cancelled': Colors.red,
  };

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    super.dispose();
  }

  void _startTracking() {
    _updateRideData();
    // Update every 10 seconds
    _trackingTimer = Timer.periodic(
      const Duration(seconds: 10),
      (timer) => _updateRideData(),
    );
  }

  Future<void> _updateRideData() async {
    try {
      final response = await ApiService.trackRide(rideId: widget.rideId);

      if (response['success']) {
        setState(() {
          rideData = response['data'];
          isLoading = false;
          rideStatus = rideData!['ride']['status'];

          // Update locations
          pickupLocation = LatLng(
            rideData!['pickup']['latitude'],
            rideData!['pickup']['longitude'],
          );
          dropoffLocation = LatLng(
            rideData!['dropoff']['latitude'],
            rideData!['dropoff']['longitude'],
          );

          // Update driver location if available
          if (rideData!['driver_location'] != null) {
            driverLocation = LatLng(
              rideData!['driver_location']['latitude'],
              rideData!['driver_location']['longitude'],
            );
          }
        });

        // Stop tracking if ride is completed or cancelled
        if (rideStatus == 'completed' || rideStatus == 'cancelled') {
          _trackingTimer?.cancel();
        }
      }
    } catch (e) {
      print('Error tracking ride: $e');
    }
  }

  Future<void> _refreshTrackingData() async {
    await _updateRideData();
    _showSuccessSnackBar('Ride data refreshed!');
  }

  Future<void> _cancelRide() async {
    if (rideStatus != 'pending' && rideStatus != 'accepted') {
      _showErrorSnackBar('Cannot cancel ride at this stage');
      return;
    }

    final confirmed = await _showCancelConfirmation();
    if (!confirmed) return;

    try {
      final response = await ApiService.cancelRide(rideId: widget.rideId);

      if (response['success']) {
        setState(() {
          rideStatus = 'cancelled';
        });
        _showSuccessSnackBar('Ride cancelled successfully');
        _trackingTimer?.cancel();
      } else {
        _showErrorSnackBar('Failed to cancel ride: ${response['message']}');
      }
    } catch (e) {
      _showErrorSnackBar('Error cancelling ride: $e');
    }
  }

  Future<bool> _showCancelConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cancel Ride?'),
            content: const Text(
              'Are you sure you want to cancel this ride? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Yes, Cancel',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
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

    // Driver marker
    if (driverLocation != null) {
      markers.add(
        Marker(
          width: 80,
          height: 80,
          point: driverLocation!,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue,
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
                  Icons.directions_car,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Driver',
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

    return markers;
  }

  Widget _buildStatusCard() {
    if (rideData == null) return const SizedBox.shrink();

    final ride = rideData!['ride'];
    final statusColor = statusColors[rideStatus] ?? Colors.grey;
    final statusMessage = statusMessages[rideStatus] ?? 'Unknown status';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  rideStatus.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Ride #${ride['id']}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            statusMessage,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.payment, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Payment: ${ride['payment_method']?.toUpperCase() ?? 'N/A'}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const Spacer(),
              Text(
                '₨${ride['total_fare']?.toStringAsFixed(0) ?? '0'}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDriverInfo() {
    if (rideData == null || rideData!['ride']['driver'] == null) {
      return const SizedBox.shrink();
    }

    final driver = rideData!['ride']['driver'];
    final vehicle = rideData!['ride']['vehicle'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Driver Information',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  driver['name']?.substring(0, 1)?.toUpperCase() ?? 'D',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver['name'] ?? 'Driver',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (vehicle != null) ...[
                      Text(
                        '${vehicle['make']} ${vehicle['model']}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      Text(
                        'Color: ${vehicle['color']}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    onPressed: () {
                      // TODO: Implement call functionality
                      _showErrorSnackBar('Call feature coming soon!');
                    },
                    icon: const Icon(Icons.call, color: Colors.green),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.green.shade50,
                    ),
                  ),
                  const Text('Call', style: TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Ride'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (rideStatus == 'pending' || rideStatus == 'accepted')
            IconButton(
              onPressed: _cancelRide,
              icon: const Icon(Icons.cancel),
              tooltip: 'Cancel Ride',
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Map
                Expanded(
                  flex: 3,
                  child: FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter: pickupLocation ?? LatLng(28.6139, 77.2090),
                      initialZoom: 14.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.wcab',
                      ),
                      MarkerLayer(markers: _buildMarkers()),
                    ],
                  ),
                ),

                // Ride details
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: RefreshIndicator(
                      onRefresh: _refreshTrackingData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            _buildStatusCard(),
                            const SizedBox(height: 16),
                            _buildDriverInfo(),
                            const SizedBox(height: 16),

                            // Route information
                            if (rideData != null) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Route Details',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.my_location,
                                          color: Colors.green,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            rideData!['pickup']['address'],
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            rideData!['dropoff']['address'],
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
