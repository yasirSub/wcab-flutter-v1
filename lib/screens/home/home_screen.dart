import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/auth_provider.dart';
import '../../services/location_service.dart';
import '../../widgets/simple_map_widget.dart';
import '../welcome_screen.dart';
import '../booking/book_ride_screen.dart';
import '../booking/enhanced_booking_screen.dart';
import '../driver/driver_mode_screen.dart';
import '../history/ride_history_screen.dart';
import '../settings/settings_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeTab(),
    const RidesTab(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: user?.isDriver == true
            ? const Color(0xFF4CAF50)
            : const Color(0xFF2196F3),
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(
              user?.isDriver == true ? Icons.local_taxi : Icons.history,
            ),
            label: user?.isDriver == true ? 'Rides' : 'History',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  Position? currentPosition;
  bool isLoadingLocation = false;
  String currentAddress = 'Getting location...';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      isLoadingLocation = true;
    });

    try {
      currentPosition = await LocationService.getCurrentLocation();
      if (currentPosition != null) {
        currentAddress = await LocationService.getAddressFromCoordinates(
          currentPosition!.latitude,
          currentPosition!.longitude,
        );
      } else {
        // Use fallback location (Delhi, India)
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
        currentAddress = 'Delhi, India (Default Location)';
      }
    } catch (e) {
      print('Error getting location: $e');
      // Use fallback location
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
      currentAddress = 'Delhi, India (Default Location)';
    } finally {
      setState(() {
        isLoadingLocation = false;
      });
    }
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome back!',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
            ),
            Text(
              user?.name ?? 'User',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isDriver ? 'DRIVER' : 'CUSTOMER',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Stats Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDriver
                      ? [const Color(0xFF4CAF50), const Color(0xFF388E3C)]
                      : [const Color(0xFF2196F3), const Color(0xFF1976D2)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color:
                        (isDriver
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFF2196F3))
                            .withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isDriver ? Icons.local_taxi : Icons.location_on,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isDriver
                              ? 'Ready to earn today?'
                              : 'Where do you want to go?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (isDriver) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DriverModeScreen(),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const EnhancedBookingScreen(),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: isDriver
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFF2196F3),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isDriver ? 'Go Online' : 'Book a Ride',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 16),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: isDriver
                  ? [
                      _buildActionCard(
                        icon: Icons.directions_car,
                        title: 'My Vehicle',
                        subtitle: 'Manage vehicle info',
                        color: const Color(0xFF4CAF50),
                        onTap: () {},
                      ),
                      _buildActionCard(
                        icon: Icons.account_balance_wallet,
                        title: 'Earnings',
                        subtitle: 'View your earnings',
                        color: const Color(0xFFFF9800),
                        onTap: () {},
                      ),
                      _buildActionCard(
                        icon: Icons.star,
                        title: 'Ratings',
                        subtitle: 'Check your ratings',
                        color: const Color(0xFFFFC107),
                        onTap: () {},
                      ),
                      _buildActionCard(
                        icon: Icons.support_agent,
                        title: 'Support',
                        subtitle: 'Get help',
                        color: const Color(0xFF9C27B0),
                        onTap: () {},
                      ),
                    ]
                  : [
                      _buildActionCard(
                        icon: Icons.history,
                        title: 'Ride History',
                        subtitle: 'View past rides',
                        color: const Color(0xFF2196F3),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RideHistoryScreen(),
                            ),
                          );
                        },
                      ),
                      _buildActionCard(
                        icon: Icons.favorite,
                        title: 'Favorites',
                        subtitle: 'Saved locations',
                        color: const Color(0xFFE91E63),
                        onTap: () {},
                      ),
                      _buildActionCard(
                        icon: Icons.payment,
                        title: 'Payment',
                        subtitle: 'Manage payments',
                        color: const Color(0xFF4CAF50),
                        onTap: () {},
                      ),
                      _buildActionCard(
                        icon: Icons.support_agent,
                        title: 'Support',
                        subtitle: 'Get help',
                        color: const Color(0xFF9C27B0),
                        onTap: () {},
                      ),
                    ],
            ),

            const SizedBox(height: 24),

            // Live Map Section
            const Text(
              'Live Map',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: currentPosition == null
                  ? Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.blue[100]!, Colors.blue[50]!],
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.map, size: 48, color: Colors.blue[600]),
                            const SizedBox(height: 8),
                            Text(
                              isLoadingLocation
                                  ? 'Loading your location...'
                                  : 'Map will show your area',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (isLoadingLocation)
                              const Padding(
                                padding: EdgeInsets.only(top: 8.0),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    )
                  : Stack(
                      children: [
                        SimpleMapWidget(
                          currentPosition: currentPosition,
                          markers: isDriver
                              ? [
                                  MapMarker(
                                    position: const Offset(100, 80),
                                    title: 'You are here',
                                    color: Colors.green,
                                    icon: Icons.local_taxi,
                                  ),
                                ]
                              : [],
                          showCurrentLocation: true,
                        ),
                        // Overlay with current address
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
                              currentAddress,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        // Tap to expand overlay
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              // Navigate to full map screen
                              if (isDriver) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const DriverModeScreen(),
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const BookRideScreen(),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDriver
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFF2196F3),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.fullscreen,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 24),

            // Recent Activity
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Icon(
                    isDriver ? Icons.local_taxi : Icons.history,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isDriver ? 'No rides completed yet' : 'No ride history yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isDriver
                        ? 'Start accepting rides to see your activity'
                        : 'Book your first ride to see your history',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class RidesTab extends StatelessWidget {
  const RidesTab({super.key});

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
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RideHistoryScreen(),
                ),
              );
            },
            icon: const Icon(Icons.list),
            tooltip: 'View All',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
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
                isDriver ? 'No rides yet' : 'No ride history',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isDriver
                    ? 'Start accepting rides to see them here'
                    : 'Your completed rides will appear here',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RideHistoryScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDriver
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text('View History'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
