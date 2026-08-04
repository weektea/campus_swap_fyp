import 'package:flutter/material.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/features/home/domain/entities/product.dart';
import 'package:campus_swap/features/product/presentation/pages/product_details_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:campus_swap/core/session/user_session.dart';
import 'package:campus_swap/features/profile/presentation/pages/report_user_page.dart';
import 'package:campus_swap/core/widgets/reputation_badge.dart';

class PublicProfilePage extends StatefulWidget {
  final String userId;
  final String userName;

  const PublicProfilePage({super.key, required this.userId, required this.userName});

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  Map<String, dynamic>? _userProfile;
  List<Product> _listings = [];
  List<dynamic> _reviews = [];
  bool _isLoading = true;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final apiClient = ApiClient();
    try {
        // 1. Fetch User Info
        final userRes = await apiClient.get('/auth/user/${widget.userId}');
        if (userRes != null && userRes['user'] != null) {
            _userProfile = userRes['user'];
            _isFollowing = _userProfile?['is_following'] ?? false;
        }

        // 2. Fetch User Listings
        String endpoint = '/products?seller_id=${widget.userId}';
        if (UserSession().isLoggedIn) {
            endpoint += '&exclude_reported_by=${UserSession().userId}';
        }
        final productsRes = await apiClient.get(endpoint);
        if (productsRes is List) {
            _listings = productsRes.map((data) => Product.fromJson(data)).toList();
            _listings = _listings.where((p) => p.status == 'Available').toList();
        }

        // 3. Fetch Reviews
        try {
            final reviewsRes = await apiClient.get('/reviews/user/${widget.userId}');
            if (reviewsRes is List) {
                _reviews = reviewsRes;
            }
        } catch (e) {
            debugPrint("Error fetching reviews in public profile: $e");
        }

        if (mounted) setState(() => _isLoading = false);
    } catch (e) {
        if (mounted) setState(() => _isLoading = false);
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

  String _formatDate(String? isoString) {
      if (isoString == null) return 'N/A';
      try {
          final dt = DateTime.parse(isoString);
          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
      } catch (e) {
          return 'N/A';
      }
  }

  Future<void> _toggleFollow() async {
    if (!UserSession().isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to follow sellers')),
      );
      return;
    }

    final apiClient = ApiClient();
    final originalState = _isFollowing;

    setState(() {
      _isFollowing = !_isFollowing;
      if (_userProfile != null) {
        final currentFollowers = _userProfile!['follower_count'] ?? 0;
        _userProfile!['follower_count'] = _isFollowing ? currentFollowers + 1 : currentFollowers - 1;
      }
    });

    try {
      if (originalState) {
        await apiClient.post('/auth/user/${widget.userId}/unfollow', {});
      } else {
        await apiClient.post('/auth/user/${widget.userId}/follow', {});
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFollowing = originalState;
          if (_userProfile != null) {
            final currentFollowers = _userProfile!['follower_count'] ?? 0;
            _userProfile!['follower_count'] = originalState ? currentFollowers + 1 : currentFollowers - 1;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update follow status: $e')),
        );
      }
    }
  }

