import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  List<Map<String, dynamic>> rides = [];
  bool isLoading = true;
  String selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadRideHistory();
  }

  Future<void> _loadRideHistory() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiService.getRideHistory();

      if (response['success']) {
        final rideData = response['data'];

        // Convert API response to local format
        rides =
            (rideData['data'] as List?)?.map<Map<String, dynamic>>((ride) {
              return {
                'id': ride['id']?.toString() ?? '',
                'date':
                    DateTime.tryParse(ride['created_at'] ?? '') ??
                    DateTime.now(),
                'pickup': ride['pickup_address'] ?? 'Unknown pickup',
                'destination': ride['dropoff_address'] ?? 'Unknown destination',
                'fare':
                    double.tryParse(ride['total_fare']?.toString() ?? '0') ??
                    0.0,
                'status': ride['status'] ?? 'unknown',
                'driver': ride['driver']?['name'] ?? 'Unknown driver',
                'vehicle': ride['vehicle'] != null
                    ? '${ride['vehicle']['make']} ${ride['vehicle']['model']} - ${ride['vehicle']['license_plate'] ?? 'N/A'}'
                    : 'Unknown vehicle',
                'rating':
                    double.tryParse(ride['rating']?.toString() ?? '0') ?? 0.0,
                'duration': ride['duration'] ?? 0,
                'distance':
                    double.tryParse(ride['distance']?.toString() ?? '0') ?? 0.0,
              };
            }).toList() ??
            [];
      } else {
        // Fallback to mock data if API fails
        _loadMockData();
      }
    } catch (e) {
      print('Error loading ride history: $e');
      // Fallback to mock data on error
      _loadMockData();
    }

    setState(() {
      isLoading = false;
    });
  }

  void _loadMockData() {
    // Mock data fallback
    rides = [
      {
        'id': '1',
        'date': DateTime.now().subtract(const Duration(days: 1)),
        'pickup': '123 Main Street, Downtown',
        'destination': '456 Oak Avenue, Uptown',
        'fare': 25.50,
        'status': 'completed',
        'driver': 'John Smith',
        'vehicle': 'Toyota Camry - ABC123',
        'rating': 4.8,
        'duration': 25,
        'distance': 12.3,
      },
      {
        'id': '2',
        'date': DateTime.now().subtract(const Duration(days: 3)),
        'pickup': '789 Pine Street, Midtown',
        'destination': '321 Elm Road, Suburbs',
        'fare': 18.75,
        'status': 'completed',
        'driver': 'Sarah Johnson',
        'vehicle': 'Honda Civic - XYZ789',
        'rating': 5.0,
        'duration': 18,
        'distance': 8.7,
      },
      {
        'id': '3',
        'date': DateTime.now().subtract(const Duration(days: 7)),
        'pickup': '555 Broadway, Theater District',
        'destination': '777 Park Avenue, Upper East',
        'fare': 32.25,
        'status': 'completed',
        'driver': 'Mike Wilson',
        'vehicle': 'Ford Focus - DEF456',
        'rating': 4.5,
        'duration': 35,
        'distance': 15.2,
      },
    ];
  }

  List<Map<String, dynamic>> get filteredRides {
    if (selectedFilter == 'all') return rides;
    return rides.where((ride) => ride['status'] == selectedFilter).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'ongoing':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'ongoing':
        return Icons.directions_car;
      default:
        return Icons.help;
    }
  }

  Widget _buildFilterChips() {
    final filters = [
      {'key': 'all', 'label': 'All'},
      {'key': 'completed', 'label': 'Completed'},
      {'key': 'cancelled', 'label': 'Cancelled'},
    ];

    return Container(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter['key'];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter['label']!),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  selectedFilter = filter['key']!;
                });
              },
              selectedColor: const Color(0xFF2196F3).withOpacity(0.2),
              checkmarkColor: const Color(0xFF2196F3),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRideCard(Map<String, dynamic> ride) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isDriver = authProvider.user?.isDriver == true;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showRideDetails(ride),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status and date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(ride['status']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(ride['status']),
                          size: 16,
                          color: _getStatusColor(ride['status']),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ride['status'].toString().toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(ride['status']),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    DateFormat('MMM dd, yyyy').format(ride['date']),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Pickup location
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ride['pickup'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              // Dotted line
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const SizedBox(width: 4),
                    Container(
                      width: 1,
                      height: 20,
                      child: CustomPaint(painter: DottedLinePainter()),
                    ),
                    const SizedBox(width: 11),
                  ],
                ),
              ),

              // Destination
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ride['destination'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Bottom info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (ride['status'] == 'completed') ...[
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          ride['rating'].toString(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${ride['distance']} km • ${ride['duration']} min',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ] else ...[
                    Text(
                      isDriver
                          ? 'Customer: ${ride['customer'] ?? 'N/A'}'
                          : 'Driver: ${ride['driver']}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                  Text(
                    ride['status'] == 'cancelled'
                        ? 'Cancelled'
                        : '\$${ride['fare'].toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ride['status'] == 'cancelled'
                          ? Colors.red
                          : const Color(0xFF2196F3),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRideDetails(Map<String, dynamic> ride) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RideDetailsModal(ride: ride),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isDriver = user?.isDriver == true;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDriver
            ? const Color(0xFF4CAF50)
            : const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        title: Text(isDriver ? 'My Rides' : 'Ride History'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilterChips(),
                Expanded(
                  child: filteredRides.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isDriver ? Icons.local_taxi : Icons.history,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'No rides found',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                selectedFilter == 'all'
                                    ? 'Your ride history will appear here'
                                    : 'No ${selectedFilter} rides found',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadRideHistory,
                          child: ListView.builder(
                            itemCount: filteredRides.length,
                            itemBuilder: (context, index) {
                              return _buildRideCard(filteredRides[index]);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1;

    const dashHeight = 2.0;
    const dashSpace = 2.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RideDetailsModal extends StatelessWidget {
  final Map<String, dynamic> ride;

  const RideDetailsModal({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Title
                Text(
                  'Ride Details',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 24),

                // Ride info
                _buildDetailRow(
                  'Date',
                  DateFormat('MMM dd, yyyy • hh:mm a').format(ride['date']),
                ),
                _buildDetailRow(
                  'Status',
                  ride['status'].toString().toUpperCase(),
                ),
                _buildDetailRow('Pickup', ride['pickup']),
                _buildDetailRow('Destination', ride['destination']),

                if (ride['status'] == 'completed') ...[
                  _buildDetailRow('Driver', ride['driver']),
                  _buildDetailRow('Vehicle', ride['vehicle']),
                  _buildDetailRow('Distance', '${ride['distance']} km'),
                  _buildDetailRow('Duration', '${ride['duration']} minutes'),
                  _buildDetailRow('Rating', '${ride['rating']} ⭐'),
                ],

                _buildDetailRow(
                  'Fare',
                  ride['status'] == 'cancelled'
                      ? 'Cancelled'
                      : '\$${ride['fare'].toStringAsFixed(2)}',
                ),

                const SizedBox(height: 32),

                // Actions
                if (ride['status'] == 'completed') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Book again functionality
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Book again feature coming soon!'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Book Again'),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        // TODO: Get receipt functionality
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Receipt feature coming soon!'),
                          ),
                        );
                      },
                      child: const Text('Get Receipt'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
