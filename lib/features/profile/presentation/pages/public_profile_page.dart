import 'package:flutter/material.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/features/home/domain/entities/product.dart';
import 'package:campus_swap/features/product/presentation/pages/product_details_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:campus_swap/core/session/user_session.dart';

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

  @override
  Widget build(BuildContext context) {
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
                                            '${double.parse(_userProfile!['reputation_score'].toString()).toStringAsFixed(1)} (${_userProfile!['total_reviews'] ?? 0})',
                                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Text("Member since ${_formatDate(_userProfile?['createdAt'])}", style: GoogleFonts.outfit(color: Colors.grey))
                                ],
                            ),
                        ),
                        const SizedBox(height: 32),
                        
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
                           if (_userProfile!['year_of_study'] != null)
                             _buildInfoRow('Year of Study', 'Year ${_userProfile!['year_of_study']}'),
                          
                          if (_userProfile!['email'] == null && _userProfile!['phone_number'] == null && _userProfile!['year_of_study'] == null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    "This profile is private.",
                                    style: GoogleFonts.outfit(color: Colors.grey[600], fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ),
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
                        Text("Listings", style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
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
      showDialog(
          context: context,
          builder: (context) {
              String description = '';
              String violationType = 'Harassment';
              bool isSubmitting = false;
              return StatefulBuilder(
                  builder: (context, setState) {
                      return AlertDialog(
                          title: Text('Report @${widget.userName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                  DropdownButtonFormField<String>(
                                      value: violationType,
                                      decoration: const InputDecoration(
                                          labelText: 'Reason for Report',
                                          border: OutlineInputBorder(),
                                      ),
                                      items: const [
                                          DropdownMenuItem(value: 'Harassment', child: Text('Offline Harassment')),
                                          DropdownMenuItem(value: 'No-show', child: Text('No-show / Flaked')),
                                          DropdownMenuItem(value: 'Scam', child: Text('Scam / Fraud')),
                                          DropdownMenuItem(value: 'Spam', child: Text('Spamming')),
                                          DropdownMenuItem(value: 'Other', child: Text('Other Misbehavior')),
                                      ],
                                      onChanged: (val) {
                                          if (val != null) {
                                              setState(() => violationType = val);
                                          }
                                      },
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                      onChanged: (val) => description = val,
                                      maxLines: 3,
                                      decoration: const InputDecoration(
                                          labelText: 'Details of Misconduct',
                                          hintText: 'Explain the issue or behavior...',
                                          border: OutlineInputBorder(),
                                      ),
                                  ),
                              ],
                          ),
                          actions: [
                              TextButton(
                                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                  onPressed: isSubmitting
                                      ? null
                                      : () async {
                                          if (description.trim().isEmpty) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Please provide details of misconduct')),
                                              );
                                              return;
                                          }
                                          setState(() => isSubmitting = true);
                                          try {
                                              final apiClient = ApiClient();
                                              await apiClient.post('/auth/user/${widget.userId}/report', {
                                                  'violation_type': violationType,
                                                  'description': description.trim(),
                                              });
                                              if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text('User reported successfully.'), backgroundColor: Colors.green),
                                                  );
                                                  Navigator.pop(context);
                                              }
                                          } catch (e) {
                                              if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('Failed to submit report: $e'), backgroundColor: Colors.red),
                                                  );
                                              }
                                          } finally {
                                              if (context.mounted) {
                                                  setState(() => isSubmitting = false);
                                              }
                                          }
                                      },
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006940)),
                                  child: isSubmitting
                                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Text('Submit', style: TextStyle(color: Colors.white)),
                              ),
                          ],
                      );
                  },
              );
          },
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
}
