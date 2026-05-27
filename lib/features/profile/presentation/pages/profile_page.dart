import 'package:flutter/material.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/core/session/user_session.dart';
import 'package:campus_swap/features/auth/presentation/pages/login_page.dart';
import 'package:campus_swap/features/profile/presentation/pages/my_listings_page.dart';
import 'package:campus_swap/features/profile/presentation/pages/my_purchases_page.dart';
import 'package:campus_swap/features/profile/presentation/pages/saved_items_page.dart';
import 'package:campus_swap/features/profile/presentation/pages/settings_page.dart';
import 'package:campus_swap/features/profile/presentation/pages/help_center_page.dart';
import 'package:campus_swap/features/profile/presentation/pages/sustainability_dashboard_page.dart';
import 'package:campus_swap/features/profile/presentation/pages/student_profile_page.dart';
// import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _itemsReused = 0;
  double _co2Saved = 0.0;
  double _co2Bought = 0.0;
  double _co2Sold = 0.0;
  bool _loadingStats = true;
  bool _isUploading = false;
  double _reputationScore = 5.0;
  int _totalReviews = 0;

  @override
  void initState() {
    super.initState();
    _fetchStats();
    _fetchUserProfile();
  }

  // Fetch fresh profile data to get latest avatar
  Future<void> _fetchUserProfile() async {
      final session = UserSession();
      if (!session.isLoggedIn) return;
      try {
          final apiClient = ApiClient();
          // Assuming we have a route GET /auth/me or similar, if not we use /auth/user/:id
          final resData = await apiClient.get('/auth/user/${session.userId}');
          if (resData != null && resData['user'] != null) {
              final userData = resData['user'];
              setState(() {
                  if (userData['profile_image_url'] != null) {
                      session.avatarUrl = userData['profile_image_url'];
                  }
                  // Extract True Backend Carbon Value
                  if (userData['total_carbon_saved'] != null) {
                      _co2Saved = double.tryParse(userData['total_carbon_saved'].toString()) ?? 0.0;
                  }
                  if (userData['carbon_saved_buyer'] != null) {
                      _co2Bought = double.tryParse(userData['carbon_saved_buyer'].toString()) ?? 0.0;
                  }
                  if (userData['carbon_saved_seller'] != null) {
                      _co2Sold = double.tryParse(userData['carbon_saved_seller'].toString()) ?? 0.0;
                  }
                  if (userData['items_reused'] != null) {
                      _itemsReused = int.tryParse(userData['items_reused'].toString()) ?? 0;
                  }
                  if (userData['reputation_score'] != null) {
                      _reputationScore = double.tryParse(userData['reputation_score'].toString()) ?? 5.0;
                  }
                  if (userData['total_reviews'] != null) {
                      _totalReviews = int.tryParse(userData['total_reviews'].toString()) ?? 0;
                  }
              });
          }
      } catch (e) {
          debugPrint('Error fetching profile: $e');
      }
  }

  Future<void> _fetchStats() async {
      final session = UserSession();
// ... (rest of _fetchStats same logic)
      if (!session.isLoggedIn) {
          setState(() => _loadingStats = false);
          return;
      }
      
      try {
          final apiClient = ApiClient();
          // Fetch selling transactions that are completed
          final res = await apiClient.get('/transactions/user/${session.userId}?type=selling');
// ...
          if (res is List) {
              if (mounted) {
                  setState(() {
                      _loadingStats = false;
                  });
              }
          }
      } catch (e) {
          debugPrint('Error fetching stats: $e');
          if (mounted) setState(() => _loadingStats = false);
      }
  }

  Future<void> _pickAndUploadAvatar() async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile == null) return;

      setState(() => _isUploading = true);
      final session = UserSession();

      try {
          final apiClient = ApiClient();
          // 1. Upload Image
          final uploadRes = await apiClient.postMultipart('/upload', pickedFile);
          final imageUrl = uploadRes['url']; 

          // 2. Update User Profile
          await apiClient.patch('/auth/user/${session.userId}', {'profile_picture': imageUrl});

          // 3. Update Local Session
          setState(() {
              session.avatarUrl = imageUrl;
              _isUploading = false;
          });
          
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avatar Updated!')));
          }
      } catch (e) {
          if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload Failed: $e')));
              setState(() => _isUploading = false);
          }
      }
  }


  @override
  Widget build(BuildContext context) {
    final session = UserSession();

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickAndUploadAvatar,
              child: Stack(
                children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.teal,
                      backgroundImage: session.avatarUrl != null 
                          ? NetworkImage('${ApiClient.baseUrl.replaceAll('/api', '')}${session.avatarUrl}') 
                          : null,
                      child: _isUploading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : (session.avatarUrl == null ? const Icon(Icons.person, size: 50, color: Colors.white) : null),
                    ),
                    Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, size: 16, color: Colors.grey),
                        ),
                    )
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              session.fullName ?? 'Guest User', 
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              session.email ?? 'Not Logged In',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            if (session.isLoggedIn) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StudentProfilePage()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  side: BorderSide(color: Colors.teal.shade300),
                ),
                child: Text('View Profile', style: TextStyle(color: Colors.teal.shade700)),
              ),
            ],
            if (session.isLoggedIn) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_rounded, size: 20, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    '${_reputationScore.toStringAsFixed(1)} ($_totalReviews)',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Verified', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 32),
            
            // Sustainability Impact Card (FYP Requirement)
            GestureDetector(
              onTap: () {
                 if (!_loadingStats) {
                     Navigator.push(context, MaterialPageRoute(builder: (_) => SustainabilityDashboardPage(itemsReused: _itemsReused, co2Saved: _co2Saved, co2Bought: _co2Bought, co2Sold: _co2Sold)));
                 }
              },
              child: Container(
                padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF1B5E20), Colors.green.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.green.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))
                ]
              ),
              child: Column(
                children: [
                   Row(
                    children: [
                      const Icon(Icons.eco, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      const Text("My Eco-Impact", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                        Column(
                        children: [
                          _loadingStats 
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text("$_itemsReused", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                          Text("Items Reused", style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                        ],
                      ),
                      Container(height: 40, width: 1, color: Colors.white24),
                      Column(
                        children: [
                           _loadingStats 
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text("$_co2Saved kg", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                          Text("CO2 Saved", style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                        ],
                      ),
                    ],
                  )
                ],
              ),
            ),
            ),
            const SizedBox(height: 32),
            
            // Menu Items
            _buildMenuItem(context, Icons.inventory_2_outlined, 'My Inventory', () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const MyListingsPage()));
            }),
            _buildMenuItem(context, Icons.shopping_bag_outlined, 'My Orders', () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const MyTransactionsPage()));
            }),
            _buildMenuItem(context, Icons.bookmark_outline, 'Saved Items', () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedItemsPage()));
            }), // "Save favorite items"
            _buildMenuItem(context, Icons.help_outline, 'Help & Support (Resolution Center)', () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpCenterPage()));
            }), // "Provide user support"
            _buildMenuItem(context, Icons.settings_outlined, 'Settings', () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
            }),
            const SizedBox(height: 24),
            _buildMenuItem(context, Icons.logout, 'Logout', () {
              // Clear session
              UserSession().clear();
              Navigator.pushAndRemoveUntil(
                context, 
                MaterialPageRoute(builder: (_) => const LoginPage()), 
                (route) => false
              );
            }, isDestructive: true),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : null),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : null,
          fontWeight: isDestructive ? FontWeight.bold : FontWeight.normal
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
