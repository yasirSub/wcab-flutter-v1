import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class SimpleMapWidget extends StatefulWidget {
  final Position? currentPosition;
  final List<MapMarker> markers;
  final bool showCurrentLocation;

  const SimpleMapWidget({
    super.key,
    this.currentPosition,
    this.markers = const [],
    this.showCurrentLocation = true,
  });

  @override
  State<SimpleMapWidget> createState() => _SimpleMapWidgetState();
}

class _SimpleMapWidgetState extends State<SimpleMapWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[100]!, Colors.green[100]!],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Background pattern to simulate map
          CustomPaint(painter: MapPatternPainter(), size: Size.infinite),

          // Current location indicator
          if (widget.currentPosition != null && widget.showCurrentLocation)
            Positioned(
              left: 50,
              top: 50,
              child: Container(
                width: 20,
                height: 20,
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
                  Icons.my_location,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),

          // Custom markers
          ...widget.markers.map(
            (marker) => Positioned(
              left: marker.position.dx,
              top: marker.position.dy,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      marker.title,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Icon(marker.icon, color: marker.color, size: 24),
                ],
              ),
            ),
          ),

          // Location info overlay
          if (widget.currentPosition != null)
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Lat: ${widget.currentPosition!.latitude.toStringAsFixed(4)}, '
                  'Lng: ${widget.currentPosition!.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // Map placeholder text
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map, size: 48, color: Colors.blue[600]),
                  const SizedBox(height: 8),
                  Text(
                    'Interactive Map',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.currentPosition != null
                        ? 'Location: ${widget.currentPosition!.latitude.toStringAsFixed(2)}, ${widget.currentPosition!.longitude.toStringAsFixed(2)}'
                        : 'Getting location...',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for map-like background
class MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;

    // Draw grid lines to simulate map streets
    for (double i = 0; i < size.width; i += 30) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    for (double i = 0; i < size.height; i += 30) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // Draw some random "roads"
    paint.color = Colors.grey.withOpacity(0.4);
    paint.strokeWidth = 2;

    canvas.drawLine(
      Offset(size.width * 0.2, 0),
      Offset(size.width * 0.8, size.height),
      paint,
    );

    canvas.drawLine(
      Offset(0, size.height * 0.3),
      Offset(size.width, size.height * 0.7),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Simple marker class
class MapMarker {
  final Offset position;
  final String title;
  final Color color;
  final IconData icon;

  const MapMarker({
    required this.position,
    required this.title,
    this.color = Colors.red,
    this.icon = Icons.location_on,
  });
}
