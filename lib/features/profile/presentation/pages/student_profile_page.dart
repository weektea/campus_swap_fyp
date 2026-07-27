import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/core/session/user_session.dart';
import 'package:campus_swap/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:campus_swap/core/widgets/reputation_badge.dart';

class StudentProfilePage extends StatefulWidget {
  final String? userId;
  const StudentProfilePage({super.key, this.userId});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  Map<String, dynamic>? _userData;
  int _activeListingsCount = 0;
  List<dynamic> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    final session = UserSession();
    final targetUserId = widget.userId ?? session.userId;
    if (targetUserId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final apiClient = ApiClient();
      
      // 1. Fetch User Data
      final resData = await apiClient.get('/auth/user/$targetUserId');
      if (resData != null && resData['user'] != null) {
        _userData = resData['user'];
      }

      // 2. Fetch Active Listings Count
      try {
        final listingsRes = await apiClient.get('/products?seller_id=$targetUserId');
        if (listingsRes is List) {
          _activeListingsCount = listingsRes.where((p) => p['status'] == 'Available').length;
        }
      } catch (e) {
        debugPrint('Error fetching listings count: $e');
      }

      // 3. Fetch Reviews
      try {
        final reviewsRes = await apiClient.get('/reviews/user/$targetUserId');
        if (reviewsRes is List) {
          _reviews = reviewsRes;
        }
      } catch (e) {
        debugPrint('Error fetching reviews: $e');
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  IconData _getBadgeIcon(String? iconName) {
    switch (iconName) {
      case 'leaf':
        return Icons.eco;
      case 'award':
        return Icons.workspace_premium;
      case 'school':
        return Icons.school;
      default:
        return Icons.star;
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18, 
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          if (widget.userId == null || widget.userId == UserSession().userId)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfilePage()),
                );
                // Refresh data when coming back
                _fetchProfileData();
              },
            )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : _userData == null 
              ? const Center(child: Text('Failed to load profile data.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Basic User Information
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.teal.shade100,
                              backgroundImage: _userData!['profile_image_url'] != null 
                                  ? NetworkImage('${ApiClient.baseUrl.replaceAll('/api', '')}${_userData!['profile_image_url']}') 
                                  : null,
                              child: _userData!['profile_image_url'] == null 
                                  ? const Icon(Icons.person, size: 50, color: Colors.teal) 
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _userData!['full_name'] ?? (_userData!['username'] != null ? '@${_userData!['username']}' : 'No Name'),
                              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            if (_userData!['username'] != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '@${_userData!['username']}',
                                style: const TextStyle(fontSize: 16, color: Colors.teal, fontWeight: FontWeight.w500),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Text(
                                _userData!['role']?.toString().toUpperCase() ?? 'STUDENT',
                                style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  ((int.tryParse((_userData!['completed_transactions_count'] ?? _userData!['successful_transactions_count'] ?? 0).toString()) ?? 0) == 0)
                                      ? 'No Rating Yet (${_userData!['total_reviews'] ?? 0} reviews)'
                                      : '${double.tryParse((_userData!['reputation_score'] ?? 5.0).toString())?.toStringAsFixed(1) ?? '5.0'} (${_userData!['total_reviews'] ?? 0} reviews)',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                const SizedBox(width: 12),
                                ReputationBadge.fromUser(_userData!),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Transaction Statistics Cards
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.teal.shade900.withOpacity(0.2) : Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isDark ? Colors.teal.shade800.withOpacity(0.4) : Colors.teal.shade100),
                              ),
                              child: Column(
                                children: [
                                  const Text('📦', style: TextStyle(fontSize: 20)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_userData!['successful_transactions_count'] ?? 0} Deals Done',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isDark ? Colors.teal.shade200 : Colors.teal.shade900,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.teal.shade900.withOpacity(0.2) : Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isDark ? Colors.teal.shade800.withOpacity(0.4) : Colors.teal.shade100),
                              ),
                              child: Column(
                                children: [
                                  const Text('⚡', style: TextStyle(fontSize: 20)),
                                  const SizedBox(height: 4),
                                  Text(
                                    _userData!['response_speed'] ?? 'Replies fast',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isDark ? Colors.teal.shade200 : Colors.teal.shade900,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const Divider(),
                      _buildSectionHeader('Basic Information', Icons.badge_outlined),
                      _buildDataRow('Full Name', _userData!['full_name'] ?? 'N/A'),
                      _buildDataRow('Email', _userData!['email'] ?? 'N/A'),
                      _buildDataRow('Phone Number', _userData!['phone_number'] ?? 'Not provided'),

                      const Divider(),
                      _buildSectionHeader('Academic Identity', Icons.school_outlined),
                      _buildDataRow('Student ID', _userData!['university_id'] ?? 'Not provided'),
                      _buildDataRow('Year of Study', _userData!['year_of_study']?.toString() ?? 'Not provided'),

                      const Divider(),
                      _buildSectionHeader('Personalization & Privacy', Icons.privacy_tip_outlined),
                      _buildDataRow('Bio', _userData!['bio'] ?? 'No bio available.'),
                      if (_userData!['primary_intent'] != null)
                        _buildDataRow('Primary Intent', _userData!['primary_intent'] == 'buy' ? '🛍️ Buying' : (_userData!['primary_intent'] == 'sell' ? '📦 Selling' : '👀 Browsing')),
                      if (_userData!['preference_tags'] != null && (_userData!['preference_tags'] as List).isNotEmpty)
                        _buildTagsRow('Looking For / Interests', List<String>.from(_userData!['preference_tags']), isDark),
                      _buildDataRow('Privacy Setting', _userData!['privacy_setting'] ?? 'Public'),
                      _buildDataRow('Full Name Visibility', _userData!['show_full_name'] == true ? 'Visible' : 'Hidden (Private)'),
                      _buildDataRow('Phone Visibility', _userData!['show_phone_number'] == true ? 'Visible' : 'Hidden (Private)'),
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 12),
                        child: InkWell(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Go to Settings to change Full Name and Phone visibility.'),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Change Name & Phone visibility in Settings.',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Divider(),
                      _buildSectionHeader('Trading & Platform Metrics', Icons.analytics_outlined),
                      _buildDataRow('Reputation Score', '${_userData!['reputation_score'] ?? '5.0'} / 5.0 (${_userData!['total_reviews'] ?? 0} reviews)'),
                      _buildDataRow('Active Listings', '$_activeListingsCount items'),
                      _buildDataRow('Total Carbon Saved', '${_userData!['total_carbon_saved'] ?? '0.0'} kg CO2e'),
                      
                      // Achievements & Badges Section
                      const Divider(),
                      _buildSectionHeader('Achievements & Badges', Icons.emoji_events_outlined),
                      const SizedBox(height: 8),
                      _userData!['badges'] == null || (_userData!['badges'] as List).isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                "Complete transactions to unlock badges!",
                                style: GoogleFonts.outfit(
                                  color: Colors.grey.shade500,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 14,
                                ),
                              ),
                            )
                          : Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: (_userData!['badges'] as List).map((badge) {
                                final label = badge['label'] ?? '';
                                final iconName = badge['icon'] ?? '';
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.orange.shade900.withOpacity(0.2) : Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: isDark ? Colors.orange.shade800.withOpacity(0.4) : Colors.orange.shade200),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(_getBadgeIcon(iconName), color: isDark ? Colors.orange.shade200 : Colors.orange.shade800, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        label,
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: isDark ? Colors.orange.shade200 : Colors.orange.shade900,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),

                      const Divider(),
                      _buildSectionHeader('Reviews', Icons.rate_review_outlined),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 28),
                            const SizedBox(width: 8),
                            Text(
                              '${_userData!['reputation_score'] ?? '5.0'} / 5.0',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${_reviews.length} reviews)',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_reviews.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(
                            child: Text(
                              'No reviews yet.',
                              style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _reviews.length,
                          itemBuilder: (context, index) {
                            final r = _reviews[index];
                            final reviewer = r['reviewer'] ?? {};
                            final reviewerName = reviewer['username'] ?? 'Anonymous';
                            final rating = r['rating'] ?? 5;
                            final comment = r['comment'] ?? 'No comment provided.';
                            final transaction = r['transaction'] ?? {};
                            final product = transaction['product'] ?? {};
                            final productTitle = product['title'] ?? 'Unknown Item';
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 0,
                              color: Colors.grey.shade50,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '@$reviewerName',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.teal,
                                          ),
                                        ),
                                        Row(
                                          children: List.generate(5, (starIndex) {
                                            return Icon(
                                              Icons.star_rounded,
                                              size: 16,
                                              color: starIndex < rating ? Colors.amber : Colors.grey.shade300,
                                            );
                                          }),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      comment,
                                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Ref: $productTitle',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  Widget _buildTagsRow(String label, List<String> tags, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: tags.map((t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF005A43).withValues(alpha: 0.2) : const Color(0xFFE6F4F1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF005A43) : const Color(0xFFB2DFDB)),
              ),
              child: Text(
                t,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFF80CBC4) : const Color(0xFF005A43),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}
