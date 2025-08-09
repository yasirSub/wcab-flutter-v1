import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class FreeMapWidget extends StatefulWidget {
  final Position? currentPosition;
  final List<Marker> markers;
  final Function(MapController)? onMapCreated;
  final bool showCurrentLocation;

  const FreeMapWidget({
    super.key,
    this.currentPosition,
    this.markers = const [],
    this.onMapCreated,
    this.showCurrentLocation = true,
  });

  @override
  State<FreeMapWidget> createState() => _FreeMapWidgetState();
}

class _FreeMapWidgetState extends State<FreeMapWidget> {
  late MapController mapController;

  @override
  void initState() {
    super.initState();
    print('FreeMapWidget: Initializing map controller');
    mapController = MapController();
    if (widget.onMapCreated != null) {
      widget.onMapCreated!(mapController);
    }
    print('FreeMapWidget: Map controller initialized');
  }

  @override
  Widget build(BuildContext context) {
    print('FreeMapWidget: Building map widget');
    // Default to Delhi, India if no position
    final center = widget.currentPosition != null
        ? LatLng(
            widget.currentPosition!.latitude,
            widget.currentPosition!.longitude,
          )
        : LatLng(28.6139, 77.2090); // Delhi, India

    print('FreeMapWidget: Map center: ${center.latitude}, ${center.longitude}');
    List<Marker> allMarkers = [...widget.markers];
    print('FreeMapWidget: Total markers: ${allMarkers.length}');

    // Add current location marker if available
    if (widget.currentPosition != null && widget.showCurrentLocation) {
      allMarkers.add(
        Marker(
          point: LatLng(
            widget.currentPosition!.latitude,
            widget.currentPosition!.longitude,
          ),
          child: Stack(
            children: [
              // Pulsing circle animation for current location
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
              // Main location pin
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.navigation,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              // Location label
              Positioned(
                top: 55,
                left: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'You are here',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    print('FreeMapWidget: Creating FlutterMap widget');
    return Stack(
      children: [
        // Main map widget
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 14.0,
            minZoom: 3.0,
            maxZoom: 18.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
            onMapReady: () {
              print('FreeMapWidget: Map is ready!');
            },
            onTap: (tapPosition, point) {
              print(
                'FreeMapWidget: Map tapped at ${point.latitude}, ${point.longitude}',
              );
            },
          ),
          children: [
            // Map Tiles (Free OpenStreetMap)
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.wcab',
              maxZoom: 18,
              maxNativeZoom: 19,
              additionalOptions: const {
                'attribution': '© OpenStreetMap contributors',
              },
              fallbackUrl: 'https://c.tile.openstreetmap.org/{z}/{x}/{y}.png',
              errorTileCallback: (tile, error, stackTrace) {
                print('FreeMapWidget: Tile load error: $error');
              },
            ),

            // Markers Layer
            if (allMarkers.isNotEmpty) MarkerLayer(markers: allMarkers),
          ],
        ),

        // Map Controls Overlay
        Positioned(
          top: 20,
          right: 20,
          child: Column(
            children: [
              // Center on location button
              if (widget.currentPosition != null)
                FloatingActionButton.small(
                  heroTag: "center_location",
                  onPressed: () {
                    if (widget.currentPosition != null) {
                      mapController.move(
                        LatLng(
                          widget.currentPosition!.latitude,
                          widget.currentPosition!.longitude,
                        ),
                        15.0,
                      );
                      print('FreeMapWidget: Centered on current location');
                    }
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.my_location, color: Colors.blue),
                ),
              const SizedBox(height: 10),
              // Zoom in button
              FloatingActionButton.small(
                heroTag: "zoom_in",
                onPressed: () {
                  final currentZoom = mapController.camera.zoom;
                  mapController.move(
                    mapController.camera.center,
                    currentZoom + 1,
                  );
                },
                backgroundColor: Colors.white,
                child: const Icon(Icons.add, color: Colors.blue),
              ),
              const SizedBox(height: 5),
              // Zoom out button
              FloatingActionButton.small(
                heroTag: "zoom_out",
                onPressed: () {
                  final currentZoom = mapController.camera.zoom;
                  mapController.move(
                    mapController.camera.center,
                    currentZoom - 1,
                  );
                },
                backgroundColor: Colors.white,
                child: const Icon(Icons.remove, color: Colors.blue),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Helper function to create custom markers
Marker createCustomMarker({
  required LatLng point,
  required String title,
  Color color = Colors.red,
  IconData icon = Icons.location_on,
}) {
  return Marker(
    point: point,
    child: GestureDetector(
      onTap: () {
        // You can add onTap functionality here
        print('Marker tapped: $title');
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Icon(icon, color: color, size: 32),
        ],
      ),
    ),
  );
}
