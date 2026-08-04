import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/core/session/user_session.dart';

class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  bool _publicProfile = true;
  bool _showFullName = true;
  bool _showPhoneNumber = true;
  bool _showOnlineStatus = true;
  bool _allowTagging = true;
  bool _shareDataAnalytics = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = ApiClient();
      final res = await apiClient.get('/auth/user/${UserSession().userId}');
      if (res != null && res['user'] != null) {
        final userData = res['user'];
        setState(() {
          _publicProfile = (userData['privacy_setting'] ?? 'Public') == 'Public';
          _showFullName = userData['show_full_name'] ?? true;
          _showPhoneNumber = userData['show_phone_number'] ?? true;
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSetting(Map<String, dynamic> patch) async {
    try {
      final apiClient = ApiClient();
      await apiClient.patch('/auth/user/${UserSession().userId}', patch);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Privacy setting updated!', style: GoogleFonts.outfit()),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update privacy setting.', style: GoogleFonts.outfit()),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Privacy Settings', style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildSectionHeader("Profile Privacy & Visibility"),
                SwitchListTile(
                  value: _publicProfile,
                  onChanged: (val) {
                    setState(() => _publicProfile = val);
                    _updateSetting({'privacy_setting': val ? 'Public' : 'Private'});
                  },
                  title: Text("Public Profile", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    "When Public, others can view your Email, Faculty, and Year of Study. When Private, these details are hidden.",
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
                  ),
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
                SwitchListTile(
                  value: _showFullName,
                  onChanged: (val) {
                    setState(() => _showFullName = val);
                    _updateSetting({'show_full_name': val});
                  },
                  title: Text("Show Full Name", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    "Display full name on public profile. If disabled, only @username is visible.",
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
                  ),
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
                SwitchListTile(
                  value: _showPhoneNumber,
                  onChanged: (val) {
                    setState(() => _showPhoneNumber = val);
                    _updateSetting({'show_phone_number': val});
                  },
                  title: Text("Show Phone Number", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    "Allow other students to see your phone number on profile.",
                    style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
                  ),
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
                SwitchListTile(
                  value: _showOnlineStatus,
                  onChanged: (val) => setState(() => _showOnlineStatus = val),
                  title: Text("Online Status", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  subtitle: Text("Let others know when you are active.", style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600])),
                  activeColor: Theme.of(context).colorScheme.primary,
                ),

                const Divider(height: 32),
                _buildSectionHeader("Interactions"),
                SwitchListTile(
                  value: _allowTagging,
                  onChanged: (val) => setState(() => _allowTagging = val),
                  title: Text("Allow Tagging", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  subtitle: Text("Allow others to tag you in comments or posts.", style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600])),
                  activeColor: Theme.of(context).colorScheme.primary,
                ),

                const Divider(height: 32),
                _buildSectionHeader("Data & Analytics"),
                SwitchListTile(
                  value: _shareDataAnalytics,
                  onChanged: (val) => setState(() => _shareDataAnalytics = val),
                  title: Text("Share Usage Data", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  subtitle: Text("Help us improve Campus Swap by sharing anonymous usage statistics.", style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600])),
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
