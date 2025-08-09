import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/booking/enhanced_booking_screen.dart';
import 'screens/booking/ride_tracking_screen.dart';
import 'screens/history/ride_history_screen.dart';

void main() {
  runApp(const WCabApp());
}

class WCabApp extends StatelessWidget {
  const WCabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'WCab',
            debugShowCheckedModeBanner: false,
            theme: ThemeProvider.lightTheme,
            darkTheme: ThemeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const AuthWrapper(),
            routes: {
              '/enhanced-booking': (context) => const EnhancedBookingScreen(),
              '/ride-history': (context) => const RideHistoryScreen(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == '/ride-tracking') {
                final rideId = settings.arguments as int;
                return MaterialPageRoute(
                  builder: (context) => RideTrackingScreen(rideId: rideId),
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    // Initialize both auth and theme
    await Future.wait([
      authProvider.checkAuthStatus(),
      themeProvider.initializeTheme(),
    ]);

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_taxi, size: 80, color: Color(0xFF2196F3)),
              SizedBox(height: 20),
              Text(
                'WCab',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2196F3),
                ),
              ),
              SizedBox(height: 40),
              CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isAuthenticated) {
          return const HomeScreen();
        } else {
          return const WelcomeScreen();
        }
      },
    );
  }
}
