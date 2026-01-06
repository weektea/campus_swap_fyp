import 'package:flutter/material.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/core/session/user_session.dart';
import 'package:campus_swap/features/auth/presentation/pages/login_page.dart';
import 'package:campus_swap/features/profile/presentation/pages/my_listings_page.dart';
import 'package:campus_swap/features/profile/presentation/pages/my_purchases_page.dart';
import 'package:campus_swap/features/profile/presentation/pages/saved_items_page.dart';
import 'package:campus_swap/features/profile/presentation/pages/settings_page.dart';
import 'package:campus_swap/features/profile/presentation/pages/help_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _itemsReused = 0;
  double _co2Saved = 0.0;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
      final session = UserSession();
      if (!session.isLoggedIn) {
          setState(() => _loadingStats = false);
          return;
      }
      
      try {
          final apiClient = ApiClient();
          // Fetch selling transactions that are completed
          final res = await apiClient.get('/transactions/user/${session.userId}?type=selling');
          if (res is List) {
              final completedSales = res.where((t) => t['status'] == 'Completed').toList();
              final count = completedSales.length;
              // Assumption: 1 item = 2.5kg CO2
              final saved = count * 2.5;
              
              if (mounted) {
                  setState(() {
                      _itemsReused = count;
                      _co2Saved = saved;
                      _loadingStats = false;
                  });
              }
          }
      } catch (e) {
          debugPrint('Error fetching stats: $e');
          if (mounted) setState(() => _loadingStats = false);
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
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.teal,
              child: Icon(Icons.person, size: 50, color: Colors.white),
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF1B5E20), Colors.green.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
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
            const SizedBox(height: 32),
            
            // Menu Items
            _buildMenuItem(context, Icons.inventory_2_outlined, 'My Listings', () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const MyListingsPage()));
            }),
            _buildMenuItem(context, Icons.shopping_bag_outlined, 'My Transactions', () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const MyTransactionsPage()));
            }),
            _buildMenuItem(context, Icons.bookmark_outline, 'Saved Items', () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedItemsPage()));
            }), // "Save favorite items"
            _buildMenuItem(context, Icons.help_outline, 'Help & Support', () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpPage()));
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
