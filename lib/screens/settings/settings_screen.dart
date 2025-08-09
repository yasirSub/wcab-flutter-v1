import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import 'edit_profile_screen.dart';
import 'notifications_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _locationServices = true;
  bool _autoAcceptRides = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = authProvider.user;
    final isDriver = user?.isDriver == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: isDriver
            ? const Color(0xFF4CAF50)
            : const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Account Settings
            _buildSettingsSection('Account', [
              _buildSettingsItem(
                icon: Icons.person_outline,
                title: 'Edit Profile',
                subtitle: 'Update your personal information',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );
                },
              ),
              _buildSettingsItem(
                icon: Icons.security,
                title: 'Privacy & Security',
                subtitle: 'Manage your privacy and security settings',
                onTap: () {
                  _showPrivacySettings(context);
                },
              ),
              _buildSettingsItem(
                icon: Icons.payment,
                title: 'Payment Methods',
                subtitle: 'Manage your payment options',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment settings coming soon'),
                    ),
                  );
                },
              ),
            ]),

            const SizedBox(height: 24),

            // App Preferences
            _buildSettingsSection('Preferences', [
              _buildSettingsItem(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Customize your notification preferences',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
              _buildThemeSelector(themeProvider),
              _buildSwitchItem(
                icon: Icons.location_on_outlined,
                title: 'Location Services',
                subtitle: 'Allow app to access your location',
                value: _locationServices,
                onChanged: (value) {
                  setState(() => _locationServices = value);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value
                            ? 'Location services enabled'
                            : 'Location services disabled',
                      ),
                    ),
                  );
                },
              ),
              _buildSettingsItem(
                icon: Icons.language,
                title: 'Language',
                subtitle: 'English (US)',
                onTap: () {
                  _showLanguageSelector(context);
                },
              ),
            ]),

            const SizedBox(height: 24),

            // Driver-specific settings
            if (isDriver) ...[
              _buildSettingsSection('Driver Settings', [
                _buildSwitchItem(
                  icon: Icons.auto_awesome,
                  title: 'Auto Accept Rides',
                  subtitle: 'Automatically accept nearby ride requests',
                  value: _autoAcceptRides,
                  onChanged: (value) {
                    setState(() => _autoAcceptRides = value);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value
                              ? 'Auto accept enabled'
                              : 'Auto accept disabled',
                        ),
                      ),
                    );
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.directions_car,
                  title: 'Vehicle Information',
                  subtitle: 'Update your vehicle details',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vehicle settings coming soon'),
                      ),
                    );
                  },
                ),
                _buildSettingsItem(
                  icon: Icons.account_balance_wallet,
                  title: 'Earnings & Payouts',
                  subtitle: 'Manage your earnings and payment methods',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Earnings settings coming soon'),
                      ),
                    );
                  },
                ),
              ]),
              const SizedBox(height: 24),
            ],

            // Support & Legal
            _buildSettingsSection('Support & Legal', [
              _buildSettingsItem(
                icon: Icons.help_outline,
                title: 'Help & Support',
                subtitle: 'Get help or contact support',
                onTap: () {
                  _showHelpOptions(context);
                },
              ),
              _buildSettingsItem(
                icon: Icons.feedback_outlined,
                title: 'Send Feedback',
                subtitle: 'Share your thoughts with us',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Feedback feature coming soon'),
                    ),
                  );
                },
              ),
              _buildSettingsItem(
                icon: Icons.article_outlined,
                title: 'Terms of Service',
                subtitle: 'Read our terms and conditions',
                onTap: () {
                  _showTermsOfService(context);
                },
              ),
              _buildSettingsItem(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                subtitle: 'Learn about our privacy practices',
                onTap: () {
                  _showPrivacyPolicy(context);
                },
              ),
              _buildSettingsItem(
                icon: Icons.info_outline,
                title: 'About WCab',
                subtitle: 'App version and information',
                onTap: () {
                  _showAboutDialog(context);
                },
              ),
            ]),

            const SizedBox(height: 32),

            // Logout Button
            _buildLogoutButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> items) {
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
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: const Divider(height: 1),
        ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          leading: Icon(icon, color: Colors.grey[600]),
          title: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: onTap,
        ),
      ],
    );
  }

  Widget _buildSwitchItem({
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

  Widget _buildThemeSelector(ThemeProvider themeProvider) {
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
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: const Color(0xFF2196F3),
                size: 20,
              ),
            ),
            title: const Text(
              'Theme',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              'Current: ${themeProvider.themeModeDisplayName}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            onTap: () => _showThemeDialog(themeProvider),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              subtitle: const Text('Always use light theme'),
              value: ThemeMode.light,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              subtitle: const Text('Always use dark theme'),
              value: ThemeMode.dark,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('System'),
              subtitle: const Text('Follow system theme'),
              value: ThemeMode.system,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text(
          'Logout',
          style: TextStyle(
            color: Colors.red,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: const Text('Sign out of your account'),
        onTap: () => _showLogoutDialog(context),
      ),
    );
  }

  // Additional dialog methods
  void _showPrivacySettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Privacy & Security'),
          content: const Text(
            'Manage your privacy settings, data sharing preferences, and security options.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showLanguageSelector(BuildContext context) {
    final languages = [
      'English (US)',
      'Spanish',
      'French',
      'German',
      'Italian',
      'Portuguese',
      'Hindi',
      'Chinese',
      'Japanese',
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Language'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: languages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(languages[index]),
                  leading: Radio<int>(
                    value: index,
                    groupValue: 0, // English selected by default
                    onChanged: (value) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Language changed to ${languages[index]}',
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showHelpOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Help & Support',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.chat, color: Color(0xFF2196F3)),
                  title: const Text('Live Chat'),
                  subtitle: const Text('Chat with our support team'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Live chat coming soon!')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.email, color: Color(0xFF2196F3)),
                  title: const Text('Email Support'),
                  subtitle: const Text('Send us an email'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Email support coming soon!'),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.phone, color: Color(0xFF2196F3)),
                  title: const Text('Call Support'),
                  subtitle: const Text('Speak with our team'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Phone support coming soon!'),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.help_center,
                    color: Color(0xFF2196F3),
                  ),
                  title: const Text('FAQ'),
                  subtitle: const Text('Find answers to common questions'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('FAQ coming soon!')),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTermsOfService(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Terms of Service'),
          content: const SingleChildScrollView(
            child: Text(
              'Welcome to WCab. By using our service, you agree to these terms...\n\n'
              '1. Acceptance of Terms\n'
              'By accessing and using WCab, you accept and agree to be bound by the terms and provision of this agreement.\n\n'
              '2. Service Description\n'
              'WCab provides a platform that connects passengers with drivers for transportation services.\n\n'
              '3. User Responsibilities\n'
              'Users must provide accurate information and comply with all applicable laws.\n\n'
              '[This is a sample terms of service. Please replace with actual terms.]',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Privacy Policy'),
          content: const SingleChildScrollView(
            child: Text(
              'WCab Privacy Policy\n\n'
              'Last updated: [Date]\n\n'
              '1. Information We Collect\n'
              'We collect information you provide directly to us, such as when you create an account, request a ride, or contact us.\n\n'
              '2. How We Use Your Information\n'
              'We use the information we collect to provide, maintain, and improve our services.\n\n'
              '3. Information Sharing\n'
              'We do not sell, trade, or otherwise transfer your personal information to third parties without your consent.\n\n'
              '[This is a sample privacy policy. Please replace with actual policy.]',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                authProvider.logout();
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'WCab',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.local_taxi,
        size: 48,
        color: Color(0xFF2196F3),
      ),
      children: const [
        Text(
          'WCab is a modern taxi booking application that connects passengers with drivers efficiently and safely.',
        ),
        SizedBox(height: 16),
        Text('© 2024 WCab. All rights reserved.'),
      ],
    );
  }
}
