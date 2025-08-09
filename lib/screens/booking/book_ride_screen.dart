import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:geolocator/geolocator.dart';
import '../../services/location_service.dart';
import '../../services/api_service.dart';
import '../../widgets/simple_map_widget.dart';
import '../../widgets/free_map_widget.dart';

class BookRideScreen extends StatefulWidget {
  const BookRideScreen({super.key});

  @override
  State<BookRideScreen> createState() => _BookRideScreenState();
}

class _BookRideScreenState extends State<BookRideScreen> {
  gmaps.GoogleMapController? mapController;
  Position? currentPosition;
  String currentAddress = 'Getting location...';
  String destinationAddress = '';
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _pickupController = TextEditingController();

  Set<gmaps.Marker> markers = {}; // Google Maps markers
  bool isLoading = false;
  String selectedVehicleType = 'standard';
  double estimatedFare = 0.0;
  int estimatedTime = 0;
  bool useFreeMap = true; // Toggle between Google Maps and free map
  bool forceShowFreeMap = true; // Always show free map immediately

  final Map<String, Map<String, dynamic>> vehicleTypes = {
    'standard': {
      'name': 'Standard',
      'icon': Icons.directions_car,
      'pricePerKm': 2.5,
      'basePrice': 5.0,
    },
    'premium': {
      'name': 'Premium',
      'icon': Icons.local_taxi,
      'pricePerKm': 4.0,
      'basePrice': 8.0,
    },
    'suv': {
      'name': 'SUV',
      'icon': Icons.airport_shuttle,
      'pricePerKm': 5.5,
      'basePrice': 12.0,
    },
  };

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _pickupController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      isLoading = true;
    });

    try {
      currentPosition = await LocationService.getCurrentLocation();
      if (currentPosition != null) {
        currentAddress = await LocationService.getAddressFromCoordinates(
          currentPosition!.latitude,
          currentPosition!.longitude,
        );
        _pickupController.text = currentAddress;

        _addMarker(
          'pickup',
          currentPosition!.latitude,
          currentPosition!.longitude,
          'Pickup Location',
          gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueGreen,
          ),
        );
      }
    } catch (e) {
      print('Error getting location: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _addMarker(
    String id,
    double lat,
    double lng,
    String title,
    gmaps.BitmapDescriptor icon,
  ) {
    setState(() {
      markers.add(
        gmaps.Marker(
          markerId: gmaps.MarkerId(id),
          position: gmaps.LatLng(lat, lng),
          infoWindow: gmaps.InfoWindow(title: title),
          icon: icon,
        ),
      );
    });
  }

  Future<void> _searchDestination() async {
    if (_destinationController.text.isEmpty) return;

    setState(() {
      isLoading = true;
    });

    try {
      final destPosition = await LocationService.getCoordinatesFromAddress(
        _destinationController.text,
      );

      if (destPosition != null) {
        _addMarker(
          'destination',
          destPosition.latitude,
          destPosition.longitude,
          'Destination',
          gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueRed,
          ),
        );

        // Calculate fare and time
        if (currentPosition != null) {
          final distance =
              LocationService.calculateDistance(
                currentPosition!.latitude,
                currentPosition!.longitude,
                destPosition.latitude,
                destPosition.longitude,
              ) /
              1000; // Convert to km

          final vehicleData = vehicleTypes[selectedVehicleType]!;
          estimatedFare =
              vehicleData['basePrice'] + (distance * vehicleData['pricePerKm']);
          estimatedTime = (distance * 2)
              .round(); // Rough estimate: 2 minutes per km
        }

        // Move camera to show both markers (Google Maps only)
        if (mapController != null && !useFreeMap) {
          final bounds = gmaps.LatLngBounds(
            southwest: gmaps.LatLng(
              currentPosition!.latitude < destPosition.latitude
                  ? currentPosition!.latitude
                  : destPosition.latitude,
              currentPosition!.longitude < destPosition.longitude
                  ? currentPosition!.longitude
                  : destPosition.longitude,
            ),
            northeast: gmaps.LatLng(
              currentPosition!.latitude > destPosition.latitude
                  ? currentPosition!.latitude
                  : destPosition.latitude,
              currentPosition!.longitude > destPosition.longitude
                  ? currentPosition!.longitude
                  : destPosition.longitude,
            ),
          );

          mapController!.animateCamera(
            gmaps.CameraUpdate.newLatLngBounds(bounds, 100),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error finding destination: $e')));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildVehicleSelector() {
    return Container(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: vehicleTypes.length,
        itemBuilder: (context, index) {
          final key = vehicleTypes.keys.elementAt(index);
          final vehicle = vehicleTypes[key]!;
          final isSelected = selectedVehicleType == key;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedVehicleType = key;
                // Recalculate fare if destination is set
                if (_destinationController.text.isNotEmpty &&
                    currentPosition != null) {
                  _searchDestination();
                }
              });
            },
            child: Container(
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2196F3) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2196F3)
                      : Colors.grey[300]!,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    vehicle['icon'],
                    color: isSelected ? Colors.white : Colors.grey[600],
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    vehicle['name'],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        title: const Text('Book a Ride'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Map
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                FreeMapWidget(
                  currentPosition: currentPosition,
                  showCurrentLocation: true,
                ),
                if (isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),

          // Booking Details
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location inputs
                    TextField(
                      controller: _pickupController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.my_location,
                          color: Colors.green,
                        ),
                        hintText: 'Pickup location',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      readOnly: true,
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: _destinationController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                        ),
                        hintText: 'Where to?',
                        suffixIcon: IconButton(
                          onPressed: _searchDestination,
                          icon: const Icon(Icons.search),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      onSubmitted: (_) => _searchDestination(),
                    ),

                    const SizedBox(height: 20),

                    // Vehicle selector
                    const Text(
                      'Choose Vehicle',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildVehicleSelector(),

                    const SizedBox(height: 20),

                    // Fare and time estimate
                    if (estimatedFare > 0) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Estimated Fare',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '\$${estimatedFare.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2196F3),
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Estimated Time',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '${estimatedTime} min',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Book ride button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed:
                            (_destinationController.text.isEmpty || isLoading)
                            ? null
                            : () {
                                // Navigate to enhanced booking screen
                                Navigator.pushNamed(
                                  context,
                                  '/enhanced-booking',
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 8,
                        ),
                        child: Text(
                          estimatedFare > 0
                              ? 'Book Ride - \$${estimatedFare.toStringAsFixed(2)}'
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
        ],
      ),
    );
  }
}
