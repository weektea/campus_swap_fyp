import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:campus_swap/core/session/user_session.dart';
import 'package:campus_swap/features/auth/presentation/pages/login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _emailUpdates = false;

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
          Text("Account", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700])),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text("Change Password", style: GoogleFonts.outfit()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mock: Password Change Requested")));
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text("Privacy Settings", style: GoogleFonts.outfit()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mock: Privacy Settings")));
            },
          ),

          const Divider(height: 48),

          Text("Notifications", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700])),
          const SizedBox(height: 16),
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

          const Divider(height: 48),
          
          Text("About", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700])),
           const SizedBox(height: 16),
           ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text("Version", style: GoogleFonts.outfit()),
            trailing: Text("1.0.0 (Beta)", style: GoogleFonts.outfit(color: Colors.grey)),
          ),

          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _logout,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text("Log Out", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
