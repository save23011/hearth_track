import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/widgets/custom_button.dart';
import 'package:Soulene/shared/models/user_model.dart';
import 'package:Soulene/core/services/api_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to settings
            },
          ),
        ],
      ),
      body:Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFDEF3FD), Color(0xFFF0DEFD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(),
            const SizedBox(height: 24),

            // Profile Options
            _buildProfileOptions(context),
            const SizedBox(height: 24),

            // Logout Button
            CustomButton(
              text: 'Logout',
              onPressed: () => _logout(context),
              type: ButtonType.secondary,
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final user = ApiService.user != null
        ? User.fromJson(ApiService.user!)
        : null;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
           Text(
            "${user?.firstName?? 'John'} ${user?.lastName?? 'Doe'}",
            style: AppTheme.heading2,
          ),
          const SizedBox(height: 4),
          Text(
            "${user?.email?? 'john.doe@example.com'}",
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Edit Profile',
            onPressed: () {
              // TODO: Navigate to edit profile
            },
            type: ButtonType.secondary,
            height: 40,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOptions(BuildContext context) {
    final options = [
      ProfileOption(
        icon: Icons.person_outline,
        title: 'Personal Information',
        onTap: () {},
      ),
      ProfileOption(
        icon: Icons.medical_information_outlined,
        title: 'Health Profile',
        onTap: () {},
      ),
      ProfileOption(
        icon: Icons.notifications_outlined,
        title: 'Notifications',
        onTap: () {},
      ),
      ProfileOption(
        icon: Icons.privacy_tip_outlined,
        title: 'Privacy Settings',
        onTap: () {},
      ),
      ProfileOption(
        icon: Icons.help_outline,
        title: 'Help & Support',
        onTap: () {},
      ),
      ProfileOption(
        icon: Icons.info_outline,
        title: 'About',
        onTap: () {},
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          
          return Column(
            children: [
              ListTile(
                leading: Icon(
                  option.icon,
                  color: AppTheme.textSecondary,
                ),
                title: Text(
                  option.title,
                  style: AppTheme.bodyLarge,
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: AppTheme.textSecondary,
                ),
                onTap: option.onTap,
              ),
              if (index < options.length - 1)
                const Divider(
                  height: 1,
                  indent: 72,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await AuthService.logout();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      // Handle error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logout failed. Please try again.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}

class ProfileOption {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  ProfileOption({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}
