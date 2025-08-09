import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Notification settings
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;

  // Ride notifications
  bool _rideRequests = true;
  bool _rideUpdates = true;
  bool _driverArrival = true;
  bool _tripStarted = true;
  bool _tripCompleted = true;

  // Promotional notifications
  bool _offers = true;
  bool _newFeatures = false;
  bool _newsletters = false;

  // Driver-specific notifications
  bool _newRideRequests = true;
  bool _passengerUpdates = true;
  bool _earningsUpdates = true;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.getNotificationSettings();

      if (result['success'] && result['data'] != null) {
        final settings = result['data'];
        setState(() {
          _pushNotifications = settings['push_notifications'] ?? true;
          _emailNotifications = settings['email_notifications'] ?? true;
          _smsNotifications = settings['sms_notifications'] ?? false;
          _rideRequests = settings['ride_requests'] ?? true;
          _rideUpdates = settings['ride_updates'] ?? true;
          _driverArrival = settings['driver_arrival'] ?? true;
          _tripStarted = settings['trip_started'] ?? true;
          _tripCompleted = settings['trip_completed'] ?? true;
          _offers = settings['offers'] ?? true;
          _newFeatures = settings['new_features'] ?? false;
          _newsletters = settings['newsletters'] ?? false;
          _newRideRequests = settings['new_ride_requests'] ?? true;
          _passengerUpdates = settings['passenger_updates'] ?? true;
          _earningsUpdates = settings['earnings_updates'] ?? true;
        });
      }
    } catch (e) {
      print('Failed to load notification settings: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveNotificationSettings() async {
    setState(() => _isLoading = true);

    try {
      final settings = {
        'push_notifications': _pushNotifications,
        'email_notifications': _emailNotifications,
        'sms_notifications': _smsNotifications,
        'ride_requests': _rideRequests,
        'ride_updates': _rideUpdates,
        'driver_arrival': _driverArrival,
        'trip_started': _tripStarted,
        'trip_completed': _tripCompleted,
        'new_ride_requests': _newRideRequests,
        'passenger_updates': _passengerUpdates,
        'earnings_updates': _earningsUpdates,
        'offers': _offers,
        'new_features': _newFeatures,
        'newsletters': _newsletters,
      };

      final result = await ApiService.updateNotificationSettings(
        settings: settings,
      );

      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification preferences saved!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to save preferences'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save preferences: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isDriver = user?.isDriver == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: isDriver
            ? const Color(0xFF4CAF50)
            : const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveNotificationSettings,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // General Notification Methods
                  _buildNotificationSection(
                    'Notification Methods',
                    'Choose how you want to receive notifications',
                    [
                      _buildSwitchTile(
                        icon: Icons.notifications,
                        title: 'Push Notifications',
                        subtitle: 'Receive notifications on your device',
                        value: _pushNotifications,
                        onChanged: (value) {
                          setState(() => _pushNotifications = value);
                        },
                      ),
                      _buildSwitchTile(
                        icon: Icons.email,
                        title: 'Email Notifications',
                        subtitle: 'Receive notifications via email',
                        value: _emailNotifications,
                        onChanged: (value) {
                          setState(() => _emailNotifications = value);
                        },
                      ),
                      _buildSwitchTile(
                        icon: Icons.sms,
                        title: 'SMS Notifications',
                        subtitle: 'Receive notifications via SMS',
                        value: _smsNotifications,
                        onChanged: (value) {
                          setState(() => _smsNotifications = value);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Ride Notifications (for customers) or Driver Notifications
                  if (isDriver)
                    _buildNotificationSection(
                      'Driver Notifications',
                      'Manage notifications related to your driving',
                      [
                        _buildSwitchTile(
                          icon: Icons.directions_car,
                          title: 'New Ride Requests',
                          subtitle: 'Get notified when new rides are available',
                          value: _newRideRequests,
                          onChanged: (value) {
                            setState(() => _newRideRequests = value);
                          },
                        ),
                        _buildSwitchTile(
                          icon: Icons.person,
                          title: 'Passenger Updates',
                          subtitle: 'Updates about your current passengers',
                          value: _passengerUpdates,
                          onChanged: (value) {
                            setState(() => _passengerUpdates = value);
                          },
                        ),
                        _buildSwitchTile(
                          icon: Icons.account_balance_wallet,
                          title: 'Earnings Updates',
                          subtitle: 'Daily and weekly earnings summaries',
                          value: _earningsUpdates,
                          onChanged: (value) {
                            setState(() => _earningsUpdates = value);
                          },
                        ),
                      ],
                    )
                  else
                    _buildNotificationSection(
                      'Ride Notifications',
                      'Stay updated about your rides and bookings',
                      [
                        _buildSwitchTile(
                          icon: Icons.local_taxi,
                          title: 'Ride Requests',
                          subtitle: 'Confirmation of your ride bookings',
                          value: _rideRequests,
                          onChanged: (value) {
                            setState(() => _rideRequests = value);
                          },
                        ),
                        _buildSwitchTile(
                          icon: Icons.update,
                          title: 'Ride Updates',
                          subtitle: 'Status updates for your rides',
                          value: _rideUpdates,
                          onChanged: (value) {
                            setState(() => _rideUpdates = value);
                          },
                        ),
                        _buildSwitchTile(
                          icon: Icons.location_on,
                          title: 'Driver Arrival',
                          subtitle: 'When your driver is nearby',
                          value: _driverArrival,
                          onChanged: (value) {
                            setState(() => _driverArrival = value);
                          },
                        ),
                        _buildSwitchTile(
                          icon: Icons.play_arrow,
                          title: 'Trip Started',
                          subtitle: 'When your trip begins',
                          value: _tripStarted,
                          onChanged: (value) {
                            setState(() => _tripStarted = value);
                          },
                        ),
                        _buildSwitchTile(
                          icon: Icons.check_circle,
                          title: 'Trip Completed',
                          subtitle: 'When your trip is finished',
                          value: _tripCompleted,
                          onChanged: (value) {
                            setState(() => _tripCompleted = value);
                          },
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),

                  // Promotional Notifications
                  _buildNotificationSection(
                    'Promotional',
                    'Offers, updates, and marketing communications',
                    [
                      _buildSwitchTile(
                        icon: Icons.local_offer,
                        title: 'Offers & Promotions',
                        subtitle: 'Special deals and discount offers',
                        value: _offers,
                        onChanged: (value) {
                          setState(() => _offers = value);
                        },
                      ),
                      _buildSwitchTile(
                        icon: Icons.new_releases,
                        title: 'New Features',
                        subtitle: 'Updates about new app features',
                        value: _newFeatures,
                        onChanged: (value) {
                          setState(() => _newFeatures = value);
                        },
                      ),
                      _buildSwitchTile(
                        icon: Icons.article,
                        title: 'Newsletters',
                        subtitle: 'Company news and updates',
                        value: _newsletters,
                        onChanged: (value) {
                          setState(() => _newsletters = value);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Notification Schedule
                  _buildNotificationScheduleSection(),

                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveNotificationSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDriver
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Save Preferences',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildNotificationSection(
    String title,
    String subtitle,
    List<Widget> items,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: const Divider(height: 1),
        ),
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          secondary: Icon(icon, color: Colors.grey[600]),
          title: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF2196F3),
        ),
      ],
    );
  }

  Widget _buildNotificationScheduleSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notification Schedule',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Control when you receive notifications',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.schedule, color: Colors.grey[600]),
              title: const Text('Quiet Hours'),
              subtitle: const Text('9:00 PM - 7:00 AM'),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                _showQuietHoursDialog();
              },
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.weekend, color: Colors.grey[600]),
              title: const Text('Weekend Settings'),
              subtitle: const Text('Customize weekend notifications'),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Weekend settings coming soon!'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showQuietHoursDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Quiet Hours'),
          content: const Text(
            'During quiet hours, you will only receive notifications for urgent matters like ride cancellations or emergency alerts.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Time picker coming soon!')),
                );
              },
              child: const Text('Change Times'),
            ),
          ],
        );
      },
    );
  }
}