  Future<void> _showFollowersOrFollowingModal(bool showFollowers) async {
    final title = showFollowers ? 'Followers' : 'Following';
    final endpoint = showFollowers 
        ? '/auth/user/${widget.userId}/followers' 
        : '/auth/user/${widget.userId}/following';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        List<dynamic> usersList = [];
        bool modalLoading = true;

        return StatefulBuilder(
          builder: (context, setModalState) {
            if (modalLoading) {
              modalLoading = false;
              ApiClient().get(endpoint).then((res) {
                if (res is List && mounted) {
                  setModalState(() {
                    usersList = res;
                  });
                }
              }).catchError((err) {
                // handle error silently
              });
            }

            return Container(
              padding: const EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * 0.5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: usersList.isEmpty
                        ? const Center(
                            child: Text(
                              'No users found',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: usersList.length,
                            itemBuilder: (context, index) {
                              final u = usersList[index];
                              final String profileImg = u['profile_image_url'] ?? '';
                              final String name = u['full_name'] ?? u['username'] ?? 'User';
                              final String uname = u['username'] ?? '';
                              final bool verified = u['is_verified'] ?? false;

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: profileImg.isNotEmpty ? NetworkImage(profileImg) : null,
                                  child: profileImg.isEmpty ? Text(name[0].toUpperCase()) : null,
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    if (verified)
                                      const Icon(Icons.verified_rounded, color: Colors.blue, size: 14),
                                  ],
                                ),
                                subtitle: Text('@$uname'),
                                onTap: () {
                                  Navigator.pop(context);
                                  if (u['id'] != widget.userId) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PublicProfilePage(userId: u['id'], userName: uname),
                                      ),
                                    ).then((_) => _fetchData());
                                  }
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
        appBar: AppBar(
            title: Text(widget.userName, style: GoogleFonts.outfit()),
            actions: [
                IconButton(
                    icon: const Icon(Icons.report_gmailerrorred_rounded, color: Colors.red),
                    onPressed: () => _showReportUserDialog(context),
                )
            ],
        ),
        body: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        // Header
                        Center(
                            child: Column(
                                children: [
                                    CircleAvatar(
                                        radius: 40,
                                        backgroundImage: (_userProfile != null && _userProfile!['profile_image_url'] != null)
                                            ? NetworkImage('${ApiClient.baseUrl.replaceAll('/api', '')}${_userProfile!['profile_image_url']}')
                                            : null,
                                        child: (_userProfile == null || _userProfile!['profile_image_url'] == null) 
                                            ? Text(widget.userName[0].toUpperCase(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold))
                                            : null,
                                    ),
                                    const SizedBox(height: 12),
                                    if (_userProfile != null && _userProfile!['full_name'] != null) ...[
                                      Text(_userProfile!['full_name'], style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text('@${widget.userName}', style: GoogleFonts.outfit(fontSize: 16, color: Colors.teal, fontWeight: FontWeight.w500)),
                                    ] else ...[
                                      Text('@${widget.userName}', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
                                    ],
                                     if (_userProfile != null && _userProfile!['reputation_score'] != null) ...[
                                       const SizedBox(height: 8),
                                       Row(
                                         mainAxisAlignment: MainAxisAlignment.center,
                                         children: [
                                           const Icon(Icons.star_rounded, size: 20, color: Colors.amber),
                                           const SizedBox(width: 4),
                                           Text(
                                             ((int.tryParse((_userProfile!['completed_transactions_count'] ?? _userProfile!['successful_transactions_count'] ?? 0).toString()) ?? 0) == 0)
                                                 ? 'No Rating Yet (${_userProfile!['total_reviews'] ?? 0})'
                                                 : '${double.parse(_userProfile!['reputation_score'].toString()).toStringAsFixed(1)} (${_userProfile!['total_reviews'] ?? 0})',
                                             style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                                           ),
                                           const SizedBox(width: 8),
                                           ReputationBadge.fromUser(_userProfile!),
                                         ],
                                       ),
                                     ],
                                    const SizedBox(height: 8),
                                    Text("Member since ${_formatDate(_userProfile?['createdAt'])}", style: GoogleFonts.outfit(color: Colors.grey)),
                                    const SizedBox(height: 12),
                                    Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                            InkWell(
                                                onTap: () => _showFollowersOrFollowingModal(true),
                                                borderRadius: BorderRadius.circular(8),
                                                child: Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                    child: Column(
                                                        children: [
                                                            Text(
                                                                '${_userProfile?['follower_count'] ?? 0}',
                                                                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                                                            ),
                                                            Text(
                                                                'Followers',
                                                                style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                                                            ),
                                                        ],
                                                    ),
                                                ),
                                            ),
                                            const SizedBox(width: 16),
                                            InkWell(
                                                onTap: () => _showFollowersOrFollowingModal(false),
                                                borderRadius: BorderRadius.circular(8),
                                                child: Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                    child: Column(
                                                        children: [
                                                            Text(
                                                                '${_userProfile?['following_count'] ?? 0}',
                                                                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                                                            ),
                                                            Text(
                                                                'Following',
                                                                style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                                                            ),
                                                        ],
                                                    ),
                                                ),
                                            ),
                                        ],
                                    ),
                                    if (UserSession().isLoggedIn && UserSession().userId != widget.userId) ...[
                                        const SizedBox(height: 16),
                                        ElevatedButton.icon(
                                            onPressed: _toggleFollow,
                                            icon: Icon(
                                                _isFollowing ? Icons.check_circle : Icons.person_add_alt_1_rounded,
                                                color: _isFollowing ? Colors.teal : Colors.white,
                                            ),
                                            label: Text(
                                                _isFollowing ? 'Following' : 'Follow',
                                                style: GoogleFonts.outfit(
                                                    fontWeight: FontWeight.bold,
                                                    color: _isFollowing ? Colors.teal : Colors.white,
                                                ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: _isFollowing ? Colors.teal.shade50 : Colors.teal,
                                                foregroundColor: _isFollowing ? Colors.teal : Colors.white,
                                                elevation: 0,
                                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(20),
                                                    side: const BorderSide(color: Colors.teal),
                                                ),
                                            ),
                                        ),
                                    ]
                                ],
                            ),
                        ),
                        const SizedBox(height: 16),
                         if (_userProfile != null) 
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
                                         '${_userProfile!['successful_transactions_count'] ?? 0} Deals Done',
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
                                         _userProfile!['response_speed'] ?? 'Replies fast',
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
                         const SizedBox(height: 24),
                        
                        if (_userProfile != null) ...[
                          if (_userProfile!['bio'] != null && _userProfile!['bio'].toString().trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                '"${_userProfile!['bio']}"',
                                style: GoogleFonts.outfit(fontStyle: FontStyle.italic, color: Colors.grey[700], fontSize: 15),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, color: Colors.teal),
                                const SizedBox(width: 8),
                                Text(
                                  "About Student",
                                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
                                ),
                              ],
                            ),
                          ),
                           if (_userProfile!['full_name'] != null)
                             _buildInfoRow('Full Name', _userProfile!['full_name']),
                           if (_userProfile!['university_id'] != null)
                             _buildInfoRow('Student ID', _userProfile!['university_id']),
                           if (_userProfile!['email'] != null)
                             _buildInfoRow('Email', _userProfile!['email']),
                           if (_userProfile!['phone_number'] != null)
                             _buildInfoRow('Phone Number', _userProfile!['phone_number']),
                           if (_userProfile!['faculty'] != null)
                             _buildInfoRow('Faculty', _userProfile!['faculty']),
                           if (_userProfile!['year_of_study'] != null)
                             _buildInfoRow('Year of Study', 'Year ${_userProfile!['year_of_study']}'),
                          
                          if (_userProfile!['email'] == null && _userProfile!['faculty'] == null && _userProfile!['year_of_study'] == null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Email, Faculty, and Year of Study are hidden (Profile Privacy: Private).",
                                      style: GoogleFonts.outfit(color: Colors.grey[600], fontStyle: FontStyle.italic, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                                              if (_userProfile != null) ...[
                           const Divider(),
                           Padding(
                             padding: const EdgeInsets.symmetric(vertical: 8.0),
                             child: Row(
                               children: [
                                 const Icon(Icons.emoji_events_outlined, color: Colors.teal),
                                 const SizedBox(width: 8),
                                 Text(
                                   "Achievements & Badges",
                                   style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
                                 ),
                               ],
                             ),
                           ),
                           const SizedBox(height: 8),
                           _userProfile!['badges'] == null || (_userProfile!['badges'] as List).isEmpty
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
                                   children: (_userProfile!['badges'] as List).map((badge) {
                                     final label = badge['label'] ?? '';
                                     final iconName = badge['icon'] ?? '';
                                     return Container(
                                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                       decoration: BoxDecoration(
                                         color: isDark ? Colors.orange.shade900.withValues(alpha: 0.2) : Colors.orange.shade50,
                                         borderRadius: BorderRadius.circular(16),
                                         border: Border.all(color: isDark ? Colors.orange.shade800.withValues(alpha: 0.4) : Colors.orange.shade200),
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
                         ],

                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              const Icon(Icons.rate_review_outlined, color: Colors.teal),
                              const SizedBox(width: 8),
                              Text(
                                "Reviews",
                                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 28),
                              const SizedBox(width: 8),
                              Text(
                                '${_userProfile?['reputation_score'] ?? '5.0'} / 5.0',
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '(${_reviews.length} reviews)',
                                style: GoogleFonts.outfit(
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
                                style: GoogleFonts.outfit(color: Colors.grey.shade500, fontStyle: FontStyle.italic),
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
                                            style: GoogleFonts.outfit(
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
                                        style: GoogleFonts.outfit(fontSize: 14, color: Colors.black87),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Ref: $productTitle',
                                        style: GoogleFonts.outfit(
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
                        
                        const Divider(),
                        const SizedBox(height: 16),
                        Text("Listings (${_listings.length})", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        
                        _listings.isEmpty 
                            ? Center(child: Text("No active listings", style: GoogleFonts.outfit(color: Colors.grey)))
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _listings.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                    final product = _listings[index];
                                    return GestureDetector(
                                        onTap: () => Navigator.push(context, MaterialPageRoute(
                                             builder: (_) => ProductDetailsPage(product: product)
                                         )).then((result) {
                                             if (result == 'reported') {
                                                 _fetchData();
                                             }
                                         }),
                                        child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(color: Colors.grey.shade200),
                                            ),
                                            child: Row(
                                                children: [
                                                    // Image
                                                    ClipRRect(
                                                        borderRadius: BorderRadius.circular(12),
                                                        child: product.imageUrl.isNotEmpty
                                                            ? CachedNetworkImage(imageUrl: product.imageUrl, width: 90, height: 90, fit: BoxFit.cover)
                                                            : Container(width: 90, height: 90, color: Colors.grey[200]),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    // Details
                                                    Expanded(
                                                        child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                                Text(product.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                                                                const SizedBox(height: 6),
                                                                Container(
                                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                                                    child: Text(product.type == 'Rent' ? 'RENTAL' : 'SALE', style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                                                                ),
                                                                const SizedBox(height: 8),
                                                                Text(
                                                                    'RM ${product.type == 'Rent' ? '${product.rentalPricePerDay.toStringAsFixed(2)}/day' : product.price.toStringAsFixed(2)}', 
                                                                    style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16)
                                                                ),
                                                            ],
                                                        )
                                                    ),
                                                    const Icon(Icons.chevron_right, color: Colors.grey)
                                                ],
                                            ),
                                        ),
                                    );
                                },
                            )
                    ],
                ),
            )
    );
  }

  void _showReportUserDialog(BuildContext context) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ReportUserPage(
                  userId: widget.userId,
                  username: widget.userName,
                  profilePicture: _userProfile?['profile_image_url'],
              ),
          ),
      );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsRow(String label, List<String> tags, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 3,
            child: Wrap(
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
          ),
        ],
      ),
    );
  }
}
