import 'package:flutter/material.dart';
import 'package:campus_swap/core/api/api_client.dart';
import 'package:campus_swap/features/profile/presentation/pages/ticket_chat_page.dart';
import 'package:campus_swap/features/profile/presentation/pages/submit_ticket_page.dart';
import 'package:campus_swap/features/profile/presentation/pages/help_category_detail_page.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiClient _apiClient = ApiClient();
  
  List<dynamic> _reports = [];
  List<dynamic> _disputes = [];
  List<dynamic> _tickets = [];
  bool _isLoading = true;
  String _currentFilter = 'All'; // 'All', 'Pending', 'Resolved'

  int get _pendingCount {
    int count = 0;
    for (var t in _tickets) {
      if (t['status'] != 'Resolved') count++;
    }
    for (var d in _disputes) {
      if (d['status'] != 'Resolved') count++;
    }
    for (var r in _reports) {
      if (['Pending', 'In-Progress', 'Escalated', 'Awaiting Reply'].contains(r['status'])) count++;
    }
    return count;
  }

  int get _resolvedCount {
    int count = 0;
    for (var t in _tickets) {
      if (t['status'] == 'Resolved') count++;
    }
    for (var d in _disputes) {
      if (d['status'] == 'Resolved') count++;
    }
    for (var r in _reports) {
      if (['Uphold', 'Dismissed'].contains(r['status'])) count++;
    }
    return count;
  }

  List<dynamic> get _filteredReports {
    if (_currentFilter == 'Pending') {
      return _reports.where((r) => ['Pending', 'In-Progress', 'Escalated', 'Awaiting Reply'].contains(r['status'])).toList();
    } else if (_currentFilter == 'Resolved') {
      return _reports.where((r) => ['Uphold', 'Dismissed'].contains(r['status'])).toList();
    }
    return _reports;
  }

  List<dynamic> get _filteredDisputes {
    if (_currentFilter == 'Pending') {
      return _disputes.where((d) => d['status'] != 'Resolved').toList();
    } else if (_currentFilter == 'Resolved') {
      return _disputes.where((d) => d['status'] == 'Resolved').toList();
    }
    return _disputes;
  }

  List<dynamic> get _filteredTickets {
    if (_currentFilter == 'Pending') {
      return _tickets.where((t) => t['status'] != 'Resolved').toList();
    } else if (_currentFilter == 'Resolved') {
      return _tickets.where((t) => t['status'] == 'Resolved').toList();
    }
    return _tickets;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final reportsRes = await _apiClient.get('/tickets/my-reports');
      final disputesRes = await _apiClient.get('/tickets/my-disputes');
      final ticketsRes = await _apiClient.get('/tickets/my-tickets');
      
      if (mounted) {
        setState(() {
          _reports = reportsRes is List ? reportsRes : [];
          _disputes = disputesRes is List ? disputesRes : [];
          _tickets = ticketsRes is List ? ticketsRes : [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getBadgeColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
      case 'uphold':
      case 'completed':
        return const Color(0xFF4CAF50); // Green
      case 'in-progress':
      case 'investigating':
      case 'escalated':
        return const Color(0xFF2196F3); // Blue
      case 'awaiting reply':
        return const Color(0xFFFF5722); // Orange for awaiting reply
      case 'dismissed':
      case 'cancelled':
        return const Color(0xFFF44336); // Red
      case 'pending':
      case 'new':
      case 'open':
      default:
        return const Color(0xFFFFC107); // Yellow
    }
  }

  Widget _buildGridButton(IconData icon, String label) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (label == 'Order FAQs') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HelpCategoryDetailPage(
                    categoryName: 'Order FAQs',
                    introduction: 'Find answers about purchasing, selling, renting, payments, and disputes.',
                    faqs: [
                      HelpFaqItem(
                        question: 'How do I purchase an item?',
                        answer: 'Click "Buy Now" on any available listing. You can negotiate details with the seller via chat. Payments are held in escrow for your security.',
                      ),
                      HelpFaqItem(
                        question: 'How does renting work?',
                        answer: 'Rental listings require a daily rate and a security deposit. Once the rental duration ends, return the item and confirm with the seller to get your deposit back.',
                      ),
                      HelpFaqItem(
                        question: 'What is the escrow payment system?',
                        answer: 'When you pay for an item, the funds are held securely by the Campus Swap system. They are only released to the seller after you confirm receipt.',
                      ),
                      HelpFaqItem(
                        question: 'How do I cancel my order?',
                        answer: 'You can request order cancellation before the seller has scheduled a meetup. Go to your orders and click "Cancel".',
                      ),
                      HelpFaqItem(
                        question: 'How do I open a dispute?',
                        answer: 'If an item is not received, damaged, or fraudulent, you can open a dispute from the Order details screen to request admin mediation.',
                      ),
                      HelpFaqItem(
                        question: 'Where should I meet the seller?',
                        answer: 'We recommend using designated Safe Meetup Zones on campus. These are public, well-lit, and monitored areas.',
                      ),
                    ],
                  ),
                ),
              );
            } else if (label == 'Report App Issue') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SubmitTicketPage()));
            } else if (label == 'Account FAQs') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HelpCategoryDetailPage(
                    categoryName: 'Account FAQs',
                    introduction: 'Manage your profile, student verification, notifications, and security.',
                    faqs: [
                      HelpFaqItem(
                        question: 'How do I update my profile details?',
                        answer: 'Go to Profile -> Edit Profile to change your display name, bio, and contact preferences.',
                      ),
                      HelpFaqItem(
                        question: 'What is the Academic Identity / Student ID?',
                        answer: 'Your Student ID is verified during registration to ensure all campus swap users are active students. It cannot be edited after verification.',
                      ),
                      HelpFaqItem(
                        question: 'How is my sustainability rating calculated?',
                        answer: 'Your green score increases with every successful transaction. Reusing items on campus directly prevents carbon emissions.',
                      ),
                      HelpFaqItem(
                        question: 'What happens if I receive a warning or ban?',
                        answer: 'To maintain a safe campus environment, users who violate community guidelines may receive warnings, temporary suspensions, or permanent bans.',
                      ),
                      HelpFaqItem(
                        question: 'Can I change my registered email?',
                        answer: 'Your email is tied to your verified university domain and cannot be changed. If you need to update it, contact support.',
                      ),
                    ],
                  ),
                ),
              );
            } else if (label == 'Report User') {
              showDialog(
                context: context,
                builder: (context) {
                  String targetUsername = '';
                  String description = '';
                  bool isSubmitting = false;
                  return StatefulBuilder(
                    builder: (context, setState) {
                      return AlertDialog(
                        title: const Text('Report User', style: TextStyle(fontWeight: FontWeight.bold)),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              onChanged: (val) => targetUsername = val,
                              decoration: const InputDecoration(
                                labelText: 'Target Username (Optional)',
                                hintText: 'Enter username to report...',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              onChanged: (val) => description = val,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Details of Misconduct',
                                hintText: 'Explain the issue or harassment...',
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
                                      await apiClient.post('/tickets', {
                                        'category': 'Harassment',
                                        'subject': targetUsername.trim().isNotEmpty
                                            ? 'Reporting User: ${targetUsername.trim()}'
                                            : 'Reporting User',
                                        'description': description.trim(),
                                      });
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Report submitted successfully as a support ticket.')),
                                        );
                                        Navigator.pop(context);
                                        _fetchData();
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Failed to submit report: $e'), backgroundColor: Colors.red),
                                        );
                                      }
                                    } finally {
                                      setState(() => isSubmitting = false);
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
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF006940), size: 32),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard(dynamic item, String type) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    String title = '';
    String status = item['status'] ?? 'Unknown';
    String dateStr = item['createdAt'] != null ? item['createdAt'].toString().substring(0, 10) : 'Unknown date';
    String esgMessage = '';
    
    if (type == 'Report') {
      title = 'Reported Listing #${item['id'].toString().substring(0, 6).toUpperCase()}';
      if (status == 'Uphold') {
        esgMessage = "Thank you for your contribution to a safer, greener campus.";
      }
    } else if (type == 'Dispute') {
      title = 'Dispute on Order #${item['transaction_id'].toString().substring(0, 6).toUpperCase()}';
    } else {
      title = item['subject'] ?? 'Support Ticket #${item['id'].toString().substring(0, 6).toUpperCase()}';
    }

    return GestureDetector(
      onTap: () {
        if (type == 'Dispute' || type == 'SupportTicket') {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => TicketChatPage(
              referenceId: item['id'],
              referenceType: type,
              title: title,
              status: status,
            )
          )).then((_) => _fetchData());
        } else {
          // For Reports, just show dialog since it's one-way
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Report Details'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Reason: ${item['violation_type'] ?? 'Violation'}'),
                  const SizedBox(height: 8),
                  Text('Status: $status'),
                  if (esgMessage.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(esgMessage, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    )
                  ]
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))
              ],
            )
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getBadgeColor(status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                )
              ],
            ),
            const SizedBox(height: 8),
            Text('Created $dateStr', style: const TextStyle(color: Colors.grey, fontSize: 13)),
            if (esgMessage.isNotEmpty)
               Padding(
                 padding: const EdgeInsets.only(top: 8.0),
                 child: Text(esgMessage, style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
               )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryGreen = const Color(0xFF006940);
    final bgColor = isDark ? theme.colorScheme.surface : const Color(0xFFF9F9F9);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Help Center', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SubmitTicketPage()));
        },
        backgroundColor: primaryGreen,
        child: const Icon(Icons.headset_mic, color: Colors.white),
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Container(
                color: bgColor,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[850] : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          icon: Icon(Icons.search, color: Colors.grey),
                          hintText: 'Search for help...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Grid Options
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 2.0,
                      children: [
                        _buildGridButton(Icons.receipt_long, 'Order FAQs'),
                        _buildGridButton(Icons.person_outline, 'Account FAQs'),
                        _buildGridButton(Icons.flag_outlined, 'Report User'),
                        _buildGridButton(Icons.error_outline, 'Report App Issue'),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    const Text('My Support Tickets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _currentFilter = _currentFilter == 'Pending' ? 'All' : 'Pending';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _currentFilter == 'Pending' ? primaryGreen.withValues(alpha: 0.1) : (isDark ? Colors.grey[850] : Colors.white),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _currentFilter == 'Pending' ? primaryGreen : Colors.grey.withValues(alpha: 0.2),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$_pendingCount Pending',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _currentFilter == 'Pending' ? primaryGreen : (isDark ? Colors.white : Colors.black87),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Active Tickets',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _currentFilter = _currentFilter == 'Resolved' ? 'All' : 'Resolved';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _currentFilter == 'Resolved' ? Colors.green.withValues(alpha: 0.1) : (isDark ? Colors.grey[850] : Colors.white),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _currentFilter == 'Resolved' ? Colors.green : Colors.grey.withValues(alpha: 0.2),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$_resolvedCount Resolved',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _currentFilter == 'Resolved' ? Colors.green : (isDark ? Colors.white : Colors.black87),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'History',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: primaryGreen,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: primaryGreen,
                  tabs: const [
                    Tab(text: 'Reports'),
                    Tab(text: 'Disputes'),
                    Tab(text: 'Tickets'),
                  ],
                ),
                bgColor: isDark ? theme.colorScheme.surface : Colors.white,
              ),
            ),
          ];
        },
        body: Container(
          color: isDark ? theme.colorScheme.surface : const Color(0xFFF0F2F0),
          child: TabBarView(
            controller: _tabController,
            children: [
              // Reports Tab
              ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredReports.length,
                itemBuilder: (context, index) => _buildTicketCard(_filteredReports[index], 'Report'),
              ),
              
              // Disputes Tab
              ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredDisputes.length,
                itemBuilder: (context, index) => _buildTicketCard(_filteredDisputes[index], 'Dispute'),
              ),
              
              // Tickets Tab
              ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredTickets.length,
                itemBuilder: (context, index) => _buildTicketCard(_filteredTickets[index], 'SupportTicket'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar, {required this.bgColor});

  final TabBar _tabBar;
  final Color bgColor;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: bgColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return oldDelegate.bgColor != bgColor || oldDelegate._tabBar != _tabBar;
  }
}
