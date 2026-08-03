import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/core/session/user_session.dart';
import 'package:campus_swap/features/auth/presentation/pages/login_page.dart';
import 'package:campus_swap/core/services/socket_service.dart';
import 'package:campus_swap/core/services/notification_service.dart';
import 'package:campus_swap/features/profile/presentation/pages/my_listings_page.dart';
import 'package:campus_swap/features/profile/presentation/pages/my_purchases_page.dart';
import 'package:campus_swap/features/profile/presentation/pages/saved_items_page.dart';
import 'package:campus_swap/features/profile/presentation/pages/settings_page.dart';
import 'package:campus_swap/features/profile/presentation/pages/help_center_page.dart';
import 'package:campus_swap/features/profile/presentation/pages/sustainability_dashboard_page.dart';
import 'package:campus_swap/features/profile/presentation/pages/student_profile_page.dart';
import 'package:campus_swap/core/widgets/reputation_badge.dart';
import 'package:campus_swap/features/home/presentation/pages/home_page.dart';
import 'package:campus_swap/features/profile/presentation/pages/profile_analytics_dashboard_page.dart';
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
  double _outstandingFees = 0.0;
  bool _dismissedOutstandingCard = false;

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
          final resData = await apiClient.get('/auth/user/${session.userId}');
          if (resData != null && resData['user'] != null) {
              final userData = resData['user'];
              setState(() {
                  if (userData['profile_image_url'] != null) {
                      session.avatarUrl = userData['profile_image_url'];
                  }
                  if (userData['username'] != null) {
                      session.username = userData['username'];
                  }
                  if (userData['full_name'] != null) {
                      session.fullName = userData['full_name'];
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
                  if (userData['total_outstanding_fees'] != null) {
                      _outstandingFees = double.tryParse(userData['total_outstanding_fees'].toString()) ?? 0.0;
                  }
              });
          }
      } catch (e) {
          debugPrint('Error fetching profile: $e');
      }
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (_outstandingFees > 0.0 && !_dismissedOutstandingCard) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.amber.shade900.withValues(alpha: 0.3) : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.amber.shade700 : Colors.amber.shade400, width: 1.2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: isDark ? Colors.amber.shade300 : Colors.amber.shade900, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Outstanding Platform Fees: RM ${_outstandingFees.toStringAsFixed(2)}',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  title: Row(
                                    children: [
                                      Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                                      const SizedBox(width: 8),
                                      Text('Platform Fees Info', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                                    ],
                                  ),
                                  content: Text(
                                    'This balance represents platform service fees from your completed sales. Automated settlement features will be introduced in the next phase.',
                                    style: GoogleFonts.outfit(fontSize: 14, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: Text('Understood', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6.0),
                              child: Icon(Icons.info_outline, size: 18, color: isDark ? Colors.amber.shade300 : Colors.amber.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _dismissedOutstandingCard = true;
                        });
                      },
                      child: Icon(Icons.close, size: 18, color: isDark ? Colors.amber.shade300 : Colors.amber.shade900),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            
            // Row 1: The CircleAvatar
            GestureDetector(
              onTap: _pickAndUploadAvatar,
              child: CircleAvatar(
                radius: 45,
                backgroundColor: theme.colorScheme.primary,
                backgroundImage: session.avatarUrl != null 
                    ? NetworkImage('${ApiClient.baseUrl.replaceAll('/api', '')}${session.avatarUrl}') 
                    : null,
                child: _isUploading 
                  ? CircularProgressIndicator(color: theme.colorScheme.onPrimary)
                  : (session.avatarUrl == null ? Icon(Icons.person, size: 45, color: theme.colorScheme.onPrimary) : null),
              ),
            ),
            const SizedBox(height: 8),
            
            // Row 2: Full Name + Verified/Not Verified Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    session.fullName ?? (session.username != null ? '@${session.username}' : 'Guest User'), 
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Verified', 
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            
            // Row 3: @username
            if (session.username != null) ...[
              Text(
                '@${session.username}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
            ],
            
            // Row 4: Rating + View Profile side-by-side
            if (session.isLoggedIn) ...[
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, size: 20, color: theme.colorScheme.secondary),
                      const SizedBox(width: 4),
                      Text(
                        _reputationScore < 5.0 
                          ? '${_reputationScore.toStringAsFixed(1)} / 5.0'
                          : (_totalReviews == 0 ? '5.0 (New)' : '${_reputationScore.toStringAsFixed(1)} ($_totalReviews)'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ReputationBadge(
                        completedTransactionsCount: _totalReviews,
                        score: _reputationScore,
                      ),
                    ],
                  ),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StudentProfilePage()),
                      ).then((_) => _fetchUserProfile());
                    },
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      side: BorderSide(color: theme.colorScheme.outline),
                    ),
                    child: Text(
                      'View Profile',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            
            // Sustainability Impact Card (FYP Requirement)
            GestureDetector(
              onTap: () async {
                 if (!_loadingStats) {
                     await Navigator.push(context, MaterialPageRoute(builder: (_) => SustainabilityDashboardPage(itemsReused: _itemsReused, co2Saved: _co2Saved, co2Bought: _co2Bought, co2Sold: _co2Sold)));
                     _fetchUserProfile();
                 }
              },
              child: Container(
                padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ]
              ),
              child: Column(
                children: [
                   Row(
                    children: [
                      Icon(Icons.eco, color: theme.colorScheme.onPrimary, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        "My Eco-Impact",
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                        Column(
                        children: [
                          _loadingStats 
                              ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: theme.colorScheme.onPrimary, strokeWidth: 2))
                              : Text(
                                  "$_itemsReused",
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                          Text(
                            "Items Reused",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                      Container(height: 40, width: 1, color: theme.colorScheme.onPrimary.withValues(alpha: 0.24)),
                      Column(
                        children: [
                           _loadingStats 
                              ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: theme.colorScheme.onPrimary, strokeWidth: 2))
                              : Text(
                                  "$_co2Saved kg CO2e",
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                          Text(
                            "Carbon Saved",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                            ),
                          ),
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
            _buildMenuItem(context, Icons.shopping_bag_outlined, 'My Orders', () async {
               final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const MyTransactionsPage(isPushed: true)));
               if (result == 'go_to_home' && context.mounted) {
                   final homeState = context.findAncestorStateOfType<HomePageState>();
                   if (homeState != null) {
                       homeState.setSelectedIndex(0);
                   }
               }
            }),
            _buildMenuItem(context, Icons.bookmark_outline, 'Saved Items', () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedItemsPage()));
            }),
            _buildMenuItem(context, Icons.bar_chart_outlined, 'Analytics & Impact Dashboard', () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileAnalyticsDashboardPage()));
            }),
            _buildMenuItem(context, Icons.help_outline, 'Help & Support (Resolution Center)', () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpCenterPage()));
            }),
            _buildMenuItem(context, Icons.settings_outlined, 'Settings', () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
            }),
            const SizedBox(height: 24),
            _buildMenuItem(context, Icons.logout, 'Logout', () async {
              final theme = Theme.of(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Logout?', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  content: const Text('Are you sure you want to logout of your account?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text('Logout', style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                // Clear session
                SocketService().disconnect();
                NotificationService().stopPolling();
                UserSession().clear();
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('auto_login', false);
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context, 
                    MaterialPageRoute(builder: (_) => const LoginPage()), 
                    (route) => false
                  );
                }
              }
            }, isDestructive: true),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isDestructive ? theme.colorScheme.error : theme.colorScheme.onSurface,
          fontWeight: isDestructive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
      onTap: onTap,
    );
  }
}
