import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  bool _showOnlineStatus = true;
  bool _allowTagging = true;
  bool _publicProfile = true;
  bool _shareDataAnalytics = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Privacy Settings', style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionHeader("Visibility"),
          SwitchListTile(
            value: _publicProfile,
            onChanged: (val) => setState(() => _publicProfile = val),
            title: Text("Public Profile", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            subtitle: Text("Allow others to see your listings and profile details.", style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
            activeColor: Theme.of(context).colorScheme.primary,
          ),
          SwitchListTile(
            value: _showOnlineStatus,
            onChanged: (val) => setState(() => _showOnlineStatus = val),
            title: Text("Online Status", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            subtitle: Text("Let others know when you are active.", style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
            activeColor: Theme.of(context).colorScheme.primary,
          ),

          const Divider(height: 32),
          _buildSectionHeader("Interactions"),
          SwitchListTile(
            value: _allowTagging,
            onChanged: (val) => setState(() => _allowTagging = val),
            title: Text("Allow Tagging", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            subtitle: Text("Allow others to tag you in comments or posts.", style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
            activeColor: Theme.of(context).colorScheme.primary,
          ),

          const Divider(height: 32),
          _buildSectionHeader("Data & Analytics"),
          SwitchListTile(
            value: _shareDataAnalytics,
            onChanged: (val) => setState(() => _shareDataAnalytics = val),
            title: Text("Share Usage Data", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            subtitle: Text("Help us improve Campus Swap by sharing anonymous usage statistics.", style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
            activeColor: Theme.of(context).colorScheme.primary,
          ),
          
          const SizedBox(height: 48),
          Center(
              child: TextButton.icon(
                  onPressed: (){
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Privacy Policy opened (Mock)")));
                  },
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: Text("View Privacy Policy", style: GoogleFonts.outfit()),
              )
          )
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 12, 
          fontWeight: FontWeight.bold, 
          color: Colors.grey[600],
          letterSpacing: 1.2
        ),
      ),
    );
  }
}
