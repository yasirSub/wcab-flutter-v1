import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'driver_profile_screen.dart';
import 'rider_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;

        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Route to appropriate profile based on user type
        final isDriver = user.isDriver == true;

        if (isDriver) {
          return const DriverProfileScreen();
        } else {
          return const RiderProfileScreen();
        }
      },
    );
  }
}
