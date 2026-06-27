import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:campus_swap/core/session/user_session.dart';
import 'package:campus_swap/features/auth/presentation/pages/login_page.dart';
import 'package:campus_swap/core/theme/theme_provider.dart';
import 'package:campus_swap/features/profile/presentation/pages/help_page.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/features/profile/presentation/pages/change_password_page.dart';
import 'package:campus_swap/features/profile/presentation/pages/edit_profile_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _emailUpdates = false;
  bool _showFullName = true;
  bool _showPhoneNumber = true;
  bool _isLoadingSettings = false;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    setState(() => _isLoadingSettings = true);
    try {
      final apiClient = ApiClient();
      final res = await apiClient.get('/auth/user/${UserSession().userId}');
      if (res != null && res['user'] != null) {
        final userData = res['user'];
        setState(() {
          _showFullName = userData['show_full_name'] ?? true;
          _showPhoneNumber = userData['show_phone_number'] ?? true;
        });
      }
    } catch (_) {}
    finally {
      if (mounted) setState(() => _isLoadingSettings = false);
    }
  }

  Future<void> _updatePrivacySetting(String key, bool value) async {
    try {
      final apiClient = ApiClient();
      await apiClient.patch('/auth/user/${UserSession().userId}', {
        key: value,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Privacy setting updated!'),
            duration: const Duration(milliseconds: 500),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save setting: $e')),
        );
      }
    }
  }

  void _logout() {
    UserSession().clear();
    Navigator.pushAndRemoveUntil(
      context, 
      MaterialPageRoute(builder: (_) => const LoginPage()), 
      (route) => false
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings', style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Section 1: Account Security
          Text("Account Security", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700])),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text("Security: Change Password", style: GoogleFonts.outfit()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordPage()));
            },
          ),

          const Divider(height: 32),

          // Section 2: Privacy Settings
          Text("Privacy Settings", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700])),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _showFullName,
            onChanged: (val) {
              setState(() => _showFullName = val);
              _updatePrivacySetting('show_full_name', val);
            },
            title: Text("Show Full Name on Profile", style: GoogleFonts.outfit()),
            subtitle: Text("If turned off, only your @username handle is visible to other students.", style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
            activeColor: Theme.of(context).colorScheme.primary,
          ),
          SwitchListTile(
            value: _showPhoneNumber,
            onChanged: (val) {
              setState(() => _showPhoneNumber = val);
              _updatePrivacySetting('show_phone_number', val);
            },
            title: Text("Show Phone Number on Profile", style: GoogleFonts.outfit()),
            subtitle: Text("Allow other buyers and sellers to see your contact number.", style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
            activeColor: Theme.of(context).colorScheme.primary,
          ),

          const Divider(height: 32),

          // Section 3: Display & Accessibility
          Text("Display & Accessibility", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700])),
          const SizedBox(height: 8),
          SwitchListTile(
            value: ThemeProvider.instance.isDark(context), 
            onChanged: (val) {
               ThemeProvider.instance.toggleTheme(val);
               setState(() {});
             },
            title: Text("Appearance: Dark Mode", style: GoogleFonts.outfit()),
            activeColor: Theme.of(context).colorScheme.primary,
          ),
          SwitchListTile(
            value: ThemeProvider.instance.isLargeText, 
            onChanged: (val) {
               ThemeProvider.instance.toggleLargeText(val);
               setState(() {});
             },
            title: Text("Text Size: Large Text", style: GoogleFonts.outfit()),
            subtitle: Text("Enlarge app text for enhanced readability.", style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
            activeColor: Theme.of(context).colorScheme.primary,
          ),

          const Divider(height: 32),

          // Section 4: Notification Settings
          Text("Notification Settings", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700])),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _notificationsEnabled, 
            onChanged: (val) => setState(() => _notificationsEnabled = val),
            title: Text("Push Notifications", style: GoogleFonts.outfit()),
            activeColor: Theme.of(context).colorScheme.primary,
          ),
          SwitchListTile(
            value: _emailUpdates, 
            onChanged: (val) => setState(() => _emailUpdates = val),
            title: Text("Email Updates", style: GoogleFonts.outfit()),
            activeColor: Theme.of(context).colorScheme.primary,
          ),
          
          const Divider(height: 32),

          // Section 4: About
          Text("About", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700])),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text("Version", style: GoogleFonts.outfit()),
            trailing: Text("1.0.0 (Beta)", style: GoogleFonts.outfit(color: Colors.grey)),
          ),

          const Divider(height: 32),
          
          // Section 5: Danger Zone
          Text("Danger Zone", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red[700])),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _deactivateAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text("Deactivate Account", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _deactivateAccount() async {
      final confirm = await showDialog(
          context: context, 
          builder: (context) => AlertDialog(
              title: Text("Deactivate Account?", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              content: Text("Are you sure you want to deactivate your account? Your public profile will be hidden, but your historical transaction data will be securely preserved to comply with ongoing responsibilities.", style: GoogleFonts.outfit()),
              actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Deactivate", style: TextStyle(color: Colors.red))),
              ],
          )
      );

      if (confirm == true) {
          try {
             final apiClient = ApiClient();
             await apiClient.delete('/auth/user/${UserSession().userId}'); 
             
             if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Account deactivated successfully. Goodbye!")));
                _logout();
             }
          } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to deactivate account: $e")));
          }
      }
  }
}
